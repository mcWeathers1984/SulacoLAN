#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# -------------------------
# Step 1: Project name
# -------------------------
prompt_project_name() {
  local name=""
  while true; do
    printf '\n=== New Project Generator ===\n' >&2
    read -rp 'Enter project name (letters/numbers/_ only; cannot start with "-"): ' name

    [[ -n "$name" ]] || { printf 'Project name cannot be empty.\n' >&2; continue; }
    [[ "${name:0:1}" != "-" ]] || { printf 'Project name cannot start with "-".\n' >&2; continue; }

    if [[ ! "$name" =~ ^[A-Za-z0-9_]+$ ]]; then
      printf 'Invalid name. Use only letters, numbers, and underscore.\n' >&2
      continue
    fi

    [[ ! -e "$name" ]] || die "Path already exists: $PWD/$name"

    printf '%s\n' "$name"
    return 0
  done
}

create_project_skeleton() {
  local proj="$1"

  mkdir -p -- "$proj"/{include,src,scripts}
  mkdir -p -- "$proj"/build/{debug,release}
  mkdir -p -- "$proj"/bin/{debug,release}

  : > "$proj/README.md"
  : > "$proj/.gitignore"
  : > "$proj/project.manifest"

  printf '\nProject created successfully.\n' >&2
  printf 'Root: %s/%s\n' "$PWD" "$proj" >&2
}

# -------------------------
# Step 2: Core selections
# -------------------------
prompt_language() {
  local choice=""
  while true; do
    printf '\nSelect language:\n' >&2
    printf '  1) C\n' >&2
    printf '  2) C++\n' >&2
    read -rp 'Choice [1-2]: ' choice
    case "$choice" in
      1) printf 'c\n'; return 0 ;;
      2) printf 'cpp\n'; return 0 ;;
      *) printf 'Invalid selection.\n' >&2 ;;
    esac
  done
}

prompt_build_system() {
  local choice=""
  while true; do
    printf '\nSelect build system:\n' >&2
    printf '  1) Makefile\n' >&2
    printf '  2) CMake (auto: Ninja if available, else Unix Makefiles)\n' >&2
    read -rp 'Choice [1-2]: ' choice
    case "$choice" in
      1) printf 'make\n'; return 0 ;;
      2) printf 'cmake\n'; return 0 ;;
      *) printf 'Invalid selection.\n' >&2 ;;
    esac
  done
}

prompt_libs() {
  local choice=""
  while true; do
    printf '\nSelect optional libraries to link:\n' >&2
    printf '  1) none\n' >&2
    printf '  2) math (libm)\n' >&2
    printf '  3) ncurses\n' >&2
    printf '  4) math + ncurses\n' >&2
    read -rp 'Choice [1-4]: ' choice
    case "$choice" in
      1) printf 'none\n'; return 0 ;;
      2) printf 'math\n'; return 0 ;;
      3) printf 'ncurses\n'; return 0 ;;
      4) printf 'math+ncurses\n'; return 0 ;;
      *) printf 'Invalid selection.\n' >&2 ;;
    esac
  done
}

default_standard_for() {
  local lang="$1"
  if [[ "$lang" == "cpp" ]]; then
    printf 'c++23\n'
  else
    printf 'c11\n'
  fi
}

detect_cmake_generator() {
  if have_cmd ninja; then
    printf 'Ninja\n'
  else
    printf 'Unix Makefiles\n'
  fi
}

write_manifest() {
  local proj="$1" lang="$2" std="$3" buildsys="$4" cmake_gen="$5" libs="$6"
  local ts
  ts="$(date -Is 2>/dev/null || date)"

  {
    printf 'project_name=%s\n' "$proj"
    printf 'language=%s\n' "$lang"
    printf 'standard=%s\n' "$std"
    printf 'build_system=%s\n' "$buildsys"
    if [[ "$buildsys" == "cmake" ]]; then
      printf 'cmake_generator=%s\n' "$cmake_gen"
    fi
    printf 'libraries=%s\n' "$libs"
    printf 'created_at=%s\n' "$ts"
  } > "$proj/project.manifest"
}

# -------------------------
# Step 3: Template generation
# -------------------------
guard_token() {
  local s="$1"
  s="${s^^}"
  s="$(printf '%s' "$s" | sed 's/[^A-Z0-9]/_/g; s/__\+/_/g')"
  printf '%s\n' "$s"
}

read_manifest() {
  local manifest="$1"
  [[ -f "$manifest" ]] || die "Manifest not found: $manifest"
  # shellcheck disable=SC1090
  source "$manifest"
  : "${project_name:?Missing project_name in manifest}"
  : "${language:?Missing language in manifest}"
  : "${standard:?Missing standard in manifest}"
  : "${build_system:?Missing build_system in manifest}"
  : "${libraries:?Missing libraries in manifest}"
}

gen_templates_c() {
  local proj="$1" libs="$2"
  local guard base_h base_c main_c
  guard="$(guard_token "$proj")"
  base_h="$proj/include/${proj}.h"
  base_c="$proj/src/${proj}.c"
  main_c="$proj/src/main.c"

  cat > "$base_h" <<EOF
#ifndef ${guard}_H
#define ${guard}_H

int ${proj}_add(int a, int b);

#endif /* ${guard}_H */
EOF

  cat > "$base_c" <<EOF
#include "${proj}.h"

int ${proj}_add(int a, int b)
{
    return a + b;
}
EOF

  if [[ "$libs" == *"ncurses"* ]]; then
    cat > "$main_c" <<EOF
#include <ncurses.h>
#include "${proj}.h"

int main(void)
{
    initscr();
    printw("Result: %d\\n", ${proj}_add(2, 3));
    printw("Press any key to exit...");
    refresh();
    getch();
    endwin();
    return 0;
}
EOF
  else
    cat > "$main_c" <<EOF
#include <stdio.h>
#include "${proj}.h"

int main(void)
{
    int result = ${proj}_add(2, 3);
    printf("Result: %d\\n", result);
    return 0;
}
EOF
  fi
}

gen_templates_cpp() {
  local proj="$1" libs="$2"
  local guard base_h base_cpp main_cpp
  guard="$(guard_token "$proj")"
  base_h="$proj/include/${proj}.hpp"
  base_cpp="$proj/src/${proj}.cpp"
  main_cpp="$proj/src/main.cpp"

  cat > "$base_h" <<EOF
#ifndef ${guard}_HPP
#define ${guard}_HPP

namespace ${proj} {
    int add(int a, int b);
}

#endif /* ${guard}_HPP */
EOF

  cat > "$base_cpp" <<EOF
#include "${proj}.hpp"

namespace ${proj} {
    int add(int a, int b)
    {
        return a + b;
    }
}
EOF

  if [[ "$libs" == *"ncurses"* ]]; then
    cat > "$main_cpp" <<EOF
#include <ncurses.h>
#include "${proj}.hpp"

int main()
{
    initscr();
    printw("Result: %d\\n", ${proj}::add(2, 3));
    printw("Press any key to exit...");
    refresh();
    getch();
    endwin();
    return 0;
}
EOF
  else
    cat > "$main_cpp" <<EOF
#include <iostream>
#include "${proj}.hpp"

int main()
{
    int result = ${proj}::add(2, 3);
    std::cout << "Result: " << result << '\\n';
    return 0;
}
EOF
  fi
}

generate_templates_from_manifest() {
  local proj="$1"
  local manifest="$proj/project.manifest"
  read_manifest "$manifest"

  [[ "$project_name" == "$proj" ]] || die "Manifest project_name ($project_name) != directory ($proj)"

  printf '\nGenerating templates...\n' >&2
  if [[ "$language" == "c" ]]; then
    gen_templates_c "$proj" "$libraries"
  elif [[ "$language" == "cpp" ]]; then
    gen_templates_cpp "$proj" "$libraries"
  else
    die "Unknown language in manifest: $language"
  fi
}

# -------------------------
# Step 4: Build system generation
# -------------------------
libs_to_ldlibs() {
  # Outputs linker libs (LDLIBS style)
  local libs="$1"
  local out=()
  if [[ "$libs" == *"math"* ]]; then out+=("-lm"); fi
  if [[ "$libs" == *"ncurses"* ]]; then out+=("-lncurses"); fi
  printf '%s' "${out[*]:-}"
}

generate_makefile() {
  local proj="$1" lang="$2" std="$3" libs="$4"
  local mf="$proj/Makefile"
  local ldlibs
  ldlibs="$(libs_to_ldlibs "$libs")"

  local is_cpp=0
  [[ "$lang" == "cpp" ]] && is_cpp=1

  cat > "$mf" <<EOF
# Auto-generated Makefile (Mr McWeathers Ultimate New Project Generator)
# Project: ${proj}

PROJECT      := ${proj}
LANG         := ${lang}

BUILD_DEBUG  := build/debug
BUILD_REL    := build/release
BIN_DEBUG    := bin/debug
BIN_REL      := bin/release

SRCDIR       := src
INCDIR       := include

SOURCES      := \$(SRCDIR)/main.$([[ $is_cpp -eq 1 ]] && echo cpp || echo c) \\
               \$(SRCDIR)/\$(PROJECT).$([[ $is_cpp -eq 1 ]] && echo cpp || echo c)

# Toolchain (overridable): make debug CC=clang CXX=clang++
CC           ?= gcc
CXX          ?= g++

CSTD         := ${std}
CXXSTD       := ${std}

WARNFLAGS    := -Wall -Wextra -Wpedantic
DBGFLAGS     := -O0 -g
RELFLAGS     := -O2 -DNDEBUG
INCFLAGS     := -I\$(INCDIR)

# Dependency generation
DEPFLAGS     := -MMD -MP

# Link libraries
LDLIBS       := ${ldlibs}

# Select flags based on language
ifeq (\$(LANG),cpp)
  STD_FLAG   := -std=\$(CXXSTD)
else
  STD_FLAG   := -std=\$(CSTD)
endif

.PHONY: all debug release clean run-debug run-release

all: debug

debug: \$(BIN_DEBUG)/\$(PROJECT)
release: \$(BIN_REL)/\$(PROJECT)

# Debug build
\$(BIN_DEBUG)/\$(PROJECT): \$(BUILD_DEBUG) \$(BIN_DEBUG) \$(patsubst \$(SRCDIR)/%,\$(BUILD_DEBUG)/%,\$(SOURCES:.c=.o))
ifeq (\$(LANG),cpp)
\t\$(CXX) \$(STD_FLAG) \$(WARNFLAGS) \$(DBGFLAGS) \$(INCFLAGS) -o \$@ \$(filter %.o,\$^) \$(LDLIBS)
else
\t\$(CC)  \$(STD_FLAG) \$(WARNFLAGS) \$(DBGFLAGS) \$(INCFLAGS) -o \$@ \$(filter %.o,\$^) \$(LDLIBS)
endif

# Release build
\$(BIN_REL)/\$(PROJECT): \$(BUILD_REL) \$(BIN_REL) \$(patsubst \$(SRCDIR)/%,\$(BUILD_REL)/%,\$(SOURCES:.c=.o))
ifeq (\$(LANG),cpp)
\t\$(CXX) \$(STD_FLAG) \$(WARNFLAGS) \$(RELFLAGS) \$(INCFLAGS) -o \$@ \$(filter %.o,\$^) \$(LDLIBS)
else
\t\$(CC)  \$(STD_FLAG) \$(WARNFLAGS) \$(RELFLAGS) \$(INCFLAGS) -o \$@ \$(filter %.o,\$^) \$(LDLIBS)
endif

# Compile rules (debug)
\$(BUILD_DEBUG)/%.o: \$(SRCDIR)/%.c | \$(BUILD_DEBUG)
\t\$(CC)  \$(STD_FLAG) \$(WARNFLAGS) \$(DBGFLAGS) \$(INCFLAGS) \$(DEPFLAGS) -c \$< -o \$@
\$(BUILD_DEBUG)/%.o: \$(SRCDIR)/%.cpp | \$(BUILD_DEBUG)
\t\$(CXX) \$(STD_FLAG) \$(WARNFLAGS) \$(DBGFLAGS) \$(INCFLAGS) \$(DEPFLAGS) -c \$< -o \$@

# Compile rules (release)
\$(BUILD_REL)/%.o: \$(SRCDIR)/%.c | \$(BUILD_REL)
\t\$(CC)  \$(STD_FLAG) \$(WARNFLAGS) \$(RELFLAGS) \$(INCFLAGS) \$(DEPFLAGS) -c \$< -o \$@
\$(BUILD_REL)/%.o: \$(SRCDIR)/%.cpp | \$(BUILD_REL)
\t\$(CXX) \$(STD_FLAG) \$(WARNFLAGS) \$(RELFLAGS) \$(INCFLAGS) \$(DEPFLAGS) -c \$< -o \$@

\$(BUILD_DEBUG) \$(BUILD_REL) \$(BIN_DEBUG) \$(BIN_REL):
\t@mkdir -p \$@

run-debug: debug
\t./\$(BIN_DEBUG)/\$(PROJECT)

run-release: release
\t./\$(BIN_REL)/\$(PROJECT)

clean:
\trm -rfv build/debug build/release bin/debug/\$(PROJECT) bin/release/\$(PROJECT)

# Include dependency files if present
-include \$(wildcard \$(BUILD_DEBUG)/*.d) \$(wildcard \$(BUILD_REL)/*.d)
EOF
}

generate_cmakelists() {
  local proj="$1" lang="$2" std="$3" libs="$4"
  local cm="$proj/CMakeLists.txt"

  local cm_lang="C"
  if [[ "$lang" == "cpp" ]]; then
    cm_lang="CXX"
  fi

  # Extract numeric standard for CMake:
  #   c11   -> 11
  #   c17   -> 17
  #   c23   -> 23
  #   c++20 -> 20
  #   c++23 -> 23
  local std_num
  std_num="$(printf '%s' "$std" | sed 's/[^0-9]//g')"
  [[ -n "$std_num" ]] || std_num="11"

  local want_math=0 want_ncurses=0
  [[ "$libs" == *"math"* ]] && want_math=1
  [[ "$libs" == *"ncurses"* ]] && want_ncurses=1

  cat > "$cm" <<EOF
cmake_minimum_required(VERSION 3.16)

project(${proj} LANGUAGES ${cm_lang})

# Standard
set(CMAKE_${cm_lang}_STANDARD ${std_num})
set(CMAKE_${cm_lang}_STANDARD_REQUIRED ON)
set(CMAKE_${cm_lang}_EXTENSIONS OFF)

# Output directories: bin/{debug,release}
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "\${CMAKE_SOURCE_DIR}/bin")
foreach(OUTPUTCONFIG DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
  string(TOLOWER "\${OUTPUTCONFIG}" OUTPUTCONFIG_LOWER)
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_\${OUTPUTCONFIG} "\${CMAKE_SOURCE_DIR}/bin/\${OUTPUTCONFIG_LOWER}")
endforeach()

add_executable(${proj}
  src/main.$([[ "$lang" == "cpp" ]] && echo cpp || echo c)
  src/${proj}.$([[ "$lang" == "cpp" ]] && echo cpp || echo c)
)

target_include_directories(${proj} PRIVATE "\${CMAKE_SOURCE_DIR}/include")

# Warnings (GCC/Clang)
if (CMAKE_${cm_lang}_COMPILER_ID MATCHES "GNU|Clang")
  target_compile_options(${proj} PRIVATE -Wall -Wextra -Wpedantic)
endif()

# Libraries
EOF

  if [[ $want_ncurses -eq 1 ]]; then
    cat >> "$cm" <<EOF

find_package(Curses REQUIRED)
target_include_directories(${proj} PRIVATE \${CURSES_INCLUDE_DIRS})
target_link_libraries(${proj} PRIVATE \${CURSES_LIBRARIES})
EOF
  fi

  if [[ $want_math -eq 1 ]]; then
    cat >> "$cm" <<EOF

# libm
target_link_libraries(${proj} PRIVATE m)
EOF
  fi
}


generate_build_system_from_manifest() {
  local proj="$1"
  local manifest="$proj/project.manifest"
  read_manifest "$manifest"

  printf '\nGenerating build system files...\n' >&2
  if [[ "$build_system" == "make" ]]; then
    generate_makefile "$proj" "$language" "$standard" "$libraries"
    printf 'Wrote: %s/Makefile\n' "$proj" >&2
  elif [[ "$build_system" == "cmake" ]]; then
    generate_cmakelists "$proj" "$language" "$standard" "$libraries"
    printf 'Wrote: %s/CMakeLists.txt\n' "$proj" >&2
  else
    die "Unknown build_system in manifest: $build_system"
  fi
}

# -------------------------
# Main flow (Steps 1–4)
# -------------------------
main() {
  local project_name language standard build_system libs cmake_gen

  project_name="$(prompt_project_name)"
  create_project_skeleton "$project_name"

  language="$(prompt_language)"
  standard="$(default_standard_for "$language")"

  build_system="$(prompt_build_system)"
  cmake_gen="N/A"
  if [[ "$build_system" == "cmake" ]]; then
    cmake_gen="$(detect_cmake_generator)"
  fi

  libs="$(prompt_libs)"

  write_manifest "$project_name" "$language" "$standard" "$build_system" "$cmake_gen" "$libs"
  printf '\nSelections saved to %s/project.manifest\n' "$project_name" >&2

  generate_templates_from_manifest "$project_name"
  generate_build_system_from_manifest "$project_name"

  printf '\nNext: generate scripts (build.sh / develop.sh / buglog.sh).\n' >&2
}

main "$@"
