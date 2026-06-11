# Windows release output

Build locally on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/release_windows.ps1
```

Or trigger GitHub Actions:

```sh
gh workflow run release-windows.yml
```

## Artifacts

| File | Use |
|------|-----|
| `Khine-<version>-windows-setup.exe` | **Recommended.** Double-click to install Khine to Program Files with Start menu shortcuts. |
| `Khine-<version>-windows.zip` | Portable build. Extract anywhere and run `Khine.exe`. |

## First launch

Windows SmartScreen may warn about an unknown publisher. Click **More info** → **Run anyway** on the first launch.
