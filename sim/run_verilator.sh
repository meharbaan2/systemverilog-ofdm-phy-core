#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

echo "========================================"
echo " SystemVerilog OFDM PHY Core Regression"
echo "========================================"
echo
echo "Project: $(pwd)"
echo "Simulator: $(tools/oss-cad-suite/bin/verilator --version)"
echo
echo "Testbench: tb/ofdm_basic_tb.sv"
echo "Checks:"
echo "  - QPSK / 16-QAM / 64-QAM mapper-demapper identity"
echo "  - Pilot insertion/extraction and alternating pilot polarity"
echo "  - Cyclic prefix insertion/removal"
echo "  - 64-point FFT/IFFT fixed-point round trip"
echo "  - Ideal-channel frame-level OFDM TX/RX recovery"
echo
echo "[1/2] Building simulation..."

tools/oss-cad-suite/bin/verilator -sv --binary --timing \
  -f sim/ofdm_files.f \
  --top-module ofdm_basic_tb \
  --Wno-TIMESCALEMOD --Wno-WIDTHEXPAND --Wno-WIDTHTRUNC

echo
echo "[2/2] Running simulation..."
./obj_dir/Vofdm_basic_tb

echo
echo "Build output: obj_dir/"
echo "Result: PASS"
