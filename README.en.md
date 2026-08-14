<p align="center">
  <img src="MacFan-logo.png" width="128" alt="MacFan logo" />
</p>

<h1 align="center">MacFan</h1>

<p align="center">
  <b>Precise fan control for Mac</b><br />
  Native SwiftUI · live readings · one-click SMC writes
</p>

<p align="center">
  <a href="./README.md">简体中文</a> ·
  <a href="./README.en.md">English</a>
</p>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-191b1e" />
  <img alt="Universal Binary" src="https://img.shields.io/badge/Universal-arm64%20%7C%20x86__64-1f6b52" />
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5-F05138" />
  <img alt="License MIT" src="https://img.shields.io/badge/License-MIT-e23b2e" />
  <img alt="Version" src="https://img.shields.io/badge/version-1.1.7-e23b2e" />
</p>

<p align="center">
  <a href="https://linux503.github.io/MacFan/assets/MacFan-1.1.7-macos.zip"><b>Download v1.1.7</b></a>
  ·
  <a href="https://linux503.github.io/MacFan/">Website</a>
  ·
  <a href="https://github.com/linux503/MacFan/releases/latest">Releases</a>
</p>

<p align="center">
  <img src="docs/assets/poster-dashboard.jpg" alt="MacFan dashboard: modes, temperatures, fan RPM, and thermal trail" width="920" />
</p>

<p align="center"><i>Dashboard: pick a mode on the left, watch temps, fans, and the thermal trail on the right.</i></p>

---

## What it is

MacFan is a native fan controller for **macOS 14+**. It talks to the SMC: live RPM and temperatures, and real target writes.

Universal Binary for **Apple Silicon** and **Intel**. Do not authorize an Xcode Debug build. Use the [website zip](https://linux503.github.io/MacFan/assets/MacFan-1.1.7-macos.zip).

<table>
<tr>
<td width="50%">
<img src="docs/assets/poster-modes.jpg" alt="Four control modes" />
<p align="center"><i>Four control modes</i></p>
</td>
<td width="50%">
<img src="docs/assets/poster-scenes.jpg" alt="Six scenes" />
<p align="center"><i>Six built-in scenes</i></p>
</td>
</tr>
</table>

---

## Features

### Four control modes

| Mode | What it does |
|------|----------------|
| **Max Speed** | Push every fan to maximum for compiles, exports, or thermal dips |
| **Manual** | Set target RPM per fan; the slider matches the live reading |
| **System Auto** | Hand control back to macOS SMC — switch here after long sessions |
| **Scene Mode** | Follow a temperature curve, with optional app linking and night schedule |

### Six scenes

| Scene | Notes | Airflow |
|-------|-------|---------|
| **Silent Office** | Docs and meetings, noise first | 28% |
| **Media Lounge** | Quiet first, mild heat is OK | 32% |
| **Creator Burst** | Extra cooling for Xcode / Final Cut | 62% |
| **Game Arena** | High airflow against frame-time heat | 78% |
| **Arctic Max** | All fans at maximum | 100% |
| **Night Owl** | Lower RPM from 23:00–07:00 | 22% |

### Always available

- **Live gauges**: CPU / GPU / chassis temperature and per-fan RPM
- **Thermal trail**: history chart on the main panel
- **App linking**: switch scenes when a matching app is frontmost
- **Night schedule**: quieter curve by time of day
- **Menu bar extra**: Max Speed / System Auto / Silent Office, plus Quit
- **Closing the window does not quit**: the extra stays; choose **Quit MacFan** there
- **Chinese and English**: in-app toggle, **Chinese by default** (not tied to system language)
- **Dark / light**: sidebar or `⌘⇧L` for light
- **Update check**: website `version.json`, then GitHub Releases (`⌘U`)
- **Website**: sidebar, menu bar, or `⌘0`

---

## Install

<p align="center">
  <img src="docs/assets/poster-start.jpg" alt="Three steps: download, Applications, authorize" width="920" />
</p>

**Needs:** macOS 14.0+ · live speed writes need administrator rights (SMC)

1. Download **[MacFan-1.1.7-macos.zip](https://linux503.github.io/MacFan/assets/MacFan-1.1.7-macos.zip)**
2. Drag `MacFan.app` into **Applications**
3. If macOS blocks it: right-click the icon → **Open**
4. Click **Authorize Administrator** and enter your password  
   The card must show **MacFan v1.1.7**

Do not authorize a Debug build from Xcode / DerivedData. That path is the old installer and looks like “authorized, but the helper is not ready”.

---

## Usage

1. Confirm the sidebar auth card is in the administrator state.
2. Pick a control mode, or open Scene Mode and choose a curve.
3. In Manual, drag the per-fan sliders.
4. When you are done, switch back to **System Auto**.
5. After you close the window, the menu bar icon still controls or quits the app.

| Shortcut | Action |
|----------|--------|
| `⌘U` | Check for updates |
| `⌘0` | Open the website |
| `⌘⇧L` | Light appearance |

---

## Privileges

| Capability | Admin |
|------------|-------|
| Read fan RPM / temperatures | Usually no |
| Write target / max RPM | **Yes** (root LaunchDaemon) |
| Apple Silicon (especially M3 / M4) | May need `Ftst` unlock against `thermalmonitord` |

The helper installs as a LaunchDaemon:

- plist: `/Library/LaunchDaemons/com.macfan.smchelper.plist`
- socket: `/tmp/macfan-smc.sock`

Quitting the app **does not** stop the helper, so the next launch should not need a new password. After long manual sessions, restore System Auto.

---

## FAQ

<details>
<summary><b>Authorized, but the helper is not ready</b></summary>

<br />

You are probably on an Xcode Debug build or an old zip. Then:

1. Choose **Quit MacFan** in the menu bar; confirm Activity Monitor shows no MacFan
2. Install v1.1.7 from the website into Applications
3. Confirm the card says **MacFan v1.1.7**, then authorize again
</details>

<details>
<summary><b>Can’t be opened / damaged</b></summary>

<br />

Right-click → Open. If that still fails:

```bash
xattr -cr /Applications/MacFan.app
```
</details>

<details>
<summary><b>The app is still running after I close the window</b></summary>

<br />

Expected: MacFan stays in the menu bar. Open the extra → **Quit MacFan**.
</details>

<details>
<summary><b>On Apple Silicon, RPM snaps back</b></summary>

<br />

`thermalmonitord` may override user writes. MacFan tries a `Ftst` unlock. If it still snaps back, switch to System Auto, then try Max Speed again.
</details>

---

## Build from source

```bash
git clone https://github.com/linux503/MacFan.git
cd MacFan
open MacFan.xcodeproj
```

Select **My Mac** → Product → Clean Build Folder → ⌘R.  
The window must show **v1.1.7**.

```bash
xcodebuild -scheme MacFan -configuration Release -destination 'platform=macOS' build
```

See the [contributing guide](CONTRIBUTING.en.md) for conventions.

---

## Architecture

```
MacFan/
├── MacFan/                 # SwiftUI app
│   ├── Models/             # scenes, fans, thermals
│   ├── Services/           # SMC client, helper, view model, updates
│   ├── SMC/                # AppleSMC C bridge
│   └── Views/              # sidebar, dashboard, menu bar, theme
├── docs/                   # website (GitHub Pages)
└── MacFan.xcodeproj
```

- **UI**: SwiftUI + `MenuBarExtra`
- **Hardware**: `AdaptiveFanController` + `SMCClient` (Intel / Apple Silicon)
- **Writes**: LaunchDaemon → Unix socket `/tmp/macfan-smc.sock`
- **Arch**: `arm64` + `x86_64` Universal

Preview the site locally with `open docs/index.html`.

---

## Changelog

<details>
<summary><b>1.1.7</b> — new mark, Quit in the menu bar, compact extra</summary>

- One mark for Dock, menu bar, website, and GitHub
- Quit MacFan in the menu bar extra
- Smaller menu bar panel
</details>

<details>
<summary><b>1.1.6</b> — LaunchDaemon helper</summary>

- Helper installs as a LaunchDaemon (no nohup / python3 stub)
- Password prompt on the main thread
- Quitting the app no longer kills the helper
</details>

---

## Roadmap

- [ ] Signed privileged helper (no password every time)
- [ ] Custom curve editor
- [ ] Export / import scenes
- [ ] Sparkle auto-update

Security reports: [SECURITY.md](SECURITY.md).

---

## License

[MIT](LICENSE) © 2026 MacFan
