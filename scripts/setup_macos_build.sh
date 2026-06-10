#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="${MOLE_UI_BUILD_DIR:-$HOME/Library/Caches/mole_ui_build}"

mkdir -p "$CACHE_DIR"

if [ -L "$ROOT/build" ]; then
  echo "build/ already symlinked to $(readlink "$ROOT/build")"
elif [ -d "$ROOT/build" ]; then
  echo "Moving build/ to internal drive..."
  rsync -a --delete "$ROOT/build/" "$CACHE_DIR/"
  rm -rf "$ROOT/build"
  ln -s "$CACHE_DIR" "$ROOT/build"
  echo "build/ -> $CACHE_DIR"
else
  ln -s "$CACHE_DIR" "$ROOT/build"
  echo "build/ -> $CACHE_DIR"
fi

dot_clean -m "$ROOT" 2>/dev/null || true
find "$ROOT" -name '._*' -type f -delete 2>/dev/null || true

echo "macOS build environment ready."
