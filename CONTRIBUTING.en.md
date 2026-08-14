# Contributing

<p>
  <a href="./CONTRIBUTING.md">简体中文</a> ·
  <a href="./CONTRIBUTING.en.md">English</a>
</p>

Thanks for looking at [MacFan](README.en.md). Read the product notes before changing fan-control code.

## Setup

- macOS 14+
- Xcode 15+
- A real Mac (SMC reads/writes; preview data is not hardware)

## Flow

1. Fork, branch as `feature/xxx` or `fix/xxx`
2. Keep the diff small; one job per PR
3. Verify authorize + RPM writes on hardware with **Release** or the website DMG
4. Do not test the admin helper from a DerivedData Debug build
5. Commits should say **why**
6. Open a Pull Request

## Conventions

- SwiftUI follows `MFTheme`; do not invent a second palette
- Copy goes in `MacFan/Services/L10n.swift` — **add both Chinese and English**
- SMC I/O stays in `MacFan/SMC` and `Services/SMCClient.swift`
- The installer is `MacFan/Resources/install-smc-helper.sh` (no nohup / python3)
- The site lives in `docs/`; bump `?v=` after CSS changes
- Do not commit DerivedData, user Xcode files, secrets, or `AppIcon-preview.png`

## Verify

```bash
xcodebuild -scheme MacFan -configuration Release -destination 'platform=macOS' build
```

- The auth card shows the current version
- RPM changes after authorize, and **System Auto** restores
- Closing the window keeps the menu bar extra, which can still quit

## Safety

Fan control writes the SMC. Restore **System Auto** when you finish on hardware. Reports: [SECURITY.md](SECURITY.md).
