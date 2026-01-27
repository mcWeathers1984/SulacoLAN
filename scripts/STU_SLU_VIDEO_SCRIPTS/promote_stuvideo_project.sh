#!/usr/bin/env bash
set -euo pipefail

STU_ROOT="/mnt/STU_SLU_VIDEO"
P1="$STU_ROOT/01_PROJECTS"
P2="$STU_ROOT/02_UPLOAD_READY"
P3="$STU_ROOT/03_PUBLISHED"

if [[ $# -ne 2 ]]; then
  echo "Usage: $(basename "$0") <project_id> upload_ready|published"
  exit 1
fi

ID="$1"
STATE="$2"
YEAR="${ID:0:4}"
SRC=""

[[ -d "$P1/$YEAR/$ID" ]] && SRC="$P1/$YEAR/$ID"
[[ -d "$P2/$ID" ]] && SRC="$P2/$ID"

[[ -n "$SRC" ]] || { echo "Project not found: $ID"; exit 1; }

case "$STATE" in
  upload_ready) DEST="$P2/$ID" ;;
  published)    DEST="$P3/$ID" ;;
  *) echo "Invalid state: $STATE"; exit 1 ;;
esac

[[ ! -e "$DEST" ]] || { echo "Destination exists: $DEST"; exit 1; }

mv -v "$SRC" "$DEST"
echo "Moved → $DEST"
