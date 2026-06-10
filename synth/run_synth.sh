#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

YOSYS=${YOSYS:-tools/oss-cad-suite/bin/yosys}
NEXTPNR=${NEXTPNR:-tools/oss-cad-suite/bin/nextpnr-ice40}
SLANG_PLUGIN=${SLANG_PLUGIN:-tools/oss-cad-suite/share/yosys/plugins/slang.so}
REPORT_DIR=${REPORT_DIR:-reports}
mkdir -p "$REPORT_DIR"

run_yosys() {
  top="$1"
  log="$REPORT_DIR/${top}_yosys.log"
  json="$REPORT_DIR/${top}.json"
  asc="$REPORT_DIR/${top}.asc"
  pnr_log="$REPORT_DIR/${top}_nextpnr.log"

  "$YOSYS" -Q -l "$log" -p "
    plugin -i $SLANG_PLUGIN;
    read_slang --top $top -F synth/ofdm_synth_files.f;
    synth_ice40 -top $top -json $json;
    stat;
  "

  if command -v "$NEXTPNR" >/dev/null 2>&1; then
    "$NEXTPNR" --up5k --package sg48 --json "$json" --asc "$asc" --freq 12 > "$pnr_log" 2>&1 || true
  fi
}

extract_number() {
  pattern="$1"
  file="$2"
  awk -v pat="$pattern" '$0 ~ pat { value=$NF } END { if (value == "") print "n/a"; else print value }' "$file"
}

run_yosys ofdm_tx_stream
run_yosys ofdm_rx_stream

{
  echo "# Synthesis Report"
  echo
  echo "Target: Lattice iCE40UP5K SG48"
  echo
  echo "Tool flow: OSS CAD Suite Yosys, slang front-end, synth_ice40, nextpnr-ice40."
  echo "The iCE40 DSP/BRAM rows are open-source tool estimates and target-specific."
  echo
  echo "| Top | LUT usage | FF usage | DSP usage | BRAM usage | Max clock estimate |"
  echo "| --- | ---: | ---: | ---: | ---: | --- |"
  for top in ofdm_tx_stream ofdm_rx_stream; do
    log="$REPORT_DIR/${top}_yosys.log"
    pnr_log="$REPORT_DIR/${top}_nextpnr.log"
    lut=$(extract_number "SB_LUT4" "$log")
    ff=$(extract_number "SB_DFF" "$log")
    dsp=$(extract_number "SB_MAC16" "$log")
    bram=$(extract_number "SB_RAM40_4K" "$log")
    fmax="n/a"
    if [ -f "$pnr_log" ]; then
      fmax=$(awk '/Max frequency/ { value=$0 } END { if (value == "") print "n/a"; else print value }' "$pnr_log")
    fi
    echo "| $top | $lut | $ff | $dsp | $bram | $fmax |"
  done
  echo
  echo "Regenerate with:"
  echo
  echo "\`\`\`sh"
  echo "sh synth/run_synth.sh"
  echo "\`\`\`"
} > "$REPORT_DIR/synthesis_report.md"

echo "Wrote $REPORT_DIR/synthesis_report.md"
