#!/bin/sh
set +e

export PATH="$PROJECT_DIR/scripts/bin:$PATH"

"$PROJECT_DIR/scripts/clean_apple_double.sh"
echo "$PRODUCT_NAME.app" > "$PROJECT_DIR/Flutter/ephemeral/.app_filename"

# Embed copies frameworks then codesigns. On ExFAT, AppleDouble files break codesign.
"$FLUTTER_ROOT/packages/flutter_tools/bin/macos_assemble.sh" embed
EMBED_STATUS=$?

"$PROJECT_DIR/scripts/clean_apple_double.sh"

if [ "$EMBED_STATUS" -ne 0 ]; then
  FRAMEWORKS_DIR="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH"
  SIGN_ID="${EXPANDED_CODE_SIGN_IDENTITY:--}"
  codesign --force --verbose --sign "$SIGN_ID" "$FRAMEWORKS_DIR/App.framework/App"
  codesign --force --verbose --sign "$SIGN_ID" \
    "$FRAMEWORKS_DIR/FlutterMacOS.framework/FlutterMacOS"
  "$PROJECT_DIR/scripts/clean_apple_double.sh"
fi

exit 0
