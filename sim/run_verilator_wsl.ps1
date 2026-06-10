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

$installedDistros = @(& wsl.exe -l -q 2>$null | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($installedDistros.Count -eq 0) {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Error "WSL is installed, but no Linux distributions are registered for Windows user '$currentUser'. If Ubuntu exists at \\wsl.localhost\Ubuntu under your normal account, run run.bat from that account or set up a WSL distro for this user."
    exit 1
}

$distro = $env:OFDM_WSL_DISTRO
if ([string]::IsNullOrWhiteSpace($distro)) {
    $distro = "Ubuntu"
}

Write-Host "Using WSL distro preference: $distro"
& wsl.exe -d $distro -- sh -lc $cmd
$exitCode = $LASTEXITCODE
if ($exitCode -eq 127 -or $exitCode -eq 4294967295) {
    Write-Host "Named WSL distro '$distro' did not run. Trying the default WSL distro..."
    & wsl.exe -- sh -lc $cmd
    $exitCode = $LASTEXITCODE
}

exit $exitCode
