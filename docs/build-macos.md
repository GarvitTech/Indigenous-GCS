# Building IndigenousGCS on macOS

## Prerequisites

### 1. Xcode Command Line Tools

```bash
xcode-select --install
```

Verify the installation:
```bash
clang --version
```

### 2. Homebrew

If Homebrew is not installed:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the post-install instructions to add Homebrew to your PATH. On Apple
Silicon (M1/M2/M3) Homebrew lives at `/opt/homebrew`; on Intel it is at
`/usr/local`.

### 3. Qt 6 — Option A: Homebrew (recommended for development)

```bash
brew install cmake qt@6
```

Set the environment variables so CMake can find Qt:
```bash
export QT_DIR="$(brew --prefix qt@6)"
export CMAKE_PREFIX_PATH="$QT_DIR"
```

Add these lines to your `~/.zshrc` (or `~/.bash_profile`) to make them
persistent:
```bash
echo 'export QT_DIR="$(brew --prefix qt@6)"' >> ~/.zshrc
echo 'export CMAKE_PREFIX_PATH="$QT_DIR"'    >> ~/.zshrc
```

### 3. Qt 6 — Option B: Qt Online Installer

1. Download the installer from <https://www.qt.io/download>
2. Run it and sign in / create a free Qt account
3. Select: **Qt → Qt 6.5 (or later) → macOS**
4. Also check: Qt Quick, Qt Location, Qt Positioning, Qt SerialPort, Qt SQL,
   Qt Network, Qt Charts
5. After installation, note the path (e.g. `~/Qt/6.8.3/macos`)
6. Export it:
   ```bash
   export QT_DIR=~/Qt/6.8.3/macos
   export CMAKE_PREFIX_PATH="$QT_DIR"
   ```

---

## Clone

```bash
git clone <repo-url>
cd IndigenousGCS
```

---

## Build

### Release build

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j8
```

Or let CMake choose the CPU count automatically:
```bash
cmake --build build --config Release -j$(sysctl -n hw.ncpu)
```

### Debug build

```bash
cmake -S . -B build-debug -DCMAKE_BUILD_TYPE=Debug
cmake --build build-debug -j$(sysctl -n hw.ncpu)
```

---

## Run

```bash
open build/bin/IndigenousGCS.app
```

Or launch directly from the terminal:
```bash
build/bin/IndigenousGCS.app/Contents/MacOS/IndigenousGCS
```

---

## Running Tests

```bash
cd build && ctest --output-on-failure
```

Or from the project root:
```bash
ctest --test-dir build --output-on-failure
```

---

## Creating a Distributable DMG

### Using the packaging script (simplest)

```bash
./tools/package-macos.sh
```

The script:
1. Configures and builds a Release version in `build-release/`
2. Runs `macdeployqt` to bundle all Qt and QML libraries
3. Creates `dist/IndigenousGCS-macOS.dmg` with `hdiutil`

If `macdeployqt` is not on your `PATH`, set `QT_PATH` first:
```bash
QT_PATH="$(brew --prefix qt@6)/bin" ./tools/package-macos.sh
```

### Manual macdeployqt steps

After building:

```bash
QT_BIN="$(brew --prefix qt@6)/bin"

# Bundle Qt frameworks and QML modules into the .app
"$QT_BIN/macdeployqt" build/bin/IndigenousGCS.app \
    -qmldir="$PWD/qml" \
    -always-overwrite

# Verify it opens without errors
open build/bin/IndigenousGCS.app

# Create the DMG
mkdir -p dist
hdiutil create \
    -volname "IndigenousGCS" \
    -srcfolder build/bin/IndigenousGCS.app \
    -ov -format UDZO \
    dist/IndigenousGCS-macOS.dmg
```

### Using CPack (CMake-integrated)

```bash
cmake -S . -B build-release -DCMAKE_BUILD_TYPE=Release
cmake --build build-release --config Release -j$(sysctl -n hw.ncpu)
cmake --install build-release --config Release --prefix "$PWD/build-release/install"
cd build-release && cpack --config CPackConfig.cmake
```

Output: `build-release/IndigenousGCS-1.0.0-macOS.dmg`

---

## Apple Silicon vs Intel Notes

### Apple Silicon (M1/M2/M3/M4)

Homebrew installs Qt as native arm64 — the build is fully native without any
extra configuration. Performance is excellent; no Rosetta needed.

```bash
# Confirm arm64 binary
file build/bin/IndigenousGCS.app/Contents/MacOS/IndigenousGCS
# → Mach-O 64-bit executable arm64
```

### Intel (x86_64)

Homebrew installs Qt as x86_64 — build proceeds normally.

### Universal Binary (arm64 + x86_64)

Requires a Qt build with both architectures (the Qt Online Installer does not
provide universal Qt 6 for macOS). With a compatible Qt:

```bash
cmake -S . -B build-universal \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build-universal -j$(sysctl -n hw.ncpu)
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `Qt6 not found` | Set `CMAKE_PREFIX_PATH` to your Qt install dir |
| `qmake: command not found` | Use CMake, not qmake — this project uses CMake |
| `qt@6 keg not linked` | Run `brew link qt@6 --force` or set `QT_DIR` manually |
| App won't open (Gatekeeper) | `xattr -cr build/bin/IndigenousGCS.app` |
| Serial port permission denied | `sudo chmod 666 /dev/tty.usbserial-*` |
| `macdeployqt` not found | `QT_PATH="$(brew --prefix qt@6)/bin" ./tools/package-macos.sh` |
| Missing QML modules at runtime | Pass `-qmldir="$PWD/qml"` to `macdeployqt` |
| CMake can't find `Qt6::Location` | Install the Location and Positioning modules via Qt Installer |
| Tests fail to compile | Ensure `ENABLE_TESTING` is `ON` (default); check CMake output for missing test deps |

---

## Quick Reference

```bash
# Full build and run
brew install cmake qt@6
export CMAKE_PREFIX_PATH="$(brew --prefix qt@6)"
git clone <repo> && cd IndigenousGCS
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j8
open build/bin/IndigenousGCS.app

# Tests
cd build && ctest --output-on-failure

# Package DMG
./tools/package-macos.sh
```
