$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if ($projectRoot -notmatch '^([A-Za-z]):\\(.*)$') {
    throw "Expected a Windows drive path, got: $projectRoot"
}

$drive = $Matches[1].ToLowerInvariant()
$pathPart = $Matches[2] -replace '\\', '/'
$wslProjectRoot = "/mnt/$drive/$pathPart"
$quotedProjectRoot = $wslProjectRoot.Replace("'", "'\''")
$cmd = "cd '$quotedProjectRoot' && sh sim/run_verilator.sh"

wsl.exe -d Ubuntu -- sh -lc $cmd
