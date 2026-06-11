#!/bin/sh
cat <<'EOF'
Windows release must be built on Windows (or GitHub Actions).

On a Windows machine with Flutter + Visual Studio C++ tools:

  powershell -ExecutionPolicy Bypass -File scripts/release_windows.ps1

From macOS/Linux, use GitHub Actions instead:

  gh workflow run release-windows.yml

The zip will appear under dist/windows/ or as a workflow artifact.
EOF
