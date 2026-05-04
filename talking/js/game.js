// Tamagotchi-like state mechanics. Stats decay over time and update UI.

import * as storage from "./storage.js";

const TICK_MS = 60_000; // Decay every minute
const DECAY = { hunger: -1.5, happiness: -1, energy: -0.7 };

let timer = null;
let onChange = null;

export function start({ onUpdate } = {}) {
  onChange = onUpdate;
  // Decay since last visit
  const lastTickKey = "oksiTalking.lastTick";
  const last = parseInt(localStorage.getItem(lastTickKey) || "0", 10);
  if (last) {
    const elapsedMin = Math.min(60 * 24, Math.floor((Date.now() - last) / TICK_MS));
    if (elapsedMin > 0) decayBy(elapsedMin);
  }
  localStorage.setItem(lastTickKey, String(Date.now()));

  timer = setInterval(() => {
    decayBy(1);
    localStorage.setItem(lastTickKey, String(Date.now()));
  }, TICK_MS);
  emit();
}

export function stop() {
  if (timer) clearInterval(timer);
  timer = null;
}

function decayBy(minutes) {
  const s = storage.get().stats;
  storage.updateStats({
    hunger: s.hunger + DECAY.hunger * minutes,
    happiness: s.happiness + DECAY.happiness * minutes,
    energy: s.energy + DECAY.energy * minutes,
  });
  emit();
}

function emit() {
  onChange?.(storage.get().stats);
}

export function feed(amount = 25) {
  const s = storage.get().stats;
  storage.updateStats({
    hunger: s.hunger + amount,
    happiness: s.happiness + 5,
  });
  emit();
}

export function pet(amount = 20) {
  const s = storage.get().stats;
  storage.updateStats({
    happiness: s.happiness + amount,
    energy: s.energy - 2,
  });
  emit();
}

export function sleep(amount = 40) {
  const s = storage.get().stats;
  storage.updateStats({
    energy: s.energy + amount,
    hunger: s.hunger - 5,
  });
  emit();
}

export function getMood() {
  const s = storage.get().stats;
  if (s.hunger < 25) return "hungry";
  if (s.energy < 25) return "sleepy";
  if (s.happiness < 25) return "sad";
  if (s.happiness > 80 && s.energy > 50) return "happy";
  return "ok";
}
