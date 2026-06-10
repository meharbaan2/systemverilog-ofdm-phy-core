# Synthesis Report

Target: Lattice iCE40UP5K SG48

Tool flow: OSS CAD Suite Yosys, slang front-end, `synth_ice40`, and `nextpnr-ice40`.

This checked-in report is a transparent placeholder until `sh synth/run_synth.sh` is run in Linux/WSL. The simulation regression is passing; synthesis numbers should be regenerated locally before treating area/timing as measured FPGA results.

| Top | LUT usage | FF usage | DSP usage | BRAM usage | Max clock estimate |
| --- | ---: | ---: | ---: | ---: | --- |
| `ofdm_tx_stream` | pending local synth run | pending local synth run | pending local synth run | pending local synth run | pending local synth run |
| `ofdm_rx_stream` | pending local synth run | pending local synth run | pending local synth run | pending local synth run | pending local synth run |

Notes:

- The iCE40UP5K does not report DSP/BRAM in the same way as larger FPGA families; treat those rows as open-source synthesis estimates.
- The RTL uses a portable in-repo FFT and reciprocal approximation, not vendor IP.
- The synthesis script keeps generated logs, JSON netlists, and nextpnr output under `reports/`.
