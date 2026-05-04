// Text-to-Speech via Web Speech Synthesis API.
// Picks the best Russian voice available, exposes onBoundary-like volume estimate
// for lip-sync via a synthetic envelope (since the API doesn't expose audio levels).

let voicesReady = null;

function loadVoices() {
  if (voicesReady) return voicesReady;
  voicesReady = new Promise((resolve) => {
    const get = () => {
      const v = window.speechSynthesis.getVoices();
      if (v && v.length) resolve(v);
    };
    get();
    window.speechSynthesis.onvoiceschanged = get;
    setTimeout(() => resolve(window.speechSynthesis.getVoices() || []), 1500);
  });
  return voicesReady;
}

async function pickVoice(lang = "ru") {
  const voices = await loadVoices();
  // Prefer female Russian voice if metadata available
  const ru = voices.filter((v) => v.lang && v.lang.toLowerCase().startsWith(lang.toLowerCase()));
  if (!ru.length) return voices[0] || null;
  const female = ru.find((v) => /female|женский|milena|alyona|katya|tatyana|alena/i.test(v.name));
  return female || ru[0];
}

export function isSupported() {
  return typeof window !== "undefined" && "speechSynthesis" in window;
}

export async function speak(text, opts = {}) {
  if (!isSupported() || !text) return;
  const { rate = 1.05, pitch = 1.4, volume = 1, lang = "ru-RU", onLevel, onEnd, onStart } = opts;

  const voice = await pickVoice(lang.split("-")[0]);
  const utt = new SpeechSynthesisUtterance(text);
  if (voice) utt.voice = voice;
  utt.lang = lang;
  utt.rate = rate;
  utt.pitch = pitch;
  utt.volume = volume;

  // Synthetic lip-sync envelope: emit a varying level while speaking.
  let levelTimer = null;
  const startEnvelope = () => {
    if (!onLevel) return;
    let t = 0;
    levelTimer = setInterval(() => {
      t += 0.06;
      // Combine multiple sine waves with noise for natural-looking mouth motion
      const base = 0.35 + 0.25 * Math.sin(t * 9) + 0.15 * Math.sin(t * 17 + 1.3);
      const noise = (Math.random() - 0.5) * 0.15;
      const level = Math.max(0, Math.min(1, base + noise));
      onLevel(level);
    }, 60);
  };
  const stopEnvelope = () => {
    if (levelTimer) {
      clearInterval(levelTimer);
      levelTimer = null;
    }
    if (onLevel) onLevel(0);
  };

  return new Promise((resolve) => {
    utt.onstart = () => {
      onStart?.();
      startEnvelope();
    };
    utt.onend = () => {
      stopEnvelope();
      onEnd?.();
      resolve();
    };
    utt.onerror = () => {
      stopEnvelope();
      onEnd?.();
      resolve();
    };
    // Cancel any in-flight utterance
    window.speechSynthesis.cancel();
    window.speechSynthesis.speak(utt);
  });
}

export function cancel() {
  if (isSupported()) {
    window.speechSynthesis.cancel();
  }
}
