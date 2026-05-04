# Oksi Talking Backend

Минимальный FastAPI прокси к Groq API. Хранит API-ключ на сервере, чтобы фронтенд не выставлял его в браузер.

## Запуск локально

```bash
cd backend
pip install -e .
export OKSI=gsk_xxx  # или GROQ_API_KEY
uvicorn app.main:app --port 8766 --reload
```

Проверь:
```bash
curl http://localhost:8766/
curl -X POST http://localhost:8766/chat \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Привет!"}],"model":"llama-3.1-8b-instant"}'
```

## Endpoints

| Метод | URL | Описание |
|-------|-----|----------|
| GET | `/` | Статус сервиса, наличие ключа |
| GET | `/healthz` | Health check |
| POST | `/chat` | Прокси к Groq Chat Completions |

### POST /chat

Тело:
```json
{
  "messages": [
    { "role": "system", "content": "Ты — Окси..." },
    { "role": "user", "content": "Привет!" }
  ],
  "model": "llama-3.3-70b-versatile",
  "temperature": 0.85,
  "max_tokens": 220,
  "top_p": 0.95
}
```

Ответ:
```json
{
  "text": "Привет! 👋",
  "model": "llama-3.3-70b-versatile",
  "usage": { "prompt_tokens": 32, "completion_tokens": 5, ... }
}
```

## Защита от злоупотреблений

- Per-IP rate limit: `RPM_LIMIT` запросов в минуту (по умолчанию 20).
- Whitelist моделей (см. `ALLOWED_MODELS` в `app/main.py`).

## Деплой

Поддерживается деплой через `deploy backend` (Fly.io). После деплоя установи секрет:
```bash
fly secrets set OKSI=gsk_xxx --app <имя-приложения>
```

Затем настрой фронтенд:
- Параметр URL: `?backend=https://<твой-app>.fly.dev`
- Или константа: `window.OKSI_BACKEND = 'https://<твой-app>.fly.dev'`
- Или поставить фронтенд за тем же доменом — proxy подхватится автоматически
