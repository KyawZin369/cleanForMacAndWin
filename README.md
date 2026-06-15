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

### Setup & run (development)

```powershell
git clone <this-repo>
cd cleanForMacAndWin
powershell -ExecutionPolicy Bypass -File scripts\run_windows.ps1
```

`run_windows.ps1` fetches WinMole, applies patches, and launches the app. No manual vendor setup or environment variables.

### Release

On Windows 10/11, one command builds everything (vendor fetch, Flutter build, installer, zip):

```powershell
git clone <this-repo>
cd cleanForMacAndWin
powershell -ExecutionPolicy Bypass -File scripts\release_windows.ps1
```

Outputs under `dist/windows/`:

| File | For end users |
|------|----------------|
| `Khine-<version>-windows-setup.exe` | **Recommended.** Double-click to install. No Flutter, Git, or WinMole needed. |
| `Khine-<version>-windows.zip` | Portable. Extract anywhere and run `Khine.exe`. |

End users only run the installer or `Khine.exe`. WinMole is bundled inside the app.

## Updating vendored CLIs

**Mole (macOS):**

```bash
rm -rf vendor/Mole
git clone --depth 1 https://github.com/tw93/Mole.git vendor/Mole
sh scripts/strip_vendor_git.sh vendor/Mole
./scripts/build_mole.sh
```

**WinMole (Windows):**

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup_winmole_vendor.ps1
```

Or on macOS/Linux (CI / cross-platform):

```bash
sh scripts/setup_winmole_vendor.sh
```

This re-clones WinMole and re-syncs `scripts/windows/khine/` into `vendor/WinMole/bin/khine/`.
