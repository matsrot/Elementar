"""
Gera os sons e as músicas do Elementar por síntese (sem arquivos de terceiros).
Uso: python tools/gerar_audio.py   (requer numpy)
Os arquivos saem em assets/audio/. Para trocar por outros sons, basta colocar
arquivos .ogg ou .wav com os MESMOS NOMES nessa pasta.
"""
import os
import wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


def wave_shape(freq, t, shape="square", duty=0.5):
    phase = (freq * t) % 1.0
    if shape == "square":
        w = np.where(phase < duty, 1.0, -1.0)
    elif shape == "triangle":
        w = 4.0 * np.abs(phase - 0.5) - 1.0
    else:  # sine
        w = np.sin(2 * np.pi * phase)
    if shape == "square":  # suaviza o timbre áspero
        k = np.ones(4) / 4
        w = np.convolve(w, k, mode="same")
    return w


def note(freq, dur, shape="square", vol=0.5, attack=0.004, decay=6.0, duty=0.5, sustain=False):
    n = int(SR * dur)
    t = np.arange(n) / SR
    w = wave_shape(freq, t, shape, duty)
    env = np.minimum(1.0, t / attack) if attack > 0 else np.ones(n)
    if sustain:
        rel = int(SR * 0.03)
        env = env * np.concatenate([np.ones(max(n - rel, 0)), np.linspace(1, 0, min(rel, n))])
    else:
        env = env * np.exp(-decay * t / max(dur, 1e-3))
        fade = int(SR * 0.01)
        env[-fade:] *= np.linspace(1, 0, fade)
    return w * env * vol


def seq(items):
    return np.concatenate(items) if items else np.zeros(1)


def sweep(f0, f1, dur, vol=0.4, shape="square"):
    n = int(SR * dur)
    t = np.arange(n) / SR
    f = np.linspace(f0, f1, n)
    phase = np.cumsum(f) / SR
    if shape == "square":
        w = np.where((phase % 1.0) < 0.5, 1.0, -1.0)
        w = np.convolve(w, np.ones(4) / 4, mode="same")
    else:
        w = np.sin(2 * np.pi * phase)
    env = np.exp(-3.0 * t / dur)
    fade = int(SR * 0.01)
    env[-fade:] *= np.linspace(1, 0, fade)
    return w * env * vol


def save(name, data, peak=0.85):
    data = np.asarray(data, dtype=np.float64)
    m = np.max(np.abs(data)) or 1.0
    data = data / m * peak
    pcm = (data * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())
    print(f"{name}.wav  {len(pcm) / SR:.2f}s")


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = np.zeros(n)
    for t in tracks:
        out[: len(t)] += t
    return out


# ------------------------------------------------------------------ efeitos sonoros
save("coletar", seq([note(midi(64), 0.08, "triangle", vol=0.6, decay=7.0), note(midi(71), 0.18, "triangle", vol=0.6, decay=7.0)]), peak=0.5)
save("combinar", seq([note(midi(72), 0.09), note(midi(76), 0.09), note(midi(79), 0.22)]))
save("separar", seq([note(midi(79), 0.09), note(midi(76), 0.09), note(midi(72), 0.22)]))
save("estrela", seq([note(midi(84), 0.07), note(midi(88), 0.07), note(midi(91), 0.07), note(midi(96), 0.35, decay=4.0)]))
chord = mix(note(midi(72), 0.9, vol=0.35, decay=3), note(midi(76), 0.9, vol=0.35, decay=3),
            note(midi(79), 0.9, vol=0.35, decay=3), note(midi(84), 0.9, vol=0.35, decay=3))
save("missao", seq([note(midi(72), 0.14), note(midi(76), 0.14), note(midi(79), 0.14), chord]))
save("erro", seq([note(midi(55), 0.10, vol=0.45), note(midi(50), 0.16, vol=0.45)]))
save("pulo", sweep(170, 340, 0.13, vol=0.4, shape="sine"), peak=0.5)
save("clique", note(880, 0.045, vol=0.4, decay=8))

# ------------------------------------------------------------------ músicas (loops)
# Progressão em Lá menor: Am - F - C - G
CHORDS = [
    (45, [57, 60, 64]),   # Am
    (41, [53, 57, 60]),   # F
    (48, [60, 64, 67]),   # C
    (43, [55, 59, 62]),   # G
]


def build_music(bpm, melody, arp_vol, lead_vol, arp_shape):
    eighth = 60.0 / bpm / 2
    parts_arp, parts_bass, parts_lead = [], [], []
    pattern = [0, 1, 2, 1, 0, 1, 2, 1]
    for rep in range(2):
        for bar, (bass, tones) in enumerate(CHORDS):
            bar_len = eighth * 8
            parts_bass.append(note(midi(bass), bar_len, "triangle", 0.45, attack=0.01, sustain=True))
            for i in range(8):
                parts_arp.append(note(midi(tones[pattern[i]]), eighth, arp_shape, arp_vol, decay=5.0))
                m = melody[bar][i] if melody else None
                if m is None:
                    parts_lead.append(np.zeros(int(SR * eighth)))
                else:
                    parts_lead.append(note(midi(m), eighth, "square", lead_vol, decay=3.5, duty=0.25))
    return mix(seq(parts_bass), seq(parts_arp), seq(parts_lead))


MELODY = [
    [76, None, 72, None, 69, None, 72, 76],   # Am
    [77, None, 72, None, 69, None, 72, 77],   # F
    [76, None, 72, None, 67, None, 72, 76],   # C
    [74, None, 71, None, 67, None, 71, 74],   # G
]
save("musica_menu", build_music(76, None, 0.55, 0.0, "triangle"), peak=0.7)
save("musica_fase", build_music(112, MELODY, 0.4, 0.28, "triangle"), peak=0.7)
