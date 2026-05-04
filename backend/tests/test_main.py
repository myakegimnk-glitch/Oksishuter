"""Smoke tests for the Oksi Talking backend."""
from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import app


def test_root() -> None:
    client = TestClient(app)
    r = client.get("/")
    assert r.status_code == 200
    body = r.json()
    assert body["service"] == "oksi-talking-backend"
    assert body["ok"] is True
    assert "models" in body


def test_healthz() -> None:
    client = TestClient(app)
    r = client.get("/healthz")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_chat_rejects_unknown_model() -> None:
    client = TestClient(app)
    r = client.post(
        "/chat",
        json={
            "messages": [{"role": "user", "content": "hi"}],
            "model": "evil-model",
        },
    )
    assert r.status_code == 400


def test_chat_rejects_empty_messages() -> None:
    client = TestClient(app)
    r = client.post(
        "/chat",
        json={"messages": [], "model": "llama-3.1-8b-instant"},
    )
    # Either 400 (empty-messages) or 422 from pydantic — both acceptable.
    assert r.status_code in (400, 422)
