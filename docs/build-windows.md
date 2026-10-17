# Building IndigenousGCS on Windows

## Prerequisites

### 1. Visual Studio 2022 (or Build Tools)

**Option A — Full IDE:**
Download from <https://visualstudio.microsoft.com/> and select the workload:
- **Desktop development with C++**

**Option B — Build Tools only (no IDE):**
Download *Build Tools for Visual Studio 2022* from the same page. Select:
- **C++ build tools**  
- **MSVC v143 compiler toolset**  
- **Windows 10/11 SDK**

### 2. CMake

Download from <https://cmake.org/download/> (Windows x64 Installer).  
During installation, choose **Add CMake to the system PATH**.

Verify:
```powershell
cmake --version
```

### 3. Qt 6

Download the Qt Online Installer from <https://www.qt.io/download>.

1. Run the installer and sign in / create a free Qt account.
2. Select: **Qt → Qt 6.5 (or later) → MSVC 2022 64-bit**
3. Also check these components under the same kit:
   - Qt Quick
   - Qt Quick Controls
   - Qt Location
   - Qt Positioning
   - Qt SerialPort
   - Qt SQL
   - Qt Network

Default installation path: `C:\Qt\6.x.x\msvc2022_64`

### 4. Add Qt to PATH (optional but convenient)

```powershell
# In the same PowerShell session
$env:PATH = "C:\Qt\6.8.3\msvc2022_64\bin;$env:PATH"
```

Or set permanently via System Properties → Environment Variables.

---

## Clone

```powershell
git clone <repo-url>
cd IndigenousGCS
```

---

## Before you build: check your environment

Run this first. It reports exactly which component is missing and the command
to install it, instead of leaving you with a confusing CMake error:

```powershell
.\tools\check-windows-env.ps1
```

It checks Windows architecture, CMake version, the Visual Studio C++ workload,
Qt 6 (including the Location, Positioning, SerialPort, SQL and Quick modules),
Git, and optionally Ninja, NSIS and Python. It prints the Qt directory to use.

---

## Build — Visual Studio Generator

```powershell
$QtDir = "C:\Qt\6.8.3\msvc2022_64"

cmake -S . -B build `
    -G "Visual Studio 17 2022" -A x64 `
    -DCMAKE_PREFIX_PATH="$QtDir"

cmake --build build --config Release
```

The executable is at `build\bin\Release\IndigenousGCS.exe`.

---

## Build — Ninja (faster incremental builds)

Open a **x64 Native Tools Command Prompt for VS 2022** (from the Start menu),
or run `vcvarsall.bat amd64` in your current shell first. Then:

```powershell
$QtDir = "C:\Qt\6.8.3\msvc2022_64"

cmake -S . -B build -G Ninja `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_PREFIX_PATH="$QtDir"

cmake --build build
```

The executable is at `build\bin\IndigenousGCS.exe`.

---

## Running Tests

```powershell
cd build
ctest -C Release --output-on-failure
```

---

## Deploying Qt (running the .exe without an installer)

After building, Qt DLLs must be next to the executable:

```powershell
& "$QtDir\bin\windeployqt.exe" `
    --qmldir qml `
    "build\bin\Release\IndigenousGCS.exe"

# Launch directly
& ".\build\bin\Release\IndigenousGCS.exe"
```

`windeployqt` copies all required Qt DLLs, plugins, and QML modules next to
the executable. Without this step the application will fail to start with
missing DLL errors.

---

## Creating a Windows Installer (NSIS)

### Install NSIS

```powershell
winget install NSIS.NSIS
```

Or download from <https://nsis.sourceforge.io/>.

### Using the build script (recommended)

The PowerShell script at `tools/build-windows.ps1` automates everything —
configure, build, test, deploy the Qt runtime, and produce the NSIS installer:

```powershell
# Full pipeline: build + test + windeployqt + NSIS installer
.\tools\build-windows.ps1 -QtDir "C:\Qt\6.8.3\msvc2022_64"

# Faster incremental builds (run from an x64 Native Tools prompt)
.\tools\build-windows.ps1 -QtDir "C:\Qt\6.8.3\msvc2022_64" -Generator Ninja

# Build only, no installer (useful in CI or without NSIS)
.\tools\build-windows.ps1 -QtDir "C:\Qt\6.8.3\msvc2022_64" -SkipPackage

# Skip the test suite too
.\tools\build-windows.ps1 -QtDir "C:\Qt\6.8.3\msvc2022_64" -SkipTests -SkipPackage
```

The script verifies that `windeployqt` actually placed the core Qt DLLs
(`Qt6Core.dll`, `Qt6Gui.dll`, `Qt6Quick.dll`, `Qt6Location.dll`,
`Qt6SerialPort.dll`) next to the executable, and warns loudly if any are
missing — that is the usual cause of "it runs on my machine but not on the
user's".

If the script stops with `Execution of scripts is disabled on this system`,
run it for the current session only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### Using CMake install + CPack manually

```powershell
# Install to a staging directory with Qt deployed
cmake --install build --config Release `
    --prefix ".\build\install"

# Run CPack to generate the installer
cpack --config build\CPackConfig.cmake
```

Output: `build\IndigenousGCS-1.0.0-Windows.exe`

---

## Quick Reference

```powershell
# One-liner build + run (Visual Studio generator)
$Qt = "C:\Qt\6.8.3\msvc2022_64"
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DCMAKE_PREFIX_PATH=$Qt
cmake --build build --config Release
& "$Qt\bin\windeployqt.exe" --release --qmldir qml build\bin\Release\IndigenousGCS.exe
.\build\bin\Release\IndigenousGCS.exe
```

---

## Application icon

The Windows executable icon and its version metadata come from
`resources/icons/app_icon.rc`, which is compiled into `IndigenousGCS.exe`
automatically by CMake (see the `WIN32` block in `cmake/Packaging.cmake`).
Nothing needs to be done by hand.

The resource script references `app_icon.ico` (6 embedded sizes: 16/32/48/64/128/256).
If you change `app_icon.png`, regenerate the `.ico` so the two stay in sync:

```bash
# macOS / Linux, requires ImageMagick
magick app_icon.png -define icon:auto-resize=256,128,64,48,32,16 app_icon.ico
```

The same `.ico` is used for the NSIS installer/uninstaller icon via
`CPACK_NSIS_MUI_ICON` in `cmake/Packaging.cmake`.

---

## Running without an installer (portable folder)

After `windeployqt` has run, the whole application is contained in the
executable's directory. You can zip that folder and run it on any Windows 10/11
x64 machine with no Qt installation:

```powershell
Compress-Archive -Path "build\bin\Release\*" -DestinationPath "IndigenousGCS-portable.zip"
```

---

## Verifying the build is self-contained

The single most common Windows deployment failure is a missing Qt DLL that
only exists on the build machine. To check, run the executable with a clean
`PATH` — if it starts, the deployment is genuinely self-contained:

```powershell
$env:PATH = "C:\Windows\System32;C:\Windows"
.\build\bin\Release\IndigenousGCS.exe
```

Alternatively, list the DLLs the executable imports and confirm each one is
present in the same folder:

```powershell
dumpbin /DEPENDENTS build\bin\Release\IndigenousGCS.exe
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `Qt6 not found` | Set `-DCMAKE_PREFIX_PATH` to your Qt MSVC kit dir |
| `Qt6Location` / `Qt6Positioning` not found | Add Location and Positioning to your Qt kit in Qt Maintenance Tool |
| Missing DLLs at runtime | Run `windeployqt` against the built executable |
| App starts then exits immediately | Check that `Qt6Quick.dll` and the `qml\` module folder were deployed beside the .exe |
| Map shows "API Key Required" watermark | The build must use the keyless OSM provider — check `qml.mapping.custom.host` is `https://tile.openstreetmap.org/{z}/{x}/{y}.png` |
| Map tiles stay blank | Requires outbound HTTPS to `tile.openstreetmap.org`; a corporate proxy will block it |
| COM port not found | Check Device Manager → Ports (COM & LPT); install the ESP32 USB-serial driver (CP210x or CH340) |
| Build fails with MSVC | Ensure "Desktop development with C++" workload is installed |
| `ninja: command not found` | Use the VS generator, or run from x64 Native Tools prompt |
| NSIS not found by CPack | Install NSIS and restart the shell |
| `Execution of scripts is disabled` | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` |
| Antivirus blocks build | Add the project and build directories to exclusions |
| `windeployqt` copies wrong Qt | Ensure `%PATH%` includes only one Qt version's `bin` dir |
