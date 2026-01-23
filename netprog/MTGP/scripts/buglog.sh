#!/usr/bin/env bash
set -euo pipefail

_resolve() {
  if command -v readlink >/dev/null 2>&1 && readlink -f / >/dev/null 2>&1; then readlink -f "$1"
  else python3 - "$1" <<'PY'
import os, sys; print(os.path.abspath(sys.argv[1]))
PY
  fi
}

SCRIPT_PATH="$(_resolve "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
README_PATH="$REPO_ROOT/README.md"
PROJECT_NAME="$(basename "$REPO_ROOT")"
DATE_NOW="$(date '+%Y-%m-%d %H:%M:%S')"

die(){ printf 'Error: %s\n' "$*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }

repeat_line(){ printf '%*s' "$1" '' | tr ' ' "$2"; }
stars(){ local w="$1"; local n=$((w/4)); local s=""; for((i=0;i<n;++i));do s+="*"$'\t';done; echo "${s%$'\t'}"|cut -c1-"$w"; }
banner(){
  local n="$1" b w d e
  if have figlet && figlet -f slant "$n" >/dev/null 2>&1; then b="$(figlet -f slant "$n")"
  elif have figlet; then b="$(figlet "$n")"
  else b="$n"; fi
  w="$(printf '%s\n' "$b" | awk 'NF{last=$0} END{print length(last)}')"; [ -z "$w" ] && w="${#n}"; [ "$w" -lt 1 ] && w=60
  d="$(repeat_line "$w" -)"; e="$(repeat_line "$w" =)"
  printf '%s\n%s\n' "$b" "$d"; stars "$w"; printf '%s\n' "$e"
}
ensure_readme(){
  local r="$1" p="$2"
  if [ ! -f "$r" ]; then
    umask 002
    { banner "$p"; printf '\n## Project\n\n**Name:** %s\n\n**Description:** _Add a brief description here._\n\n**Author:** _Your Name_\n\n**Created:** %s\n\n**Version:** 0.1.0\n\n---\n\n## Log\n\n_Entries appended by **scripts/buglog.sh**_\n\n' "$p" "$(date '+%Y-%m-%d')"; } > "$r" || die "create $r"
    chmod 664 "$r" 2>/dev/null || true
  else
    grep -qE '^##[[:space:]]+Log' "$r" || printf '\n---\n\n## Log\n\n_Entries appended by **scripts/buglog.sh**_\n\n' >> "$r"
  fi
}
append(){
  local r="$1" t="$2" h="$3" b="$4"; local T="$(echo "$t"|tr '[:lower:]' '[:upper:]')"
  { printf '### [%s] %s — %s\n\n%s\n\n---\n\n' "$DATE_NOW" "$T" "$h" "$b"; } >> "$r" || die "write $r"
}

valid(){ case "$1" in bug|fix|todo|note|goal) return 0;; *) return 1;; esac; }
TYPE="${1:-}"; TITLE="${2:-}"; BODY="${3:-}"

if [ -z "$TYPE" ] || [ -z "$TITLE" ]; then
  while :; do read -rp 'Entry type [bug|fix|todo|note|goal]: ' TYPE; TYPE="${TYPE,,}"; valid "$TYPE" && break; done
  read -rp 'Short title: ' TITLE
  echo 'Enter entry body (Ctrl-D to finish):'; BODY="$(cat || true)"
fi
[ -n "$BODY" ] || BODY="(no description provided)"

ensure_readme "$README_PATH" "$PROJECT_NAME"
append "$README_PATH" "$TYPE" "$TITLE" "$BODY"
echo "Appended $TYPE entry to $README_PATH"
