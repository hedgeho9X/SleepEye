# Changelog

## 0.1.1

- Added ad-hoc signing during release packaging to reduce macOS Gatekeeper "damaged app" failures for early unsigned builds.
- Added release troubleshooting notes for clearing quarantine on downloaded builds.

## 0.1.0

- Added a full macOS app window with timer controls, today stats, rhythm settings, and a recent 7-day stats chart.
- Added local daily history persistence for focus sessions, breaks, focus duration, and break duration.
- Added the camera-area reminder island and full-screen rest countdown.
- Added local release packaging with a versioned `.zip` and SHA256 checksum.
- Added GitHub Actions release automation for `v*` tags.
