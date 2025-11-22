#!/usr/bin/env bash
set -euo pipefail

# new_netproj.sh
# Create a C++23 CMake+Ninja networking/TUI project with WSL gcc/clang presets,
# buglog.sh and develop.sh, editor config, and header skeletons.

usage() {
  echo "Usage:"
  echo "  $(basename "$0")                    # interactive mode"
  echo "  $(basename "$0") <project_path> [--ncurses]"
  exit 1
}

# Resolve a project path (supports ~, relative, absolute)
resolve_project_path() {
  local input="$1"
  # Expand '~'
  input="${input/#\~/$HOME}"
  # Convert to absolute path, allowing missing dirs
  local abs
  abs="$(realpath -m "$input")"
  echo "$abs"
}

USE_NCURSES="OFF"
PROJECT_ROOT=""
PROJECT_NAME=""

# --- Parse arguments / interactive mode ---

if [[ $# -ge 1 ]]; then
  case "$1" in
    -h|--help)
      usage
      ;;
    *)
      PROJECT_ROOT="$(resolve_project_path "$1")"
      shift
      ;;
  esac

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ncurses)
        USE_NCURSES="ON"
        shift
        ;;
      *)
        echo "Unknown argument: $1"
        usage
        ;;
    esac
  done
else
  read -rp "Project path (absolute or relative): " INPUT_PATH
  if [[ -z "$INPUT_PATH" ]]; then
    echo "Project path cannot be empty."
    exit 1
  fi
  PROJECT_ROOT="$(resolve_project_path "$INPUT_PATH")"

  read -rp "Enable ncurses TUI support? [y/N]: " ans
  case "${ans,,}" in
    y|yes) USE_NCURSES="ON" ;;
    *)     USE_NCURSES="OFF" ;;
  esac
fi

PROJECT_NAME="$(basename "$PROJECT_ROOT")"
PROJECT_PARENT="$(dirname "$PROJECT_ROOT")"

# Validate / create dirs
if [[ -e "$PROJECT_ROOT" ]]; then
  echo "Error: '$PROJECT_ROOT' already exists. Aborting."
  exit 1
fi

mkdir -p "$PROJECT_PARENT"
mkdir -p "$PROJECT_ROOT"
mkdir -p "$PROJECT_ROOT/src" "$PROJECT_ROOT/src/tui"
mkdir -p "$PROJECT_ROOT/include/mcw/net" "$PROJECT_ROOT/include/mcw/tui"
mkdir -p "$PROJECT_ROOT/scripts" "$PROJECT_ROOT/.vscode"

echo "Creating project '$PROJECT_NAME' at '$PROJECT_ROOT' (ncurses: $USE_NCURSES)..."

# --- CMakeLists.txt ---

cat > "$PROJECT_ROOT/CMakeLists.txt" <<EOF
cmake_minimum_required(VERSION 3.20)

project($PROJECT_NAME LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Options
option(ENABLE_NCURSES "Enable ncurses-based TUI" $USE_NCURSES)

add_executable(\${PROJECT_NAME}
    src/main.cpp
    src/tui/menu.cpp
)

target_include_directories(\${PROJECT_NAME}
    PRIVATE
        \${CMAKE_CURRENT_SOURCE_DIR}/include
)

# Compiler identification macros
if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_definitions(\${PROJECT_NAME} PRIVATE MCW_COMPILER_MSVC=1)
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_compile_definitions(\${PROJECT_NAME} PRIVATE MCW_COMPILER_CLANG=1)
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_definitions(\${PROJECT_NAME} PRIVATE MCW_COMPILER_GCC=1)
endif()

# Platform macros
if (WIN32)
    target_compile_definitions(\${PROJECT_NAME} PRIVATE MCW_PLATFORM_WINDOWS=1)
else()
    target_compile_definitions(\${PROJECT_NAME} PRIVATE MCW_PLATFORM_LINUX=1)
endif()

# ncurses support (Linux/WSL first)
if (ENABLE_NCURSES)
    find_package(Curses REQUIRED)
    target_link_libraries(\${PROJECT_NAME} PRIVATE Curses::Curses)
    target_compile_definitions(\${PROJECT_NAME} PRIVATE MCW_USE_NCURSES=1)
endif()
EOF

# --- CMakePresets.json (WSL, gcc+clang) ---

cat > "$PROJECT_ROOT/CMakePresets.json" <<'EOF'
{
  "version": 3,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 20,
    "patch": 0
  },

  "configurePresets": [
    {
      "name": "base",
      "hidden": true,
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/build/${presetName}",
      "cacheVariables": {
        "CMAKE_CXX_STANDARD": "23",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    },

    {
      "name": "wsl-clang-debug",
      "inherits": "base",
      "displayName": "WSL Clang Debug",
      "description": "Debug build using clang++ inside WSL",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Linux"
      },
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_C_COMPILER": "clang",
        "CMAKE_CXX_COMPILER": "clang++"
      }
    },
    {
      "name": "wsl-clang-release",
      "inherits": "base",
      "displayName": "WSL Clang Release",
      "description": "Release build using clang++ inside WSL",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Linux"
      },
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_C_COMPILER": "clang",
        "CMAKE_CXX_COMPILER": "clang++"
      }
    },

    {
      "name": "wsl-gcc-debug",
      "inherits": "base",
      "displayName": "WSL GCC Debug",
      "description": "Debug build using g++ inside WSL",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Linux"
      },
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_C_COMPILER": "gcc",
        "CMAKE_CXX_COMPILER": "g++"
      }
    },
    {
      "name": "wsl-gcc-release",
      "inherits": "base",
      "displayName": "WSL GCC Release",
      "description": "Release build using g++ inside WSL",
      "condition": {
        "type": "equals",
        "lhs": "${hostSystemName}",
        "rhs": "Linux"
      },
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_C_COMPILER": "gcc",
        "CMAKE_CXX_COMPILER": "g++"
      }
    }
  ],

  "buildPresets": [
    {
      "name": "wsl-clang-debug",
      "configurePreset": "wsl-clang-debug"
    },
    {
      "name": "wsl-clang-release",
      "configurePreset": "wsl-clang-release"
    },
    {
      "name": "wsl-gcc-debug",
      "configurePreset": "wsl-gcc-debug"
    },
    {
      "name": "wsl-gcc-release",
      "configurePreset": "wsl-gcc-release"
    }
  ]
}
EOF

# --- .vscode/settings.json (2 spaces, no formatOnSave) ---

cat > "$PROJECT_ROOT/.vscode/settings.json" <<'EOF'
{
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.detectIndentation": false,
  "editor.formatOnSave": false,
  "[cpp]": {
    "editor.tabSize": 2,
    "editor.insertSpaces": true
  },
  "files.eol": "\n"
}
EOF

# --- .editorconfig ---

cat > "$PROJECT_ROOT/.editorconfig" <<'EOF'
root = true

[*.{c,cpp,h,hpp}]
indent_style = space
indent_size = 2
tab_width = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
EOF

# --- .gitignore (basic) ---

cat > "$PROJECT_ROOT/.gitignore" <<'EOF'
build/
CMakeFiles/
CMakeCache.txt
cmake_install.cmake
compile_commands.json
*.log
EOF

# --- README.md ---

cat > "$PROJECT_ROOT/README.md" <<EOF
# $PROJECT_NAME

Networking/TUI playground project.

Use \`scripts/develop.sh\` to configure and build with CMake presets.
Use \`scripts/buglog.sh\` to append notes/bugs/fixes/todos to this README.
EOF

# --- include/mcw/config.hpp ---

cat > "$PROJECT_ROOT/include/mcw/config.hpp" <<'EOF'
#pragma once

#include <version>

// Platform
#if defined(_WIN32) || defined(_WIN64)
  #define MCW_PLATFORM_WINDOWS 1
#else
  #define MCW_PLATFORM_LINUX 1
#endif

// C++ standard
#if __cplusplus >= 202302L
  #define MCW_CPP23 1
#else
  #define MCW_CPP23 0
#endif

// std::print feature
#if defined(__cpp_lib_print) && (__cpp_lib_print >= 202207L)
  #define MCW_HAS_STD_PRINT 1
#else
  #define MCW_HAS_STD_PRINT 0
#endif

// std::format feature
#if defined(__cpp_lib_format) && (__cpp_lib_format >= 201907L)
  #define MCW_HAS_STD_FORMAT 1
#else
  #define MCW_HAS_STD_FORMAT 0
#endif

EOF

# --- include/mcw/print.hpp ---

cat > "$PROJECT_ROOT/include/mcw/print.hpp" <<'EOF'
#pragma once
#include "mcw/config.hpp"

#include <string_view>
#include <utility>

#if MCW_HAS_STD_PRINT
  #include <print>
#elif MCW_HAS_STD_FORMAT
  #include <format>
  #include <iostream>
#else
  #include <iostream>
#endif

namespace mcw {

template <typename... Args>
inline void print(std::string_view fmt, Args&&... args) {
#if MCW_HAS_STD_PRINT
    std::print(fmt, std::forward<Args>(args)...);
#elif MCW_HAS_STD_FORMAT
    std::cout << std::vformat(fmt, std::make_format_args(args...));
#else
    // Very basic fallback: just print the format string as-is.
    (void)sizeof...(args);
    std::cout << fmt;
#endif
}

template <typename... Args>
inline void println(std::string_view fmt, Args&&... args) {
#if MCW_HAS_STD_PRINT
    std::println(fmt, std::forward<Args>(args)...);
#else
    print(fmt, std::forward<Args>(args)...);
    std::cout << '\n';
#endif
}

} // namespace mcw
EOF

# --- include/mcw/net/platform.hpp (sockets platform glue stub) ---

cat > "$PROJECT_ROOT/include/mcw/net/platform.hpp" <<'EOF'
#pragma once

#include "mcw/config.hpp"

#if MCW_PLATFORM_WINDOWS
  #include <winsock2.h>
  #include <ws2tcpip.h>
  // TODO: initialize WSA, link with ws2_32.lib when targeting Windows
#else
  #include <sys/types.h>
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <arpa/inet.h>
  #include <unistd.h>
#endif

namespace mcw::net {
// Future cross-platform socket helpers will live here.
}
EOF

# --- ipv4 stubs ---

cat > "$PROJECT_ROOT/include/mcw/net/ipv4_addr.hpp" <<'EOF'
#pragma once

#include <cstdint>
#include <string>

namespace mcw::net {

class ipv4_addr {
public:
    constexpr ipv4_addr() noexcept : value_{0} {}
    explicit constexpr ipv4_addr(std::uint32_t v) noexcept : value_{v} {}

    static ipv4_addr from_octets(std::uint8_t a, std::uint8_t b,
                                 std::uint8_t c, std::uint8_t d) noexcept;

    static ipv4_addr from_string(const std::string& s);

    std::string to_string() const;

    std::uint32_t value() const noexcept { return value_; }

private:
    std::uint32_t value_; // store in host order for now
};

} // namespace mcw::net
EOF

cat > "$PROJECT_ROOT/include/mcw/net/ipv4_network.hpp" <<'EOF'
#pragma once

#include <cstdint>
#include "mcw/net/ipv4_addr.hpp"

namespace mcw::net {

class ipv4_network {
public:
    ipv4_network(ipv4_addr network, std::uint8_t prefix_len) noexcept
      : network_{network}, prefix_len_{prefix_len} {}

    ipv4_addr network_address() const noexcept;
    ipv4_addr broadcast_address() const noexcept;
    ipv4_addr first_host() const noexcept;
    ipv4_addr last_host() const noexcept;
    std::uint32_t host_count() const noexcept;

    std::uint8_t prefix_length() const noexcept { return prefix_len_; }

private:
    ipv4_addr    network_;
    std::uint8_t prefix_len_{};
};

} // namespace mcw::net
EOF

# --- TUI header stub ---

cat > "$PROJECT_ROOT/include/mcw/tui/menu.hpp" <<'EOF'
#pragma once

namespace mcw::tui {

enum class main_choice {
    quit = 0,
    subnet_tools,
    ping_tools
    // extend later
};

main_choice show_main_menu();

} // namespace mcw::tui
EOF

# --- src/main.cpp ---

cat > "$PROJECT_ROOT/src/main.cpp" <<'EOF'
#include "mcw/print.hpp"
#include "mcw/tui/menu.hpp"

int main() {
    using mcw::println;
    using mcw::tui::main_choice;

    println("Welcome to the net TUI.\n");

    for (;;) {
        auto choice = mcw::tui::show_main_menu();
        switch (choice) {
            case main_choice::subnet_tools:
                println("[TODO] Subnet tools not implemented yet.");
                break;
            case main_choice::ping_tools:
                println("[TODO] Ping tools not implemented yet.");
                break;
            case main_choice::quit:
            default:
                println("Goodbye.");
                return 0;
        }
    }
}
EOF

# --- src/tui/menu.cpp (simple non-ncurses menu stub) ---

cat > "$PROJECT_ROOT/src/tui/menu.cpp" <<'EOF'
#include "mcw/tui/menu.hpp"
#include "mcw/print.hpp"

#include <iostream>
#include <limits>

namespace mcw::tui {

main_choice show_main_menu() {
    using mcw::println;

    println("==== Main Menu ====");
    println("  1) Subnet tools");
    println("  2) Ping tools");
    println("  0) Quit");
    println("-------------------");

    int choice = -1;
    while (true) {
        println("Enter choice (0-2): ");
        if (!(std::cin >> choice)) {
            std::cin.clear();
            std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
            println("Invalid input. Please enter a number.");
            continue;
        }

        if (choice < 0 || choice > 2) {
            println("Invalid choice. Please enter 0, 1, or 2.");
            continue;
        }

        break;
    }

    switch (choice) {
        case 1: return main_choice::subnet_tools;
        case 2: return main_choice::ping_tools;
        case 0:
        default:
            return main_choice::quit;
    }
}

} // namespace mcw::tui
EOF

# --- scripts/buglog.sh ---

cat > "$PROJECT_ROOT/scripts/buglog.sh" <<'EOF'
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
EOF

chmod +x "$PROJECT_ROOT/scripts/buglog.sh"

# --- scripts/develop.sh ---

cat > "$PROJECT_ROOT/scripts/develop.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Simple helper to configure+build via CMake presets on WSL.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "$PROJECT_ROOT"

read -rp "Build type [d=Debug, r=Release] (default d): " BT
BT="${BT:-d}"
BT="${BT,,}"

case "$BT" in
  d|debug) BUILD_TYPE="debug" ;;
  r|release) BUILD_TYPE="release" ;;
  *)
    echo "Invalid build type: $BT"
    exit 1
    ;;
esac

read -rp "Compiler [c=clang, g=gcc] (default c): " CC
CC="${CC:-c}"
CC="${CC,,}"

case "$CC" in
  c|clang) COMPILER="clang" ;;
  g|gcc)   COMPILER="gcc" ;;
  *)
    echo "Invalid compiler choice: $CC"
    exit 1
    ;;
esac

PRESET="wsl-${COMPILER}-${BUILD_TYPE}"
echo "Using preset: $PRESET"

cmake --preset "$PRESET"
cmake --build --preset "$PRESET"
EOF

chmod +x "$PROJECT_ROOT/scripts/develop.sh"

echo "Project '$PROJECT_NAME' created at '$PROJECT_ROOT'."
echo "Next steps:"
echo "  cd \"$PROJECT_ROOT\""
echo "  ./scripts/develop.sh    # choose clang/gcc and debug/release"
echo "  ./scripts/buglog.sh     # add notes/bugs/fixes/todos to README.md"

