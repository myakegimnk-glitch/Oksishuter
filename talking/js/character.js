// Character animation - mouth lip-sync, emotions, reactions.

const els = {
  character: null,
  img: null,
  mouth: null,
  emote: null,
  zzz: null,
  heart: null,
};

let mouthSmooth = 0;

export function init() {
  els.character = document.getElementById("character");
  els.img = document.getElementById("character-img");
  els.mouth = document.getElementById("mouth-overlay");
  els.emote = document.getElementById("emote");
  els.zzz = document.getElementById("zzz");
  els.heart = document.getElementById("heart");

  // Tap on character = pet it
  els.character.addEventListener("click", () => {
    triggerEvent("tap");
  });
}

let listeners = new Set();
export function on(handler) { listeners.add(handler); }
function triggerEvent(name) { listeners.forEach((h) => h(name)); }

/**
 * Set mouth opening level (0-1). Smoothed for natural look.
 */
export function setMouth(level) {
  // Smooth toward target
  mouthSmooth = mouthSmooth * 0.6 + level * 0.4;
  const scale = 0.05 + mouthSmooth * 1.4;
  if (els.mouth) {
    els.mouth.style.transform = `scaleY(${scale})`;
  }
}

let mouthIdleRaf = null;
export function startIdleMouth() {
  stopIdleMouth();
  const start = performance.now();
  const tick = (now) => {
    const t = (now - start) / 1000;
    // Tiny idle movement
    const lvl = 0.02 + 0.02 * Math.sin(t * 1.2);
    setMouth(lvl);
    mouthIdleRaf = requestAnimationFrame(tick);
  };
  mouthIdleRaf = requestAnimationFrame(tick);
}

export function stopIdleMouth() {
  if (mouthIdleRaf) {
    cancelAnimationFrame(mouthIdleRaf);
    mouthIdleRaf = null;
  }
  setMouth(0);
}

export function showEmote(emoji, duration = 1500) {
  if (!els.emote) return;
  els.emote.textContent = emoji;
  els.emote.classList.remove("show");
  // Force reflow
  void els.emote.offsetWidth;
  els.emote.classList.add("show");
  setTimeout(() => {
    els.emote.classList.remove("show");
    els.emote.textContent = "";
  }, duration);
}

export function showHeart() {
  if (!els.heart) return;
  els.heart.hidden = false;
  els.heart.classList.remove("show");
  void els.heart.offsetWidth;
  els.heart.classList.add("show");
  setTimeout(() => {
    els.heart.classList.remove("show");
    els.heart.hidden = true;
  }, 1200);
}

export function bounce() {
  if (!els.character) return;
  els.character.classList.remove("bounce");
  void els.character.offsetWidth;
  els.character.classList.add("bounce");
  setTimeout(() => els.character.classList.remove("bounce"), 600);
}

export function shake() {
  if (!els.character) return;
  els.character.classList.remove("shake");
  void els.character.offsetWidth;
  els.character.classList.add("shake");
  setTimeout(() => els.character.classList.remove("shake"), 500);
}

export function setSleeping(sleeping) {
  if (!els.character) return;
  els.character.classList.toggle("sleeping", sleeping);
  if (els.zzz) els.zzz.hidden = !sleeping;
}

export function setSkin(skin) {
  if (!els.img) return;
  const map = { green: "assets/oksi-green.png", pink: "assets/oksi-pink.png" };
  els.img.src = map[skin] || map.green;
}

/**
 * Detect emotion from text (simple keyword-based) and trigger appropriate animation.
 */
export function reactToText(text) {
  const t = text.toLowerCase();
  if (/(люблю|обнима|целу|сердечк|❤|💖|😘)/.test(t)) {
    showEmote("💖");
    showHeart();
  } else if (/(смешн|ха-ха|хаха|анекдот|😂|🤣|смех)/.test(t)) {
    showEmote("😂");
    bounce();
  } else if (/(грустн|плач|слёзы|😢|😭)/.test(t)) {
    showEmote("😢");
  } else if (/(злой|злюсь|бесишь|👿|😠)/.test(t)) {
    showEmote("😠");
    shake();
  } else if (/(удивлён|вау|ого|😲|😮)/.test(t)) {
    showEmote("😲");
  } else if (/(спать|спит|💤)/.test(t)) {
    showEmote("💤");
  } else if (/(привет|здравств|хай|👋)/.test(t)) {
    showEmote("👋");
    bounce();
  }
}
