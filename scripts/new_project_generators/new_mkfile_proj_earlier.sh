#!/usr/bin/env bash
set -euo pipefail

# Hicks-native "new project generator" (Makefile-based)
#
# Usage:
#   ./newproj.sh <project_name> <c|cpp>            # defaults for std/deps, no prompts
#   ./newproj.sh <project_name> <c|cpp> <deps>     # deps: none|math|ncurses|math+ncurses
#   ./newproj.sh                                   # interactive mode
#
# Defaults:
#   C   -> c18
#   C++ -> c++20
#   deps -> none

die() { printf "ERROR: %s\n" "$*" >&2; exit 1; }

is_valid_name() {
  # must start with letter, contain only lowercase letters, digits, underscore
  [[ "${1:-}" =~ ^[a-z][a-z0-9_]*$ ]]
}

prompt() {
  local varname="$1" msg="$2" def="${3:-}"
  local input=""
  if [[ -n "$def" ]]; then
    read -r -p "$msg [$def]: " input
    input="${input:-$def}"
  else
    read -r -p "$msg: " input
  fi
  printf -v "$varname" "%s" "$input"
}

choose() {
  # choose VAR "Message" "default" "opt1 opt2 opt3"
  local varname="$1" msg="$2" def="$3" opts="$4"
  local input=""
  while true; do
    read -r -p "$msg ($opts) [$def]: " input
    input="${input:-$def}"
    for o in $opts; do
      if [[ "$input" == "$o" ]]; then
        printf -v "$varname" "%s" "$input"
        return 0
      fi
    done
    printf "Invalid choice. Pick one of: %s\n" "$opts" >&2
  done
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

detect_compiler() {
  # Prefer clang if available, else gcc/g++
  local lang="$1"
  if [[ "$lang" == "c" ]]; then
    if have_cmd clang; then echo "clang"; return; fi
    if have_cmd gcc; then echo "gcc"; return; fi
    die "No C compiler found (need clang or gcc)."
  else
    if have_cmd clang++; then echo "clang++"; return; fi
    if have_cmd g++; then echo "g++"; return; fi
    die "No C++ compiler found (need clang++ or g++)."
  fi
}

validate_deps() {
  local deps="${1:-}"
  case "$deps" in
    none|math|ncurses|math+ncurses) return 0 ;;
    *) return 1 ;;
  esac
}

deps_to_libs() {
  local deps="$1"
  case "$deps" in
    none) echo "" ;;
    math) echo "-lm" ;;
    ncurses) echo "-lncurses" ;;
    math+ncurses) echo "-lm -lncurses" ;;
    *) die "Internal: unknown deps '$deps'" ;;
  esac
}

make_main_templates() {
  local lang="$1" proj="$2" deps="$3"
  local ext_c ext_h mainfile hdrfile

  if [[ "$lang" == "c" ]]; then
    ext_c="c"; ext_h="h"
  else
    ext_c="cpp"; ext_h="hpp"
  fi

  mainfile="src/${proj}.${ext_c}"
  hdrfile="include/${proj}.${ext_h}"

  # Header
  if [[ "$lang" == "c" ]]; then
    cat > "$hdrfile" <<EOF
#ifndef ${proj}_H
#define ${proj}_H

/* ${proj}: project header */

int ${proj}_hello(void);

#endif /* ${proj}_H */
EOF
  else
    cat > "$hdrfile" <<EOF
#pragma once

// ${proj}: project header

int ${proj}_hello();
EOF
  fi

  # Dependency includes
  local uses_math=0 uses_ncurses=0
  case "$deps" in
    none) uses_math=0; uses_ncurses=0 ;;
    math) uses_math=1; uses_ncurses=0 ;;
    ncurses) uses_math=0; uses_ncurses=1 ;;
    math+ncurses) uses_math=1; uses_ncurses=1 ;;
    *) die "Internal: unknown deps '$deps'" ;;
  esac

  # Source
  if [[ "$lang" == "c" ]]; then
    {
      echo '#include <stdio.h>'
      echo "#include \"${proj}.h\""
      (( uses_math )) && echo '#include <math.h>'
      (( uses_ncurses )) && echo '#include <ncurses.h>'
      echo
      echo "int ${proj}_hello(void) {"
      echo "    puts(\"Hello from ${proj}!\");"
      echo "    return 0;"
      echo "}"
      echo
      echo "int main(void) {"
      echo "    ${proj}_hello();"
      if (( uses_math )); then
        echo "    double x = 2.0;"
        echo "    printf(\"sqrt(%.1f) = %.6f\\n\", x, sqrt(x));"
      fi
      if (( uses_ncurses )); then
        echo "    initscr();"
        echo "    printw(\"ncurses says: Hello from the terminal cave.\\n\");"
        echo "    printw(\"Press any key to exit...\");"
        echo "    refresh();"
        echo "    getch();"
        echo "    endwin();"
      fi
      echo "    return 0;"
      echo "}"
    } > "$mainfile"
  else
    {
      echo '#include <iostream>'
      echo "#include \"${proj}.hpp\""
      (( uses_math )) && echo '#include <cmath>'
      (( uses_ncurses )) && echo '#include <ncurses.h>'
      echo
      echo "int ${proj}_hello() {"
      echo "    std::cout << \"Hello from ${proj}!\" << std::endl;"
      echo "    return 0;"
      echo "}"
      echo
      echo "int main() {"
      echo "    ${proj}_hello();"
      if (( uses_math )); then
        echo "    double x = 2.0;"
        echo "    std::cout << \"sqrt(\" << x << \") = \" << std::sqrt(x) << std::endl;"
      fi
      if (( uses_ncurses )); then
        echo "    initscr();"
        echo "    printw(\"ncurses says: Hello from the terminal cave.\\n\");"
        echo "    printw(\"Press any key to exit...\");"
        echo "    refresh();"
        echo "    getch();"
        echo "    endwin();"
      fi
      echo "    return 0;"
      echo "}"
    } > "$mainfile"
  fi
}

write_makefile() {
  local proj="$1" lang="$2" std="$3" deps="$4" cc="$5"
  local ext src libs
  if [[ "$lang" == "c" ]]; then ext="c"; else ext="cpp"; fi
  src="src/${proj}.${ext}"
  libs="$(deps_to_libs "$deps")"

  # IMPORTANT: Make recipe lines MUST begin with a literal TAB.
  # We generate them using printf '\t...' to guarantee tabs.
  {
    printf "# Auto-generated Makefile for %s\n\n" "$proj"
    printf "PROJECT := %s\n" "$proj"
    printf "LANG    := %s\n" "$lang"
    printf "STD     := %s\n" "$std"
    printf "CC      := %s\n\n" "$cc"

    printf "SRC     := %s\n" "$src"
    printf "INC_DIR := include\n\n"

    printf "DBG_DIR := bin/debug\n"
    printf "REL_DIR := bin/release\n\n"

    printf "DBG_BIN := \$(DBG_DIR)/\$(PROJECT)\n"
    printf "REL_BIN := \$(REL_DIR)/\$(PROJECT)\n\n"

    printf "CFLAGS_COMMON   := -I\$(INC_DIR) -Wall -Wextra -Wpedantic\n"
    printf "CFLAGS_DEBUG    := -O0 -g3 -DDEBUG\n"
    printf "CFLAGS_RELEASE  := -O2 -DNDEBUG\n\n"

    printf "LDFLAGS_COMMON  :=\n"
    printf "LDLIBS          := %s\n\n" "$libs"

    printf "STD_FLAG := -std=\$(STD)\n\n"

    printf ".PHONY: all debug release clean run-debug run-release dirs\n\n"
    printf "all: debug\n\n"

    printf "dirs:\n"
    printf "\t@mkdir -p \$(DBG_DIR) \$(REL_DIR)\n\n"

    printf "debug: dirs\n"
    printf "\t\$(CC) \$(STD_FLAG) \$(CFLAGS_COMMON) \$(CFLAGS_DEBUG) \$(LDFLAGS_COMMON) -o \$(DBG_BIN) \$(SRC) \$(LDLIBS)\n\n"

    printf "release: dirs\n"
    printf "\t\$(CC) \$(STD_FLAG) \$(CFLAGS_COMMON) \$(CFLAGS_RELEASE) \$(LDFLAGS_COMMON) -o \$(REL_BIN) \$(SRC) \$(LDLIBS)\n\n"

    printf "run-debug: debug\n"
    printf "\t./\$(DBG_BIN)\n\n"

    printf "run-release: release\n"
    printf "\t./\$(REL_BIN)\n\n"

    printf "clean:\n"
    printf "\trm -rf bin\n"
  } > Makefile
}

write_develop_sh() {
  cat > develop.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
develop.sh commands:
  build-debug     Build debug executable
  build-release   Build release executable
  run-debug       Build+run debug executable
  run-release     Build+run release executable
  clean           Remove build outputs
  note            Append a timestamped note to README.md
USAGE
}

cmd="${1:-}"
shift || true

case "$cmd" in
  build-debug)   make debug ;;
  build-release) make release ;;
  run-debug)     make run-debug ;;
  run-release)   make run-release ;;
  clean)         make clean ;;
  note)
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    printf "\n## Note (%s)\n\n%s\n" "$ts" "${*:-<no text provided>}" >> README.md
    echo "Appended note to README.md"
    ;;
  ""|-h|--help|help) usage ;;
  *) echo "Unknown command: $cmd" >&2; usage; exit 2 ;;
esac
EOF
  chmod +x develop.sh
}

write_readme() {
  local proj="$1" lang="$2" std="$3" deps="$4"
  cat > README.md <<EOF
# ${proj}

- Language: ${lang}
- Standard: ${std}
- Deps: ${deps}

## Build

\`\`\`bash
./develop.sh build-debug
./develop.sh build-release
\`\`\`

## Run

\`\`\`bash
./develop.sh run-debug
./develop.sh run-release
\`\`\`

## Notes
EOF
}

sanity_check_makefile_tabs() {
  # Fail fast if any recipe lines under known targets start with spaces instead of a tab.
  # We search for lines that look like 2+ spaces then a command, which is suspicious.
  if grep -nE '^(  +)[^#[:space:]]' Makefile >/dev/null 2>&1; then
    echo "WARNING: Makefile contains lines starting with spaces that may be recipes."
    echo "Run: sed -n '1,120p' Makefile | cat -A"
  fi
}

main() {
  local proj="${1:-}"
  local lang_in="${2:-}"
  local deps_in="${3:-}"

  local interactive=0
  [[ -z "$proj" || -z "$lang_in" ]] && interactive=1

  if (( interactive )); then
    # Full interactive
    while true; do
      prompt proj "Project name (lowercase, starts with letter, [a-z0-9_])"
      is_valid_name "$proj" && break
      echo "Invalid. Use only lowercase letters/digits/underscore and start with a letter."
    done

    choose lang_in "Language" "c" "c cpp"
    if [[ "$lang_in" == "c" ]]; then
      choose std "C standard" "c18" "c99 c18"
    else
      choose std "C++ standard" "c++20" "c++11 c++20 c++23"
    fi

    choose deps "Dependencies" "none" "none math ncurses math+ncurses"
  else
    # CLI defaults (minimal knobs)
    is_valid_name "$proj" || die "Invalid project name '$proj'. Use: ^[a-z][a-z0-9_]*$"

    case "$lang_in" in
      c|C)   lang_in="c" ;;
      cpp|c++|CPP|C++) lang_in="cpp" ;;
      *) die "Language must be 'c' or 'cpp'." ;;
    esac

    if [[ "$lang_in" == "c" ]]; then
      std="c18"
    else
      std="c++20"
    fi

    if [[ -n "$deps_in" ]]; then
      validate_deps "$deps_in" || die "Deps must be one of: none|math|ncurses|math+ncurses"
      deps="$deps_in"
    else
      deps="none"
    fi
  fi

  # Normalize lang
  local lang=""
  case "$lang_in" in
    c) lang="c" ;;
    cpp) lang="cpp" ;;
    *) die "Internal: lang normalization failed." ;;
  esac

  # Create root directory in current working directory
  local root="${PWD}/${proj}"
  [[ -e "$root" ]] && die "Target directory already exists: $root"

  mkdir -p "$root"/{src,include,bin/debug,bin/release}
  cd "$root"

  local cc
  cc="$(detect_compiler "$lang")"

  make_main_templates "$lang" "$proj" "$deps"
  write_makefile "$proj" "$lang" "$std" "$deps" "$cc"
  write_readme "$proj" "$lang" "$std" "$deps"
  write_develop_sh

  sanity_check_makefile_tabs

  echo "Created project: $root"
  echo "Compiler: $cc | Std: $std | Deps: $deps"
  echo "Try: cd '$proj' && ./develop.sh run-debug"
}

main "$@"

