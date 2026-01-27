#!/usr/bin/env bash
set -euo pipefail

STU_ROOT="${STU_ROOT:-/mnt/STU_SLU_VIDEO}"
TEMPLATE_DIR="$STU_ROOT/95_TEMPLATES/default_project"
PROJECTS_ROOT="$STU_ROOT/01_PROJECTS"

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") --title "Video title" [--date YYYY-MM-DD] [--source Ripley|Hicks|Other] [--series STU]

Examples:
  $(basename "$0") --title "SulacoLAN Reset: Reinstall + Network Bring-up" --source Ripley
  $(basename "$0") --title "Hicks Demo: DHCP/DNS" --date 2026-01-22 --source Hicks

Creates:
  $PROJECTS_ROOT/<YEAR>/<YYYY-MM-DD>_<slug>/

Copies template files:
  $TEMPLATE_DIR/project.yaml
  $TEMPLATE_DIR/notes.md
USAGE
}

# Defaults
TITLE=""
DATE_REC="$(date +%F)"
SOURCE="Ripley"
SERIES="STU"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      TITLE="${2:-}"; shift 2;;
    --date)
      DATE_REC="${2:-}"; shift 2;;
    --source)
      SOURCE="${2:-}"; shift 2;;
    --series)
      SERIES="${2:-}"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Error: unknown argument: $1" >&2
      usage; exit 1;;
  esac
done

if [[ -z "$TITLE" ]]; then
  echo "Error: --title is required." >&2
  usage
  exit 1
fi

# Validate date format (basic)
if ! [[ "$DATE_REC" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Error: --date must be YYYY-MM-DD (got: $DATE_REC)" >&2
  exit 1
fi

# Validate source
case "$SOURCE" in
  Ripley|Hicks|Other) : ;;
  *)
    echo "Error: --source must be Ripley, Hicks, or Other (got: $SOURCE)" >&2
    exit 1;;
esac

# Ensure template exists
if [[ ! -f "$TEMPLATE_DIR/project.yaml" || ! -f "$TEMPLATE_DIR/notes.md" ]]; then
  echo "Error: template files not found in: $TEMPLATE_DIR" >&2
  echo "Expected: project.yaml and notes.md" >&2
  exit 1
fi

# Slugify title (lowercase; non-alnum -> underscore; collapse repeats)
slugify() {
  local s="$1"
  s="$(echo "$s" | tr '[:upper:]' '[:lower:]')"
  s="$(echo "$s" | sed -E 's/[^a-z0-9]+/_/g; s/^_+|_+$//g; s/__+/_/g')"
  echo "$s"
}

SLUG="$(slugify "$TITLE")"
ID="${DATE_REC}_${SLUG}"
YEAR="${DATE_REC:0:4}"

DEST_DIR="$PROJECTS_ROOT/$YEAR/$ID"

if [[ -e "$DEST_DIR" ]]; then
  echo "Error: project already exists: $DEST_DIR" >&2
  exit 1
fi

mkdir -p "$PROJECTS_ROOT/$YEAR"
mkdir -p "$DEST_DIR"/{raw,audio,video,assets,scripts,exports,thumbs}

# Copy templates
cp -a "$TEMPLATE_DIR/project.yaml" "$DEST_DIR/project.yaml"
cp -a "$TEMPLATE_DIR/notes.md" "$DEST_DIR/notes.md"

# Populate YAML (simple substitutions)
escape_quotes() { printf '%s' "$1" | sed 's/"/\\"/g'; }
TITLE_ESC="$(escape_quotes "$TITLE")"

sed -i \
  -e "s/^id: \".*\"/id: \"$ID\"/" \
  -e "s/^title: \".*\"/title: \"$TITLE_ESC\"/" \
  -e "s/^series: \".*\"/series: \"$SERIES\"/" \
  -e "s/^date_recorded: \".*\"/date_recorded: \"$DATE_REC\"/" \
  -e "s/^capture_source: \".*\"/capture_source: \"$SOURCE\"/" \
  "$DEST_DIR/project.yaml"

echo "Created project:"
echo "  $DEST_DIR"
echo
echo "Next:"
echo "  Drop recordings in: $DEST_DIR/raw"
echo "  Put code/scripts in: $DEST_DIR/scripts"
echo "  Final renders go in: $DEST_DIR/exports"
echo
echo "Tip:"
echo "  cd \"$DEST_DIR\""
