# Building Indigenous GCS on Windows

## Prerequisites

### 1. Install Visual Studio 2022
Download from https://visualstudio.microsoft.com/
Select: **Desktop development with C++**

### 2. Install CMake
Download from https://cmake.org/download/ and add to PATH.

### 3. Install Qt 6
Download Qt Online Installer from https://www.qt.io/download
Install: **Qt 6.5+** → **MSVC 2022 64-bit**

---

## Build (Command Prompt)

```cmd
set CMAKE_PREFIX_PATH=C:\Qt\6.x.x\msvc2022_64

cd IndigenousGCS
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 ^
      -DCMAKE_PREFIX_PATH=%CMAKE_PREFIX_PATH%
cmake --build build --config Release
```

### Or with Ninja (faster)
```cmd
cmake -S . -B build -G Ninja ^
      -DCMAKE_PREFIX_PATH=C:\Qt\6.x.x\msvc2022_64 ^
      -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

---

## Run

```cmd
build\bin\Release\IndigenousGCS.exe
```

---

## Deploy (windeployqt)

```cmd
C:\Qt\6.x.x\msvc2022_64\bin\windeployqt.exe ^
    --qmldir qml ^
      build\bin\Release\IndigenousGCS.exe
```

The CMake install/package step performs the equivalent Qt/QML deployment
automatically when Qt 6.5 or newer is used.
```

---

## Package as Installer

The fastest repeatable option from a PowerShell terminal is:

```powershell
.\tools\build-windows.ps1 -QtDir "C:\Qt\6.8.3\msvc2022_64"
```

This configures x64 MSVC, builds Release, runs the tests, deploys Qt/QML, and
creates the NSIS installer.

```cmd
cmake --build build --config Release --target package
```

Requires NSIS: https://nsis.sourceforge.io/

The generated installer is written to `build\IndigenousGCS-1.0.0-win64.exe`.
The application executable itself is written to
`build\bin\Release\IndigenousGCS.exe` for the Visual Studio generator.

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `Qt6 not found` | Set `CMAKE_PREFIX_PATH` to Qt MSVC dir |
| Missing DLLs at runtime | Run `windeployqt` |
| COM port not found | Check Device Manager for port name |
| Build fails with MSVC | Ensure "Desktop C++" workload installed |
