// Groq API client.
// Tries the backend proxy first (server-side key), then BYOK (user key in settings),
// then falls back to local canned replies so the pet game still works.

const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";

// Backend proxy URL. Resolved relative to the page so a same-origin deploy
// works without configuration; can be overridden by ?backend=URL or window.OKSI_BACKEND.
function backendUrl() {
  if (typeof window !== "undefined" && window.OKSI_BACKEND) return window.OKSI_BACKEND;
  const params = new URLSearchParams(window.location.search);
  if (params.get("backend")) return params.get("backend");
  // Cached from a previous /chat probe.
  const cached = localStorage.getItem("oksi.backend");
  if (cached) return cached;
  return null;
}

let _backendKnown = null; // null = unknown, true/false = probed

async function probeBackend() {
  if (_backendKnown !== null) return _backendKnown;
  const candidates = [];
  const explicit = backendUrl();
  if (explicit) candidates.push(explicit.replace(/\/+$/, ""));
  // Same-origin fallback (e.g. behind same domain via reverse proxy)
  candidates.push("");
  for (const base of candidates) {
    try {
      const r = await fetch(`${base}/healthz`, { method: "GET", cache: "no-store" });
      if (r.ok) {
        const j = await r.json().catch(() => ({}));
        if (j.status === "ok") {
          _backendKnown = base;
          if (base) localStorage.setItem("oksi.backend", base);
          return base;
        }
      }
    } catch {
      // continue
    }
  }
  _backendKnown = false;
  return false;
}

const FALLBACK_REPLIES = [
  "Я тебя слышу, но без API-ключа я могу только повторять и обниматься 🥺",
  "Дай мне Groq-ключ в настройках, и я буду умнее любого кота 🐱",
  "Без ИИ я как Том — повторяю за тобой высоким голосом. Открой настройки!",
  "Хочу думать, но мне нужен ключ Groq в настройках ⚙️",
  "Эй, я слышу, но без ключа я могу только мяукать 😺",
];

const MOOD_REPLIES = {
  hungry: ["Я голодная! Покорми меня 🍕", "Желудок урчит... 🍔", "Дай чего-нибудь вкусненького!"],
  sleepy: ["Я устааала... 💤", "Спать охота...", "Уложи меня поспать 🥱"],
  sad: ["Мне грустно 😢", "Поговори со мной 🥺", "Обними меня?"],
  happy: ["Я в отличном настроении! 🌟", "Жизнь прекрасна 💖", "Ура! Мы вместе 🎉"],
};

export async function chat({ apiKey, model, persona, history, userMessage }) {
  // Build messages array with last few turns
  const msgs = [
    { role: "system", content: persona || "Ты — Окси, дружелюбная виртуальная подруга. Отвечай коротко и весело по-русски." },
  ];
  for (const h of history.slice(-8)) {
    msgs.push({ role: h.role === "user" ? "user" : "assistant", content: h.text });
  }
  msgs.push({ role: "user", content: userMessage });

  const requestModel = model || "llama-3.3-70b-versatile";

  // 1) Try backend proxy (server holds the key)
  const backend = await probeBackend();
  if (backend !== false) {
    try {
      const r = await fetch(`${backend}/chat`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ messages: msgs, model: requestModel }),
      });
      if (r.ok) {
        const j = await r.json();
        if (j.text) return j.text;
      } else if (r.status === 503) {
        // server has no key; fall through to BYOK
      } else if (r.status === 429) {
        return "Слишком много запросов, дай мне минутку отдохнуть 😅";
      }
    } catch (e) {
      console.warn("backend proxy failed", e);
    }
  }

  // 2) BYOK fallback - call Groq directly with user-provided key
  if (!apiKey) {
    return pickRandom(FALLBACK_REPLIES);
  }

  try {
    const res = await fetch(GROQ_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: requestModel,
        messages: msgs,
        temperature: 0.85,
        max_tokens: 220,
        top_p: 0.95,
      }),
    });
    if (!res.ok) {
      const errText = await res.text().catch(() => "");
      console.warn("groq err", res.status, errText);
      if (res.status === 401) return "API-ключ не подходит. Проверь его в настройках ⚙️";
      if (res.status === 429) return "Слишком много запросов, дай мне минутку отдохнуть 😅";
      return "Ой, что-то с ИИ. Попробуй ещё раз чуть позже 🥺";
    }
    const json = await res.json();
    const text = json?.choices?.[0]?.message?.content?.trim();
    return text || "Хм... я не знаю что ответить 🤔";
  } catch (e) {
    console.warn("groq fetch failed", e);
    return "Связь пропала. Проверь интернет 📶";
  }
}

export function moodReply(mood) {
  const list = MOOD_REPLIES[mood];
  if (!list) return null;
  return pickRandom(list);
}

function pickRandom(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

const JOKES = [
  "Заходит улитка в бар и говорит: «Дайте мне виски!» Бармен её выкидывает. Через год улитка возвращается: «А чё это было?» 🐌",
  "— Доктор, я каждое утро в 7 утра хожу в туалет! — А в чём проблема? — В том, что я просыпаюсь в 8! 😆",
  "Кошка зашла в магазин и говорит: «Мне молока». Продавец: «Хвост покажи!» — «При чём тут хвост?!» — «Так у нас скидка по карте лояльности!» 🐈",
  "Что говорит программист, когда не может найти баг? «Это не баг, это фича!» 🐛",
  "Окси заходит в кафе. Официант: «Вам что?» Окси: «Мне всё. И себе тоже возьмите!» 🍰",
  "— Алло, это пицца? — Нет, это окси, и мне грустно. Ты любишь меня? 🥺",
];

export function getJoke() {
  return pickRandom(JOKES);
}
