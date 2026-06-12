#!/bin/sh
# Verify Windows release bundle has everything Khine needs (run on any OS).
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/vendor/WinMole"
KHINE="$ROOT/scripts/windows/khine"
FAIL=0

check() {
  if [ -e "$1" ]; then
    echo "  OK  $1"
  else
    echo "  MISSING  $1"
    FAIL=1
  fi
}

echo "Checking WinMole vendor..."
check "$VENDOR/winmole.ps1"
check "$VENDOR/bin/clean.ps1"
if grep -q 'Clear-UserCaches' "$VENDOR/bin/clean.ps1" 2>/dev/null; then
  echo "  BROKEN  clean.ps1 still calls missing Clear-UserCaches"
  FAIL=1
fi
if grep -q 'Invoke-DevCleanup' "$VENDOR/bin/clean.ps1" 2>/dev/null; then
  echo "  BROKEN  clean.ps1 still calls missing Invoke-DevCleanup"
  FAIL=1
fi
check "$VENDOR/bin/optimize.ps1"
check "$VENDOR/bin/analyze.exe"
check "$VENDOR/bin/status.exe"
check "$VENDOR/lib/core/common.ps1"

echo ""
echo "Checking Khine Windows adapters..."
for script in _common.ps1 analyze_json.ps1 status_json.ps1 clean_run.ps1 uninstall_list.ps1 uninstall_apps.ps1 uninstall_lib.ps1; do
  check "$KHINE/$script"
  check "$VENDOR/bin/khine/$script"
done

echo ""
echo "Checking Flutter Windows project..."
check "$ROOT/windows/CMakeLists.txt"
check "$ROOT/scripts/release_windows.ps1"
check "$ROOT/scripts/bundle_winmole.ps1"
check "$ROOT/scripts/windows/khine.iss"

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "Bundle verification FAILED. Run: sh scripts/setup_winmole_vendor.sh"
  exit 1
fi

echo ""
echo "Bundle verification passed."
