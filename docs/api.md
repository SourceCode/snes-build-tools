# API Reference

This project utilizes **PVSnesLib**, a C library that wraps low-level SNES hardware registers.

## Core Functions

### Initialization

```c
void consoleInit(void);
```

Initializes the PPU, clears VRAM/CGRAM, and sets up a basic state. Must be called first.

### Video Setup

```c
void setMode(u8 mode, u8 size);
```

Sets the SNES Video Mode.

- `mode`: `BG_MODE1` (standard), `BG_MODE7` (rotation/scaling), etc.
- `size`: Tile size (usually 0 for 8x8).

### Background Management

```c
void bgInitTileSet(u8 bgNumber, u8* tileSource, u8* palSource, u8 palEntry,
                   u16 tileSize, u16 palSize, u8 colorMode, u16 vramAddr);
```

Uploads gfx data to VRAM and palette data to CGRAM in one go.

- `bgNumber`: 0-3 (BG1-BG4).
- `vramAddr`: Destination address in VRAM.

```c
void bgSetMapPtr(u8 bgNumber, u16 vramAddr, u8 mapSize);
```

Tells the PPU where to find the Tilemap for a specific background.

### Display Control

```c
void setScreenOn(void);
```

Turns the screen ON (full brightness).

```c
void WaitForVBlank(void);
```

Pauses CPU execution until the Vertical Blanking Interval starts. This is the **Frame Sync** function. All graphical updates must happen immediately after this returns.

### DMA / Memory

```c
void dmaCopyCGram(u8* source, u16 address, u16 size);
```

Copies color data from RAM to CGRAM (Palette Memory) using DMA channel 0. Fast.

## Standard Library Support

PVSnesLib includes a minimal implementation of libc:

- `memcpy`, `memset`
- `rand`, `srand`
- `sprintf` (limited)
- No file I/O (stdio) or dynamic memory allocation (malloc/free) is standard practice.

## Types

- `u8`: Unsigned 8-bit integer
- `u16`: Unsigned 16-bit integer (Word)
- `u32`: Unsigned 32-bit integer (Long)
- `s8`, `s16`, `s32`: Signed equivalents
