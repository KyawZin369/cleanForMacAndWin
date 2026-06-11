# Windows release output

Build on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/release_windows.ps1
```

Or trigger GitHub Actions from macOS:

```bash
gh workflow run release-windows.yml
```

Output: `Khine-0.1.0-windows.zip` — extract on any Windows 10/11 PC and run `Khine.exe`.
