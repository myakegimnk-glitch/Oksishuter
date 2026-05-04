// Persistent state via localStorage.
const KEY = "oksiTalking.v1";

const defaults = () => ({
  groqKey: "",
  groqModel: "llama-3.3-70b-versatile",
  skin: "green",
  mode: "ai", // ai | echo | both
  tts: true,
  pitchEnabled: true,
  rate: 1.05,
  pitch: 1.4,
  persona:
    "Ты — Окси, дерзкая, дружелюбная и очень разговорчивая виртуальная помощница в виде пухлого милого персонажа. " +
    "Ты говоришь по-русски, отвечаешь коротко (1-3 предложения), с юмором, эмодзи иногда уместны. " +
    "Ты любишь поесть, поспать и обниматься. Если пользователь грубит — отшучивайся.",
  stats: { hunger: 80, happiness: 80, energy: 80 },
  history: [],
  hasSeenWelcome: false,
  bannerDismissed: false,
});

let state = load();

function load() {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return defaults();
    const parsed = JSON.parse(raw);
    return { ...defaults(), ...parsed, stats: { ...defaults().stats, ...(parsed.stats || {}) } };
  } catch {
    return defaults();
  }
}

function save() {
  try {
    localStorage.setItem(KEY, JSON.stringify(state));
  } catch (e) {
    console.warn("storage save failed", e);
  }
}

export function get() {
  return state;
}

export function update(patch) {
  state = { ...state, ...patch };
  save();
  return state;
}

export function updateStats(patch) {
  state.stats = { ...state.stats, ...patch };
  // Clamp to [0, 100]
  for (const k of Object.keys(state.stats)) {
    state.stats[k] = Math.max(0, Math.min(100, state.stats[k]));
  }
  save();
  return state.stats;
}

export function addHistory(role, text) {
  state.history.push({ role, text, ts: Date.now() });
  // Keep last 100 messages
  if (state.history.length > 100) {
    state.history = state.history.slice(-100);
  }
  save();
}

export function clearHistory() {
  state.history = [];
  save();
}

export function reset() {
  state = defaults();
  save();
}
