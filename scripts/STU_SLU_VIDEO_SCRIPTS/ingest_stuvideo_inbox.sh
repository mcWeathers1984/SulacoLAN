#!/usr/bin/env bash
set -euo pipefail

STU_ROOT="/mnt/STU_SLU_VIDEO"
INBOX="$STU_ROOT/00_INBOX"
P1="$STU_ROOT/01_PROJECTS"
P2="$STU_ROOT/02_UPLOAD_READY"
P3="$STU_ROOT/03_PUBLISHED"

if [[ $# -ne 1 ]]; then
  echo "Usage: $(basename "$0") <project_id>"
  exit 1
fi

ID="$1"
YEAR="${ID:0:4}"
PROJ=""

[[ -d "$P1/$YEAR/$ID" ]] && PROJ="$P1/$YEAR/$ID"
[[ -d "$P2/$ID" ]] && PROJ="$P2/$ID"
[[ -d "$P3/$ID" ]] && PROJ="$P3/$ID"

[[ -n "$PROJ" ]] || { echo "Project not found: $ID"; exit 1; }

RAW="$PROJ/raw"
mkdir -p "$RAW"

shopt -s nullglob
FILES=("$INBOX"/*)
shopt -u nullglob

[[ ${#FILES[@]} -gt 0 ]] || { echo "INBOX empty."; exit 0; }

for f in "${FILES[@]}"; do
  ts="$(date +%Y%m%d-%H%M%S)"
  mv -v "$f" "$RAW/${ts}_$(basename "$f")"
  sleep 1
done

echo "Ingest complete → $RAW"
