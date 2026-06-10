$ErrorActionPreference = "Stop"

Write-Host "Running SystemVerilog OFDM PHY regression..."
& (Join-Path $PSScriptRoot "sim\run_verilator_wsl.ps1")
exit $LASTEXITCODE
