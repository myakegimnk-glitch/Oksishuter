// Main controller - wires up all modules.

import * as storage from "./storage.js";
import * as speech from "./speech.js";
import * as tts from "./tts.js";
import * as ai from "./ai.js";
import * as echo from "./echo.js";
import * as character from "./character.js";
import * as game from "./game.js";
import * as ui from "./ui.js";

const els = {};
let isListening = false;
let isSpeaking = false;
let isEchoing = false;

document.addEventListener("DOMContentLoaded", () => {
  cacheElements();
  character.init();
  ui.init();
  bindEvents();
  // Allow magic-link key auto-import (#k=<groq_key>) — useful for first-time mobile setup.
  importKeyFromHash();
  applyState();
  game.start({
    onUpdate: (stats) => {
      ui.setStats(stats);
      respondToMood();
    },
  });
  character.startIdleMouth();
  refreshAiBanner();

  if (!storage.get().hasSeenWelcome) {
    showWelcome();
  } else {
    greet();
  }
});

function cacheElements() {
  els.btnTalk = document.getElementById("btn-talk");
  els.btnFeed = document.getElementById("btn-feed");
  els.btnPet = document.getElementById("btn-pet");
  els.btnSleep = document.getElementById("btn-sleep");
  els.btnJoke = document.getElementById("btn-joke");
  els.btnMode = document.getElementById("btn-mode");
  els.modeIcon = document.getElementById("mode-icon");
  els.modeLabel = document.getElementById("mode-label");

  els.btnSettings = document.getElementById("btn-settings");
  els.btnHistory = document.getElementById("btn-history");
  els.btnCloseHistory = document.getElementById("btn-close-history");
  els.btnClearHistory = document.getElementById("btn-clear-history");

  els.settingsModal = document.getElementById("settings-modal");
  els.btnCloseSettings = document.getElementById("btn-close-settings");
  els.welcomeModal = document.getElementById("welcome-modal");
  els.btnWelcomeStart = document.getElementById("btn-welcome-start");

  els.setSkin = document.getElementById("setting-skin");
  els.setMode = document.getElementById("setting-mode");
  els.setKey = document.getElementById("setting-groq-key");
  els.setModel = document.getElementById("setting-groq-model");
  els.setPersona = document.getElementById("setting-persona");
  els.setTts = document.getElementById("setting-tts");
  els.setPitchEnabled = document.getElementById("setting-pitch");
  els.setRate = document.getElementById("setting-rate");
  els.setPitch = document.getElementById("setting-pitch-value");
  els.rateVal = document.getElementById("rate-value");
  els.pitchVal = document.getElementById("pitch-value");
  els.btnTestVoice = document.getElementById("btn-test-voice");

  els.welcomeKey = document.getElementById("welcome-groq-key");
  els.aiBanner = document.getElementById("ai-banner");
  els.btnBannerSettings = document.getElementById("btn-banner-settings");
  els.btnBannerDismiss = document.getElementById("btn-banner-dismiss");
}

function bindEvents() {
  // Main actions
  els.btnTalk.addEventListener("click", onTalk);
  els.btnFeed.addEventListener("click", onFeed);
  els.btnPet.addEventListener("click", onPet);
  els.btnSleep.addEventListener("click", onSleep);
  els.btnJoke.addEventListener("click", onJoke);
  els.btnMode.addEventListener("click", onToggleMode);

  // Top bar
  els.btnSettings.addEventListener("click", openSettings);
  els.btnHistory.addEventListener("click", openHistory);
  els.btnCloseHistory.addEventListener("click", ui.hideHistory);
  els.btnClearHistory.addEventListener("click", () => {
    storage.clearHistory();
    ui.renderHistory([]);
  });

  els.btnCloseSettings.addEventListener("click", closeSettings);
  els.btnWelcomeStart.addEventListener("click", () => {
    const k = (els.welcomeKey?.value || "").trim();
    if (k) storage.update({ groqKey: k });
    storage.update({ hasSeenWelcome: true });
    els.welcomeModal.hidden = true;
    refreshAiBanner();
    greet();
  });
  els.welcomeKey?.addEventListener("input", (e) => {
    const v = e.target.value.trim();
    if (v) storage.update({ groqKey: v });
    refreshAiBanner();
  });

  // AI banner
  els.btnBannerSettings.addEventListener("click", () => {
    els.aiBanner.hidden = true;
    openSettings();
    setTimeout(() => els.setKey?.focus(), 100);
  });
  els.btnBannerDismiss.addEventListener("click", () => {
    storage.update({ bannerDismissed: true });
    els.aiBanner.hidden = true;
  });

  // Settings inputs - live save
  els.setSkin.addEventListener("change", (e) => {
    storage.update({ skin: e.target.value });
    character.setSkin(e.target.value);
  });
  els.setMode.addEventListener("change", (e) => {
    storage.update({ mode: e.target.value });
    updateModeButton();
  });
  els.setKey.addEventListener("input", (e) => {
    storage.update({ groqKey: e.target.value.trim() });
    refreshAiBanner();
  });
  els.setModel.addEventListener("change", (e) => storage.update({ groqModel: e.target.value }));
  els.setPersona.addEventListener("input", (e) => storage.update({ persona: e.target.value }));
  els.setTts.addEventListener("change", (e) => storage.update({ tts: e.target.checked }));
  els.setPitchEnabled.addEventListener("change", (e) => storage.update({ pitchEnabled: e.target.checked }));
  els.setRate.addEventListener("input", (e) => {
    const v = parseFloat(e.target.value);
    storage.update({ rate: v });
    els.rateVal.textContent = v.toFixed(2);
  });
  els.setPitch.addEventListener("input", (e) => {
    const v = parseFloat(e.target.value);
    storage.update({ pitch: v });
    els.pitchVal.textContent = v.toFixed(2);
  });
  els.btnTestVoice.addEventListener("click", testVoice);

  // Tap on character
  character.on((evt) => {
    if (evt === "tap") onPet();
  });

  // Hotkey: space = talk
  document.addEventListener("keydown", (e) => {
    if (e.code === "Space" && document.activeElement?.tagName !== "TEXTAREA" && document.activeElement?.tagName !== "INPUT") {
      e.preventDefault();
      onTalk();
    }
  });
}

function applyState() {
  const s = storage.get();
  character.setSkin(s.skin);
  els.setSkin.value = s.skin;
  els.setMode.value = s.mode;
  els.setKey.value = s.groqKey;
  els.setModel.value = s.groqModel;
  els.setPersona.value = s.persona;
  els.setTts.checked = s.tts;
  els.setPitchEnabled.checked = s.pitchEnabled;
  els.setRate.value = s.rate;
  els.setPitch.value = s.pitch;
  els.rateVal.textContent = s.rate.toFixed(2);
  els.pitchVal.textContent = s.pitch.toFixed(2);
  ui.setStats(s.stats);
  updateModeButton();
}

function updateModeButton() {
  const mode = storage.get().mode;
  if (mode === "echo") {
    els.modeIcon.textContent = "🦜";
    els.modeLabel.textContent = "Эхо";
  } else if (mode === "both") {
    els.modeIcon.textContent = "🎭";
    els.modeLabel.textContent = "Оба";
  } else {
    els.modeIcon.textContent = "🤖";
    els.modeLabel.textContent = "ИИ";
  }
}

function showWelcome() {
  els.welcomeKey.value = storage.get().groqKey || "";
  els.welcomeModal.hidden = false;
  els.aiBanner.hidden = true;
}

function refreshAiBanner() {
  // Show banner only when no key is configured AND user hasn't dismissed it
  // AND welcome modal is not currently up.
  const s = storage.get();
  const hasKey = !!(s.groqKey && s.groqKey.length > 10);
  const welcomeUp = !els.welcomeModal.hidden;
  const shouldShow = !hasKey && !s.bannerDismissed && !welcomeUp;
  els.aiBanner.hidden = !shouldShow;
}

function openSettings() {
  applyState(); // refresh values
  els.settingsModal.hidden = false;
}
function closeSettings() {
  els.settingsModal.hidden = true;
}

function openHistory() {
  ui.renderHistory(storage.get().history);
  ui.showHistory();
}

function greet() {
  const greetings = [
    "Привет! Я Окси 👋",
    "О, ты пришёл! 💖",
    "Соскучилась! 🥰",
    "Привет-привет! 😊",
    "Эй, как дела? 🌟",
  ];
  const text = greetings[Math.floor(Math.random() * greetings.length)];
  oksiSay(text);
  character.bounce();
}

async function onTalk() {
  if (isListening) {
    speech.stopCurrent();
    return;
  }
  if (isSpeaking || isEchoing) {
    tts.cancel();
    isSpeaking = false;
    isEchoing = false;
  }

  const mode = storage.get().mode;

  if (mode === "echo") {
    return runEcho();
  }
  if (mode === "both") {
    // "Both" = run AI, but if no key, fallback to echo
    if (!storage.get().groqKey) return runEcho();
  }

  if (!speech.isSupported()) {
    oksiSay("Браузер не поддерживает распознавание речи 😔 Попробуй Chrome на Android.");
    return;
  }

  isListening = true;
  els.btnTalk.classList.add("recording");
  ui.setListening(true);
  ui.showBubble("Слушаю...", 0);

  try {
    const text = await speech.listenOnce({
      lang: "ru-RU",
      onInterim: (interim) => ui.updateBubble(interim),
      onError: (e) => console.warn("speech err", e),
    });
    isListening = false;
    els.btnTalk.classList.remove("recording");
    ui.setListening(false);
    ui.hideBubble();

    if (!text || !text.trim()) {
      oksiSay("Я ничего не услышала 🥺 Скажи громче!");
      return;
    }
    storage.addHistory("user", text);
    await replyWithAI(text);
  } catch (e) {
    isListening = false;
    els.btnTalk.classList.remove("recording");
    ui.setListening(false);
    ui.hideBubble();
    if (e?.message === "speech-not-supported") {
      oksiSay("Браузер не поддерживает распознавание речи 😔");
    } else if (e?.message === "not-allowed") {
      oksiSay("Дай мне доступ к микрофону, и я тебя услышу! 🎤");
    } else {
      console.warn(e);
      oksiSay("Ой, не получилось услышать. Попробуй ещё раз!");
    }
  }
}

async function replyWithAI(userMessage) {
  const s = storage.get();
  ui.showBubble("Думаю...", 0);
  const reply = await ai.chat({
    apiKey: s.groqKey,
    model: s.groqModel,
    persona: s.persona,
    history: s.history,
    userMessage,
  });
  storage.addHistory("oksi", reply);
  await oksiSay(reply);
}

async function oksiSay(text, opts = {}) {
  if (!text) return;
  ui.showBubble(text, opts.persistMs ?? 0);
  character.reactToText(text);

  const s = storage.get();
  if (!s.tts) {
    setTimeout(() => ui.hideBubble(), 3500);
    return;
  }

  isSpeaking = true;
  character.stopIdleMouth();
  await tts.speak(text, {
    rate: s.rate,
    pitch: s.pitchEnabled ? s.pitch : 1.0,
    onLevel: (lvl) => character.setMouth(lvl),
    onEnd: () => {
      character.setMouth(0);
      character.startIdleMouth();
      isSpeaking = false;
      setTimeout(() => ui.hideBubble(), 1500);
    },
  });
}

async function runEcho() {
  if (!echo.isSupported()) {
    oksiSay("Браузер не поддерживает запись звука 😔");
    return;
  }
  if (isEchoing) return;
  isEchoing = true;

  els.btnTalk.classList.add("recording");
  ui.setListening(true);
  ui.showBubble("Говори, я повторю...", 0);

  let stopFn = null;
  // Allow tap to stop early
  const onClick = () => stopFn?.();
  els.btnTalk.addEventListener("click", onClick, { once: true });

  try {
    const s = storage.get();
    character.stopIdleMouth();
    await echo.echoCycle({
      maxMs: 6000,
      pitch: s.pitchEnabled ? Math.max(1.2, s.pitch) : 1.4,
      onLevel: (lvl) => character.setMouth(lvl),
      onRecordStart: () => {},
      onRecordEnd: () => {
        ui.setListening(false);
        els.btnTalk.classList.remove("recording");
        ui.showBubble("...", 1500);
      },
      onPlayEnd: () => {
        character.setMouth(0);
        character.startIdleMouth();
      },
    });
  } catch (e) {
    console.warn("echo err", e);
    if (e?.name === "NotAllowedError" || /denied|permission/i.test(String(e?.message))) {
      oksiSay("Дай доступ к микрофону! 🎤");
    } else {
      oksiSay("Ой, не получилось. Попробуй ещё!");
    }
  } finally {
    isEchoing = false;
    els.btnTalk.classList.remove("recording");
    ui.setListening(false);
    els.btnTalk.removeEventListener("click", onClick);
    ui.hideBubble();
  }
}

function onFeed() {
  game.feed(25);
  character.showEmote("🍕");
  character.bounce();
  oksiSay(pickRandom([
    "Ммм, вкусно! 😋",
    "Спасибо! 🤤",
    "Ещё хочу! 🍕",
    "Объедение! 💕",
  ]));
}

function onPet() {
  game.pet(20);
  character.showHeart();
  character.showEmote("💖");
  oksiSay(pickRandom([
    "Приятно... 🥰",
    "Ещё-ещё! 💖",
    "Я тебя люблю! 💕",
    "Мур-мур 😻",
    "Ой, щекотно! 🤭",
  ]));
}

function onSleep() {
  game.sleep(40);
  character.setSleeping(true);
  oksiSay("Спокойной ночи... 💤", { persistMs: 3000 });
  setTimeout(() => {
    character.setSleeping(false);
    oksiSay("Я отдохнула! 🌟");
  }, 3500);
}

function onJoke() {
  const joke = ai.getJoke();
  storage.addHistory("oksi", joke);
  oksiSay(joke);
  character.bounce();
}

function onToggleMode() {
  const cur = storage.get().mode;
  const next = cur === "ai" ? "echo" : cur === "echo" ? "both" : "ai";
  storage.update({ mode: next });
  els.setMode.value = next;
  updateModeButton();
  const labels = { ai: "Режим: ИИ 🤖", echo: "Режим: Эхо 🦜", both: "Режим: Оба 🎭" };
  oksiSay(labels[next]);
}

let lastMoodReplyAt = 0;
function respondToMood() {
  // Don't spam mood-based comments
  if (Date.now() - lastMoodReplyAt < 30_000) return;
  if (isSpeaking || isListening || isEchoing) return;
  const mood = game.getMood();
  if (mood === "ok") return;
  const reply = ai.moodReply(mood);
  if (reply && Math.random() < 0.4) {
    lastMoodReplyAt = Date.now();
    oksiSay(reply);
  }
}

async function testVoice() {
  const s = storage.get();
  await tts.speak("Привет! Я Окси, твоя говорящая помощница. Как тебе мой голос?", {
    rate: s.rate,
    pitch: s.pitchEnabled ? s.pitch : 1.0,
    onLevel: (lvl) => character.setMouth(lvl),
    onEnd: () => character.setMouth(0),
  });
}

function pickRandom(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function importKeyFromHash() {
  const hash = window.location.hash || "";
  if (!hash) return;
  const params = new URLSearchParams(hash.slice(1));
  const key = params.get("k") || params.get("groq");
  if (!key) return;
  storage.update({ groqKey: key.trim() });
  // Strip the hash so the key isn't lingering in the URL bar.
  history.replaceState(null, "", window.location.pathname + window.location.search);
}
