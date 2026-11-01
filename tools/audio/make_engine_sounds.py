#!/usr/bin/env python3
"""Builds the synthesized car sounds in assets/audio/ (all made from scratch here, so CC0).

Engine: a V8 modelled as a train of exhaust pressure pulses, one per cylinder firing, sent
through two exhaust pipes (simple waveguides) and a muffler. For each of the RPM_POINTS it
renders one seamless loop "on load" (throttle open: louder, brighter, rougher) and one "off load"
(throttle closed: soft and dark). The game crossfades the two loops nearest to the engine revs and
pitches them to the exact revs, and blends the on/off loops with the throttle.

Also: wind, nitro hiss, turbo blow-off, exhaust pops, starter motor, police siren.

Usage: python3 tools/audio/make_engine_sounds.py <output dir>
Needs numpy and scipy.
"""
import sys
from pathlib import Path

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 32000
RPM_POINTS = [1000, 2000, 3200, 4500, 6000, 7600]
LOOP_SECONDS = 1.6
rng = np.random.default_rng(7)


def biquad_peak(f0, q, gain_db):
    a = 10 ** (gain_db / 40)
    w = 2 * np.pi * f0 / SR
    alpha = np.sin(w) / (2 * q)
    b = [1 + alpha * a, -2 * np.cos(w), 1 - alpha * a]
    den = [1 + alpha / a, -2 * np.cos(w), 1 - alpha / a]
    return np.array(b) / den[0], np.array(den) / den[0]


def comb(x, delay_s, fb):
    """Feedback comb: an open pipe of round-trip time delay_s, losing (1 - fb) each bounce."""
    d = max(1, int(round(delay_s * SR)))
    b = np.zeros(1)
    b[0] = 1.0
    a = np.zeros(d + 1)
    a[0] = 1.0
    a[d] = -fb
    return signal.lfilter([1.0], a, x)


def lowpass(x, fc, order=2):
    sos = signal.butter(order, min(fc, SR * 0.45), "low", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def highpass(x, fc, order=2):
    sos = signal.butter(order, fc, "high", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def bandpass(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, min(hi, SR * 0.45)], "band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def engine_period(rpm, cycles):
    """Loop length in samples: a whole number of engine cycles (two crank turns)."""
    cycle = SR * 120.0 / rpm
    n = int(round(cycle * cycles))
    return n, SR * 120.0 * cycles / n  # samples, exact rpm of the loop


def render_engine(rpm, load):
    cycles = max(2, int(round(LOOP_SECONDS * rpm / 120.0)))
    n, true_rpm = engine_period(rpm, cycles)
    cyc = n / cycles  # samples per engine cycle
    # Inputs repeat every loop; rendering three loops and keeping the last gives a seamless loop
    # once the filters have settled.
    reps = 3
    # Cross-plane V8 firing order 1-8-4-3-6-5-7-2, every 90 degrees of crank. Banks: odd left.
    order = [1, 8, 4, 3, 6, 5, 7, 2]
    cyl_gain = 1.0 + rng.normal(0, 0.12, 9)
    cyl_shift = rng.normal(0, 0.012, 9)  # tiny timing spread between cylinders
    jitter = rng.normal(0, 0.06 if load else 0.1, (cycles, 8))
    left = np.zeros(n)
    right = np.zeros(n)
    # Pulse width shrinks a little with revs; on load it is sharper and stronger.
    tau = (0.0011 - 0.0004 * (rpm / 8000)) * (0.75 if load else 1.15)
    tlen = int(tau * SR * 8)
    t = np.arange(tlen) / SR
    pulse = (t / tau) * np.exp(1 - t / tau)
    for c in range(cycles):
        for k, cyl in enumerate(order):
            pos = (c + k / 8.0 + cyl_shift[cyl]) * cyc
            i = int(pos) % n
            amp = cyl_gain[cyl] * (1 + jitter[c, k])
            if not load:
                # Closed throttle: weak, irregular combustion.
                amp *= 0.35 * (1 + rng.normal(0, 0.25))
            dst = left if cyl % 2 else right
            idx = (i + np.arange(tlen)) % n
            np.add.at(dst, idx, amp * pulse)
    left = np.tile(left, reps)
    right = np.tile(right, reps)
    # Combustion roughness: noise riding on each pulse.
    noise = np.tile(rng.normal(0, 1, n), reps)
    env_l = lowpass(np.abs(left), 900)
    env_r = lowpass(np.abs(right), 900)
    rough = 0.35 if load else 0.15
    left = left + rough * bandpass(noise, 300, 4000) * env_l
    right = right + rough * bandpass(np.roll(noise, 1234), 300, 4000) * env_r
    # Two exhaust pipes of slightly different length, then into one muffler.
    left = comb(left, 0.0072, 0.4)
    right = comb(right, 0.0079, 0.4)
    x = left + right
    for f0, q, g in [(95, 1.2, 5), (240, 2.0, 4), (520, 3.0, 2.5), (1150, 3.0, -3)]:
        b, a = biquad_peak(f0, q, g)
        x = signal.lfilter(b, a, x)
    cutoff = (900 + rpm * 0.3) if load else (500 + rpm * 0.08)
    x = lowpass(x, cutoff, 4)
    x = highpass(x, 35)
    # Intake / mechanical hiss, pulsing with the firings, more of it on load and high revs.
    hiss_amt = (0.02 + 0.05 * rpm / 8000) * (1.0 if load else 0.3)
    hiss = bandpass(np.tile(rng.normal(0, 1, n), reps), 1500, 5000) * (0.4 + lowpass(np.abs(x), 300) * 3)
    x = x / (np.std(x) + 1e-9)
    x = x + hiss_amt * hiss / (np.std(hiss) + 1e-9) * 2.5
    # Gentle saturation: on load the exhaust "barks".
    drive = 0.55 if load else 0.3
    x = np.tanh(x * drive) / np.tanh(drive * 3)
    x = x[(reps - 1) * n:]
    return x, true_rpm


def norm(x, peak=0.9):
    return x * (peak / (np.max(np.abs(x)) + 1e-9))


def fade(x, fin=0.005, fout=0.02):
    a = int(fin * SR)
    b = int(fout * SR)
    x = x.copy()
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def save(path, x):
    wavfile.write(path, SR, (np.clip(x, -1, 1) * 32767).astype(np.int16))


def seamless_noise(n, lo, hi, reps=3):
    x = np.tile(rng.normal(0, 1, n), reps)
    return bandpass(x, lo, hi)[(reps - 1) * n:]


def main(out):
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    table = []
    # Same loudness for all loops at the same load, so the crossfades don't pump. Higher revs
    # are naturally louder: that is added by the game, not baked in.
    for rpm in RPM_POINTS:
        for load in (True, False):
            x, true_rpm = render_engine(rpm, load)
            x = x / (np.sqrt(np.mean(x ** 2)) + 1e-9) * (0.22 if load else 0.16)
            name = f"engine_{'on' if load else 'off'}_{rpm}.wav"
            save(out / name, x)
            table.append((name, true_rpm))
    for name, r in table:
        print(f"{name}\t{r:.1f}")

    # Wind / road roar: steady broadband noise, the game raises it with speed.
    n = SR * 2
    wind = seamless_noise(n, 120, 2500) + 0.5 * seamless_noise(n, 40, 200)
    save(out / "wind.wav", norm(wind, 0.5))

    # Nitro: a hissing jet with a little flutter.
    n = SR * 2
    hiss = seamless_noise(n, 1500, 9000) + 0.6 * seamless_noise(n, 300, 1200)
    save(out / "nitro_loop.wav", norm(hiss, 0.6))

    # Turbo blow-off valve: a short bright "pssh" falling in pitch.
    d = int(0.55 * SR)
    t = np.arange(d) / SR
    noise = rng.normal(0, 1, d)
    x = np.zeros(d)
    seg = 256
    for i in range(0, d, seg):
        f = 5200 - 3000 * (i / d)
        x[i:i + seg] = bandpass(noise[max(0, i - 1024):i + seg], f * 0.6, f * 1.4)[-len(x[i:i + seg]):]
    env = np.minimum(t / 0.012, 1) * np.exp(-t / 0.16)
    save(out / "blowoff.wav", fade(norm(x * env, 0.8)))

    # Exhaust pops on lift-off: three variants of a short low "bang".
    for k in range(3):
        d = int(0.22 * SR)
        t = np.arange(d) / SR
        bang = rng.normal(0, 1, d) * np.exp(-t / (0.012 + 0.006 * k))
        bang = lowpass(bang, 1600 + 600 * k) + 0.4 * np.sin(2 * np.pi * (70 + 20 * k) * t) * np.exp(-t / 0.05)
        save(out / f"pop_{k}.wav", fade(norm(bang, 0.85), 0.0005))

    # Starter motor: whirring motor and the engine cranking at about 4 compressions a second
    # per cylinder pair, before it catches (the game then flares the revs).
    d = int(0.75 * SR)
    t = np.arange(d) / SR
    whirr = 0.5 * signal.sawtooth(2 * np.pi * 180 * t) + 0.3 * np.sin(2 * np.pi * 360 * t)
    crank = 0.6 + 0.4 * np.sin(2 * np.pi * 11 * t)
    x = lowpass(whirr, 2500) * crank + 0.2 * bandpass(rng.normal(0, 1, d), 500, 3000) * crank
    save(out / "starter.wav", fade(norm(x, 0.6), 0.01, 0.05))

    # Police siren: the classic two-tone wail, loopable (one 2 s sweep up and down).
    d = SR * 2
    t = np.arange(d) / SR
    f = 700 + 550 * (0.5 - 0.5 * np.cos(2 * np.pi * t / 2.0))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sign(np.sin(ph)) * 0.4 + np.sin(2 * ph) * 0.3 + np.sin(3 * ph) * 0.15
    x = lowpass(x, 3500)
    save(out / "siren.wav", norm(x, 0.5))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/audio")
