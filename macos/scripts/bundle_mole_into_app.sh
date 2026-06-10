#!/bin/sh
set -e

if [ -z "${BUILT_PRODUCTS_DIR:-}" ] || [ -z "${PRODUCT_NAME:-}" ]; then
  echo "bundle_mole_into_app.sh must run from an Xcode build." >&2
  exit 1
fi

APP_RESOURCES="$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Resources/mole"
ROOT="$(cd "$PROJECT_DIR/.." && pwd)"

"$ROOT/scripts/bundle_mole.sh" "$APP_RESOURCES"
