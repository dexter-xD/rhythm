cmake_minimum_required(VERSION 3.10)
project(rhythm C)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Build options for multi-target support
option(BUILD_GUI "Build GUI version" OFF)
option(BUILD_CLI "Build CLI version" ON)
option(BUILD_COMBINED "Build combined GUI+CLI version" OFF)

# Validate build options
if(BUILD_COMBINED)
    set(BUILD_GUI ON)
    set(BUILD_CLI ON)
    message(STATUS "Building combined GUI+CLI version")
elseif(BUILD_GUI AND BUILD_CLI)
    message(WARNING "Both BUILD_GUI and BUILD_CLI are ON. Consider using BUILD_COMBINED instead.")
elseif(NOT BUILD_GUI AND NOT BUILD_CLI AND NOT BUILD_COMBINED)
    message(FATAL_ERROR "At least one of BUILD_GUI, BUILD_CLI, or BUILD_COMBINED must be enabled")
endif()

if(BUILD_GUI)
    message(STATUS "GUI version will be built")
endif()
if(BUILD_CLI)
    message(STATUS "CLI version will be built")
endif()

# Find required packages
find_package(PkgConfig REQUIRED)
pkg_check_modules(PORTAUDIO REQUIRED portaudio-2.0)
pkg_check_modules(MPG123 REQUIRED libmpg123)
pkg_check_modules(JACK REQUIRED jack)

# Additional dependencies for CLI
if(BUILD_CLI OR BUILD_COMBINED)
    find_package(Curses REQUIRED)
endif()

# Include directories
include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${PORTAUDIO_INCLUDE_DIRS}
    ${MPG123_INCLUDE_DIRS}
    ${JACK_INCLUDE_DIRS}
)

if(BUILD_CLI OR BUILD_COMBINED)
    include_directories(${CURSES_INCLUDE_DIRS})
endif()

# Core library sources
set(CORE_SOURCES
    src/core/audio_player.c
    src/core/audio_converter.c
    src/core/playlist.c
    src/core/rhythm_engine.c
)

# CLI sources
set(CLI_SOURCES
    src/cli/main_cli.c
    src/cli/cli.c
)

# GUI sources
set(GUI_SOURCES
    src/gui/main_gui.c
)

# Create shared library for engine (needed for both CLI and GUI)
add_library(rhythm_engine SHARED ${CORE_SOURCES})
target_link_libraries(rhythm_engine
    ${PORTAUDIO_LIBRARIES}
    ${MPG123_LIBRARIES}
    ${JACK_LIBRARIES}
    m
)

# Set library properties
set_target_properties(rhythm_engine PROPERTIES
    VERSION 1.0.0
    SOVERSION 1
    PUBLIC_HEADER "include/core/rhythm_engine.h"
)

# Build CLI executable
if(BUILD_CLI OR BUILD_COMBINED)
    add_executable(rhythm-cli ${CLI_SOURCES})
    target_link_libraries(rhythm-cli 
        rhythm_engine
        ${CURSES_LIBRARIES}
    )
endif()

# Build GUI executable
if(BUILD_GUI OR BUILD_COMBINED)
    add_executable(rhythm-gui ${GUI_SOURCES})
    target_link_libraries(rhythm-gui rhythm_engine)
endif()

# Configure executable naming based on build type
if(BUILD_COMBINED)
    # GUI+TUI package: 'rhythm' (GUI) and 'rhythm-cli' (CLI)
    set_target_properties(rhythm-gui PROPERTIES OUTPUT_NAME rhythm)
    set_target_properties(rhythm-cli PROPERTIES OUTPUT_NAME rhythm-cli)
    message(STATUS "Executable naming: rhythm (GUI), rhythm-cli (CLI)")
elseif(BUILD_GUI AND NOT BUILD_CLI)
    # GUI-only package: 'rhythm' (GUI)
    set_target_properties(rhythm-gui PROPERTIES OUTPUT_NAME rhythm)
    message(STATUS "Executable naming: rhythm (GUI)")
elseif(BUILD_CLI AND NOT BUILD_GUI)
    # TUI-only package: 'rhythm' (CLI)
    set_target_properties(rhythm-cli PROPERTIES OUTPUT_NAME rhythm)
    message(STATUS "Executable naming: rhythm (CLI)")
endif()

# Install targets
install(TARGETS rhythm_engine
    LIBRARY DESTINATION lib
    PUBLIC_HEADER DESTINATION include/rhythm
)

# Install executables (using their renamed outputs)
if(BUILD_CLI OR BUILD_COMBINED)
    install(TARGETS rhythm-cli DESTINATION bin)
endif()

if(BUILD_GUI OR BUILD_COMBINED)
    install(TARGETS rhythm-gui DESTINATION bin)
    
    # Install Love2D GUI files
    install(DIRECTORY gui/
        DESTINATION share/rhythm/gui
        FILES_MATCHING 
        PATTERN "*.lua"
        PATTERN "assets/*"
    )
endif()

# Enable testing
enable_testing()

# Test executable
add_executable(test_rhythm_engine
    tests/unit/test_rhythm_engine.c
    src/core/rhythm_engine.c
    src/core/audio_player.c
    src/core/audio_converter.c
    src/core/playlist.c
)

target_link_libraries(test_rhythm_engine
    ${PORTAUDIO_LIBRARIES}
    ${MPG123_LIBRARIES}
    m
)

# Add test
add_test(NAME rhythm_engine_tests COMMAND test_rhythm_engine) 
