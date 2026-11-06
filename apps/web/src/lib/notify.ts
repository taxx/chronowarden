/** Browser delivery helpers: OS notifications, Web Audio beeps, vibration. */

export function requestNotificationPermission(): void {
  try {
    if (typeof Notification !== 'undefined' && Notification.permission === 'default') {
      void Notification.requestPermission();
    }
  } catch {
    // unsupported (e.g. iOS Safari non-PWA)
  }
}

export function notificationPermission(): string {
  try {
    return typeof Notification !== 'undefined' ? Notification.permission : 'unsupported';
  } catch {
    return 'unsupported';
  }
}

export function showOsNotification(title: string, body: string, tag = 'chronowarden-leave'): void {
  try {
    if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
      new Notification(title, { body, tag });
    }
  } catch {
    // ignore
  }
}

let audioContext: AudioContext | null = null;
let primerInstalled = false;

/**
 * Resume the shared audio context on the first user interaction.
 *
 * Browsers block audio until a gesture, so priming only from the settings
 * toggle left the beep silent for the rest of the session. Install this once at
 * startup so any tap/keypress before the alert unlocks sound.
 */
export function installAudioPrimer(): void {
  if (primerInstalled || typeof window === 'undefined') return;
  primerInstalled = true;
  const prime = () => {
    primeAudio();
    window.removeEventListener('pointerdown', prime);
    window.removeEventListener('keydown', prime);
  };
  window.addEventListener('pointerdown', prime, { once: true });
  window.addEventListener('keydown', prime, { once: true });
}

/** Create/resume the shared audio context. Call from a user gesture. */
export function primeAudio(): void {
  try {
    const Ctor = window.AudioContext ?? (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
    if (!Ctor) return;
    audioContext ??= new Ctor();
    if (audioContext.state === 'suspended') void audioContext.resume();
  } catch {
    // ignore
  }
}

export function audioState(): string {
  return audioContext ? audioContext.state : 'none';
}

/** Play [count] short beeps (resuming the context if needed). */
export function beep(count = 1): void {
  primeAudio();
  const ctx = audioContext;
  if (!ctx) return;

  const play = () => {
    try {
      const start = ctx.currentTime;
      for (let i = 0; i < count; i++) {
        const at = start + i * 0.35;
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.value = 880;
        gain.gain.setValueAtTime(0.0001, at);
        gain.gain.exponentialRampToValueAtTime(0.5, at + 0.02);
        gain.gain.exponentialRampToValueAtTime(0.0001, at + 0.28);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(at);
        osc.stop(at + 0.3);
      }
    } catch {
      // ignore
    }
  };

  if (ctx.state === 'suspended') {
    void ctx.resume().then(play).catch(() => {});
  } else {
    play();
  }
}

export function vibrationSupported(): boolean {
  return typeof navigator !== 'undefined' && 'vibrate' in navigator;
}

export function vibrate(milliseconds: number): void {
  try {
    navigator.vibrate?.(milliseconds);
  } catch {
    // ignore
  }
}
