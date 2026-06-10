#!/usr/bin/env python3
"""Generate small OFDM reference vectors for the SystemVerilog testbench.

This helper intentionally uses only the Python standard library. It mirrors the
fixed first RTL target: N=64, CP=16, pilot spacing=8, unitary FFT/IFFT scaling,
and the same binary QAM level mapping as the C++ simulator.
"""

from __future__ import annotations

import argparse
import cmath
import math
import random
from pathlib import Path

N = 64
CP = 16
PILOT_SPACING = 8
PILOTS = N // PILOT_SPACING
DATA = N - PILOTS
QFRAC = 16


def q(x: float) -> int:
    return int(round(x * (1 << QFRAC)))


def qpsk(bits: tuple[int, int]) -> complex:
    return complex(1 if bits[0] else -1, 1 if bits[1] else -1) / math.sqrt(2.0)


def add_pilots(data: list[complex]) -> list[complex]:
    out: list[complex] = []
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
    out: list[complex] = []
    for k in range(N):
        acc = 0j
        for n, xn in enumerate(x):
            acc += xn * cmath.exp(sign * 2j * math.pi * k * n / N)
        out.append(acc / math.sqrt(N))
    return out


def write_complex(path: Path, values: list[complex]) -> None:
    with path.open("w", encoding="utf-8") as f:
        for z in values:
            f.write(f"{q(z.real)} {q(z.imag)}\n")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--out", type=Path, default=Path("vectors"))
    args = parser.parse_args()

    rng = random.Random(args.seed)
    args.out.mkdir(parents=True, exist_ok=True)

    bits = [rng.randrange(2) for _ in range(DATA * 2)]
    data = [qpsk((bits[i], bits[i + 1])) for i in range(0, len(bits), 2)]
    freq = add_pilots(data)
    time = dft(freq, inverse=True)
    time_cp = time[-CP:] + time
    roundtrip = dft(time, inverse=False)

    write_complex(args.out / "qpsk_data_q16.txt", data)
    write_complex(args.out / "freq_with_pilots_q16.txt", freq)
    write_complex(args.out / "time_cp_q16.txt", time_cp)
    write_complex(args.out / "fft_roundtrip_q16.txt", roundtrip)


if __name__ == "__main__":
    main()

