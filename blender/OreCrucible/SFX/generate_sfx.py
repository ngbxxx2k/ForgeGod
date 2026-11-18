import numpy as np
import wave
import os

SR = 44100
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "raw")
PEAK_DB = -1.0


def seconds(sec):
    return int(round(sec * SR))


def circular_band(noise, low_hz, high_hz):
    spectrum = np.fft.rfft(noise)
    freqs = np.fft.rfftfreq(len(noise), 1.0 / SR)
    mask = np.ones_like(freqs)
    if low_hz > 0:
        mask *= 1.0 / (1.0 + (low_hz / np.maximum(freqs, 1e-6)) ** 4)
    if high_hz > 0:
        mask *= 1.0 / (1.0 + (freqs / high_hz) ** 4)
    return np.fft.irfft(spectrum * mask, n=len(noise))


def normalize(signal):
    peak = np.max(np.abs(signal))
    return signal * (10 ** (PEAK_DB / 20.0) / peak)


def add_wrapped(target, event, start):
    n = len(target)
    idx = (np.arange(len(event)) + start) % n
    np.add.at(target, idx, event)


def add_clipped(target, event, start):
    end = min(len(target), start + len(event))
    if start < end:
        target[start:end] += event[: end - start]


def blup(rng, base_hz, length_sec, rise):
    n = seconds(length_sec)
    t = np.arange(n) / SR
    freq = base_hz * (1.0 + rise * (1.0 - np.exp(-t / (length_sec * 0.35))))
    phase = 2 * np.pi * np.cumsum(freq) / SR
    env = (1 - np.exp(-t / 0.004)) * np.exp(-t / (length_sec * 0.35))
    body = np.sin(phase) + 0.25 * np.sin(2 * phase)
    pop = rng.normal(0, 1, n) * np.exp(-t / 0.006) * 0.35
    return (body * env + pop) * rng.uniform(0.6, 1.0)


def crackle(rng, length_sec):
    n = seconds(length_sec)
    t = np.arange(n) / SR
    burst = rng.normal(0, 1, n) * np.exp(-t / (length_sec * 0.25))
    burst = np.diff(np.concatenate([[0.0], burst]))
    return burst * rng.uniform(0.3, 1.0)


def scatter(rng, target, count, maker, wrapped=True):
    for _ in range(count):
        start = int(rng.integers(0, len(target)))
        event = maker()
        if wrapped:
            add_wrapped(target, event, start)
        else:
            add_clipped(target, event, start)


def periodic_mod(n, cycles, depth, phase=0.0):
    t = np.arange(n) / n
    return 1.0 - depth + depth * 0.5 * (1 + np.sin(2 * np.pi * cycles * t + phase))


def idle_loop(rng):
    n = seconds(4.0)
    rumble = circular_band(rng.normal(0, 1, n), 25, 110) * 2.2
    hiss = circular_band(rng.normal(0, 1, n), 300, 1800) * 0.25 * periodic_mod(n, 1, 0.3)
    bubbles = np.zeros(n)
    scatter(rng, bubbles, 9, lambda: blup(rng, rng.uniform(90, 150), rng.uniform(0.08, 0.16), 1.6))
    crack = np.zeros(n)
    scatter(rng, crack, 14, lambda: crackle(rng, rng.uniform(0.003, 0.012)))
    return rumble + hiss + bubbles * 0.55 + crack * 0.35


def active_loop(rng):
    n = seconds(4.0)
    rumble = circular_band(rng.normal(0, 1, n), 25, 140) * 2.6 * periodic_mod(n, 2, 0.35)
    roar = circular_band(rng.normal(0, 1, n), 180, 2200) * 0.9 * periodic_mod(n, 2, 0.45, -np.pi / 2)
    bubbles = np.zeros(n)
    scatter(rng, bubbles, 26, lambda: blup(rng, rng.uniform(80, 170), rng.uniform(0.06, 0.14), 2.0))
    crack = np.zeros(n)
    scatter(rng, crack, 45, lambda: crackle(rng, rng.uniform(0.002, 0.012)))
    return rumble + roar + bubbles * 0.6 + crack * 0.45


def max_loop(rng):
    n = seconds(4.0)
    rumble = circular_band(rng.normal(0, 1, n), 20, 120) * 3.4 * periodic_mod(n, 4, 0.3)
    roar = circular_band(rng.normal(0, 1, n), 120, 3000) * 1.5 * periodic_mod(n, 4, 0.5, -np.pi / 2)
    sub = np.sin(2 * np.pi * 41 * np.arange(n) / SR) * 0.35 * periodic_mod(n, 4, 0.6)
    bubbles = np.zeros(n)
    scatter(rng, bubbles, 40, lambda: blup(rng, rng.uniform(70, 160), rng.uniform(0.05, 0.12), 2.4))
    crack = np.zeros(n)
    scatter(rng, crack, 110, lambda: crackle(rng, rng.uniform(0.002, 0.015)))
    return rumble + roar + sub + bubbles * 0.55 + crack * 0.5


def sweep_noise(rng, length_sec, start_hz, end_hz, steps=24):
    n = seconds(length_sec)
    out = np.zeros(n)
    seg = n // steps
    window = np.hanning(seg * 2)
    for i in range(steps):
        frac = i / (steps - 1)
        center = start_hz * (end_hz / start_hz) ** frac
        chunk = circular_band(rng.normal(0, 1, seg * 2), center * 0.6, center * 1.6) * window
        add_clipped(out, chunk, max(0, i * seg - seg // 2))
    return out


def envelope(n, attack, release):
    t = np.arange(n) / SR
    total = n / SR
    env = np.minimum(1.0, t / max(attack, 1e-4))
    env *= np.clip((total - t) / max(release, 1e-4), 0, 1)
    return env


def active_start(rng):
    n = seconds(1.2)
    whoosh = sweep_noise(rng, 1.2, 250, 2400) * envelope(n, 0.35, 0.5) * 1.4
    out = whoosh
    for start, hz in ((0.18, 110), (0.42, 140), (0.63, 95)):
        add_clipped(out, blup(rng, hz, 0.2, 2.2) * 1.2, seconds(start))
    crack = np.zeros(n)
    scatter(rng, crack, 18, lambda: crackle(rng, rng.uniform(0.002, 0.01)), wrapped=False)
    return out + crack * 0.4 * envelope(n, 0.3, 0.4)


def max_burst(rng):
    n = seconds(2.5)
    t = np.arange(n) / SR
    freq = 35 + 45 * np.exp(-t / 0.25)
    boom = np.sin(2 * np.pi * np.cumsum(freq) / SR) * np.exp(-t / 0.55) * (1 - np.exp(-t / 0.003))
    thump = circular_band(rng.normal(0, 1, n), 20, 180) * np.exp(-t / 0.35) * 3.0
    blast = circular_band(rng.normal(0, 1, n), 200, 5000) * np.exp(-t / 0.18) * 1.2
    whoosh = sweep_noise(rng, 2.5, 1800, 300) * envelope(n, 0.02, 1.4) * 0.6
    crack = np.zeros(n)
    scatter(rng, crack, 70, lambda: crackle(rng, rng.uniform(0.002, 0.012)), wrapped=False)
    crack *= np.exp(-t / 0.9)
    return boom * 1.6 + thump + blast + whoosh + crack * 0.6


def write_wav(name, signal):
    os.makedirs(OUT_DIR, exist_ok=True)
    data = (np.clip(signal, -1, 1) * 32767).astype(np.int16)
    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SR)
        handle.writeframes(data.tobytes())
    return path


def fade_edges(signal, fade_in, fade_out):
    n = len(signal)
    env = np.ones(n)
    a = seconds(fade_in)
    b = seconds(fade_out)
    if a:
        env[:a] = np.linspace(0, 1, a)
    if b:
        env[-b:] *= np.linspace(1, 0, b)
    return signal * env


def build_all(seed=7):
    rng = np.random.default_rng(seed)
    sounds = {
        "SFX_Idle_Loop": (idle_loop(rng), True),
        "SFX_Active_Loop": (active_loop(rng), True),
        "SFX_Max_Loop": (max_loop(rng), True),
        "SFX_Active_Start": (fade_edges(active_start(rng), 0.01, 0.25), False),
        "SFX_Max_Burst": (fade_edges(max_burst(rng), 0.002, 0.6), False),
    }
    report = {}
    for name, (signal, is_loop) in sounds.items():
        signal = normalize(signal - np.mean(signal))
        path = write_wav(name, signal)
        seam = abs(signal[0] - signal[-1]) if is_loop else None
        report[name] = dict(path=path, seconds=len(signal) / SR, loop=is_loop,
                            peak_db=20 * np.log10(np.max(np.abs(signal))),
                            clipped=int(np.sum(np.abs(signal) >= 0.9999)), seam=seam)
    return report


if __name__ == "__main__":
    for key, value in build_all().items():
        print(key, value)
