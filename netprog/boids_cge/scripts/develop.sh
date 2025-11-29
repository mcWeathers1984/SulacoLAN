#!/usr/bin/env bash
set -euo pipefail

select_opt() { local PS3="$1"; shift; select o in "$@"; do [ -n "${o:-}" ] && echo "$o" && return; done; }

COMPILER=$(select_opt "Choose compiler: " g++ clang++ msvc)
CONFIG=$(select_opt "Choose build type: " Debug Release)

case "$COMPILER" in
  g++)     PRESET="linux-gcc" ;;
  clang++) PRESET="linux-clang" ;;
  msvc)    PRESET="msvc" ;;
esac

echo "[*] Configuring with preset: $PRESET"
cmake --preset "$PRESET"

echo "[*] Building $CONFIG"
if [[ "$PRESET" == "msvc" ]]; then
  cmake --build --preset "msvc-${CONFIG,,}"
else
  cmake --build --preset "${PRESET}-${CONFIG,,}" --parallel
fi

echo "[*] Done. Build dir: build/${PRESET}-${CONFIG,,}"
