# Security Policy

SleepEye is a local-first macOS utility. It does not require an account, backend, or cloud sync.

## Reporting

If you find a security issue, please open a GitHub issue with a minimal reproduction and avoid including private data.

## Current Scope

- Local settings are stored with `UserDefaults`.
- `swift run` development mode disables system notifications because it is not launched from a real `.app` bundle.
- Packaged `.app` builds may request local notification permission.
