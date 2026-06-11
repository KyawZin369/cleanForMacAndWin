#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="${MOLE_UI_BUILD_DIR:-$HOME/Library/Caches/mole_ui_build}"

mkdir -p "$CACHE_DIR"

# A prior release/install step can leave root-owned artifacts in the cache.
# The linker then fails with errno=13 when writing into Khine.app.
if find "$CACHE_DIR" -user root -print -quit 2>/dev/null | grep -q .; then
  echo "Build cache has root-owned files in $CACHE_DIR"
  if sudo -n chown -R "$(id -un):$(id -gn)" "$CACHE_DIR" 2>/dev/null; then
    echo "Fixed build cache ownership."
  else
    echo "Fix permissions, then retry:" >&2
    echo "  sudo chown -R $(id -un) \"$CACHE_DIR\"" >&2
    exit 1
  fi
fi

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
