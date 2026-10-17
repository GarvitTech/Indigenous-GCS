# tools/build-windows.ps1
#
# Build, test, deploy and package Indigenous GCS on Windows.
#
# Usage:
#   .\tools\build-windows.ps1 -QtDir "C:\Qt\6.8.3\msvc2022_64"
#   .\tools\build-windows.ps1 -QtDir "..." -SkipPackage     # no NSIS installer
#   .\tools\build-windows.ps1 -QtDir "..." -Generator Ninja # faster incremental
#
# Produces (Visual Studio generator):
#   build-windows\bin\Release\IndigenousGCS.exe
#   build-windows\IndigenousGCS-1.0.0-Windows.exe   (NSIS installer)
#
# Requires: Visual Studio 2022 (Desktop C++ workload), CMake 3.21+, Qt 6.5+
#           MSVC 2022 64-bit, and NSIS (unless -SkipPackage).

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$QtDir,

    [string]$BuildDir = "build-windows",

    [ValidateSet("VS", "Ninja")]
    [string]$Generator = "VS",

    [switch]$SkipTests,
    [switch]$SkipPackage
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {

    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name"
    }
}

# ── Preflight ────────────────────────────────────────────────────────────────
Write-Step "Checking prerequisites"

Require-Command cmake

$qtConfig = Join-Path $QtDir "lib\cmake\Qt6\Qt6Config.cmake"
if (-not (Test-Path $qtConfig)) {
    throw "Qt6 was not found under '$QtDir'. Expected: $qtConfig`nPass the Qt MSVC 2022 64-bit directory, e.g. -QtDir 'C:\Qt\6.8.3\msvc2022_64'"
}

$windeployqt = Join-Path $QtDir "bin\windeployqt.exe"
if (-not (Test-Path $windeployqt)) {
    throw "windeployqt.exe not found at '$windeployqt'. Is this a full Qt MSVC kit?"
}

if (-not $SkipPackage) {
    if (-not (Get-Command makensis -ErrorAction SilentlyContinue)) {
        throw "NSIS was not found. Install with: winget install NSIS.NSIS`nOr re-run with -SkipPackage to build without an installer."
    }
}

if ($Generator -eq "Ninja" -and -not (Get-Command ninja -ErrorAction SilentlyContinue)) {
    throw "Ninja not found. Run this from an 'x64 Native Tools Command Prompt for VS 2022', or use -Generator VS."
}

$repo        = Split-Path -Parent $PSScriptRoot
$buildPath   = Join-Path $repo $BuildDir
$installPath = Join-Path $buildPath "install"

Write-Host "    repo   : $repo"
Write-Host "    build  : $buildPath"
Write-Host "    Qt     : $QtDir"

# ── Configure ────────────────────────────────────────────────────────────────
Write-Step "Configuring CMake"

$cmakeArgs = @(
    "-S", $repo,
    "-B", $buildPath,
    "-DCMAKE_PREFIX_PATH=$QtDir",
    "-DCMAKE_INSTALL_PREFIX=$installPath"
)

if ($Generator -eq "VS") {
    $cmakeArgs += @("-G", "Visual Studio 17 2022", "-A", "x64")
} else {
    $cmakeArgs += @("-G", "Ninja", "-DCMAKE_BUILD_TYPE=Release")
}

& cmake @cmakeArgs
if ($LASTEXITCODE -ne 0) { throw "CMake configure failed (exit $LASTEXITCODE)" }

# ── Build ────────────────────────────────────────────────────────────────────
Write-Step "Building (Release)"

if ($Generator -eq "VS") {
    & cmake --build $buildPath --config Release --parallel
} else {
    & cmake --build $buildPath --parallel
}
if ($LASTEXITCODE -ne 0) { throw "Build failed (exit $LASTEXITCODE)" }

# ── Tests ────────────────────────────────────────────────────────────────────
if (-not $SkipTests) {
    Write-Step "Running unit tests"
    & ctest --test-dir $buildPath -C Release --output-on-failure
    if ($LASTEXITCODE -ne 0) { throw "Tests failed (exit $LASTEXITCODE)" }
} else {
    Write-Host "    (skipped)"
}

# ── Locate the built executable ──────────────────────────────────────────────
# The VS generator nests by config (bin\Release), Ninja does not (bin\).
$exe = Get-ChildItem -Path (Join-Path $buildPath "bin") -Filter "IndigenousGCS.exe" -Recurse |
       Select-Object -First 1
if (-not $exe) { throw "IndigenousGCS.exe was not produced under '$buildPath\bin'" }
$exeDir = $exe.DirectoryName
Write-Host "    built: $($exe.FullName)"

# ── Deploy Qt runtime ────────────────────────────────────────────────────────
Write-Step "Deploying Qt runtime with windeployqt"
Write-Host "    (copies Qt DLLs, platform plugins and QML modules next to the .exe)"

& $windeployqt --release --qmldir (Join-Path $repo "qml") $exe.FullName
if ($LASTEXITCODE -ne 0) { throw "windeployqt failed (exit $LASTEXITCODE)" }

# Verify the essentials actually landed next to the executable. This is fatal
# rather than a warning: a build that only runs because Qt happens to be on the
# developer's PATH is not shippable, and discovering that on a user's machine
# is far worse than failing here.
$required = @(
    "Qt6Core.dll", "Qt6Gui.dll", "Qt6Quick.dll", "Qt6QuickControls2.dll",
    "Qt6Network.dll", "Qt6SerialPort.dll", "Qt6Sql.dll",
    "Qt6Location.dll", "Qt6Positioning.dll"
)
$missing = @()
foreach ($dll in $required) {
    if (-not (Test-Path (Join-Path $exeDir $dll))) { $missing += $dll }
}

if ($missing.Count -gt 0) {
    throw @"
windeployqt did not place these DLLs next to the executable:
  $($missing -join ', ')

The build is not self-contained and would fail on a machine without Qt.
Check that windeployqt came from the same Qt kit used to build, and that
only one Qt version is on PATH.
"@
}

# The QML module directory must exist too, or the UI cannot load at runtime.
$qmlDir = Join-Path $exeDir "qml"
if (-not (Test-Path $qmlDir)) {
    throw "The deployed 'qml' module directory is missing from $exeDir — the UI would fail to load."
}

# The SQLite driver plugin is required for flight logging.
$sqlDrivers = Join-Path $exeDir "sqldrivers"
if (-not (Test-Path (Join-Path $sqlDrivers "qsqlite.dll"))) {
    throw "The SQLite driver plugin (sqldrivers\qsqlite.dll) was not deployed — flight logging would not work."
}

Write-Host "    OK - Qt runtime and plugins are self-contained next to the .exe"

# ── Smoke test ───────────────────────────────────────────────────────────────
# Launch the application and confirm it survives startup. A QML load failure
# exits immediately, so staying alive is a meaningful check that the UI built.
Write-Step "Smoke-testing the executable"

$env:IGCS_AUTOSTART_SIM = "1"
$stdout = Join-Path $buildPath "smoke-stdout.txt"
$stderr = Join-Path $buildPath "smoke-stderr.txt"

$proc = Start-Process -FilePath $exe.FullName -PassThru `
                      -RedirectStandardOutput $stdout `
                      -RedirectStandardError  $stderr
Start-Sleep -Seconds 15

if ($proc.HasExited) {
    Write-Host "--- stdout ---"
    Get-Content $stdout -ErrorAction SilentlyContinue | Write-Host
    Write-Host "--- stderr ---"
    Get-Content $stderr -ErrorAction SilentlyContinue | Write-Host
    throw "The application exited during startup (exit code $($proc.ExitCode))."
}
Write-Host "    Application is running after 15 seconds."
Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue

$errText = (Get-Content $stderr -ErrorAction SilentlyContinue | Out-String)
if ($errText -match "TypeError|ReferenceError|is not defined|Non-existent") {
    Write-Host $errText
    throw "QML errors were reported at startup."
}
Write-Host "    No QML errors reported."
Remove-Item Env:\IGCS_AUTOSTART_SIM -ErrorAction SilentlyContinue

# ── Install + package ────────────────────────────────────────────────────────
if ($SkipPackage) {
    Write-Step "Done (packaging skipped)"
    Write-Host "Executable: $($exe.FullName)"
    return
}

Write-Step "Installing to staging directory"
& cmake --install $buildPath --config Release
if ($LASTEXITCODE -ne 0) { throw "cmake --install failed (exit $LASTEXITCODE)" }

Write-Step "Building NSIS installer with CPack"
Push-Location $buildPath
try {
    & cpack -C Release --config (Join-Path $buildPath "CPackConfig.cmake")
    if ($LASTEXITCODE -ne 0) { throw "CPack failed (exit $LASTEXITCODE)" }
} finally {
    Pop-Location
}

Write-Step "Done"
Get-ChildItem -Path $buildPath -Filter "*.exe" |
    Where-Object { $_.Name -like "IndigenousGCS-*" } |
    ForEach-Object { Write-Host "Installer: $($_.FullName)" }
Write-Host "Portable : $($exe.FullName)"
