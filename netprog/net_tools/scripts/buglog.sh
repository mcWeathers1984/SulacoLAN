#!/usr/bin/env bash
set -euo pipefail

# Append a note/bug/fix/todo entry to README.md using a simple markdown format.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
README="${PROJECT_ROOT}/README.md"

if [[ ! -f "$README" ]]; then
  echo "README.md not found in ${PROJECT_ROOT}, creating a new one."
  echo "# $(basename "$PROJECT_ROOT")" > "$README"
  echo "" >> "$README"
fi

read -rp "Entry type (note|bug|fix|todo): " TYPE
TYPE_LOWER="${TYPE,,}"
case "$TYPE_LOWER" in
  note|bug|fix|todo) ;;
  *)
    echo "Invalid type: $TYPE_LOWER"
    exit 1
    ;;
esac

read -rp "Short title: " TITLE

echo "Enter entry details. Press Ctrl+D when done."
{
  echo ""
  echo "### $(date +%Y-%m-%d) [$TYPE_LOWER] $TITLE"
  echo ""
  cat
} >> "$README"

echo "Entry appended to $README."
