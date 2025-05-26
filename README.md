# Rhythm 🎵

A simple terminal-based MP3 player with a beautiful spectrum visualizer.

## Build

Make sure you have the required dependencies installed:

```bash
# Ubuntu/Debian
sudo apt install portaudio19-dev libmpg123-dev cmake build-essential

# Fedora/RHEL
sudo dnf install portaudio-devel mpg123-devel cmake gcc

# Arch Linux
sudo pacman -S portaudio mpg123 cmake gcc
```

Build the project:

```bash
mkdir build
cd build
cmake ..
make
```

## Run

### Play a single MP3 file:
```bash
./rhythm song.mp3
```

### Play all MP3s in a folder:
```bash
./rhythm /path/to/music/folder
```

## Controls

- **Space** - Play/Pause
- **q** - Quit
- **+** - Volume up
- **-** - Volume down
- **→** (Right arrow) - Next track
- **←** (Left arrow) - Previous track

## Features

- 🎨 Beautiful rainbow spectrum visualizer
- 📁 Single file or folder playback
- 🎛️ Volume control
- ⏯️ Play/pause functionality
- 📊 Progress bar with time display
- 🎵 Modern terminal UI

Enjoy your music! 🎶 