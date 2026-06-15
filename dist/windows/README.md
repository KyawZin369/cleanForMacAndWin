# Windows release output

One command on Windows 10/11 (fetches WinMole, builds, packages — no manual setup):

```powershell
powershell -ExecutionPolicy Bypass -File scripts/release_windows.ps1
```

Or trigger GitHub Actions:

```sh
gh workflow run release-windows.yml
```

## Artifacts for end users

| File | Use |
|------|-----|
| `Khine-<version>-windows-setup.exe` | **Recommended.** Double-click to install. WinMole is bundled — nothing else to install. |
| `Khine-<version>-windows.zip` | Portable. Extract anywhere and run `Khine.exe`. |

End users do not need Flutter, Git, PowerShell setup, or a separate WinMole install.

## First launch

Windows SmartScreen may warn about an unknown publisher. Click **More info** → **Run anyway** on the first launch.
