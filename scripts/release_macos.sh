#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/setup_macos_build.sh"

export COPYFILE_DISABLE=1
find "$ROOT" -name '._*' -type f -delete 2>/dev/null || true

echo "Building macOS release..."
flutter build macos --release

APP_NAME="Khine"
BUILD_DIR="$ROOT/build/macos/Build/Products/Release"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DIST_DIR="$ROOT/dist/macos"

if [ ! -d "$APP_PATH" ]; then
  echo "Release app not found at: $APP_PATH" >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
VERSION="$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')"
ZIP_NAME="${APP_NAME}-${VERSION}-macos.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"

rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo ""
echo "Release build complete."
echo "  App: $APP_PATH"
echo "  Zip: $ZIP_PATH"
echo ""
echo "Install: drag Khine.app to /Applications"
echo "Requires: Homebrew + mole CLI (brew install mole)"
