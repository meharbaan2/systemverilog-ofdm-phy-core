#!/usr/bin/env python3
"""Generate deterministic scoreboard vectors for the OFDM RTL regressions."""

from __future__ import annotations

import argparse
import cmath
import math
import random
from pathlib import Path

N = 64
CP = 16
PILOT_SPACING = 8
DATA = N - (N // PILOT_SPACING)
QFRAC = 16
QMAX = (1 << 23) - 1
QMIN = -(1 << 23)


def q(x: float) -> int:
    return max(QMIN, min(QMAX, int(round(x * (1 << QFRAC)))))


def qam_symbol(scheme: int, bits: int) -> complex:
    if scheme == 0:
        return complex(1 if (bits >> 5) & 1 else -1, 1 if (bits >> 4) & 1 else -1) / math.sqrt(2)
    if scheme == 1:
        norm = 1 / math.sqrt(10)
        re = (((bits >> 4) & 0x3) * 2 - 3) * norm
        im = (((bits >> 2) & 0x3) * 2 - 3) * norm
        return complex(re, im)
    norm = 1 / math.sqrt(42)
    re = (((bits >> 3) & 0x7) * 2 - 7) * norm
    im = ((bits & 0x7) * 2 - 7) * norm
    return complex(re, im)


def add_pilots(data: list[complex]) -> list[complex]:
    out = []
    di = 0
    for k in range(N):
        if k % PILOT_SPACING == 0:
            out.append(1 + 0j if (k // PILOT_SPACING) % 2 == 0 else -1 + 0j)
        else:
            out.append(data[di])
            di += 1
    return out


def dft(x: list[complex], inverse: bool) -> list[complex]:
    sign = 1 if inverse else -1
    scale = math.sqrt(N)
    out = []
    for k in range(N):
        acc = 0j
        for n, xn in enumerate(x):
            acc += xn * cmath.exp(sign * 2j * math.pi * k * n / N)
        out.append(acc / scale)
    return out


def write_complex(path: Path, values: list[complex]) -> None:
    with path.open("w", encoding="utf-8") as f:
        for z in values:
            f.write(f"{q(z.real)} {q(z.imag)}\n")


def write_qam_cases(path: Path, rng: random.Random) -> None:
    with path.open("w", encoding="utf-8") as f:
        for scheme in range(3):
            for _ in range(48):
                bits = rng.randrange(64)
                z = qam_symbol(scheme, bits)
                f.write(f"{scheme} {bits} {q(z.real)} {q(z.imag)}\n")


def write_recip_cases(path: Path) -> None:
    values = [0.125, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0]
    with path.open("w", encoding="utf-8") as f:
        for x in values:
            f.write(f"{q(x)} {q(1 / x)}\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=23)
    parser.add_argument("--out", type=Path, default=Path("vectors"))
    args = parser.parse_args()

    rng = random.Random(args.seed)
    args.out.mkdir(parents=True, exist_ok=True)

    write_qam_cases(args.out / "scoreboard_qam_cases.txt", rng)
    write_recip_cases(args.out / "scoreboard_recip_cases.txt")

    data = [qam_symbol(rng.randrange(3), rng.randrange(64)) for _ in range(DATA)]
    freq = add_pilots(data)
    time = dft(freq, inverse=True)
    time_cp = time[-CP:] + time

    awgn_cp = [z + complex(rng.gauss(0, 1e-5), rng.gauss(0, 1e-5)) for z in time_cp]
    rayleigh_freq = []
    for k, z in enumerate(freq):
        h = complex(0.85 + 0.25 * math.cos(2 * math.pi * k / N), 0.18 * math.sin(2 * math.pi * k / N))
        rayleigh_freq.append(z * h)
    rayleigh_time = dft(rayleigh_freq, inverse=True)
    rayleigh_cp = rayleigh_time[-CP:] + rayleigh_time

    write_complex(args.out / "scoreboard_data_q16.txt", data)
    write_complex(args.out / "scoreboard_tx_cp_q16.txt", time_cp)
    write_complex(args.out / "scoreboard_awgn_cp_q16.txt", awgn_cp)
    write_complex(args.out / "scoreboard_rayleigh_cp_q16.txt", rayleigh_cp)


if __name__ == "__main__":
    main()

