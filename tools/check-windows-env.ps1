# tools/check-windows-env.ps1
#
# Verifies a Windows machine has everything Indigenous GCS needs, before you
# try to build. Run this first if a build fails — it reports exactly which
# component is missing and the command to install it.
#
#   .\tools\check-windows-env.ps1
#   .\tools\check-windows-env.ps1 -QtDir "C:\Qt\6.8.3\msvc2022_64"
#
# Exit code 0 means everything required was found.

[CmdletBinding()]
param(
    [string]$QtDir = ""
)

$ErrorActionPreference = "Continue"

$script:failures = 0
$script:warnings = 0

function Ok([string]$msg)   { Write-Host "  [ OK ] $msg"   -ForegroundColor Green }
function Bad([string]$msg)  { Write-Host "  [FAIL] $msg"   -ForegroundColor Red;   $script:failures++ }
function Warn([string]$msg) { Write-Host "  [WARN] $msg"   -ForegroundColor Yellow; $script:warnings++ }
function Head([string]$msg) { Write-Host ""; Write-Host $msg -ForegroundColor Cyan }

Write-Host ""
Write-Host "Indigenous GCS - Windows environment check" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# ── Operating system ─────────────────────────
Head "Operating system"
$os = Get-CimInstance Win32_OperatingSystem
$is64 = $env:PROCESSOR_ARCHITECTURE -eq "AMD64" -or $env:PROCESSOR_ARCHITEW6432 -eq "AMD64"
Write-Host "  $($os.Caption) build $($os.BuildNumber)"
if ($is64) { Ok "64-bit Windows" } else { Bad "This is not a 64-bit Windows installation. The build requires x64." }

# ── CMake ────────────────────────
Head "CMake"
$cmake = Get-Command cmake -ErrorAction SilentlyContinue
if ($cmake) {
    $ver = (& cmake --version | Select-Object -First 1)
    $num = [version]((($ver -split ')[2]))
    if ($num -ge [version]"3.21") { Ok "$ver" }
    else { Bad "$ver is too old. 3.21 or newer is required.`n         Fix: winget install Kitware.CMake" }
} else {
    Bad "cmake not found on PATH.`n         Fix: winget install Kitware.CMake   (then reopen this shell)"
}

# ── Visual Studio C++ toolchain ──────────────────────────────
Head "Visual Studio C++ toolchain"
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property displayName 2>$null
    if ($vs) { Ok "$vs (with C++ tools)" }
    else { Bad "Visual Studio is installed but the C++ workload is missing.`n         Fix: run the Visual Studio Installer and add 'Desktop development with C++'" }
} else {
    Bad "Visual Studio not found.`n         Fix: winget install Microsoft.VisualStudio.2022.BuildTools --override '--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'"
}

# ── Qt 6 ────────────────────────
Head "Qt 6"

function Test-QtKit([string]$path) {
    $cfg    = Join-Path $path "lib\cmake\Qt6\Qt6Config.cmake"
    $deploy = Join-Path $path "bin\windeployqt.exe"
    if (-not (Test-Path $cfg))    { return "no Qt6Config.cmake" }
    if (-not (Test-Path $deploy)) { return "no windeployqt.exe" }

    # The optional modules the application actually uses.
    $needed = @("Qt6Location", "Qt6Positioning", "Qt6SerialPort", "Qt6Sql", "Qt6Quick")
    $absent = @()
    foreach ($m in $needed) {
        if (-not (Test-Path (Join-Path $path "lib\cmake\$m\$m"))) { $absent += $m }
    }
    if ($absent.Count -gt 0) { return "missing modules: $($absent -join ', ')" }
    return ""
}

$candidateKits = @()
if ($QtDir) { $candidateKits += $QtDir }

# Auto-discover under the usual Qt install root.
foreach ($root in @("C:\Qt", "$env:USERPROFILE\Qt")) {
    if (Test-Path $root) {
        Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^\d+\.\d+' } | ForEach-Object {
                Get-ChildItem -Path $_.FullName -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "msvc*_64" } | ForEach-Object {
                        $candidateKits += $_.FullName
                    }
            }
    }
}

$goodKit = $null
foreach ($kit in ($candidateKits | Select-Object -Unique)) {
    $problem = Test-QtKit $kit
    if (-not $problem) {
        Ok $kit
        if (-not $goodKit) { $goodKit = $kit }
    } else {
        Warn "$kit - $problem"
    }
}

if (-not $goodKit) {
    if ($candidateKits.Count -eq 0) {
        Bad "No Qt 6 MSVC 64-bit kit found.`n         Fix: python -m pip install aqtinstall`n              python -m aqt install-qt windows desktop 6.8.3 win64_msvc2022_64 -O C:\Qt"
    } else {
        Bad "A Qt kit was found but it is incomplete (see warnings above).`n         Open the Qt Maintenance Tool and add the missing modules."
    }
} else {
    Write-Host ""
    Write-Host "  Use this Qt directory for the build:" -ForegroundColor White
    Write-Host "    $goodKit" -ForegroundColor Green
}

# ── Ninja (optional) ─────────────────────
Head "Ninja (optional, for faster builds)"
if (Get-Command ninja -ErrorAction SilentlyContinue) { Ok "ninja found" }
else { Warn "ninja not found. Builds will use the Visual Studio generator, which is slower but works.`n         Fix: winget install Ninja-build.Ninja" }

# ── NSIS (optional) ──────────────────────
Head "NSIS (optional, only for the installer)"
if (Get-Command makensis -ErrorAction SilentlyContinue) { Ok "makensis found" }
else { Warn "NSIS not found. You can still build the app; only the installer needs it.`n         Fix: winget install NSIS.NSIS" }

# ── Git ──────────
Head "Git"
if (Get-Command git -ErrorAction SilentlyContinue) { Ok ((& git --version)) }
else { Bad "git not found.`n         Fix: winget install Git.Git" }

# ── Python (optional, for esptool firmware flashing) ─────────────────────────
Head "Python 3 (optional, for firmware flashing)"
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if ($py) { Ok "$($py.Source)" }
else { Warn "Python 3 not found. The app builds and runs fine, but the Firmware page cannot flash the ESP32.`n         Fix: winget install Python.Python.3.12" }

# ── Summary ──────
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
if ($script:failures -eq 0) {
    Write-Host "Ready to build." -ForegroundColor Green
    if ($script:warnings -gt 0) {
        Write-Host "$($script:warnings) optional item(s) missing (see WARN above)." -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Next:" -ForegroundColor White
    if ($goodKit) {
        Write-Host "  .\tools\build-windows.ps1 -QtDir `"$goodKit`"" -ForegroundColor White
    } else {
        Write-Host "  .\tools\build-windows.ps1 -QtDir <your Qt MSVC 64-bit dir>" -ForegroundColor White
    }
    exit 0
} else {
    Write-Host "$($script:failures) required item(s) missing. Fix the FAIL entries above and run this again." -ForegroundColor Red
    exit 1
}
