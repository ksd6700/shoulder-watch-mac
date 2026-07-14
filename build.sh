#!/usr/bin/env bash
set -euo pipefail

APP_NAME="ShoulderWatch"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
MODULE_CACHE="$PWD/$BUILD_DIR/ModuleCache"

if [[ -d "/Applications/Xcode.app/Contents/Developer" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$APP_DIR/Contents/Resources" "$MODULE_CACHE"

export MACOSX_DEPLOYMENT_TARGET=12.0

SWIFTC="$(xcrun --find swiftc)"
SDKROOT="$(xcrun --show-sdk-path --sdk macosx)"

"$SWIFTC" -O \
  -sdk "$SDKROOT" \
  -module-cache-path "$MODULE_CACHE" \
  Sources/ShoulderWatch/*.swift \
  -o "$MACOS_DIR/$APP_NAME" \
  -framework AppKit \
  -framework AVFoundation \
  -framework CoreImage \
  -framework SwiftUI \
  -framework Vision

cp Info.plist "$APP_DIR/Contents/Info.plist"
if [[ -f "Resources/ShoulderWatch.icns" ]]; then
  cp "Resources/ShoulderWatch.icns" "$APP_DIR/Contents/Resources/ShoulderWatch.icns"
fi
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "$APP_DIR"
