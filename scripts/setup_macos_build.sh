#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="${MOLE_UI_BUILD_DIR:-$HOME/Library/Caches/mole_ui_build}"

mkdir -p "$CACHE_DIR"

if [ -L "$ROOT/build" ]; then
  CURRENT_TARGET="$(readlink "$ROOT/build")"
  if [ ! -e "$ROOT/build" ]; then
    echo "Replacing broken build/ symlink ($CURRENT_TARGET)..."
    rm "$ROOT/build"
    ln -s "$CACHE_DIR" "$ROOT/build"
    echo "build/ -> $CACHE_DIR"
  elif [ "$CURRENT_TARGET" != "$CACHE_DIR" ]; then
    echo "Updating build/ symlink ($CURRENT_TARGET -> $CACHE_DIR)..."
    rm "$ROOT/build"
    ln -s "$CACHE_DIR" "$ROOT/build"
    echo "build/ -> $CACHE_DIR"
  else
    echo "build/ already symlinked to $CURRENT_TARGET"
  fi
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
