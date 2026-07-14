#!/usr/bin/env bash
set -euo pipefail

APP_NAME="ShoulderWatch"
VERSION="0.1.0"
DIST_DIR="dist"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION-mac-arm64.zip"

./build.sh

mkdir -p "$DIST_DIR"
ditto -c -k --sequesterRsrc --keepParent "build/$APP_NAME.app" "$ZIP_PATH"

echo "$ZIP_PATH"
