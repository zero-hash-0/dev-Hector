#!/usr/bin/env bash
# Build LadyBird browser
set -euo pipefail

BUILD_DIR="build"
BUILD_TYPE="${1:-Release}"

echo "==> Configuring ($BUILD_TYPE)"
cmake -B "$BUILD_DIR" \
      -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
      .

echo "==> Building"
cmake --build "$BUILD_DIR" --parallel "$(nproc 2>/dev/null || sysctl -n hw.ncpu)"

echo "==> Done  →  $BUILD_DIR/ladybird"
echo ""
echo "Usage:  ./$BUILD_DIR/ladybird https://example.com"
