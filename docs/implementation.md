# Implementation Details

This document explains the internal workings of the build system and the demo architecture.

## Build Pipeline

The `Makefile` orchestrates the conversion of assets and compilation of code.

### 1. Asset Conversion (`gfx4snes`)

Before code compilation, assets are processed:

- **Font**: `assets/fonts/font_large.png` -> `font_large.pic` (tiles) + `font_large.pal` (palette).
- **Background**: `assets/backgrounds/bg_earthbound.png` -> `bg_earthbound.pic` + `bg_earthbound.map`.

### 2. Compilation (`816-tcc`)

- `src/main.c` is compiled to `src/main.ps` (Pre-Assembly).
- Use `-Iinclude` to find local headers.

### 3. assembly & Linking (`wla-65816`)

- `hdr.asm`: Defines the ROM header (Title, Mapping, Interrupt Vectors).
- `data.asm`: Includes the binary asset files (`.incbin`).
- The linker (`wlalink`) combines the compiled C object and the ASM objects into the final `.sfc` file.

## Demo Engine Architecture

The **Hello SNES World** demo implements a sophisticated rendering engine.

### The Main Loop

```c
while (1) {
    // 1. Heavy Lifting (Active Frame)
    // Compute the HDMA table for the NEXT frame while the current one is drawing.
    buildHDMATable();

    // 2. Synchronization
    WaitForVBlank();

    // 3. VBlank Critical Section (Safe for Video Updates)
    swapHDMABuffers();
    updatePaletteCycle();
    setScrollRegisters();
}
```

### HDMA Distortion

The "wavy" effect is achieved by manipulating the horizontal scroll register on every scanline.

- **Double Buffering**: We use two tables (`hdma_table_a`, `hdma_table_b`).
- **Swap**: The CPU writes to the "back" buffer while the hardware reads the "front" buffer.
- **Sine Table**: A pre-calculated sine wave lookup table avoids slow floating-point math.

### Palette Cycling

The engine holds two copies of the palette:

1.  **ROM Copy**: The constant, original colors.
2.  **RAM Copy**: The active, shifting colors.

Every VBlank, the CPU recalculates the RAM copy based on the current "Phase" (Offset), then DMA copies it to CGRAM.
