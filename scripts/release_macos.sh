#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/setup_macos_build.sh"
python3 "$ROOT/scripts/generate_app_icons.py"
"$ROOT/scripts/build_mole.sh"

export COPYFILE_DISABLE=1
export MOLE_VENDOR_ROOT="$ROOT/vendor/Mole"
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

echo "Ad-hoc signing app bundle for distribution..."
find "$APP_PATH" -name '._*' -type f -delete 2>/dev/null || true
find "$APP_PATH" -name '.DS_Store' -type f -delete 2>/dev/null || true

sign_if_needed() {
  target="$1"
  if [ -f "$target" ] || [ -d "$target" ]; then
    codesign --force --sign - --timestamp=none "$target" 2>/dev/null || \
      codesign --force --sign - "$target"
  fi
}

find "$APP_PATH/Contents/Frameworks" -type d -name "*.framework" 2>/dev/null | while read -r fw; do
  fw_name="$(basename "$fw" .framework)"
  sign_if_needed "$fw/Versions/Current/$fw_name"
  sign_if_needed "$fw"
done

find "$APP_PATH/Contents/Frameworks" -type f -perm +111 2>/dev/null | while read -r bin; do
  sign_if_needed "$bin"
done

sign_if_needed "$APP_PATH/Contents/MacOS/$APP_NAME"
xattr -cr "$APP_PATH" 2>/dev/null || true
sign_if_needed "$APP_PATH"

mkdir -p "$DIST_DIR"
VERSION="$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')"
ZIP_NAME="${APP_NAME}-${VERSION}-macos.zip"
DMG_NAME="${APP_NAME}-${VERSION}-macos.dmg"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"
DMG_PATH="$DIST_DIR/$DMG_NAME"

echo "Creating zip..."
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Creating dmg..."
STAGING="$(mktemp -d "${TMPDIR:-/tmp}/khine-dmg.XXXXXX")"
cleanup() {
  rm -rf "$STAGING"
}
trap cleanup EXIT INT TERM

ditto "$APP_PATH" "$STAGING/$APP_NAME.app"
ln -s /Applications "$STAGING/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

xattr -cr "$DMG_PATH" 2>/dev/null || true

echo ""
echo "Release build complete."
echo "  App: $APP_PATH"
echo "  Zip: $ZIP_PATH"
echo "  Dmg: $DMG_PATH"
echo ""
echo "Install: drag Khine.app to /Applications"
echo "First launch on another Mac: right-click Khine.app -> Open (Gatekeeper)."
echo "Includes bundled Mole CLI — no Homebrew install required."
