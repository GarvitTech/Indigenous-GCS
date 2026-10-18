#!/bin/bash
# ============================================================================
#  IndigenousGCS — one-click installer for macOS
# ============================================================================
#  What this script does:
#    1. Installs the Apple Command Line Tools (if missing)
#    2. Installs Homebrew (if missing)
#    3. Installs Qt 6, CMake and Ninja
#    4. Builds IndigenousGCS in Release mode
#    5. Copies the finished IndigenousGCS.app to your Desktop
#    6. Removes the quarantine flag so Gatekeeper lets it open
#    7. Launches the application
#
#  Usage:  double-click this file in Finder, OR run it from Terminal:
#             ./tools/install-macos.command
# ============================================================================

set -e

# Always operate from the repository root (the folder that contains this script's parent).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

APP_NAME="IndigenousGCS.app"
BUILD_DIR="build"
DESKTOP="$HOME/Desktop"
DEST_APP="$DESKTOP/$APP_NAME"

# ── Pretty output helpers ────────────────────────────────────────────────────
BOLD="$(tput bold 2>/dev/null || true)"
GREEN="$(tput setaf 2 2>/dev/null || true)"
YELLOW="$(tput setaf 3 2>/dev/null || true)"
RED="$(tput setaf 1 2>/dev/null || true)"
RESET="$(tput sgr0 2>/dev/null || true)"

step()  { echo "${BOLD}${GREEN}==>${RESET} ${BOLD}$1${RESET}"; }
info()  { echo "    $1"; }
warn()  { echo "${YELLOW}warning:${RESET} $1"; }
die()   { echo "${RED}error:${RESET} $1" >&2; echo; echo "Press Enter to close this window."; read -r _; exit 1; }

echo
echo "${BOLD}IndigenousGCS — macOS installer${RESET}"
echo "Repository: $REPO_ROOT"
echo

# ── 1. Apple Command Line Tools ──────────────────────────────────────────────
step "Checking Apple Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
    info "Not found — installing (a system dialog may appear)..."
    # Trigger the GUI installer; it cannot be fully automated by design.
    xcode-select --install >/dev/null 2>&1 || true
    echo
    warn "A macOS dialog has opened asking to install the Command Line Tools."
    info "Please complete that installation, then re-run this script."
    echo "Press Enter to close this window."
    read -r _
    exit 0
else
    info "Already installed."
fi

# ── 2. Homebrew ──────────────────────────────────────────────────────────────
step "Checking Homebrew"
if ! command -v brew >/dev/null 2>&1; then
    info "Not found — installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Make brew available in this shell on Apple Silicon and Intel.
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    info "Already installed ($(command -v brew))."
fi

# ── 3. Qt 6, CMake, Ninja ────────────────────────────────────────────────────
step "Installing Qt 6, CMake and Ninja"
brew install qt cmake ninja git

QT_PREFIX="$(brew --prefix qt)"
info "Qt prefix: $QT_PREFIX"

# ── 4. Build ─────────────────────────────────────────────────────────────────
step "Building IndigenousGCS (this can take several minutes)"
rm -rf "$BUILD_DIR"

if command -v ninja >/dev/null 2>&1; then
    cmake -S . -B "$BUILD_DIR" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH="$QT_PREFIX"
    cmake --build "$BUILD_DIR"
else
    cmake -S . -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH="$QT_PREFIX"
    cmake --build "$BUILD_DIR" --config Release -j"$(sysctl -n hw.ncpu)"
fi

# ── 5. Copy to Desktop ───────────────────────────────────────────────────────
step "Copying the application to the Desktop"
if [ ! -d "$BUILD_DIR/bin/$APP_NAME" ]; then
    die "Build finished but $BUILD_DIR/bin/$APP_NAME was not produced."
fi

rm -rf "$DEST_APP"
cp -R "$BUILD_DIR/bin/$APP_NAME" "$DESKTOP/"
info "Installed: $DEST_APP"

# ── 6. Clear quarantine so Gatekeeper opens it ───────────────────────────────
step "Removing quarantine flag"
xattr -dr com.apple.quarantine "$DEST_APP" 2>/dev/null || true
info "Done."

# ── 7. Launch ────────────────────────────────────────────────────────────────
step "Launching IndigenousGCS"
open "$DEST_APP"

echo
echo "${GREEN}${BOLD}All done.${RESET} IndigenousGCS is on your Desktop."
info "To open it later: double-click IndigenousGCS.app on the Desktop."
echo
echo "Press Enter to close this window."
read -r _
