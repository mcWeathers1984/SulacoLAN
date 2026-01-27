#!/usr/bin/env bash
set -euo pipefail

# new_clang_project.sh (C project generator)
# Usage:
#   (a) ./new_clang_project.sh <project-name>
#   (b) ./new_clang_project.sh -i
#   (c) ./new_clang_project.sh <project-name> [cmake|make] [cli|ncurses]
#
# Creates:
# project_root/
#   bin/{debug,release}/
#   include/{project_name}.h
#   src/{project_name}.c main.c
#   README.md
#   Makefile OR CMakeLists.txt
#   BUGLOG.md
#   scripts/{develop.sh,buglog.sh,build.sh}

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
  cat >&2 <<'EOF'
Usage:
  new_clang_project.sh <project-name>
  new_clang_project.sh -i
  new_clang_project.sh <project-name> [cmake|make] [cli|ncurses]

Examples:
  ./new_clang_project.sh network-app
  ./new_clang_project.sh -i
  ./new_clang_project.sh network-app cmake ncurses
EOF
}

sanitize_name() {
  local in="$1"
  local out
  out="$(echo "$in" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_-]+/-/g; s/^-+//; s/-+$//; s/--+/-/g')"
  [[ -n "$out" ]] || die "Project name becomes empty after sanitizing."
  echo "$out"
}

to_ident() {
  local in="$1"
  local out
  out="$(echo "$in" | tr '-' '_' | sed -E 's/[^a-zA-Z0-9_]+/_/g')"
  if [[ ! "$out" =~ ^[A-Za-z_] ]]; then
    out="_${out}"
  fi
  echo "$out"
}

# IMPORTANT:
# - All menus/prompts go to STDERR so they are visible even when the function is used in $(...)
# - Only the final selected value is echoed to STDOUT
prompt_choice() {
  local title="$1"
  shift
  local options=("$@")
  local sel=""

  while :; do
    echo >&2
    echo "== $title ==" >&2
    local i=1
    for opt in "${options[@]}"; do
      echo "  $i) $opt" >&2
      ((i++))
    done
    echo >&2

    read -r -p "Select [1-${#options[@]}]: " sel >&2

    if [[ ! "$sel" =~ ^[0-9]+$ ]]; then
      echo "Invalid input: please enter a number." >&2
      continue
    fi

    if (( sel < 1 || sel > ${#options[@]} )); then
      echo "Invalid selection: out of range." >&2
      continue
    fi

    echo "Selected: ${options[$((sel-1))]}" >&2
    echo "${options[$((sel-1))]}"
    return 0
  done
}

interactive=0

while getopts ":ih" opt; do
  case "$opt" in
    i) interactive=1 ;;
    h) usage; exit 0 ;;
    \?) usage; die "Unknown option: -$OPTARG" ;;
  esac
done
shift $((OPTIND-1))

project_name=""
build_system=""
app_type=""

if [[ "$interactive" -eq 1 ]]; then
  echo >&2
  echo "==========================================" >&2
  echo "  Interactive C Project Creation Wizard" >&2
  echo "==========================================" >&2
  echo >&2

  read -r -p "Project name: " project_name >&2
  project_name="$(sanitize_name "$project_name")"

  build_system="$(prompt_choice "Build system" "make" "cmake")"
  app_type="$(prompt_choice "App type" "cli" "ncurses")"
else
  if [[ $# -lt 1 ]]; then
    usage
    die "Missing project name."
  fi

  project_name="$(sanitize_name "$1")"; shift

  build_system="${1:-make}"
  app_type="${2:-cli}"

  [[ "$build_system" == "make" || "$build_system" == "cmake" ]] || die "Build system must be 'make' or 'cmake'."
  [[ "$app_type" == "cli" || "$app_type" == "ncurses" ]] || die "App type must be 'cli' or 'ncurses'."
fi

proj_root="$project_name"
ident_base="$(to_ident "$project_name")"
guard="$(echo "${ident_base}_H" | tr '[:lower:]' '[:upper:]')"

[[ ! -e "$proj_root" ]] || die "Path already exists: $proj_root"

mkdir -p \
  "$proj_root/bin/debug" \
  "$proj_root/bin/release" \
  "$proj_root/include" \
  "$proj_root/src" \
  "$proj_root/scripts"

touch "$proj_root/BUGLOG.md"

cat > "$proj_root/README.md" <<EOF
# $project_name

Generated C project.

- Build system: **$build_system**
- App type: **$app_type**

## Quick start

\`\`\`bash
cd $project_name
./scripts/develop.sh
\`\`\`
EOF

cat > "$proj_root/include/${project_name}.h" <<EOF
#ifndef $guard
#define $guard

#ifdef __cplusplus
extern "C" {
#endif

int ${ident_base}_run(void);

#ifdef __cplusplus
}
#endif

#endif /* $guard */
EOF

cat > "$proj_root/src/${project_name}.c" <<EOF
#include "${project_name}.h"

int ${ident_base}_run(void) {
    // TODO: put your program logic here
    return 0;
}
EOF

if [[ "$app_type" == "ncurses" ]]; then
  cat > "$proj_root/src/main.c" <<EOF
#include <ncurses.h>
#include "${project_name}.h"

int main(void) {
    initscr();
    cbreak();
    noecho();
    keypad(stdscr, TRUE);

    mvprintw(1, 2, "$project_name (ncurses) - press any key to exit...");
    refresh();
    getch();

    endwin();
    return ${ident_base}_run();
}
EOF
else
  cat > "$proj_root/src/main.c" <<EOF
#include <stdio.h>
#include "${project_name}.h"

int main(void) {
    printf("$project_name (cli)\\n");
    return ${ident_base}_run();
}
EOF
fi

cat > "$proj_root/scripts/buglog.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log_file="BUGLOG.md"

echo "Enter buglog entry. Press CTRL+D when finished."
echo "---------------------------------------------"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

cat > "$tmp" || true

if [[ ! -s "$tmp" ]]; then
  echo "No entry recorded."
  exit 0
fi

ts="$(date '+%Y-%m-%d %H:%M:%S')"

{
  echo
  echo "## $ts"
  echo
  cat "$tmp"
  echo
} >> "$log_file"

echo "Saved to $log_file"
EOF
chmod +x "$proj_root/scripts/buglog.sh"

# --------------------------
# Build system files
# --------------------------
if [[ "$build_system" == "make" ]]; then
  ncurses_link=""
  if [[ "$app_type" == "ncurses" ]]; then
    ncurses_link="-lncurses"
  fi

  # IMPORTANT: Make recipes MUST begin with a literal TAB.
  # We generate the Makefile using \t escapes and printf '%b' to emit real tabs.
  makefile_template="$(cat <<'EOF'
# Makefile - __APP__
CC      ?= gcc
CSTD    ?= c11
WARN    ?= -Wall -Wextra -Wpedantic
INCDIR  := include
SRCDIR  := src

APP     := __APP__
SRC     := $(SRCDIR)/main.c $(SRCDIR)/__APP__.c
OBJDIRD := .obj/debug
OBJDIRR := .obj/release
BINDIRD := bin/debug
BINDIRR := bin/release

# Common
CPPFLAGS := -I$(INCDIR)
LDFLAGS  :=
LDLIBS   := __LDLIBS__

CFLAGS_DEBUG   := $(WARN) -std=$(CSTD) -O0 -g3 -DDEBUG
CFLAGS_RELEASE := $(WARN) -std=$(CSTD) -O2 -DNDEBUG

.PHONY: all debug release clean

all: debug

debug: $(BINDIRD)/$(APP)

release: $(BINDIRR)/$(APP)

$(BINDIRD)/$(APP): $(patsubst $(SRCDIR)/%.c,$(OBJDIRD)/%.o,$(SRC))
\t@mkdir -p $(BINDIRD)
\t$(CC) $^ -o $@ $(LDFLAGS) $(LDLIBS)

$(BINDIRR)/$(APP): $(patsubst $(SRCDIR)/%.c,$(OBJDIRR)/%.o,$(SRC))
\t@mkdir -p $(BINDIRR)
\t$(CC) $^ -o $@ $(LDFLAGS) $(LDLIBS)

$(OBJDIRD)/%.o: $(SRCDIR)/%.c
\t@mkdir -p $(OBJDIRD)
\t$(CC) $(CPPFLAGS) $(CFLAGS_DEBUG) -c $< -o $@

$(OBJDIRR)/%.o: $(SRCDIR)/%.c
\t@mkdir -p $(OBJDIRR)
\t$(CC) $(CPPFLAGS) $(CFLAGS_RELEASE) -c $< -o $@

clean:
\trm -rf .obj build bin/debug/$(APP) bin/release/$(APP)
EOF
)"

  # Substitute placeholders (safe, controlled)
  makefile_template="${makefile_template//__APP__/$project_name}"
  makefile_template="${makefile_template//__LDLIBS__/$ncurses_link}"

  # Emit Makefile with real tabs
  printf '%b' "$makefile_template" > "$proj_root/Makefile"

  cat > "$proj_root/scripts/build.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USG'
Usage:
  ./scripts/build.sh debug
  ./scripts/build.sh release
  ./scripts/build.sh clean
USG
}

cmd="${1:-}"
case "$cmd" in
  debug)   make debug ;;
  release) make release ;;
  clean)   make clean ;;
  *) usage; exit 1 ;;
esac
EOF

else
  cmake_ncurses=""
  if [[ "$app_type" == "ncurses" ]]; then
    cmake_ncurses=$'\nfind_package(Curses REQUIRED)\ninclude_directories(${CURSES_INCLUDE_DIR})\n'
  fi

  cat > "$proj_root/CMakeLists.txt" <<EOF
cmake_minimum_required(VERSION 3.16)
project($project_name C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

include_directories(\${CMAKE_SOURCE_DIR}/include)

add_executable($project_name
  src/main.c
  src/$project_name.c
)

$cmake_ncurses
EOF

  if [[ "$app_type" == "ncurses" ]]; then
    cat >> "$proj_root/CMakeLists.txt" <<'EOF'
target_link_libraries(${PROJECT_NAME} PRIVATE ${CURSES_LIBRARIES})
EOF
  fi

  cat > "$proj_root/scripts/build.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

proj="$project_name"

usage() {
  cat <<'USG'
Usage:
  ./scripts/build.sh debug
  ./scripts/build.sh release
  ./scripts/build.sh clean
USG
}

do_debug() {
  cmake -S . -B build/debug \
    -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY="\$PWD/bin/debug"
  cmake --build build/debug
}

do_release() {
  cmake -S . -B build/release \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY="\$PWD/bin/release"
  cmake --build build/release
}

do_clean() {
  rm -rf build
  rm -f "bin/debug/\$proj" "bin/release/\$proj"
}

cmd="\${1:-}"
case "\$cmd" in
  debug) do_debug ;;
  release) do_release ;;
  clean) do_clean ;;
  *) usage; exit 1 ;;
esac
EOF
fi

chmod +x "$proj_root/scripts/build.sh"

cat > "$proj_root/scripts/develop.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail

proj="$project_name"

pause() {
  read -r -p "Press ENTER to continue..." _ || true
}

run_exe() {
  local choice=""
  echo "Run which build?"
  echo "  1) debug   (bin/debug/\$proj)"
  echo "  2) release (bin/release/\$proj)"
  read -r -p "Select [1-2]: " choice

  case "\$choice" in
    1)
      [[ -x "bin/debug/\$proj" ]] || { echo "Not found/executable: bin/debug/\$proj"; return 1; }
      ./bin/debug/"\$proj"
      ;;
    2)
      [[ -x "bin/release/\$proj" ]] || { echo "Not found/executable: bin/release/\$proj"; return 1; }
      ./bin/release/"\$proj"
      ;;
    *)
      echo "Invalid selection."
      return 1
      ;;
  esac
}

while :; do
  echo
  echo "=== \$proj develop menu ==="
  echo "  1) build-debug"
  echo "  2) build-release"
  echo "  3) make clean"
  echo "  4) run executable"
  echo "  5) run buglog.sh"
  echo "  6) exit"
  echo

  read -r -p "Select [1-6]: " sel
  case "\$sel" in
    1) ./scripts/build.sh debug; pause ;;
    2) ./scripts/build.sh release; pause ;;
    3) ./scripts/build.sh clean; pause ;;
    4) run_exe; pause ;;
    5) ./scripts/buglog.sh; pause ;;
    6) exit 0 ;;
    *) echo "Invalid selection."; pause ;;
  esac
done
EOF

chmod +x "$proj_root/scripts/develop.sh"

echo
echo "Created project: $proj_root"
echo "  Build system: $build_system"
echo "  App type:     $app_type"
echo
echo "Next:"
echo "  cd $proj_root"
echo "  ./scripts/develop.sh"
echo

