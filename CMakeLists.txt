cmake_minimum_required(VERSION 3.10)
project(rhythm C)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Build options (prepared for future multi-target support)
option(BUILD_GUI "Build GUI version" OFF)
option(BUILD_CLI "Build CLI version" ON)
option(BUILD_COMBINED "Build combined GUI+CLI version" OFF)

# Find required packages
find_package(PkgConfig REQUIRED)
pkg_check_modules(PORTAUDIO REQUIRED portaudio-2.0)
pkg_check_modules(MPG123 REQUIRED libmpg123)

# Include directories
include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${PORTAUDIO_INCLUDE_DIRS}
    ${MPG123_INCLUDE_DIRS}
)

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

# Create shared library for engine (needed for GUI bridge)
add_library(rhythm_engine SHARED ${CORE_SOURCES})
target_link_libraries(rhythm_engine
    ${PORTAUDIO_LIBRARIES}
    ${MPG123_LIBRARIES}
    m
)

# For now, build CLI version (will be extended in future tasks)
add_executable(rhythm ${CLI_SOURCES})

# Link CLI executable to shared library
target_link_libraries(rhythm rhythm_engine)

# Install target
install(TARGETS rhythm DESTINATION bin)

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