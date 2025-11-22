#!/usr/bin/env bash
set -euo pipefail

# fixperms.sh
# Set proper owner/group (mikew:developers) and fix permissions.
# Supports command-line mode or interactive prompts.

# ---- Require sudo ----
if [[ "$EUID" -ne 0 ]]; then
  echo "Error: please run this script with sudo."
  exit 1
fi

# ---- Defaults ----
OWNER="mikew"
GROUP="developers"

# ---- Validate permission string ----
validate_perms() {
  local p="$1"
  [[ "$p" =~ ^[0-7]{3}$ || "$p" =~ ^[0-7]{4}$ ]]
}

# ---- Parse mode: CLI or interactive ----

if [[ $# -ge 1 ]]; then
  TARGET="$1"
  if [[ ! -e "$TARGET" ]]; then
    echo "Error: path does not exist: $TARGET"
    exit 1
  fi

  if [[ $# -ge 2 ]]; then
    PERMS="$2"
    if ! validate_perms "$PERMS"; then
      echo "Error: invalid permissions: $PERMS"
      echo "Use 3 or 4 octal digits (e.g. 755, 0755, 2775)"
      exit 1
    fi
  else
    read -rp "Enter permissions (3 or 4 digits): " PERMS
    if ! validate_perms "$PERMS"; then
      echo "Invalid permissions."
      exit 1
    fi
  fi

else
  # Interactive
  read -rp "Enter file/directory path: " TARGET
  if [[ -z "$TARGET" || ! -e "$TARGET" ]]; then
    echo "Error: invalid path."
    exit 1
  fi

  read -rp "Enter permissions (3 or 4 digits): " PERMS
  if ! validate_perms "$PERMS"; then
    echo "Invalid permissions."
    exit 1
  fi
fi

# ---- Perform changes ----
chown "$OWNER:$GROUP" "$TARGET"
chmod "$PERMS" "$TARGET"

echo "-----------------------------------------"
echo "Updated: $TARGET"
echo "Owner/Group: $OWNER:$GROUP"
echo "Permissions: $PERMS"
echo "-----------------------------------------"
echo "Done."
 
