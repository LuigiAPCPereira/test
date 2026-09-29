$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    $modelDir = Join-Path $projectRoot "build\models"
    $workDir = Join-Path $projectRoot "build\pyinstaller"
    $distDir = Join-Path $projectRoot "dist"
    $bundleDir = Join-Path $distDir "FiscalProcessor"
    $zipPath = Join-Path $distDir "FiscalProcessor-windows-x64.zip"

    Remove-Item -Recurse -Force $modelDir, $workDir, $bundleDir -ErrorAction SilentlyContinue
    Remove-Item -Force $zipPath -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force $modelDir, $workDir, $distDir | Out-Null

    python -m benchmarks.prepare_models $modelDir
    if ($LASTEXITCODE -ne 0) {
        throw "model provisioning failed with exit code $LASTEXITCODE"
    }

    $addData = $modelDir + ":models"
    $pyInstallerArgs = @(
        "-m", "PyInstaller",
        "--noconfirm",
        "--clean",
        "--onedir",
        "--windowed",
        "--name", "FiscalProcessor",
        "--distpath", $distDir,
        "--workpath", $workDir,
        "--specpath", $workDir,
        "--add-data", $addData,
        "--copy-metadata", "rapidocr",
        "--copy-metadata", "onnxruntime",
        "--collect-all", "rapidocr",
        "--collect-all", "onnxruntime",
        "--collect-all", "pypdfium2",
        "--collect-all", "pypdfium2_raw",
        "src\fiscal_processor\presentation\desktop.py"
    )
    python @pyInstallerArgs
    if ($LASTEXITCODE -ne 0) {
        throw "PyInstaller failed with exit code $LASTEXITCODE"
    }

    $exe = Join-Path $bundleDir "FiscalProcessor.exe"
    if (-not (Test-Path $exe -PathType Leaf)) {
        throw "portable executable was not created: $exe"
    }

    Compress-Archive -Path $bundleDir -DestinationPath $zipPath -CompressionLevel Optimal
    if (-not (Test-Path $zipPath -PathType Leaf)) {
        throw "portable ZIP was not created: $zipPath"
    }

    $hash = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Host "Portable ZIP: $zipPath"
    Write-Host "SHA-256: $hash"
}
finally {
    Pop-Location
}
