# SystemVerilog OFDM PHY Core

A fixed-point SystemVerilog prototype of an OFDM physical-layer baseband
datapath. The project implements the main transmit/receive processing blocks as
synthesizable RTL and includes a Verilator sanity testbench.

## Overview

The design models a small OFDM PHY configuration:

- 64 subcarriers
- 16-sample cyclic prefix
- Comb pilots every 8 subcarriers
- QPSK, 16-QAM, and 64-QAM symbol mapping
- Pilot-aided LS channel estimation
- ZF/MMSE-style frequency-domain equalization

The channel models and BER/SNR sweeps are intentionally kept outside the RTL.
This repository focuses on the hardware datapath blocks and their basic
verification.

## Features

- Fixed-point complex arithmetic package
- QAM mapper and hard-decision demapper
- Pilot insertion and extraction
- Cyclic prefix insertion and removal
- 64-point radix-2 FFT/IFFT
- LS channel estimator with linear interpolation
- Frequency-domain equalizer
- BER counter
- Frame-level OFDM TX/RX wrappers
- Verilator-based sanity testbench
- Deterministic reference-vector generator

## Repository Layout

```text
rtl/      Synthesizable SystemVerilog modules
tb/       SystemVerilog testbench
sim/      Verilator scripts, file list, vector generator
docs/     Architecture and project notes
vectors/  Generated fixed-point reference vectors
```

## Requirements

- SystemVerilog simulator with good SystemVerilog support
- Verilator is the tested simulator
- Linux or WSL is recommended
- OSS CAD Suite is a convenient way to get Verilator and related open-source EDA
  tools

## One-Click Run

On Windows, double-click:

```text
run.bat
```

This opens a console, runs the Verilator sanity test through Ubuntu WSL, prints
the regression details, and keeps the window open.

Expected result:

```text
========================================
 SystemVerilog OFDM PHY Core Regression
========================================
...
[ OK ] OFDM basic RTL sanity tests passed
Result: PASS
```

## Run The Testbench

Install or extract OSS CAD Suite so that Verilator is available at:

```text
tools/oss-cad-suite/bin/verilator
```

From Linux or WSL:

```sh
sh sim/run_verilator.sh
```

From PowerShell on Windows:

```powershell
.\run.ps1
```

Or call the WSL runner directly:

```powershell
.\sim\run_verilator_wsl.ps1
```

Manual command:

```sh
tools/oss-cad-suite/bin/verilator -sv --binary --timing \
  -f sim/ofdm_files.f \
  --top-module ofdm_basic_tb \
  --Wno-TIMESCALEMOD --Wno-WIDTHEXPAND --Wno-WIDTHTRUNC

./obj_dir/Vofdm_basic_tb
```

## Reference Vectors

Generate deterministic reference vectors:

```sh
python3 sim/generate_vectors.py --seed 7 --out vectors
```

## Verification Coverage

The current sanity testbench checks:

- QPSK, 16-QAM, and 64-QAM mapper/demapper identity
- Pilot polarity and pilot/data placement
- Cyclic prefix insertion/removal
- FFT/IFFT round trip within fixed-point tolerance
- Ideal-channel frame-level OFDM TX/RX recovery

## Design Notes

The first implementation is frame-oriented rather than a deeply pipelined
streaming design. This keeps the datapath easy to inspect while preserving
synthesizable arithmetic and clean module boundaries.

The equalizer currently uses integer division for clarity. A production FPGA
implementation would usually replace this with a pipelined reciprocal unit,
lookup table, or Newton-Raphson approximation.

See [docs/architecture.md](docs/architecture.md) for more detail.

## Limitations

- Fixed `N=64`, `CP=16`, and pilot spacing `8`
- No packet framing, coding, interleaving, CFO correction, or timing recovery
- No streaming valid/ready interface yet
- AWGN and Rayleigh fading are verification-side concerns, not RTL blocks
- Testbench is a focused sanity suite, not exhaustive constrained-random
  verification

## Roadmap

- Add streaming valid/ready interfaces
- Replace integer division with a pipelined reciprocal/equalizer datapath
- Add more fixed-point golden-vector comparisons
- Add AWGN/Rayleigh behavioral testbench scenarios
- Add synthesis reports for a target FPGA
