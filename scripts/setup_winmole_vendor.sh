#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/vendor/WinMole"

if [ -f "$DEST/winmole.ps1" ]; then
  echo "WinMole already present at $DEST"
  exit 0
fi

mkdir -p "$DEST"

echo "Fetching WinMole from GitHub..."
if command -v git >/dev/null 2>&1; then
  git clone --depth 1 https://github.com/bhadraagada/winmole.git "$DEST.tmp"
  rm -rf "$DEST"
  mv "$DEST.tmp" "$DEST"
else
  curl -L -o "$ROOT/vendor/winmole.zip" \
    https://github.com/bhadraagada/winmole/archive/refs/heads/master.zip
  unzip -q "$ROOT/vendor/winmole.zip" -d "$ROOT/vendor"
  rm -rf "$DEST"
  mv "$ROOT/vendor/winmole-master" "$DEST"
  rm -f "$ROOT/vendor/winmole.zip"
fi

echo "WinMole ready at $DEST"
