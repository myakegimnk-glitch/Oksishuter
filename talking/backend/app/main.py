"""FastAPI backend that proxies chat requests to Groq.

Lets the frontend call the LLM without exposing the API key in the browser.
The key is read from the OKSI environment variable (or GROQ_API_KEY as fallback).

Includes a tiny per-IP rate limiter to discourage abuse since the endpoint is
public.
"""
from __future__ import annotations

import asyncio
import os
import time
from collections import defaultdict, deque
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"

# Models we allow callers to request.
ALLOWED_MODELS = {
    "llama-3.3-70b-versatile",
    "llama-3.1-8b-instant",
    "mixtral-8x7b-32768",
}
DEFAULT_MODEL = "llama-3.3-70b-versatile"

# Per-IP simple token bucket: max RPM_LIMIT requests in WINDOW_SECONDS.
RPM_LIMIT = int(os.environ.get("RPM_LIMIT", "20"))
WINDOW_SECONDS = 60

_rate_state: dict[str, deque[float]] = defaultdict(deque)
_rate_lock = asyncio.Lock()


def _api_key() -> str | None:
    return os.environ.get("OKSI") or os.environ.get("GROQ_API_KEY")


class Message(BaseModel):
    role: str = Field(pattern=r"^(system|user|assistant)$")
    content: str


class ChatRequest(BaseModel):
    messages: list[Message]
    model: str = DEFAULT_MODEL
    temperature: float = 0.85
    max_tokens: int = 220
    top_p: float = 0.95


class ChatResponse(BaseModel):
    text: str
    model: str
    usage: dict[str, Any] | None = None


app = FastAPI(title="Oksi Talking Backend", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)


async def _check_rate(ip: str) -> None:
    now = time.monotonic()
    async with _rate_lock:
        dq = _rate_state[ip]
        while dq and dq[0] < now - WINDOW_SECONDS:
            dq.popleft()
        if len(dq) >= RPM_LIMIT:
            raise HTTPException(status_code=429, detail="rate-limited")
        dq.append(now)


@app.get("/")
async def root() -> dict[str, Any]:
    return {
        "service": "oksi-talking-backend",
        "ok": True,
        "has_key": _api_key() is not None,
        "models": sorted(ALLOWED_MODELS),
    }


@app.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest, request: Request) -> ChatResponse:
    key = _api_key()
    if not key:
        raise HTTPException(status_code=503, detail="server-no-key")
    if req.model not in ALLOWED_MODELS:
        raise HTTPException(status_code=400, detail=f"model not allowed: {req.model}")
    if not req.messages:
        raise HTTPException(status_code=400, detail="empty-messages")

    client_ip = request.client.host if request.client else "unknown"
    await _check_rate(client_ip)

    body = {
        "model": req.model,
        "messages": [m.model_dump() for m in req.messages],
        "temperature": req.temperature,
        "max_tokens": req.max_tokens,
        "top_p": req.top_p,
    }
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {key}",
    }
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            r = await client.post(GROQ_URL, json=body, headers=headers)
    except httpx.RequestError as e:
        raise HTTPException(status_code=502, detail=f"upstream-network: {e}") from e

    if r.status_code >= 400:
        # Don't leak key, but pass through useful info.
        try:
            payload = r.json()
        except Exception:  # noqa: BLE001
            payload = {"raw": r.text[:500]}
        raise HTTPException(status_code=r.status_code, detail={"upstream": payload})

    j = r.json()
    text = ""
    try:
        text = j["choices"][0]["message"]["content"].strip()
    except (KeyError, IndexError, AttributeError):
        text = ""
    return ChatResponse(text=text or "...", model=req.model, usage=j.get("usage"))
