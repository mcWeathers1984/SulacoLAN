cmake_minimum_required(VERSION 3.20)

project(net_tools LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Options
option(ENABLE_NCURSES "Enable ncurses-based TUI" OFF)

add_executable(${PROJECT_NAME}
    src/main.cpp
    src/tui/menu.cpp
)

target_include_directories(${PROJECT_NAME}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# Compiler identification macros
if (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_definitions(${PROJECT_NAME} PRIVATE MCW_COMPILER_MSVC=1)
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_compile_definitions(${PROJECT_NAME} PRIVATE MCW_COMPILER_CLANG=1)
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_definitions(${PROJECT_NAME} PRIVATE MCW_COMPILER_GCC=1)
endif()

# Platform macros
if (WIN32)
    target_compile_definitions(${PROJECT_NAME} PRIVATE MCW_PLATFORM_WINDOWS=1)
else()
    target_compile_definitions(${PROJECT_NAME} PRIVATE MCW_PLATFORM_LINUX=1)
endif()

# ncurses support (Linux/WSL first)
if (ENABLE_NCURSES)
    find_package(Curses REQUIRED)
    target_link_libraries(${PROJECT_NAME} PRIVATE Curses::Curses)
    target_compile_definitions(${PROJECT_NAME} PRIVATE MCW_USE_NCURSES=1)
endif()
