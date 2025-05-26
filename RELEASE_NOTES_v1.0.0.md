# Rhythm v1.0.0 - Initial Release 🎵

We're excited to announce the first stable release of **Rhythm**, a beautiful terminal-based MP3 player!

## ✨ Features

- **🎨 Beautiful Rainbow Spectrum Visualizer** - Watch your music come to life with a 32-bar vertical spectrum analyzer
- **📁 Flexible Playback** - Play single MP3 files or entire folders
- **🎛️ Volume Control** - Adjust volume on the fly with + and - keys
- **⏯️ Playback Controls** - Play, pause, and navigate tracks with intuitive controls
- **📊 Progress Display** - See current time, total duration, and visual progress bar
- **🎵 Modern Terminal UI** - Clean, boxed layout with Unicode icons and colors

## 🎮 Controls

- **Space** - Play/Pause
- **q** - Quit
- **+** - Volume up
- **-** - Volume down
- **→** (Right arrow) - Next track
- **←** (Left arrow) - Previous track

## 🚀 Quick Start

1. Install dependencies:
   ```bash
   # Ubuntu/Debian
   sudo apt install portaudio19-dev libmpg123-dev cmake build-essential
   ```

2. Build:
   ```bash
   mkdir build && cd build
   cmake .. && make
   ```

3. Run:
   ```bash
   # Single file
   ./rhythm song.mp3
   
   # Entire folder
   ./rhythm /path/to/music/folder
   ```

## 🔧 Technical Details

- Written in C for performance and portability
- Uses PortAudio for cross-platform audio output
- Uses libmpg123 for MP3 decoding
- Real-time audio visualization with FFT analysis
- Efficient playlist management for large music collections

## 🐛 Known Issues

- None reported yet! Please file issues on GitHub if you encounter any problems.

## 🙏 Acknowledgments

Built with love for music enthusiasts who prefer the terminal! 

---

**Full Changelog**: This is the initial release of Rhythm.

Enjoy your music! 🎶 