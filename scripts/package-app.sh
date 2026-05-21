#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="SleepEye"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
BUILD_NUMBER="${BUILD_NUMBER:-$(git -C "$ROOT_DIR" rev-list --count HEAD 2>/dev/null || echo 1)}"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
ZIP_PATH="$ROOT_DIR/dist/$APP_NAME-$VERSION-macos.zip"
CHECKSUM_PATH="$ROOT_DIR/dist/$APP_NAME-$VERSION-macos.sha256"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"

# SwiftPM 在部分 macOS 环境会尝试写用户级 clang module cache；项目内缓存让打包命令更稳定。
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$ROOT_DIR/.build/clang-module-cache}"

swift build \
  -c release \
  --product "$APP_NAME" \
  --cache-path "$ROOT_DIR/.build/swiftpm-cache"

BIN_DIR="$(swift build -c release --show-bin-path --cache-path "$ROOT_DIR/.build/swiftpm-cache")"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp "$ROOT_DIR/packaging/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/packaging/SleepEye.icns" "$RESOURCES_DIR/SleepEye.icns"
chmod +x "$MACOS_DIR/$APP_NAME"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$CONTENTS_DIR/Info.plist"

rm -f "$ZIP_PATH" "$CHECKSUM_PATH"
(
  cd "$ROOT_DIR/dist"
  ditto -c -k --keepParent "$APP_NAME.app" "$(basename "$ZIP_PATH")"
  shasum -a 256 "$(basename "$ZIP_PATH")" > "$(basename "$CHECKSUM_PATH")"
)

echo "Built $APP_DIR"
echo "Created $ZIP_PATH"
echo "Created $CHECKSUM_PATH"
