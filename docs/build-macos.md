# Building Indigenous GCS on macOS

## Prerequisites

### 1. Install Xcode Command Line Tools
```bash
xcode-select --install
```

### 2. Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3. Install Qt 6 and CMake
```bash
brew install cmake qt@6
```

Or install Qt via the official Qt installer from https://www.qt.io/download

### 4. Set Qt path
```bash
export CMAKE_PREFIX_PATH=$(brew --prefix qt@6)
# Add to ~/.zshrc for persistence:
echo 'export CMAKE_PREFIX_PATH=$(brew --prefix qt@6)' >> ~/.zshrc
```

---

## Build

```bash
cd IndigenousGCS
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
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
./build/bin/IndigenousGCS
# or as .app bundle:
open build/bin/IndigenousGCS.app
```

---

## Package as DMG

```bash
cmake --build build --target package
# Produces IndigenousGCS-1.0.0-Darwin.dmg
```

Deploy Qt frameworks:
```bash
$(brew --prefix qt@6)/bin/macdeployqt build/bin/IndigenousGCS.app -dmg
```

---

## Apple Silicon (M1/M2/M3)

The build works natively on Apple Silicon when Qt 6 is installed via Homebrew (arm64).

For universal binary:
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
| `Qt6 not found` | Set `CMAKE_PREFIX_PATH` to Qt install dir |
| `qmake: command not found` | Use cmake, not qmake |
| Serial port permission denied | `sudo chmod 666 /dev/tty.usbserial-*` |
| App won't open (Gatekeeper) | `xattr -cr IndigenousGCS.app` |
