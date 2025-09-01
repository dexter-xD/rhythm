<div align="center">
  <img src="gui/assets/logo/logo.png" alt="Rhythm Logo" width="128" height="128">
  
  # Rhythm
  
  **A modern Linux music player with stunning visualizations**
  
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![C](https://img.shields.io/badge/C-11-blue.svg)](https://en.wikipedia.org/wiki/C11_(C_standard_revision))
  [![Lua](https://img.shields.io/badge/Lua-5.1-lightblue.svg)](https://www.lua.org/)
  [![Platform](https://img.shields.io/badge/Platform-Linux-green.svg)](https://www.linux.org/)
  [![Build System](https://img.shields.io/badge/Build-CMake-red.svg)](https://cmake.org/)
  [![GUI](https://img.shields.io/badge/GUI-LÖVE2D-purple.svg)](https://love2d.org/)
  [![Audio](https://img.shields.io/badge/Audio-PortAudio-orange.svg)](http://www.portaudio.com/)
  [![Decoder](https://img.shields.io/badge/Decoder-mpg123-yellow.svg)](https://www.mpg123.de/)
  
  ![Rhythm Banner](banner.png)
</div>

## ✨ Features

- 🎵 **Multi-Format Support** - Play MP3, FLAC, and other popular audio formats
- 🌈 **Stunning Visualizations** - Real-time spectrum analyzer with beautiful effects
- 🎮 **Dual Interface** - Choose between CLI for simplicity or GUI for rich experience
- 🐧 **Linux Native** - Optimized for Linux systems with native performance
- 📁 **Smart Playlist Management** - Load single files or entire directories
- 🔀 **Advanced Playback** - Shuffle, repeat modes, and seamless track transitions
- ⚡ **High Performance** - Native C core with optimized audio processing
- 🎨 **Modern UI** - Clean, responsive interface built with LÖVE2D
- 🎛️ **Intuitive Controls** - Keyboard shortcuts and mouse interaction

## 🖥️ System Requirements

- **OS**: Linux (Ubuntu, Fedora, Arch, openSUSE)
- **Architecture**: x86_64
- **Dependencies**: PortAudio, mpg123, LÖVE2D (for GUI)
- **Memory**: ~100MB RAM usage
- **Disk**: ~20MB installation size

## � QInstallation

### Pre-built Debian Packages (Recommended)

We provide ready-to-install Debian packages for Ubuntu, Debian, and other Debian-based distributions. Choose the package that best fits your needs:

#### Package Options

**🎵 `rhythm-2.0.0-debian-amd64.deb` - Complete Edition (Recommended)**
- Includes both GUI and terminal interfaces
- Full feature set with visualizations
- Best choice for desktop users
- Size: ~2.4MB

**🖥️ `rhythm-gui-2.0.0-debian-amd64.deb` - GUI Only**
- Graphical interface with visualizations
- Perfect for desktop environments
- Requires LÖVE2D
- Size: ~2.4MB

**⌨️ `rhythm-tui-2.0.0-debian-amd64.deb` - Terminal Only**
- Lightweight terminal interface
- Ideal for servers and minimal systems
- No GUI dependencies required
- Size: ~20KB

#### Installation Steps

1. **Download the package** that matches your preference from the [Releases]([https://github.com/your-username/rhythm/release](https://github.com/dexter-xD/rhythm/releases/tag/v2.0.0)s) page

2. **Install the package:**
   ```bash
   # For the complete edition (recommended)
   sudo dpkg -i rhythm-2.0.0-debian-amd64.deb
   
   # For GUI-only version
   sudo dpkg -i rhythm-gui-2.0.0-debian-amd64.deb
   
   # For terminal-only version
   sudo dpkg -i rhythm-tui-2.0.0-debian-amd64.deb
   ```

3. **Install dependencies** (if any are missing):
   ```bash
   sudo apt-get install -f
   ```

4. **Launch Rhythm:**
   ```bash
   # Complete or GUI version
   rhythm                    # Launches GUI
   rhythm-cli               # Launches terminal interface (complete edition only)
   
   # Terminal-only version
   rhythm                   # Launches terminal interface
   ```

#### System Requirements for Packages

**All Packages:**
- Ubuntu 18.04+ / Debian 10+ / Linux Mint 19+
- x86_64 architecture
- PortAudio and mpg123 libraries (auto-installed)

**GUI Packages Additional Requirements:**
- LÖVE2D 11.0+ (auto-installed)
- Desktop environment (GNOME, KDE, XFCE, etc.)
- Graphics drivers with OpenGL support

#### Verifying Installation

After installation, verify that Rhythm is working correctly:

```bash
# Check if the command is available
which rhythm

# Test with version info
rhythm --version

# For complete edition, test both interfaces
rhythm --help              # GUI version help
rhythm-cli --help          # Terminal version help (only for complete edition)
```

**Desktop Integration:**
- The GUI version will appear in your application menu under "Sound & Video"
- Look for "Rhythm Music Player" with the Rhythm logo
- You can also launch it from the command line with `rhythm`

#### Uninstallation

```bash
# Remove the installed package
sudo dpkg -r rhythm        # Complete edition
sudo dpkg -r rhythm-gui    # GUI-only edition  
sudo dpkg -r rhythm-tui    # Terminal-only edition

# Remove configuration files (optional)
sudo dpkg --purge rhythm
```

### Alternative Installation Methods

If the pre-built packages don't work for your system, you can build from source:

## 🚀 Build from Source

### What is LÖVE2D?

LÖVE2D (also known as "Love") is a 2D game framework for Lua. We use it to create the beautiful GUI interface for Rhythm. The command `love gui` tells LÖVE2D to run the application in the `gui` directory.

### Install Dependencies

**Ubuntu/Debian:**
```bash
# Core dependencies for CLI
sudo apt update && sudo apt install -y \
    portaudio19-dev libmpg123-dev cmake build-essential

# For GUI support, install LÖVE2D
sudo apt install -y love
```

**Fedora/RHEL:**
```bash
# Core dependencies for CLI
sudo dnf install -y \
    portaudio-devel mpg123-devel cmake gcc

# For GUI support, install LÖVE2D
sudo dnf install -y love
```

**Arch Linux:**
```bash
# Core dependencies for CLI
sudo pacman -S \
    portaudio mpg123 cmake gcc

# For GUI support, install LÖVE2D
sudo pacman -S love
```

**Alternative LÖVE2D Installation:**
If LÖVE2D is not available in your package manager, download from [love2d.org](https://love2d.org/):
```bash
# Download and install LÖVE2D AppImage (works on most Linux distros)
wget https://github.com/love2d/love/releases/download/11.4/love-11.4-x86_64.AppImage
chmod +x love-11.4-x86_64.AppImage
sudo mv love-11.4-x86_64.AppImage /usr/local/bin/love
```

### Prerequisites for Building

```bash
# Clone the repository
git clone https://github.com/your-username/rhythm.git
cd rhythm

# Build the project
mkdir build && cd build
cmake ..
make

# Install (optional)
sudo make install
```

## 🎮 Usage

### CLI Mode (Terminal)

**Play a single file:**
```bash
./rhythm song.mp3
```

**Play entire directory:**
```bash
./rhythm /path/to/music/folder
```

**CLI Controls:**
- **Space** - Play/Pause
- **q** - Quit
- **+/-** - Volume control
- **→/←** - Next/Previous track
- **s** - Stop playback
- **m** - Toggle mute

### GUI Mode (Visual Interface)

**Launch GUI:**
```bash
# From the project root directory
love gui

# Alternative: if you're in the gui directory
cd gui
love .
```

**Note:** Make sure you have LÖVE2D installed (see installation instructions above)

**GUI Features:**
- 🎨 **Beautiful Visualizer** - Real-time spectrum analysis with particle effects
- 🎵 **Song Information** - Display current track, artist, and album
- 🎛️ **Interactive Controls** - Click-to-seek progress bar, volume slider
- 🔀 **Playback Modes** - Shuffle and repeat controls
- 📱 **Responsive Design** - Adapts to different window sizes

**GUI Controls:**
- **Mouse** - Click buttons, drag volume slider, seek in progress bar
- **Space** - Play/Pause
- **←/→** - Previous/Next track
- **↑/↓** - Volume control
- **S** - Stop
- **M** - Mute/Unmute
- **Escape** - Exit application

## 🏗️ Architecture

### Core Engine (C)
- **Audio Player** - Low-latency audio playback with PortAudio
- **Decoder** - Multi-format audio decoding with mpg123
- **Playlist Manager** - Smart track management and navigation
- **Spectrum Analyzer** - Real-time FFT analysis for visualizations

### GUI Interface (Lua/LÖVE2D)
- **Game State** - Centralized state management
- **UI Components** - Modular player, controls, and visualizer
- **Engine Bridge** - Seamless C ↔ Lua communication
- **Theme System** - Modern dark theme with glassmorphism effects

## 🎨 Visualizations

The GUI features multiple visualization modes:

- **Spectrum Bars** - Classic frequency spectrum display
- **Waveform** - Real-time audio waveform
- **Particle Effects** - Audio-reactive particle systems
- **Galactic Journey** - Immersive space-themed background
- **Floating Elements** - Dynamic UI elements that respond to music

## 🔧 Development

### Project Structure
```
rhythm/
├── src/core/          # C audio engine
├── src/cli/           # Terminal interface
├── gui/               # LÖVE2D GUI application
├── include/           # Header files
├── tests/             # Unit tests
└── build/             # Build artifacts
```

### Building Components

**CLI Only:**
```bash
cmake -DBUILD_CLI=ON -DBUILD_GUI=OFF ..
make
```

**GUI Development:**
```bash
# Run GUI directly for development (from project root)
love gui

# Or from gui directory
cd gui && love .

# For live development with file watching
love gui --console
```

**Run Tests:**
```bash
make test
```

## 🎵 Supported Formats

- **MP3** - MPEG-1/2 Audio Layer III
- **FLAC** - Free Lossless Audio Codec (planned)
- **OGG** - Ogg Vorbis (planned)
- **WAV** - Waveform Audio File Format (planned)

## 🔧 Troubleshooting

### LÖVE2D Issues

**"love: command not found"**
```bash
# Check if LÖVE2D is installed
which love

# If not installed, install it:
sudo apt install love  # Ubuntu/Debian
sudo dnf install love  # Fedora
sudo pacman -S love    # Arch

# Or download AppImage from love2d.org
```

**GUI won't start**
```bash
# Make sure you're in the project root directory
pwd  # Should show /path/to/rhythm

# Run from project root
love gui

# Check for error messages
love gui --console
```

**Audio not working in GUI**
- Ensure the C engine is built: `make` in the build directory
- Check that `librhythm_engine.so` exists in the build directory
- Verify audio permissions and PulseAudio/ALSA setup

## 🤝 Contributing

We welcome contributions from the community! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

**Quick Start:**
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Development Areas:**
- 🎵 Audio format support expansion
- 🎨 New visualization effects
- 🔧 Performance optimizations
- 📱 UI/UX improvements
- 🧪 Test coverage expansion

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [PortAudio](http://www.portaudio.com/) for cross-platform audio I/O
- [mpg123](https://www.mpg123.de/) for reliable MP3 decoding
- [LÖVE2D](https://love2d.org/) for the excellent 2D game framework
- [Lua](https://www.lua.org/) for the lightweight scripting language
- The open-source community for inspiration and support

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/your-username/rhythm/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/your-username/rhythm/discussions)
- 💬 **Community Chat**: [Discord Server](https://discord.gg/P48cY9zFal)
- 📧 **Contact**: [GitHub Profile](https://github.com/your-username)

---

<div align="center">
  <strong>🎵 Enjoy your music with Rhythm! 🎵</strong>
</div>
