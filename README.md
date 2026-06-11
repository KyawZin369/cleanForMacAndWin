# Khine (mole_ui)

A native desktop app for cleaning, optimizing, and monitoring your Mac or Windows PC. It wraps:

- **macOS:** [Mole](https://github.com/tw93/Mole)
- **Windows:** [WinMole](https://github.com/bhadraagada/winmole)

Both CLIs are bundled inside the app, so end users do not need Homebrew, `brew install mole`, or a separate WinMole install.

## macOS

### Prerequisites

- Flutter SDK (macOS desktop)
- Xcode + Command Line Tools
- Optional: Go (to build Mole `analyze-go` / `status-go` locally; otherwise downloaded from Mole releases)

### Setup & run

```bash
git clone <this-repo>
cd cleanForMacAndWin
sh scripts/setup_winmole_vendor.sh   # harmless on macOS; prepares Windows vendor if needed
flutter pub get
chmod +x scripts/*.sh macos/scripts/*.sh
./scripts/build_mole.sh
./scripts/run_macos.sh
```

### Release

```bash
./scripts/release_macos.sh
```

Outputs `dist/macos/Khine-<version>-macos.zip`.

## Windows

### Prerequisites

- Flutter SDK (Windows desktop)
- Visual Studio 2022 with **Desktop development with C++**
- PowerShell 5.1+ (built into Windows)

### Setup & run

```powershell
git clone <this-repo>
cd cleanForMacAndWin
sh scripts/setup_winmole_vendor.sh
flutter pub get
$env:WINMOLE_VENDOR_ROOT = "$PWD\vendor\WinMole"
flutter run -d windows
```

Or:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\run_windows.ps1
```

### How Windows features work

| Feature | CLI path |
|---------|----------|
| Clean | Bundled `winmole.ps1 clean -All` |
| Optimize | Bundled `winmole.ps1 optimize` |
| Uninstall | Khine adapter `bin/khine/uninstall_*.ps1` |
| Analyze | Khine adapter `bin/khine/analyze_json.ps1` |
| Status | Khine adapter `bin/khine/status_json.ps1` |

Khine-specific adapters live in `scripts/windows/khine/` and are copied into `vendor/WinMole/bin/khine/` during vendor setup. They output JSON for the Flutter UI (same models as macOS).

### Release

On Windows 10/11:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\release_windows.ps1
```

Outputs installer and portable zip under `dist/windows/`.

## Updating vendored CLIs

**Mole (macOS):**

```bash
rm -rf vendor/Mole
git clone --depth 1 https://github.com/tw93/Mole.git vendor/Mole
./scripts/build_mole.sh
```

**WinMole (Windows):**

```bash
sh scripts/setup_winmole_vendor.sh
```

This re-clones WinMole and re-syncs `scripts/windows/khine/` into `vendor/WinMole/bin/khine/`.
