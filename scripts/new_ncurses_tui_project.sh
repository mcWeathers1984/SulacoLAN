#!/usr/bin/env bash
set -euo pipefail

usage() {
cat <<EOF
Usage:
  ./new_ncurses_project.sh -i | --interactive
  ./new_ncurses_project.sh <project_name> [parent_dir]
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

INTERACTIVE=0
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--interactive) INTERACTIVE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

if [[ "$INTERACTIVE" -eq 1 ]]; then
  read -rp "Project name: " PROJECT_NAME
  read -rp "Parent dir (blank = cwd): " PARENT_DIR
else
  PROJECT_NAME="${POSITIONAL[0]-}"
  PARENT_DIR="${POSITIONAL[1]-$(pwd)}"
fi

[[ -n "$PROJECT_NAME" ]] || die "Project name required"
PARENT_DIR="${PARENT_DIR/#\~/$HOME}"

ROOT="$PARENT_DIR/$PROJECT_NAME"
[[ -e "$ROOT" ]] && die "Directory exists"

mkdir -p "$ROOT"/{bin/{debug,release},src,include,.vscode}

# README
cat > "$ROOT/README.md" <<EOF
# $PROJECT_NAME

Minimal ncurses C++23 project.

## Build
make
make release
make run
make clean

## Buglog
EOF

# VS Code settings
cat > "$ROOT/.vscode/settings.json" <<EOF
{ "editor.formatOnSave": false }
EOF

# Header
cat > "$ROOT/include/mcw.hpp" <<EOF
#pragma once
#include <string>
inline std::string mcw_banner() { return "MCW ncurses project (C++23)"; }
EOF

# Main
cat > "$ROOT/src/main.cpp" <<EOF
#include <ncurses.h>
#include "mcw.hpp"

int main() {
    initscr();
    printw("%s\nPress any key...", mcw_banner().c_str());
    getch();
    endwin();
    return 0;
}
EOF

# Makefile
cat > "$ROOT/Makefile" <<EOF
CXX=g++
STD=-std=c++23
INC=-Iinclude
LIB=-lncurses

BIN_DEBUG=bin/debug/app
BIN_RELEASE=bin/release/app

all: \$(BIN_DEBUG)

\$(BIN_DEBUG): src/main.cpp
	\$(CXX) \$(STD) \$(INC) -g \$< -o \$@ \$(LIB)

release:
	\$(CXX) \$(STD) \$(INC) -O2 src/main.cpp -o \$(BIN_RELEASE) \$(LIB)

run: all
	./\$(BIN_DEBUG)

clean:
	rm -f bin/debug/* bin/release/*
EOF

# buglog.sh
cat > "$ROOT/buglog.sh" <<'EOF'
#!/usr/bin/env bash
read -rp "Type: " TYPE
read -rp "Entry: " ENTRY
echo "- [$(date)] [$TYPE] $ENTRY" >> README.md
EOF
chmod +x "$ROOT/buglog.sh"

# develop.sh
cat > "$ROOT/develop.sh" <<EOF
#!/usr/bin/env bash
select opt in "Build Debug" "Build Release" "Clean" "Run" "Buglog" "Quit"; do
case \$REPLY in
1) make ;;
2) make release ;;
3) make clean ;;
4) make run ;;
5) ./buglog.sh ;;
6) exit 0 ;;
esac
done
EOF
chmod +x "$ROOT/develop.sh"

echo "Project created: $ROOT"

