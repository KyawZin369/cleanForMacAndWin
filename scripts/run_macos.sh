#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/setup_macos_build.sh"
find "$ROOT" -name '._*' -type f -delete 2>/dev/null || true

export COPYFILE_DISABLE=1
flutter run -d macos "$@"
