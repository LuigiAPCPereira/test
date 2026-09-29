$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$zipPath = Join-Path $projectRoot "dist\FiscalProcessor-windows-x64.zip"
if (-not (Test-Path $zipPath -PathType Leaf)) {
    throw "portable ZIP is missing: $zipPath"
}

$smokeRoot = Join-Path $env:RUNNER_TEMP "fiscal-processor-portable-smoke"
Remove-Item -Recurse -Force $smokeRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $smokeRoot | Out-Null
Expand-Archive -Path $zipPath -DestinationPath $smokeRoot -Force

$exe = Join-Path $smokeRoot "FiscalProcessor\FiscalProcessor.exe"
if (-not (Test-Path $exe -PathType Leaf)) {
    throw "extracted executable is missing: $exe"
}

$previousPath = $env:PATH
try {
    $env:PATH = "$env:SystemRoot\System32;$env:SystemRoot"
    if (Get-Command python -ErrorAction SilentlyContinue) {
        throw "Python unexpectedly remains discoverable on the smoke PATH"
    }

    $process = Start-Process -FilePath $exe -ArgumentList "--smoke" -PassThru -Wait
    if ($process.ExitCode -ne 0) {
        throw "portable smoke failed with exit code $($process.ExitCode)"
    }
}
finally {
    $env:PATH = $previousPath
}

Write-Host "Portable smoke PASS: extracted ZIP executed with Python absent from PATH."
