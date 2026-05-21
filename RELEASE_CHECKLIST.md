# Release Checklist

SleepEye release builds are local-first macOS app bundles. The current public release path creates an unsigned zip, suitable for developer testing and early distribution. Signing and notarization remain the next release-hardening step.

## Before Tagging

- Update `VERSION`.
- Update `CHANGELOG.md`.
- Run tests:

```bash
env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache swift test --cache-path .build/swiftpm-cache
```

- Build the local release package:

```bash
./scripts/package-app.sh
```

- Confirm these files exist:
  - `dist/SleepEye.app`
  - `dist/SleepEye-<version>-macos.zip`
  - `dist/SleepEye-<version>-macos.sha256`

## Tag And Publish

```bash
VERSION="$(cat VERSION)"
git tag "v$VERSION"
git push origin "v$VERSION"
```

The GitHub Actions release workflow will run tests, build the app bundle, create the zip, and upload the zip plus SHA256 file to the GitHub Release.

## Manual Verification

- Open `dist/SleepEye.app`.
- Confirm the main app window opens and appears in Dock / Cmd-Tab.
- Confirm the menu bar item is present.
- Start a focus session from the main window.
- Confirm today stats update after a completed focus session.
- Confirm the recent 7-day chart shows the updated day.
- Start a break and confirm the full-screen rest countdown can be exited.

## Known Release Gaps

- Builds are not yet code signed.
- Builds are not yet notarized.
- The release zip may show macOS Gatekeeper warnings until signing and notarization are added.
