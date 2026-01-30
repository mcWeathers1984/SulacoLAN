#!/usr/bin/env bash
# new_makefile_project_generator_v0_15.sh
# Interactive Makefile project generator for C (clang) / C++ (clang++)
# - Prompts for ALL parameters
# - Generates TAB-safe Makefile (no $$< / $$@ nonsense)
# - Defaults: C18 for C, C++23 for C++
set -euo pipefail

# -----------------------------
# Globals (avoid nounset traps)
# -----------------------------
LIBS=""
CPP23_HAS_FORMAT="n/a"
CPP23_HAS_PRINT="n/a"
CPP23_NOTES=""

# -----------------------------
# Helpers
# -----------------------------
die() { echo "ERROR: $*" >&2; exit 1; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

sanitize_name() {
  local raw="$1"
  raw="${raw// /_}"
  raw="$(echo "$raw" | tr -cd '[:alnum:]_-')"
  [[ -n "$raw" ]] || die "Project name became empty after sanitization."
  [[ "${raw:0:1}" != "-" ]] || die "Project name cannot start with '-'."
  echo "$raw"
}

prompt() {
  local msg="$1"
  local default="${2-}"
  local ans=""
  if [[ -n "$default" ]]; then
    read -r -p "$msg [$default]: " ans
    echo "${ans:-$default}"
  else
    read -r -p "$msg: " ans
    echo "$ans"
  fi
}

prompt_yesno() {
  local msg="$1"
  local default="${2:-y}" # y/n
  local ans=""
  while true; do
    read -r -p "$msg (y/n) [$default]: " ans
    ans="${ans:-$default}"
    case "$ans" in
      y|Y) echo "y"; return 0;;
      n|N) echo "n"; return 0;;
      *) echo "Please enter y or n." >&2;;
    esac
  done
}

# Print menus to STDERR so they still display even when captured via $(...)
prompt_choice() {
  local msg="$1"
  local default_idx="$2"
  shift 2
  local options=("$@")
  local ans=""

  while true; do
    echo "$msg" >&2
    for i in "${!options[@]}"; do
      printf "  %d) %s\n" "$((i+1))" "${options[$i]}" >&2
    done

    read -r -p "Select (1-${#options[@]}) [$default_idx]: " ans
    ans="${ans:-$default_idx}"

    [[ "$ans" =~ ^[0-9]+$ ]] || { echo "Enter a number." >&2; continue; }
    (( ans >= 1 && ans <= ${#options[@]} )) || { echo "Out of range." >&2; continue; }

    echo "${options[$((ans-1))]}"
    return 0
  done
}

detect_pkg_mgr() {
  if have_cmd apt-get; then echo "apt"
  elif have_cmd dnf; then echo "dnf"
  elif have_cmd dnf5; then echo "dnf"
  else echo "none"
  fi
}

install_deps_best_effort() {
  local lang="$1" # c or cpp
  local pmgr
  pmgr="$(detect_pkg_mgr)"
  [[ "$pmgr" != "none" ]] || die "No supported package manager found (apt/dnf). Install deps manually."

  echo "Installing dependencies via $pmgr (best effort; may prompt for sudo)..."
  if [[ "$pmgr" == "apt" ]]; then
    sudo apt-get update -y
    if [[ "$lang" == "c" ]]; then
      sudo apt-get install -y clang make
    else
      sudo apt-get install -y clang make || true
    fi
    # ncurses dev headers only if user chose ncurses
    # libc++ packages optionally help with C++23 <format>/<print> support
    sudo apt-get install -y libc++-dev libc++abi-dev || true
  else
    if [[ "$lang" == "c" ]]; then
      sudo dnf -y install clang make
    else
      sudo dnf -y install clang make || true
    fi
    sudo dnf -y install libcxx libcxx-devel libcxxabi libcxxabi-devel || true
  fi
}

check_ncurses_headers() {
  local compiler="$1"  # clang or clang++
  local lang_mode="$2" # c or c++
  local tmpdir
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/t.c" <<'EOF'
#include <ncurses.h>
int main(void){ return 0; }
EOF
  if ! "$compiler" -x "$lang_mode" "$tmpdir/t.c" -c -o "$tmpdir/t.o" >/dev/null 2>&1; then
    rm -rf "$tmpdir"
    return 1
  fi
  rm -rf "$tmpdir"
  return 0
}

probe_cpp23_feature() {
  local compiler="$1"
  local code="$2"
  local tmpdir
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/t.cpp" <<<"$code"
  if "$compiler" -std=c++23 "$tmpdir/t.cpp" -c -o "$tmpdir/t.o" >/dev/null 2>&1; then
    rm -rf "$tmpdir"
    echo "yes"
  else
    rm -rf "$tmpdir"
    echo "no"
  fi
}

# TAB-safe Makefile generator: emit recipe lines using printf '\t...'
write_makefile() {
  local root="$1"
  local proj="$2"
  local std_flag="$3"   # e.g. -std=c18 or -std=c++23
  local libs="$4"       # e.g. "-lm -lncurses" or ""
  local mf="$root/Makefile"

  : > "$mf"

  {
    printf "# Makefile (clang/clang++) - generated\n"
    printf "PROJ_NAME := %s\n\n" "$proj"

    printf "CXX ?= clang++\n"
    printf "CC  ?= clang\n\n"

    printf "SRC_DIR := src\n"
    printf "INC_DIR := include\n"
    printf "BDIR_D  := build/debug\n"
    printf "BDIR_R  := build/release\n"
    printf "BIN_D   := bin/debug\n"
    printf "BIN_R   := bin/release\n\n"

    printf "# Detect language by presence of .cpp in src/\n"
    printf "HAVE_CPP := \$(wildcard \$(SRC_DIR)/*.cpp)\n\n"

    printf "WARN := -Wall -Wextra -Wpedantic\n"
    printf "INCLUDES := -I\$(INC_DIR)\n\n"

    printf "STD_FLAG := %s\n" "$std_flag"
    printf "LIBS := %s\n\n" "${libs:-}"

    printf "DEBUG_FLAGS := -O0 -g3 -DDEBUG\n"
    printf "RELEASE_FLAGS := -O2 -DNDEBUG\n\n"

    printf "ifeq (\$(strip \$(HAVE_CPP)),)\n"
    printf "  # C project\n"
    printf "  SOURCES := \$(SRC_DIR)/main.c \$(SRC_DIR)/\$(PROJ_NAME).c\n"
    printf "  OBJ_D := \$(patsubst \$(SRC_DIR)/%%.c,\$(BDIR_D)/%%.o,\$(SOURCES))\n"
    printf "  OBJ_R := \$(patsubst \$(SRC_DIR)/%%.c,\$(BDIR_R)/%%.o,\$(SOURCES))\n"
    printf "  LINK := \$(CC)\n"
    printf "  CFLAGS_DEBUG   := \$(STD_FLAG) \$(WARN) \$(INCLUDES) \$(DEBUG_FLAGS)\n"
    printf "  CFLAGS_RELEASE := \$(STD_FLAG) \$(WARN) \$(INCLUDES) \$(RELEASE_FLAGS)\n\n"

    printf "  \$(BDIR_D)/%%.o: \$(SRC_DIR)/%%.c | \$(BDIR_D)\n"
    printf "\t\$(CC) \$(CFLAGS_DEBUG) -c \$< -o \$@\n\n"
    printf "  \$(BDIR_R)/%%.o: \$(SRC_DIR)/%%.c | \$(BDIR_R)\n"
    printf "\t\$(CC) \$(CFLAGS_RELEASE) -c \$< -o \$@\n\n"

    printf "else\n"
    printf "  # C++ project\n"
    printf "  SOURCES := \$(SRC_DIR)/main.cpp \$(SRC_DIR)/\$(PROJ_NAME).cpp\n"
    printf "  OBJ_D := \$(patsubst \$(SRC_DIR)/%%.cpp,\$(BDIR_D)/%%.o,\$(SOURCES))\n"
    printf "  OBJ_R := \$(patsubst \$(SRC_DIR)/%%.cpp,\$(BDIR_R)/%%.o,\$(SOURCES))\n"
    printf "  LINK := \$(CXX)\n"
    printf "  CXXFLAGS_DEBUG   := \$(STD_FLAG) \$(WARN) \$(INCLUDES) \$(DEBUG_FLAGS)\n"
    printf "  CXXFLAGS_RELEASE := \$(STD_FLAG) \$(WARN) \$(INCLUDES) \$(RELEASE_FLAGS)\n\n"

    printf "  \$(BDIR_D)/%%.o: \$(SRC_DIR)/%%.cpp | \$(BDIR_D)\n"
    printf "\t\$(CXX) \$(CXXFLAGS_DEBUG) -c \$< -o \$@\n\n"
    printf "  \$(BDIR_R)/%%.o: \$(SRC_DIR)/%%.cpp | \$(BDIR_R)\n"
    printf "\t\$(CXX) \$(CXXFLAGS_RELEASE) -c \$< -o \$@\n\n"

    printf "endif\n\n"

    printf "EXE_D := \$(BIN_D)/\$(PROJ_NAME)\n"
    printf "EXE_R := \$(BIN_R)/\$(PROJ_NAME)\n\n"

    printf ".PHONY: all debug release clean run-debug run-release info\n\n"
    printf "all: debug\n\n"

    printf "info:\n"
    printf "\t@echo \"PROJ_NAME: \$(PROJ_NAME)\"\n"
    printf "\t@echo \"SOURCES  : \$(SOURCES)\"\n"
    printf "\t@echo \"LIBS     : \$(LIBS)\"\n"
    printf "\t@echo \"STD_FLAG : \$(STD_FLAG)\"\n"
    printf "\t@echo \"CXX      : \$(CXX)\"\n"
    printf "\t@echo \"CC       : \$(CC)\"\n\n"

    printf "debug: \$(EXE_D)\n"
    printf "release: \$(EXE_R)\n\n"

    printf "\$(EXE_D): \$(OBJ_D) | \$(BIN_D)\n"
    printf "\t\$(LINK) \$(OBJ_D) -o \$@ \$(LIBS)\n\n"

    printf "\$(EXE_R): \$(OBJ_R) | \$(BIN_R)\n"
    printf "\t\$(LINK) \$(OBJ_R) -o \$@ \$(LIBS)\n\n"

    printf "\$(BIN_D):\n"
    printf "\tmkdir -p \$(BIN_D)\n\n"

    printf "\$(BIN_R):\n"
    printf "\tmkdir -p \$(BIN_R)\n\n"

    printf "\$(BDIR_D):\n"
    printf "\tmkdir -p \$(BDIR_D)\n\n"

    printf "\$(BDIR_R):\n"
    printf "\tmkdir -p \$(BDIR_R)\n\n"

    printf "clean:\n"
    printf "\trm -rfv \$(BIN_D)/* \$(BIN_R)/* \$(BDIR_D)/* \$(BDIR_R)/*\n\n"

    printf "run-debug: debug\n"
    printf "\t\$(EXE_D)\n\n"

    printf "run-release: release\n"
    printf "\t\$(EXE_R)\n"
  } >> "$mf"
}

# -----------------------------
# Interactive flow
# -----------------------------
echo "=== New Makefile Project Generator (clang/clang++) ==="

PROJ_NAME_RAW="$(prompt "Project name (folder/target name)" "my_project")"
PROJ_NAME="$(sanitize_name "$PROJ_NAME_RAW")"

OUT_PATH_DEFAULT="./$PROJ_NAME"
OUT_PATH="$(prompt "Output path" "$OUT_PATH_DEFAULT")"
[[ ! -e "$OUT_PATH" ]] || die "Output path already exists: $OUT_PATH"

DESC="$(prompt "Short description for README.md" "TODO: description")"

LANG_CHOICE="$(prompt_choice "Select language" 2 "C" "C++")"
if [[ "$LANG_CHOICE" == "C" ]]; then
  LANG="c"
  STD_CHOICE="$(prompt_choice "Select C standard" 2 "c99 (legacy)" "c18 (default)")"
  [[ "$STD_CHOICE" == "c99 (legacy)" ]] && STD="c99" || STD="c18"
else
  LANG="cpp"
  STD_CHOICE="$(prompt_choice "Select C++ standard" 3 "c++11" "c++20" "c++23 (default)")"
  case "$STD_CHOICE" in
    c++11) STD="c++11" ;;
    c++20) STD="c++20" ;;
    *)     STD="c++23" ;;
  esac
fi

DEPS_CHOICE="$(prompt_choice "Select libraries to link" 4 "none" "math" "ncurses" "math+ncurses")"
case "$DEPS_CHOICE" in
  none)          LIBS="" ;;
  math)          LIBS="-lm" ;;
  ncurses)       LIBS="-lncurses" ;;
  math+ncurses)  LIBS="-lm -lncurses" ;;
  *)             LIBS="" ;;
esac

DO_CHECK="$(prompt_yesno "Check required tools/headers before generating?" "y")"
DO_INSTALL="n"
if [[ "$DO_CHECK" == "y" ]]; then
  DO_INSTALL="$(prompt_yesno "If missing, attempt install via apt/dnf?" "n")"
fi

# -----------------------------
# Dependency handling
# -----------------------------
if [[ "$DO_INSTALL" == "y" ]]; then
  install_deps_best_effort "$LANG"
  # install ncurses headers only if needed
  if [[ "$DEPS_CHOICE" == "ncurses" || "$DEPS_CHOICE" == "math+ncurses" ]]; then
    pmgr="$(detect_pkg_mgr)"
    if [[ "$pmgr" == "apt" ]]; then
      sudo apt-get install -y libncurses-dev
    elif [[ "$pmgr" == "dnf" ]]; then
      sudo dnf -y install ncurses-devel
    fi
  fi
fi

if [[ "$DO_CHECK" == "y" ]]; then
  if [[ "$LANG" == "c" ]]; then
    have_cmd clang || die "clang not found. Install clang."
    if [[ "$DEPS_CHOICE" == "ncurses" || "$DEPS_CHOICE" == "math+ncurses" ]]; then
      check_ncurses_headers clang c || die "ncurses headers not found. Install libncurses-dev / ncurses-devel."
    fi
  else
    have_cmd clang++ || die "clang++ not found. Install clang."
    if [[ "$DEPS_CHOICE" == "ncurses" || "$DEPS_CHOICE" == "math+ncurses" ]]; then
      check_ncurses_headers clang++ c++ || die "ncurses headers not found. Install libncurses-dev / ncurses-devel."
    fi
  fi
fi

# C++23 feature probes
CPP23_HAS_FORMAT="n/a"
CPP23_HAS_PRINT="n/a"
CPP23_NOTES=""
if [[ "$LANG" == "cpp" && "$STD" == "c++23" ]]; then
  if [[ "$DO_CHECK" == "y" ]]; then
    CPP23_HAS_FORMAT="$(probe_cpp23_feature clang++ \
'#include <format>
#include <string>
int main(){ auto s = std::format("x={}", 1); (void)s; }')"

    CPP23_HAS_PRINT="$(probe_cpp23_feature clang++ \
'#include <print>
int main(){ std::print("hello {}\n", 123); }')"

    if [[ "$CPP23_HAS_FORMAT" == "no" ]]; then
      CPP23_NOTES+="\n- std::format probe: FAILED (your standard library likely lacks <format>)."
      CPP23_NOTES+="\n  Fix: upgrade toolchain/stdlib (libc++ or libstdc++)."
    else
      CPP23_NOTES+="\n- std::format probe: OK"
    fi

    if [[ "$CPP23_HAS_PRINT" == "no" ]]; then
      CPP23_NOTES+="\n- std::print probe: FAILED (common; <print> not universally available yet)."
      CPP23_NOTES+="\n  Workaround: iostream/printf, or fmtlib, or upgrade toolchain."
    else
      CPP23_NOTES+="\n- std::print probe: OK"
    fi
  else
    CPP23_NOTES+="\n- C++23 selected but checks were skipped; <format>/<print> support not verified."
  fi
fi

# -----------------------------
# Generate project skeleton
# -----------------------------
echo
echo "Generating project..."
echo "  Name : $PROJ_NAME"
echo "  Path : $OUT_PATH"
echo "  Lang : $LANG"
echo "  Std  : $STD"
echo "  Libs : ${LIBS:-<none>}"

mkdir -p "$OUT_PATH"/{src,include,bin/debug,bin/release,build/debug,build/release}

if [[ "$LANG" == "c" ]]; then
  SRC_EXT="c"
  MAIN_FILE="main.c"
  PROJ_SRC="$PROJ_NAME.c"
  PROJ_HDR="$PROJ_NAME.h"
  STD_FLAG="-std=$STD"
else
  SRC_EXT="cpp"
  MAIN_FILE="main.cpp"
  PROJ_SRC="$PROJ_NAME.cpp"
  PROJ_HDR="$PROJ_NAME.hpp"
  STD_FLAG="-std=$STD"
fi

# README
cat > "$OUT_PATH/README.md" <<EOF
# $PROJ_NAME

$DESC

## Build

- \`make debug\`
- \`make release\`
- \`make run-debug\`
- \`make run-release\`
- \`make clean\`

Or: \`./develop.sh\` for an interactive menu.

## Configuration

- Language: $LANG
- Standard: $STD
- Linked libs: ${LIBS:-none}
- Default compilers: clang / clang++

EOF

if [[ "$LANG" == "cpp" && "$STD" == "c++23" ]]; then
  cat >> "$OUT_PATH/README.md" <<EOF
## C++23 Library Feature Probe (clang++)

- <format> (std::format): $CPP23_HAS_FORMAT
- <print>  (std::print):  $CPP23_HAS_PRINT
$CPP23_NOTES

EOF
fi

cat >> "$OUT_PATH/README.md" <<'EOF'
## Bug Log
<!-- APPEND_LOG_BELOW -->
EOF

# Makefile (fixed)
write_makefile "$OUT_PATH" "$PROJ_NAME" "$STD_FLAG" "$LIBS"

# Headers + sources
if [[ "$LANG" == "c" ]]; then
  cat > "$OUT_PATH/include/$PROJ_HDR" <<EOF
#pragma once
#include <stdint.h>
int ${PROJ_NAME}_run(void);
EOF

  {
    echo "#include \"$PROJ_HDR\""
    echo "#include <stdio.h>"
    [[ "$DEPS_CHOICE" == "math" || "$DEPS_CHOICE" == "math+ncurses" ]] && echo "#include <math.h>"
    [[ "$DEPS_CHOICE" == "ncurses" || "$DEPS_CHOICE" == "math+ncurses" ]] && echo "#include <ncurses.h>"
    echo
    echo "int ${PROJ_NAME}_run(void)"
    echo "{"
    if [[ "$DEPS_CHOICE" == "ncurses" || "$DEPS_CHOICE" == "math+ncurses" ]]; then
      echo "  initscr();"
      echo "  cbreak();"
      echo "  noecho();"
      echo "  mvprintw(1, 2, \"Project: %s\", \"$PROJ_NAME\");"
      if [[ "$DEPS_CHOICE" == "math+ncurses" ]]; then
        echo "  double v = sqrt(144.0);"
        echo "  mvprintw(2, 2, \"sqrt(144.0) = %.2f\", v);"
      fi
      echo "  mvprintw(4, 2, \"Press any key to exit...\");"
      echo "  refresh();"
      echo "  getch();"
      echo "  endwin();"
      echo "  return 0;"
    else
      if [[ "$DEPS_CHOICE" == "math" ]]; then
        echo "  double v = sqrt(144.0);"
        echo "  printf(\"Project: %s\\n\", \"$PROJ_NAME\");"
        echo "  printf(\"sqrt(144.0) = %.2f\\n\", v);"
      else
        echo "  printf(\"Hello from $PROJ_NAME\\n\");"
      fi
      echo "  return 0;"
    fi
    echo "}"
  } > "$OUT_PATH/src/$PROJ_SRC"

  cat > "$OUT_PATH/src/$MAIN_FILE" <<EOF
#include "$PROJ_HDR"
int main(void) { return ${PROJ_NAME}_run(); }
EOF
else
  cat > "$OUT_PATH/include/$PROJ_HDR" <<EOF
#pragma once
namespace $PROJ_NAME {
  int run();
}
EOF

  {
    echo "#include \"$PROJ_HDR\""
    [[ "$DEPS_CHOICE" == "math" || "$DEPS_CHOICE" == "math+ncurses" ]] && echo "#include <cmath>"
    [[ "$DEPS_CHOICE" == "ncurses" || "$DEPS_CHOICE" == "math+ncurses" ]] && echo "#include <ncurses.h>"
    echo
    echo "#if __has_include(<format>)"
    echo "  #include <format>"
    echo "  #define HAS_FORMAT 1"
    echo "#else"
    echo "  #define HAS_FORMAT 0"
    echo "#endif"
    echo
    echo "#include <string>"
    echo
    echo "namespace $PROJ_NAME {"
    echo
    echo "int run()"
    echo "{"
    if [[ "$DEPS_CHOICE" == "ncurses" || "$DEPS_CHOICE" == "math+ncurses" ]]; then
      echo "  initscr();"
      echo "  cbreak();"
      echo "  noecho();"
      echo "  mvprintw(1, 2, \"Project: %s\", \"$PROJ_NAME\");"
      if [[ "$DEPS_CHOICE" == "math+ncurses" ]]; then
        echo "  double v = std::sqrt(144.0);"
        echo "  if (HAS_FORMAT) {"
        echo "    auto msg = std::format(\"sqrt(144.0) = {:.2f}\", v);"
        echo "    mvprintw(2, 2, \"%s\", msg.c_str());"
        echo "  } else {"
        echo "    mvprintw(2, 2, \"sqrt(144.0) = %.2f\", v);"
        echo "  }"
      else
        echo "  mvprintw(2, 2, \"ncurses ok\");"
      fi
      echo "  mvprintw(4, 2, \"Press any key to exit...\");"
      echo "  refresh();"
      echo "  getch();"
      echo "  endwin();"
      echo "  return 0;"
    else
      [[ "$DEPS_CHOICE" == "math" ]] && echo "  double v = std::sqrt(144.0); (void)v;"
      echo "  return 0;"
    fi
    echo "}"
    echo
    echo "} // namespace $PROJ_NAME"
  } > "$OUT_PATH/src/$PROJ_SRC"

  cat > "$OUT_PATH/src/$MAIN_FILE" <<EOF
#include "$PROJ_HDR"
int main() { return $PROJ_NAME::run(); }
EOF
fi

# develop.sh
cat > "$OUT_PATH/develop.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

PROJ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
README="$PROJ_ROOT/README.md"

proj_name() {
  grep -E '^PROJ_NAME\s*:=' "$PROJ_ROOT/Makefile" | awk '{print $3}'
}

have_exe() { [[ -x "$1" ]]; }

append_log() {
  local kind="$1"
  local entry="$2"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  printf -- "- [%s] **%s**: %s\n" "$ts" "$kind" "$entry" >> "$README"
  echo "Appended to README bug log."
}

build_debug()   { make -C "$PROJ_ROOT" debug; }
build_release() { make -C "$PROJ_ROOT" release; }
clean_all()     { make -C "$PROJ_ROOT" clean; }

run_debug() {
  local p exe
  p="$(proj_name)"
  exe="$PROJ_ROOT/bin/debug/$p"
  if ! have_exe "$exe"; then
    echo "No debug executable found. Building debug..."
    build_debug
  fi
  "$exe"
}

run_release() {
  local p exe
  p="$(proj_name)"
  exe="$PROJ_ROOT/bin/release/$p"
  if ! have_exe "$exe"; then
    echo "No release executable found. Building release..."
    build_release
  fi
  "$exe"
}

menu() {
  cat <<'MENU'

develop.sh menu
1) build-debug
2) build-release
3) clean
4) run-debug
5) run-release
6) append log entry (bug|fix|todo|note)
7) exit
MENU
}

while true; do
  menu
  read -r -p "Select> " choice
  case "$choice" in
    1) build_debug;;
    2) build_release;;
    3) clean_all;;
    4) run_debug;;
    5) run_release;;
    6)
      read -r -p "Type (bug|fix|todo|note)> " kind
      case "$kind" in bug|fix|todo|note) ;; *) echo "Invalid type."; continue;; esac
      read -r -p "Entry> " entry
      [[ -n "${entry// }" ]] || { echo "Empty entry."; continue; }
      append_log "$kind" "$entry"
      ;;
    7) exit 0;;
    *) echo "Invalid selection.";;
  esac
done
EOF
chmod +x "$OUT_PATH/develop.sh"


# -----------------------------
# Final ownership/permission fixup (project root)
# -----------------------------
FIX_OWNER_GROUP="mikew:developers"

DO_FIX="$(prompt_yesno "Apply ownership/permissions to project recursively? (sudo required)" "y")"
if [[ "$DO_FIX" == "y" ]]; then
  echo "Applying owner/group: $FIX_OWNER_GROUP"
  sudo chown -R "$FIX_OWNER_GROUP" "$OUT_PATH"

  echo "Applying permissions:"
  echo "  dirs  : 0775"
  echo "  files : 0664"
  # directories
  sudo find "$OUT_PATH" -type d -exec chmod 0775 {} +
  # regular files
  sudo find "$OUT_PATH" -type f -exec chmod 0664 {} +
  # ensure develop.sh stays executable
  sudo chmod 0775 "$OUT_PATH/develop.sh"
fi



echo
echo "Done."
echo "Next:"
echo "  cd \"$OUT_PATH\""
echo "  make info"
echo "  ./develop.sh"

