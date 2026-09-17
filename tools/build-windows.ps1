param(
    [Parameter(Mandatory = $true)]
    [string]$QtDir,
    [string]$BuildDir = "build-windows"
)

$ErrorActionPreference = "Stop"

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name"
    }
}

Require-Command cmake

if (-not (Test-Path (Join-Path $QtDir "lib\cmake\Qt6\Qt6Config.cmake"))) {
    throw "Qt6 was not found under '$QtDir'. Pass the Qt MSVC 2022 64-bit directory."
}

$nsis = Get-Command makensis -ErrorAction SilentlyContinue
if (-not $nsis) {
    throw "NSIS was not found. Install it with: winget install NSIS.NSIS"
}

$repo = Split-Path -Parent $PSScriptRoot
$buildPath = Join-Path $repo $BuildDir
$installPath = Join-Path $buildPath "install"

cmake -S $repo -B $buildPath -G "Visual Studio 17 2022" -A x64 `
    -DCMAKE_PREFIX_PATH=$QtDir `
    -DCMAKE_INSTALL_PREFIX=$installPath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

cmake --build $buildPath --config Release --parallel
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

ctest --test-dir $buildPath -C Release --output-on-failure
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

cmake --build $buildPath --config Release --target package
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Windows installer output:"
Get-ChildItem -Path $buildPath -Filter "*.exe" | Select-Object -ExpandProperty FullName
