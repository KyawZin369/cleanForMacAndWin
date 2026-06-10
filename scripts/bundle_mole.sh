#!/bin/sh
# Copy the Mole CLI runtime into a destination directory (e.g. app bundle Resources).
set -e

if [ $# -lt 1 ]; then
  echo "Usage: $0 <destination-dir>" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOLE_DIR="${MOLE_DIR:-$ROOT/vendor/Mole}"
DEST="$1"

if [ ! -d "$MOLE_DIR" ]; then
  echo "Mole source not found at: $MOLE_DIR" >&2
  exit 1
fi

"$ROOT/scripts/build_mole.sh"

rm -rf "$DEST"
mkdir -p "$DEST"

for item in mo mole lib bin; do
  if [ ! -e "$MOLE_DIR/$item" ]; then
    echo "Missing required Mole path: $MOLE_DIR/$item" >&2
    exit 1
  fi
  cp -R "$MOLE_DIR/$item" "$DEST/"
done

find "$DEST" -type f \( -name '*.sh' -o -name 'mo' -o -name 'mole' -o -name '*-go' \) -exec chmod +x {} +

echo "Bundled Mole runtime to: $DEST"
