// UI helpers - speech bubble, listening indicator, history rendering.

const els = {};

export function init() {
  els.bubble = document.getElementById("speech-bubble");
  els.bubbleText = document.getElementById("speech-text");
  els.listening = document.getElementById("listening-indicator");
  els.history = document.getElementById("history");
  els.historyList = document.getElementById("history-list");
  els.statHunger = document.getElementById("stat-hunger");
  els.statHappiness = document.getElementById("stat-happiness");
  els.statEnergy = document.getElementById("stat-energy");
}

let bubbleHideTimer = null;
export function showBubble(text, persistMs = 0) {
  if (!els.bubble) return;
  els.bubbleText.textContent = text;
  els.bubble.hidden = false;
  if (bubbleHideTimer) clearTimeout(bubbleHideTimer);
  if (persistMs > 0) {
    bubbleHideTimer = setTimeout(() => hideBubble(), persistMs);
  }
}

export function updateBubble(text) {
  if (!els.bubble) return;
  els.bubbleText.textContent = text;
}

export function hideBubble() {
  if (!els.bubble) return;
  els.bubble.hidden = true;
  if (bubbleHideTimer) {
    clearTimeout(bubbleHideTimer);
    bubbleHideTimer = null;
  }
}

export function setListening(on) {
  if (!els.listening) return;
  els.listening.hidden = !on;
}

export function setStats(stats) {
  if (els.statHunger) els.statHunger.style.width = `${Math.max(0, Math.min(100, stats.hunger))}%`;
  if (els.statHappiness) els.statHappiness.style.width = `${Math.max(0, Math.min(100, stats.happiness))}%`;
  if (els.statEnergy) els.statEnergy.style.width = `${Math.max(0, Math.min(100, stats.energy))}%`;
}

export function renderHistory(history) {
  if (!els.historyList) return;
  els.historyList.innerHTML = "";
  if (!history.length) {
    const empty = document.createElement("div");
    empty.className = "msg oksi";
    empty.textContent = "История пуста. Поговори со мной! 🗣️";
    els.historyList.appendChild(empty);
    return;
  }
  for (const item of history) {
    const div = document.createElement("div");
    div.className = `msg ${item.role === "user" ? "user" : "oksi"}`;
    div.textContent = item.text;
    const time = document.createElement("div");
    time.className = "msg-time";
    time.textContent = formatTime(item.ts);
    div.appendChild(time);
    els.historyList.appendChild(div);
  }
  els.historyList.scrollTop = els.historyList.scrollHeight;
}

function formatTime(ts) {
  const d = new Date(ts);
  return d.toLocaleTimeString("ru-RU", { hour: "2-digit", minute: "2-digit" });
}

export function showHistory() { els.history.hidden = false; }
export function hideHistory() { els.history.hidden = true; }
