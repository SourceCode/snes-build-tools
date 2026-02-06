# SNES Build Tools

A clone-and-run SNES ROM build toolchain featuring a demo ROM with an Earthbound-style animated background and large pixel text.

## What This Is

This repository provides everything you need to start building SNES ROMs in C:

- **Automated install script** that downloads and configures the complete toolchain
- **PVSnesLib SDK** with 816-tcc compiler, wla-65816 assembler, and wlalink linker
- **Demo ROM** ("Hello SNES World") showcasing animated backgrounds and text rendering
- **Project template** for starting your own SNES projects

## Demo ROM

The included `hello-snes-world` project produces a ROM that displays:
- An Earthbound-style animated background with sine-wave distortion and palette cycling
- "HELLO SNES WORLD" in large white pixel font with black border, centered on screen
- Uses SNES Mode 1 with layered backgrounds and HDMA effects

## Quick Start

> **TODO**: Complete setup instructions will be added in Phase 10.

```bash
# Clone the repository
git clone <repo-url>
cd snes-build-tools

# Run the install script (Windows)
install.bat

# Run the install script (Linux/macOS)
./install.sh

# Build the demo ROM
cd projects/hello-snes-world
make
```

## Repository Structure

```
snes-build-tools/
├── install.bat / install.sh    # Automated toolchain installer
├── tools/                      # Downloaded SDK and emulators
│   ├── pvsneslib/              # PVSnesLib SDK
│   ├── emulators/              # Optional test emulators
│   └── bin/                    # Key executables
├── projects/
│   └── hello-snes-world/       # Demo ROM project
│       ├── src/main.c          # C source
│       ├── assets/             # Graphics (PNG and converted)
│       ├── hdr.asm             # ROM header
│       ├── data.asm            # Binary asset includes
│       └── Makefile            # Build configuration
├── templates/basic/            # Starter template for new projects
├── scripts/                    # Helper scripts
├── docs/                       # Documentation
└── tmp/                        # Temporary files (gitignored)
```

## Technical Details

- **SDK**: PVSnesLib v4.5.0
- **Compiler**: 816-tcc (C to 65816 ASM)
- **Assembler**: wla-65816
- **Linker**: wlalink
- **Graphics**: gfx4snes (PNG to SNES tile format)
- **Target**: SNES / Super Famicom (WDC 65816, 3.58 MHz)
- **Video Mode**: Mode 1 (BG1: 16-color animated, BG2: 16-color text)
- **ROM Type**: LoROM, 4Mbit

## Build Pipeline

```
C source (.c) --> 816-tcc --> ASM (.asm) --> 816-opt --> wla-65816 --> wlalink --> ROM (.sfc)
PNG graphics  --> gfx4snes --> .pic/.pal/.map --> included via data.asm --> linked into ROM
```

## License

MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- [PVSnesLib](https://github.com/alekmaul/pvsneslib) by Alekmaul
- [Earthbound Battle Backgrounds JS](https://github.com/gjtorikian/Earthbound-Battle-Backgrounds-JS) by Garen Torikian
- The SNES homebrew community
