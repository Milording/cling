<div align="center">

# 🏆 Cling

### Xbox-style achievements for Claude Code.

Cling is a native macOS menu bar app that tracks your local Claude Code activity and unlocks achievements as you work.

[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6-orange?logo=swift)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Stars](https://img.shields.io/github/stars/Milording/cling?style=social)](https://github.com/Milording/cling/stargazers)

<img src="assets/popover-light.png" width="330" alt="Cling achievements grid in light mode"> <img src="assets/popover-dark.png" width="330" alt="Cling achievements grid in dark mode">

</div>

## What it does

Cling reads Claude Code transcripts stored on your Mac and tracks milestones such as token usage, commits, streaks, late-night sessions, project activity, and more.

When you unlock an achievement, it shows a toast with a sound inspired by Xbox 360 achievements.

<div align="center">
<img src="assets/toast.gif" width="560" alt="Achievement unlock animation">
</div>

Achievements are displayed as interactive 3D coins. Drag them to rotate and view the date on the back.

<div align="center">
<img src="assets/coin.gif" width="240" alt="Interactive 3D achievement coin">
</div>

## Features

- 67 achievements across Bronze, Silver, Gold, and Platinum tiers
- Hidden achievements
- Token, activity, and usage statistics
- Light and dark mode
- Native SwiftUI app with zero third-party dependencies

All data stays on your Mac. Cling has no account system, telemetry, or network layer.

## Achievements

A few examples:

| Tier | Achievement | Requirement |
|:----:|-------------|-------------|
| 🥉 Bronze | **First Contact** | Send your first message |
| 🥉 Bronze | **Night Owl I** | Work during 10 nights between midnight and 5 AM |
| 🥉 Bronze | **Git Gud I** | Make 10 Git commits |
| 🥈 Silver | **Millionaire's Club II** | Generate 10,000,000 tokens |
| 🥈 Silver | **Weekend Warrior** | Work on both days of 10 weekends |
| 🥈 Silver | **Potty Mouth II** | Swear 25 times |
| 🥇 Gold | **Daily Driver III** | Reach a 100-day streak |
| 🥇 Gold | **Car Payment** | Reach $500 in estimated usage |
| 💎 Platinum | **Daily Driver IV** | Reach a 365-day streak |
| 💎 Platinum | **100% Claude Completion** | Unlock every other achievement |

Some achievements are hidden until you unlock them.

<div align="center">
<img src="assets/card-horizontal.png" width="560" alt="Shareable achievement card">
<br>
<em>Unlocked achievements can be exported as shareable images.</em>
</div>

## Install

Cling requires macOS 14 or newer and the Swift toolchain included with Xcode 15 or newer.

```sh
git clone https://github.com/Milording/cling.git
cd cling
scripts/bundle.sh --install
open /Applications/Cling.app
```

To build without installing:

```sh
scripts/bundle.sh
open dist/Cling.app
```

Cling appears in the menu bar as a trophy icon.

Tracking begins after the first launch. Existing Claude Code history is not imported.

> Cling is currently unsigned and unnotarized. macOS may require approval under **System Settings → Privacy & Security** after the first launch.

### Launch at login

Open Cling settings and enable **Launch at login**.

The app must be installed in `/Applications` for this option to work.

## Privacy

Claude Code stores transcripts under:

```text
~/.claude/projects/
```

Cling reads those files locally and saves progress to:

```text
~/Library/Application Support/Cling/state.json
```

Nothing is uploaded or sent to an external service.

## Development

```sh
swift build
swift test
scripts/bundle.sh
```

The project uses Swift Package Manager and can be built entirely from the command line.

```text
Sources/Cling/
├── Monitor/   # Transcript monitoring and JSONL parsing
├── Engine/    # Achievement rules and persistence
├── Toast/     # Unlock notifications
├── UI/        # Menu bar interface and settings
├── Share/     # Achievement card rendering
└── Support/   # Sounds, icons, login item, and status
```

### Developer mode

Enable **Dev mode** in settings to:

- preview unlock notifications
- force-unlock achievements
- reset progress
- inject test activity
- test time-based and session-based rules

## Roadmap

- [ ] Claude Desktop support

## Contributing

Issues and pull requests are welcome.

New achievements are implemented as small rules inside `Sources/Cling/Engine`.

Please run the test suite before submitting a pull request:

```sh
swift test
```

## Credits

- Icons by [Lucide](https://lucide.dev)
- Interface inspired by [Numi](https://numi.app)
- Built for [Claude Code](https://claude.com/claude-code)

## License

[MIT](LICENSE) © Anton Mitrofanov

<div align="center">
<sub>Found Cling useful? Consider leaving a ⭐</sub>
</div>
