# Khine (mole_ui)

A native macOS app for cleaning, optimizing, and monitoring your Mac. It wraps the [Mole](https://github.com/tw93/Mole) CLI in a Flutter UI.

## Bundled Mole CLI

This project vendors the full Mole source under `vendor/Mole/`. The macOS app bundles that runtime inside the app (`Contents/Resources/mole/`), so **end users do not need Homebrew or `brew install mole`**.

## Prerequisites

- Flutter SDK (macOS desktop enabled)
- Xcode + Command Line Tools
- Optional: Go (to build `analyze-go` / `status-go` locally; otherwise they are downloaded from Mole releases during build)

## First-time setup

```bash
git clone <this-repo>
cd cleanForMacAndWin

# Mole source (if vendor/Mole is missing)
git clone https://github.com/tw93/Mole.git vendor/Mole

flutter pub get
chmod +x scripts/*.sh macos/scripts/*.sh
./scripts/build_mole.sh
```

## Run (development)

```bash
./scripts/run_macos.sh
```

This prepares the build cache, builds Mole helpers, and runs `flutter run -d macos`.

## Release build

```bash
./scripts/release_macos.sh
```

Output:

- `build/macos/Build/Products/Release/Khine.app`
- `dist/macos/Khine-<version>-macos.zip`

## Updating Mole

Replace `vendor/Mole` with a newer checkout from https://github.com/tw93/Mole, then rebuild:

```bash
rm -rf vendor/Mole
git clone --depth 1 https://github.com/tw93/Mole.git vendor/Mole
./scripts/build_mole.sh
./scripts/release_macos.sh
```
