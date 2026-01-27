cat > ~/heic_to_jpg.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Convert HEIC/HEIF -> JPG (high quality), preserving folder structure.
# Safe default: writes to an output tree; does NOT delete or overwrite originals.

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") <input_dir> [output_dir] [quality]

Examples:
  $(basename "$0") /mnt/e/iPhoneDump
  $(basename "$0") /mnt/e/iPhoneDump /mnt/e/iPhoneDump_CONVERTED_JPG 95

Notes:
  - Keeps originals untouched
  - Preserves directory structure under output_dir
  - Writes a conversion log to output_dir/_logs/
USAGE
}

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage; exit 1
fi

IN_DIR="$1"
OUT_DIR="${2:-${IN_DIR%/}_CONVERTED_JPG}"
QUALITY="${3:-95}"

[[ -d "$IN_DIR" ]] || { echo "Error: input_dir not found: $IN_DIR" >&2; exit 1; }
[[ "$QUALITY" =~ ^[0-9]{1,3}$ ]] || { echo "Error: quality must be 0-100" >&2; exit 1; }
(( QUALITY >= 1 && QUALITY <= 100 )) || { echo "Error: quality must be 1-100" >&2; exit 1; }

command -v magick >/dev/null || { echo "Error: ImageMagick (magick) not installed." >&2; exit 1; }

mkdir -p "$OUT_DIR/_logs"
LOG="$OUT_DIR/_logs/heic_to_jpg_$(date +%Y%m%d-%H%M%S).log"

echo "Input : $IN_DIR" | tee -a "$LOG"
echo "Output: $OUT_DIR" | tee -a "$LOG"
echo "Quality: $QUALITY" | tee -a "$LOG"
echo "----" | tee -a "$LOG"

# Count source files
SRC_COUNT="$(find "$IN_DIR" -type f \( -iname '*.heic' -o -iname '*.heif' \) | wc -l | tr -d ' ')"
echo "Found HEIC/HEIF: $SRC_COUNT" | tee -a "$LOG"

if [[ "$SRC_COUNT" -eq 0 ]]; then
  echo "Nothing to do." | tee -a "$LOG"
  exit 0
fi

# Convert
FAILS=0
CONVERTED=0

# Preserve structure: compute relative path from IN_DIR, mirror it into OUT_DIR
while IFS= read -r -d '' src; do
  rel="${src#"$IN_DIR"/}"
  rel_noext="${rel%.*}"
  dest_dir="$OUT_DIR/$(dirname "$rel_noext")"
  dest="$OUT_DIR/${rel_noext}.jpg"

  mkdir -p "$dest_dir"

  if [[ -e "$dest" ]]; then
    echo "SKIP (exists): $dest" | tee -a "$LOG"
    continue
  fi

  if magick "$src" -quality "$QUALITY" "$dest" >>"$LOG" 2>&1; then
    ((CONVERTED++))
    echo "OK: $rel -> ${rel_noext}.jpg" | tee -a "$LOG"
  else
    ((FAILS++))
    echo "FAIL: $rel" | tee -a "$LOG"
  fi
done < <(find "$IN_DIR" -type f \( -iname '*.heic' -o -iname '*.heif' \) -print0)

echo "----" | tee -a "$LOG"
echo "Converted: $CONVERTED" | tee -a "$LOG"
echo "Failed   : $FAILS" | tee -a "$LOG"

# Basic sanity count
OUT_COUNT="$(find "$OUT_DIR" -type f -iname '*.jpg' | wc -l | tr -d ' ')"
echo "Total JPG in output tree: $OUT_COUNT" | tee -a "$LOG"

if [[ "$FAILS" -gt 0 ]]; then
  echo "Completed with failures. See log: $LOG" | tee -a "$LOG"
  exit 2
fi

echo "Completed successfully. Log: $LOG" | tee -a "$LOG"
EOF

chmod +x ~/heic_to_jpg.sh

