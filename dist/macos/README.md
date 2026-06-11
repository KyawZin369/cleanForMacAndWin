# macOS release output

Build locally on a Mac:

```sh
sh scripts/release_macos.sh
```

Or trigger GitHub Actions:

```sh
gh workflow run release-macos.yml
```

## Artifacts

| File | Use |
|------|-----|
| `Khine-<version>-macos.pkg` | **Recommended.** Double-click to run the installer wizard. Installs to `/Applications`. |
| `Khine-<version>-macos.dmg` | Open the disk image, then double-click **Install Khine** or drag `Khine.app` to **Applications**. |
| `Khine-<version>-macos.zip` | Portable app bundle only. Copy `Khine.app` to `/Applications` manually. |

## First launch

macOS Gatekeeper may block unsigned builds. Right-click `Khine.app` → **Open** → **Open** on the first launch.
