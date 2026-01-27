#!/usr/bin/env bash
set -euo pipefail

STU_ROOT="/mnt/STU_SLU_VIDEO"
ARCHIVE="$STU_ROOT/04_ARCHIVE"

if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") /path/to/project_dir"
  exit 1
fi

PROJ="$1"
[[ -d "$PROJ" ]] || { echo "Not a directory: $PROJ"; exit 1; }
[[ -f "$PROJ/project.yaml" ]] || { echo "Missing project.yaml"; exit 1; }

ID="$(basename "$PROJ")"
YEAR="${ID:0:4}"

DEST="$ARCHIVE/$YEAR"
OUT="$DEST/$ID.tar.zst"

mkdir -p "$DEST"
[[ ! -e "$OUT" ]] || { echo "Archive exists: $OUT"; exit 1; }

(
  cd "$(dirname "$PROJ")"
  tar -I 'zstd -19' -cf "$OUT" "$ID"
)

sha256sum "$OUT" > "$OUT.sha256"

echo "Archived:"
echo "  $OUT"
