#!/bin/sh
# ExFAT/USB volumes create AppleDouble (._*) files that break macOS codesign.

_clean_dir() {
  dir="$1"
  if [ -n "$dir" ] && [ -d "$dir" ]; then
    find "$dir" -name '._*' -print -delete 2>/dev/null || true
    dot_clean -m "$dir" 2>/dev/null || true
  fi
}

_clean_dir "$BUILT_PRODUCTS_DIR"
_clean_dir "$TARGET_BUILD_DIR"
_clean_dir "$PROJECT_DIR/Flutter/ephemeral"

APP=""
if [ -n "$TARGET_BUILD_DIR" ] && [ -n "$WRAPPER_NAME" ]; then
  APP="$TARGET_BUILD_DIR/$WRAPPER_NAME.app"
elif [ -n "$BUILT_PRODUCTS_DIR" ] && [ -n "$FULL_PRODUCT_NAME" ]; then
  APP="$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME"
elif [ -n "$BUILT_PRODUCTS_DIR" ] && [ -n "$PRODUCT_NAME" ]; then
  APP="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app"
fi

if [ -n "$APP" ] && [ -d "$APP" ]; then
  dot_clean -m "$APP" 2>/dev/null || true
  find "$APP" -name '._*' -print -delete 2>/dev/null || true
  xattr -cr "$APP" 2>/dev/null || true
fi
