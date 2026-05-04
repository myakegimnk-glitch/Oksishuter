// "Тom-style echo" - record user voice, play it back with a higher pitch.
// Implementation: MediaRecorder records audio, decode it via AudioContext,
// then play it back through an offline-rendered pitch shift (resample-based)
// or simply playbackRate trick on an <audio> element.

let audioCtx = null;

function getAudioCtx() {
  if (!audioCtx) {
    const Ctx = window.AudioContext || window.webkitAudioContext;
    audioCtx = new Ctx();
  }
  if (audioCtx.state === "suspended") {
    audioCtx.resume().catch(() => {});
  }
  return audioCtx;
}

export function isSupported() {
  return (
    typeof navigator !== "undefined" &&
    navigator.mediaDevices &&
    typeof MediaRecorder !== "undefined" &&
    typeof window !== "undefined" &&
    (window.AudioContext || window.webkitAudioContext)
  );
}

/**
 * Record audio for `maxMs` or until stop() is called. Returns AudioBuffer.
 * Returns { stop, promise } so caller can stop early.
 */
export function recordAudio({ maxMs = 6000 } = {}) {
  const ctx = getAudioCtx();
  let stream = null;
  let recorder = null;
  let chunks = [];
  let stopTimer = null;
  let stopped = false;

  const promise = (async () => {
    stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    const mimeType = pickMime();
    recorder = new MediaRecorder(stream, mimeType ? { mimeType } : undefined);
    recorder.ondataavailable = (e) => {
      if (e.data && e.data.size > 0) chunks.push(e.data);
    };
    const done = new Promise((res) => {
      recorder.onstop = () => res();
    });
    recorder.start();
    stopTimer = setTimeout(() => {
      if (!stopped) stopFn();
    }, maxMs);
    await done;
    // Stop the mic
    stream.getTracks().forEach((t) => t.stop());

    if (!chunks.length) return null;
    const blob = new Blob(chunks, { type: chunks[0].type || "audio/webm" });
    const arrayBuf = await blob.arrayBuffer();
    try {
      const audioBuf = await ctx.decodeAudioData(arrayBuf.slice(0));
      return audioBuf;
    } catch (e) {
      console.warn("decode failed, returning null", e);
      return null;
    }
  })();

  function stopFn() {
    if (stopped) return;
    stopped = true;
    if (stopTimer) clearTimeout(stopTimer);
    try {
      if (recorder && recorder.state !== "inactive") recorder.stop();
    } catch {}
  }

  return { stop: stopFn, promise };
}

function pickMime() {
  const candidates = [
    "audio/webm;codecs=opus",
    "audio/webm",
    "audio/ogg;codecs=opus",
    "audio/mp4",
  ];
  for (const c of candidates) {
    if (typeof MediaRecorder !== "undefined" && MediaRecorder.isTypeSupported && MediaRecorder.isTypeSupported(c)) {
      return c;
    }
  }
  return null;
}

/**
 * Play back AudioBuffer with a pitch shift (resample-based, also speeds up time).
 * Provides a level callback for lip-sync.
 */
export async function playPitched(audioBuffer, { pitch = 1.5, onLevel, onEnd } = {}) {
  if (!audioBuffer) {
    onEnd?.();
    return;
  }
  const ctx = getAudioCtx();
  const src = ctx.createBufferSource();
  src.buffer = audioBuffer;
  src.playbackRate.value = pitch; // Higher pitch + faster

  // Lip-sync: tap into output via AnalyserNode
  const analyser = ctx.createAnalyser();
  analyser.fftSize = 512;
  const data = new Uint8Array(analyser.fftSize);

  src.connect(analyser);
  analyser.connect(ctx.destination);

  let raf = null;
  const tick = () => {
    analyser.getByteTimeDomainData(data);
    let sum = 0;
    for (let i = 0; i < data.length; i++) {
      const v = (data[i] - 128) / 128;
      sum += v * v;
    }
    const rms = Math.sqrt(sum / data.length);
    const level = Math.min(1, rms * 4);
    onLevel?.(level);
    raf = requestAnimationFrame(tick);
  };

  return new Promise((resolve) => {
    src.onended = () => {
      if (raf) cancelAnimationFrame(raf);
      onLevel?.(0);
      onEnd?.();
      resolve();
    };
    src.start();
    tick();
  });
}

/**
 * Quick convenience: record, then echo back with high pitch.
 */
export async function echoCycle({ maxMs = 5000, pitch = 1.5, onLevel, onRecordStart, onRecordEnd, onPlayStart, onPlayEnd } = {}) {
  onRecordStart?.();
  const rec = recordAudio({ maxMs });
  const buf = await rec.promise;
  onRecordEnd?.();
  if (!buf) {
    onPlayEnd?.();
    return;
  }
  onPlayStart?.();
  await playPitched(buf, { pitch, onLevel, onEnd: onPlayEnd });
}

export function attachStop(rec) {
  return rec.stop;
}
