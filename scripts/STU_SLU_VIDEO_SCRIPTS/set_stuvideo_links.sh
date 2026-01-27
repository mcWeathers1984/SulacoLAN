#!/usr/bin/env bash
set -euo pipefail

STU_ROOT="/mnt/STU_SLU_VIDEO"
P1="$STU_ROOT/01_PROJECTS"
P2="$STU_ROOT/02_UPLOAD_READY"
P3="$STU_ROOT/03_PUBLISHED"

ID="$1"; shift || true
YEAR="${ID:0:4}"
YAML=""

[[ -f "$P1/$YEAR/$ID/project.yaml" ]] && YAML="$P1/$YEAR/$ID/project.yaml"
[[ -f "$P2/$ID/project.yaml" ]] && YAML="$P2/$ID/project.yaml"
[[ -f "$P3/$ID/project.yaml" ]] && YAML="$P3/$ID/project.yaml"

[[ -n "$YAML" ]] || { echo "project.yaml not found for $ID"; exit 1; }

escape() { sed 's/"/\\"/g' <<<"$1"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --youtube)   sed -i "s|^  youtube:.*|  youtube: \"$(escape "$2")\"|" "$YAML"; shift 2;;
    --peertube)  sed -i "s|^  peertube:.*|  peertube: \"$(escape "$2")\"|" "$YAML"; shift 2;;
    --github)    sed -i "s|^  github_repo:.*|  github_repo: \"$(escape "$2")\"|" "$YAML"; shift 2;;
    --status)    sed -i "s|^status:.*|status: \"$2\"|" "$YAML"; shift 2;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

echo "Updated $YAML"
