#!/bin/sh
# Build or download Mole Go helpers (analyze-go, status-go) into vendor/Mole/bin.
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOLE_DIR="${MOLE_DIR:-$ROOT/vendor/Mole}"
BIN_DIR="$MOLE_DIR/bin"

if [ ! -d "$MOLE_DIR" ]; then
  echo "Mole source not found at: $MOLE_DIR" >&2
  echo "Clone it with: git clone https://github.com/tw93/Mole.git vendor/Mole" >&2
  exit 1
fi

mkdir -p "$BIN_DIR"

get_mole_version() {
  grep '^VERSION=' "$MOLE_DIR/mole" | head -1 | sed 's/VERSION="\(.*\)"/\1/'
}

arch_suffix() {
  case "$(uname -m)" in
    arm64) echo arm64 ;;
    x86_64) echo amd64 ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

normalize_release_tag() {
  local version="$1"
  case "$version" in
    V* | v*) printf '%s\n' "$version" ;;
    *) printf 'V%s\n' "$version" ;;
  esac
}

download_binary() {
  local name="$1"
  local arch="$2"
  local version="$3"
  local tag
  tag="$(normalize_release_tag "$version")"
  local asset="${name}-darwin-${arch}"
  local url="https://github.com/tw93/mole/releases/download/${tag}/${asset}"
  local target="$BIN_DIR/${name}-go"

  echo "Downloading ${asset} (${tag})..."
  if curl -fsSL --connect-timeout 15 --max-time 120 -o "$target" "$url"; then
    chmod +x "$target"
    xattr -c "$target" 2>/dev/null || true
    return 0
  fi

  echo "Failed to download ${asset} from ${url}" >&2
  return 1
}

build_from_source() {
  if ! command -v go >/dev/null 2>&1; then
    return 1
  fi

  echo "Building Mole Go binaries from source..."
  (
    cd "$MOLE_DIR"
    go build -ldflags="-s -w" -o "$BIN_DIR/analyze-go" ./cmd/analyze
    go build -ldflags="-s -w" -o "$BIN_DIR/status-go" ./cmd/status
  )
}

need_binary() {
  local path="$1"
  [ ! -x "$path" ] || [ ! -s "$path" ]
}

ARCH="$(arch_suffix)"
VERSION="$(get_mole_version)"

if need_binary "$BIN_DIR/analyze-go" || need_binary "$BIN_DIR/status-go"; then
  if ! build_from_source; then
    download_binary analyze "$ARCH" "$VERSION"
    download_binary status "$ARCH" "$VERSION"
  fi
fi

if ! [ -x "$BIN_DIR/analyze-go" ] || ! [ -x "$BIN_DIR/status-go" ]; then
  echo "Mole Go binaries are missing in $BIN_DIR" >&2
  exit 1
fi

echo "Mole Go binaries ready in $BIN_DIR"
