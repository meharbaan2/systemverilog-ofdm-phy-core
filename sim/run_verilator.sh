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
echo "Testbenches:"
echo "  - tb/ofdm_basic_tb.sv"
echo "  - tb/ofdm_stream_tb.sv"
echo "  - tb/ofdm_scoreboard_tb.sv"
echo
echo "Checks:"
echo "  - QPSK / 16-QAM / 64-QAM mapper-demapper identity"
echo "  - Pilot insertion/extraction and alternating pilot polarity"
echo "  - Cyclic prefix insertion/removal"
echo "  - 64-point FFT/IFFT fixed-point round trip"
echo "  - Ideal-channel frame-level OFDM TX/RX recovery"
echo "  - Streaming valid/ready stalls and backpressure"
echo "  - Multiple consecutive streaming frames"
echo "  - Python scoreboard vectors, AWGN, Rayleigh smoke, reciprocal tolerance"
echo
echo "[0/3] Generating scoreboard vectors..."
python3 sim/generate_scoreboard_vectors.py --seed 23 --out vectors

run_tb() {
  name="$1"
  filelist="$2"
  top="$3"
  echo
  echo "[$name] Building $top..."
  tools/oss-cad-suite/bin/verilator -sv --binary --timing \
    -f "$filelist" \
    --top-module "$top" \
    --Mdir "obj_dir/$top" \
    --Wno-TIMESCALEMOD --Wno-WIDTHEXPAND --Wno-WIDTHTRUNC
  echo "[$name] Running $top..."
  log="obj_dir/$top/run.log"
  set +e
  "./obj_dir/$top/V$top" > "$log" 2>&1
  status=$?
  set -e
  cat "$log"
  if [ "$status" -ne 0 ]; then
    echo "[$name] $top exited with status $status"
    return "$status"
  fi
  if grep -q "\\[FAIL\\]" "$log"; then
    echo "[$name] $top printed [FAIL]; treating regression as failed"
    return 1
  fi
}

run_tb "1/3" sim/ofdm_files.f ofdm_basic_tb
run_tb "2/3" sim/ofdm_stream_files.f ofdm_stream_tb
run_tb "3/3" sim/ofdm_scoreboard_files.f ofdm_scoreboard_tb

echo
echo "Build output: obj_dir/"
echo "Regression summary:"
echo "  basic      PASS"
echo "  streaming  PASS"
echo "  scoreboard PASS"
echo "Result: PASS"
