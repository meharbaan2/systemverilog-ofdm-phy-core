# Security Notes

## Removed Artifacts

- Removed the third-party Windows Icarus installer from the repo root.
- Removed unused `tools/oss-cad-suite-windows-x64-20260603.exe`.
- Removed the extracted archive source `tools/oss-cad-suite-linux-x64-20260610.tgz` after verification.

## Toolchain Provenance

The active simulator toolchain is the extracted Linux x64 OSS CAD Suite bundle
under `tools/oss-cad-suite`, run through Ubuntu WSL.

Source release:

- Repository: `YosysHQ/oss-cad-suite-build`
- Tag: `2026-06-10`
- Asset: `oss-cad-suite-linux-x64-20260610.tgz`
- GitHub-reported SHA-256:
  `289f874fea114e04e97994406e15efbcf1f0f4773927cc64ffaabc575157a324`

The downloaded archive's local SHA-256 matched the GitHub asset digest before
the archive was deleted.

## Local Checks

- No standalone Icarus installer remains in the repo.
- No Windows `iverilog` command was found on PATH.
- Microsoft Defender custom scan over the repo completed without reporting
  detections in this project.
- `tools/oss-cad-suite/bin/verilator --version` reports:
  `Verilator 5.049 devel rev v5.048-230-gde0236be2 (mod)`.

## Notes

OSS CAD Suite includes many open-source EDA tools, including Verilator, Yosys,
and Icarus Verilog. That bundled Icarus binary is part of the verified official
OSS CAD Suite artifact, not the removed third-party Windows Icarus installer.
