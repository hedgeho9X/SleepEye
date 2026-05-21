<p align="center">
  <img src="docs/assets/sleepeye-banner.png" alt="SleepEye banner" width="100%" />
</p>

# SleepEye

[![CI](https://github.com/hedgeho9X/SleepEye/actions/workflows/ci.yml/badge.svg)](https://github.com/hedgeho9X/SleepEye/actions/workflows/ci.yml)

SleepEye is a calm macOS break timer for people who stare at screens for too long.

It has a full app window for timer controls and local stats, stays available in the menu bar, then opens a soft white-green full-screen rest countdown when it is time to look away. The product is intentionally local, lightweight, and respectful: no account, no cloud sync, no forced lock-in.

## Features

- Full macOS app window with timer controls, settings summary, and stats.
- Menu bar timer for focus and eye-care breaks.
- Built-in rhythms: 25 / 5, 50 / 10, and 20-20-20.
- Custom work and break durations.
- Full-screen rest countdown that opens automatically by default.
- Gentle top reminder strip as a fallback.
- Pause, resume, skip, extend, and stop controls.
- Today stats and recent 7-day local history.
- Local settings with `UserDefaults`.
- Core timer logic isolated from SwiftUI/AppKit for testability.

## Run From Source

Requirements:

- macOS
- Xcode command line tools
- Swift 5.9 or newer

```bash
cd /Users/jerry/Code/project/SleepEye
env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache swift run --cache-path .build/swiftpm-cache SleepEye
```

After launch, SleepEye opens a main window and also appears in the macOS menu bar.

## Build a Local App Bundle

```bash
./scripts/package-app.sh
open dist/SleepEye.app
```

The script creates:

- `dist/SleepEye.app`
- `dist/SleepEye-<version>-macos.zip`
- `dist/SleepEye-<version>-macos.sha256`

The generated app is unsigned and intended for local development / early release testing. Public release builds still need signing and notarization.

The bundle includes `packaging/SleepEye.icns` as the local app icon.

## Release

Version is stored in [`VERSION`](VERSION). For a local release package:

```bash
./scripts/package-app.sh
(cd dist && shasum -a 256 -c SleepEye-$(cat ../VERSION)-macos.sha256)
```

For GitHub Release publishing, see [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md). Pushing a `v*` tag triggers the release workflow and uploads the zip plus checksum.

## Test

```bash
env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache swift test --cache-path .build/swiftpm-cache
```

## CI

The GitHub Actions workflow runs Swift tests, verifies the local app bundle build on `macos-latest`, and uploads a local build artifact for each main branch run.

## Design Principles

- Rest should be easy to accept, not annoying.
- Full-screen rest is the main experience; the top strip is only a gentle fallback.
- Users must always have an exit: Enter ends the break, Esc returns to the reminder strip.
- Timer accuracy uses target end times instead of naive per-second decrementing.
- AppKit details stay inside small controllers; SwiftUI views stay presentation-focused.

## Roadmap

- Add code signing and notarization.
- Add a first-run onboarding screen.
- Add richer history filters beyond the recent 7-day view.
- Re-enable system notifications for packaged `.app` builds.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
