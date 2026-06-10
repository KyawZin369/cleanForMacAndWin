#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/setup_macos_build.sh"
"$ROOT/scripts/build_mole.sh"
find "$ROOT" -name '._*' -type f -delete 2>/dev/null || true

export COPYFILE_DISABLE=1
export MOLE_VENDOR_ROOT="$ROOT/vendor/Mole"
flutter run -d macos "$@"
