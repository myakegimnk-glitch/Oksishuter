// Speech recognition (Web Speech API).
// Returns null if unsupported. Provides start/stop and event hooks.

const SR =
  typeof window !== "undefined" &&
  (window.SpeechRecognition || window.webkitSpeechRecognition);

export function isSupported() {
  return Boolean(SR);
}

export function createRecognizer({ lang = "ru-RU", continuous = false, interim = true } = {}) {
  if (!SR) return null;
  const rec = new SR();
  rec.lang = lang;
  rec.continuous = continuous;
  rec.interimResults = interim;
  rec.maxAlternatives = 1;
  return rec;
}

/**
 * Start listening, return a Promise that resolves with the final transcript.
 * Calls onInterim(text) for partial results.
 * Calls onError(e) if recognition errors.
 */
export function listenOnce({ lang = "ru-RU", onInterim, onStart, onEnd, onError } = {}) {
  return new Promise((resolve, reject) => {
    const rec = createRecognizer({ lang, continuous: false, interim: true });
    if (!rec) {
      reject(new Error("speech-not-supported"));
      return;
    }

    let finalText = "";
    let resolved = false;

    rec.onstart = () => onStart?.();
    rec.onresult = (e) => {
      let interim = "";
      for (let i = e.resultIndex; i < e.results.length; i++) {
        const res = e.results[i];
        if (res.isFinal) {
          finalText += res[0].transcript;
        } else {
          interim += res[0].transcript;
        }
      }
      if (interim && onInterim) onInterim(interim);
    };
    rec.onerror = (e) => {
      onError?.(e);
      if (!resolved) {
        resolved = true;
        // "no-speech" / "aborted" should resolve with empty rather than reject
        if (e.error === "no-speech" || e.error === "aborted") {
          resolve("");
        } else {
          reject(new Error(e.error || "speech-error"));
        }
      }
    };
    rec.onend = () => {
      onEnd?.();
      if (!resolved) {
        resolved = true;
        resolve(finalText.trim());
      }
    };

    try {
      rec.start();
    } catch (e) {
      reject(e);
      return;
    }

    // Expose stop via a side-channel
    listenOnce._current = {
      stop: () => {
        try { rec.stop(); } catch {}
      },
      abort: () => {
        try { rec.abort(); } catch {}
      },
    };
  });
}

export function stopCurrent() {
  if (listenOnce._current) {
    listenOnce._current.stop();
    listenOnce._current = null;
  }
}
