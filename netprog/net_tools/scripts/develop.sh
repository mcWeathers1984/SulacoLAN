#!/usr/bin/env bash
set -euo pipefail

# Simple helper to configure+build via CMake presets on WSL.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$PROJECT_ROOT"

read -rp "Build type [d=Debug, r=Release] (default d): " BT
BT="${BT:-d}"
BT="${BT,,}"

case "$BT" in
  d|debug) BUILD_TYPE="debug" ;;
  r|release) BUILD_TYPE="release" ;;
  *)
    echo "Invalid build type: $BT"
    exit 1
    ;;
esac

read -rp "Compiler [c=clang, g=gcc] (default c): " CC
CC="${CC:-c}"
CC="${CC,,}"

case "$CC" in
  c|clang) COMPILER="clang" ;;
  g|gcc)   COMPILER="gcc" ;;
  *)
    echo "Invalid compiler choice: $CC"
    exit 1
    ;;
esac

PRESET="wsl-${COMPILER}-${BUILD_TYPE}"
echo "Using preset: $PRESET"

cmake --preset "$PRESET"
cmake --build --preset "$PRESET"
