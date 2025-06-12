#!/bin/bash

# Rhythm MP3 Player Build Script
# Usage: ./build.sh

set -e

echo "🎵 Building Rhythm MP3 Player..."

if ! command -v gcc &> /dev/null; then
    echo "❌ Error: gcc not found. Please install build-essential."
    exit 1
fi

if ! pkg-config --exists portaudio-2.0; then
    echo "❌ Error: PortAudio not found. Please install portaudio19-dev."
    exit 1
fi

if ! pkg-config --exists libmpg123; then
    echo "❌ Error: libmpg123 not found. Please install libmpg123-dev."
    exit 1
fi

mkdir -p build
cd build

if command -v cmake &> /dev/null; then
    echo "📦 Using CMake build..."
    cmake ..
    make
else
    echo "🔨 Using manual compilation..."
    cd ..
    gcc -o rhythm \
        src/main.c \
        src/playlist.c \
        src/player/audio_converter.c \
        src/player/audio_player.c \
        src/ui/cli.c \
        -Iinclude \
        $(pkg-config --cflags --libs portaudio-2.0) \
        $(pkg-config --cflags --libs libmpg123) \
        $(pkg-config --cflags --libs jack) \
        -lm
fi

echo "✅ Build complete!"
echo "🎶 Run with: ./rhythm your_music.mp3"
echo "📁 Or play a folder: ./rhythm /path/to/music/folder" 