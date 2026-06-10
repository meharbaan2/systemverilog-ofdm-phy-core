$ErrorActionPreference = "Stop"

Write-Host "Running SystemVerilog OFDM PHY sanity test..."
& (Join-Path $PSScriptRoot "sim\run_verilator_wsl.ps1")

