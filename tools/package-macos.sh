#!/usr/bin/env bash
#
# Build a distributable macOS DMG for Indigenous GCS.
#
# Usage:
#   ./tools/package-macos.sh              # auto-detect Qt
#   QT_PATH=/path/to/qt/bin ./tools/package-macos.sh
#
# Produces: build/IndigenousGCS-<version>-macOS.dmg
#
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$PROJECT_DIR/build}"
APP_BUNDLE="$BUILD_DIR/bin/IndigenousGCS.app"
VERSION="1.0.0"
DMG_NAME="IndigenousGCS-${VERSION}-macOS.dmg"

echo "==> Indigenous GCS macOS packaging"
echo "    project : $PROJECT_DIR"
echo "    build   : $BUILD_DIR"

# ── Locate macdeployqt ────────────────────────────────────────────────────
if [[ -n "${QT_PATH:-}" ]]; then
    MACDEPLOYQT="$QT_PATH/macdeployqt"
else
    MACDEPLOYQT="$(command -v macdeployqt || true)"
    if [[ -z "$MACDEPLOYQT" ]]; then
        for candidate in /opt/homebrew/bin/macdeployqt /usr/local/bin/macdeployqt; do
            [[ -x "$candidate" ]] && MACDEPLOYQT="$candidate" && break
        done
    fi
fi

if [[ ! -x "$MACDEPLOYQT" ]]; then
    echo "ERROR: macdeployqt not found." >&2
    echo "  Install Qt 6 or set QT_PATH=/path/to/qt/bin" >&2
    exit 1
fi
echo "    using   : $MACDEPLOYQT"

# ── Build if needed ───────────────────────────────────────────────────────
if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "==> App bundle not found, configuring and building"
    cmake -S "$PROJECT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
    cmake --build "$BUILD_DIR" --config Release
fi

if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "ERROR: build did not produce $APP_BUNDLE" >&2
    exit 1
fi

# ── Bundle Qt frameworks and QML plugins ─────────────────────────────────
echo "==> Running macdeployqt (this bundles Qt frameworks into the .app)"
"$MACDEPLOYQT" "$APP_BUNDLE" \
    -qmldir="$PROJECT_DIR/qml" \
    -always-overwrite \
    -verbose=1

# ── Verify the bundle is self-contained ──────────────────────────────────
echo "==> Verifying bundle linkage"
if otool -L "$APP_BUNDLE/Contents/MacOS/IndigenousGCS" | grep -q "/opt/homebrew"; then
    echo "WARNING: binary still references Homebrew Qt paths." >&2
    echo "         The DMG may not run on machines without Qt installed." >&2
else
    echo "    OK — no external Qt references"
fi

# ── Create the DMG ────────────────────────────────────────────────────────
DMG_PATH="$BUILD_DIR/$DMG_NAME"
echo "==> Creating $DMG_NAME"
rm -f "$DMG_PATH"

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create \
    -volname "Indigenous GCS" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG_PATH"

echo
echo "==> Done"
echo "    $DMG_PATH"
echo "    $(du -h "$DMG_PATH" | cut -f1) on disk"
echo
echo "Install: open the DMG and drag Indigenous GCS to Applications."