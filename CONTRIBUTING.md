# Contributing to SleepEye

Thanks for taking the time to improve SleepEye.

## Development

Run the app from source:

```bash
env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache swift run --cache-path .build/swiftpm-cache SleepEye
```

Run tests:

```bash
env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache swift test --cache-path .build/swiftpm-cache
```

## Code Style

- Keep timer logic independent from SwiftUI and AppKit.
- Keep AppKit window behavior inside small controller types.
- Prefer clear Swift names over abbreviations.
- Avoid large dependencies unless they remove real product complexity.
- Add Chinese comments for non-obvious macOS behavior, timing accuracy, and user-experience tradeoffs.

## Product Principles

- Full-screen rest is the main break experience.
- The app should never feel like a trap; always keep an exit.
- Local-first behavior is preferred.
- UI changes should make repeated daily use calmer, faster, or clearer.
