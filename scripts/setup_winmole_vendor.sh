#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/vendor/WinMole"

apply_khine_patches() {
  OPT="$DEST/bin/optimize.ps1"
  if [ -f "$OPT" ] && ! grep -q 'WINMOLE_NONINTERACTIVE' "$OPT"; then
    sed -i.bak 's/if (-not $script:DryRun -and (Test-IsAdmin)) {/if (-not $script:DryRun -and (Test-IsAdmin) -and $env:WINMOLE_NONINTERACTIVE -ne '\''1'\'') {/' "$OPT"
    rm -f "$OPT.bak"
    echo "Patched optimize.ps1 for Khine non-interactive mode"
  fi

  CLEAN="$DEST/bin/clean.ps1"
  if [ -f "$CLEAN" ] && grep -q 'Clear-UserCaches' "$CLEAN"; then
    perl -i -0pe 's/if \(\$cleanUser\) \{\s*Clear-UserCaches\s*Clear-UserLogs\s*\}/if (\$cleanUser) {\n        Invoke-UserCleanup\n    }/s' "$CLEAN"
    sed -i.bak \
      -e 's/Clear-BrowserCaches/Clear-BrowserCacheFiles/g' \
      -e 's/Clear-ApplicationCaches/Clear-CommonAppCaches/g' \
      -e 's/Clear-WindowsUpdateCache/Clear-WindowsUpdateDownloads/g' \
      "$CLEAN"
    rm -f "$CLEAN.bak"
    echo "Patched clean.ps1 (fixed upstream missing function names)"
  fi

  if [ -f "$CLEAN" ] && grep -q 'Invoke-DevCleanup' "$CLEAN"; then
    sed -i.bak 's/Invoke-DevCleanup -All/Invoke-DevToolsCleanup/' "$CLEAN"
    rm -f "$CLEAN.bak"
    echo "Patched clean.ps1 (Invoke-DevToolsCleanup)"
  fi
}

sync_khine_scripts() {
  KHINE_SCRIPTS="$ROOT/scripts/windows/khine"
  if [ -d "$KHINE_SCRIPTS" ] && [ -f "$DEST/winmole.ps1" ]; then
    mkdir -p "$DEST/bin/khine"
    cp "$KHINE_SCRIPTS"/*.ps1 "$DEST/bin/khine/"
    echo "Synced Khine WinMole adapters to $DEST/bin/khine"
  fi
}

if [ -f "$DEST/winmole.ps1" ]; then
  sync_khine_scripts
  apply_khine_patches
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

sync_khine_scripts
apply_khine_patches

echo "WinMole ready at $DEST"
