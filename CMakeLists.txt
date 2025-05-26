cmake_minimum_required(VERSION 3.10)
project(music_player C)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

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

# Add source files
file(GLOB_RECURSE SOURCES 
    "src/*.c"
)

# Create executable
add_executable(music_player ${SOURCES})

# Link libraries
target_link_libraries(music_player
    ${PORTAUDIO_LIBRARIES}
    ${MPG123_LIBRARIES}
    m
)

# Install target
install(TARGETS music_player DESTINATION bin) 