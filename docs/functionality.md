# Functionality & Capabilities

**SNES Build Tools** is designed to bridge the gap between modern C programming and 1990s hardware constraints.

## Core Workflows

### 1. Hybrid C/ASM Compilation

The toolchain uses `816-tcc` to compile C code into 65816 Assembly.

- **Why?** Writing game logic in C is 10x faster than raw ASM.
- **Optimization**: Time-critical loops (like NMI handlers or HDMA tables) can be written in ASM or optimized C.
- **SDK**: PVSnesLib provides C wrappers for SNES hardware registers (`setMode`, `bgInitTileSet`, `dmaCopyCGram`).

### 2. Automated Asset Pipeline

SNES hardware cannot read PNG or JPEG files. They must be converted into bitplanes (tiles) and palettes.

- **Input**: Standard `.png` files in `assets/`.
- **Process**: `gfx4snes` converts them based on Makefile rules.
- **Output**: `.pic` (tiles), `.pal` (colors), `.map` (tilemap arrangement).
- **Integration**: These binaries are included via `data.asm` and linked directly into the ROM.

## Demo Project: "Hello SNES World"

The included project demonstrates advanced graphical features:

### Mode 1 Rendering

- **BG1 (Background)**: 256 colors (or 16 colors x 8 palettes). Used for the wavy background.
- **BG2 (Foreground)**: Text layer.
- **BG3**: Disabled (typically used for HUDs in Mode 1).

### HDMA (Horizontal Direct Memory Access)

The "wavy" background effect isn't done by the CPU moving pixels. It uses **HDMA Channel 7** to modify the **Scroll Registers** (`BG1HOFS`, `BG1VOFS`) on _every single scanline_ automatically.

- **CPU Cost**: Near zero. The CPU just sets up a table in RAM once per frame.
- **Effect**: Sine wave distortion, perspective warping, and parallax modulation.

### Palette Cycling

The engine simulates animation by rotating colors in CGRAM (Color RAM) during VBlank, a technique used famously in _Earthbound_ / _Mother 2_ battle backgrounds.
