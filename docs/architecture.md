# OFDM PHY RTL Architecture

## Datapath Model

The core keeps the signal processing blocks frame-oriented and wraps the top
level with fixed-length valid/ready stream adapters. Each frame block accepts a
complete 64-subcarrier OFDM frame, or an 80-sample frame when the cyclic prefix
is present. The stream wrappers buffer one fixed frame and expose backpressure
without requiring a `last` signal in v1.

The intended signal flow is:

```text
bits -> QAM mapper -> pilot insertion -> IFFT -> CP insertion
     -> channel model in testbench/software
     -> CP removal -> FFT -> LS channel estimate -> equalizer
     -> data extraction -> QAM demapper -> BER counter
```

## Fixed-Point Format

`rtl/ofdm_pkg.sv` defines the shared complex type:

- `q_t`: signed 24-bit fixed point
- `QFRAC=16`
- Effective format: Q7.16 plus sign
- `1.0 == 65536`

The wider format is deliberate. A 64-point FFT can accumulate significant
intermediate magnitude before the final unitary `sqrt(64)=8` scale is applied.

## FFT/IFFT Scaling

`ofdm_fft64` implements a combinational radix-2 decimation-in-time transform.
The input is bit-reversed, six butterfly stages are applied, and the output is
arithmetically shifted right by three bits.

Both forward FFT and inverse FFT use the same final divide-by-8, matching the
C++ simulator's unitary-style FFT/IFFT scaling. In an IFFT-then-FFT round trip,
the two `1/8` scales cancel the natural `N=64` transform gain.

## Streaming Top Level

`ofdm_tx_stream` accepts `DATA_PER_FRAME=56` complex QAM symbols through
`in_valid/in_ready` and emits `FRAME_LEN=80` CP samples through
`out_valid/out_ready`.

`ofdm_rx_stream` accepts 80 time-domain CP samples and emits 56 equalized data
symbols. RX also exposes `eq_mode` and `noise_var`.

## Equalization

The equalizer computes:

```text
ZF:   Xhat = Y * conj(H) / max(|H|^2, epsilon)
MMSE: Xhat = Y * conj(H) / (|H|^2 + noise_var)
```

The equalizer avoids synthesis-time integer division. It computes a reciprocal
approximation by normalizing the denominator, selecting a small LUT seed, and
performing one Newton-Raphson refinement. `ofdm_recip_nr_pipe` exposes the same
approximation as a valid/ready pipeline stage for tone-by-tone streaming work.

## What Is Not Hardware

AWGN, Rayleigh fading, SNR sweeps, CSV export, plots, and random traffic
generation should remain in `tb/` or `sim/`. Those belong to verification and
analysis, not the synthesizable core.
