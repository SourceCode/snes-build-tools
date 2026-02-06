# Phase 7: ROM Bootstrap & Hardware Initialization

## Overview

This phase implements the core SNES initialization code that boots the hardware into a known good state and loads all graphics data into VRAM and CGRAM. This is where the ROM goes from a blank screen to having the background tiles and font tiles loaded and displayed (statically, without animation -- animation comes in Phase 8).

The main.c stub from Phase 4 is replaced with a complete initialization routine that sets up the PPU, loads assets via DMA, configures background layers, and enters the main game loop.

## Prerequisites

- Phase 1-4 completed (project structure, build system, toolchain)
- Phase 5 completed (font assets converted to SNES format)
- Phase 6 completed (background assets converted to SNES format, effect parameters defined)
- All `.pic`, `.pal`, and `.map` files exist in their respective asset directories

## Objectives

1. Write the complete main.c with hardware initialization
2. Finalize hdr.asm for LoROM configuration (update from Phase 4 if needed)
3. Finalize data.asm with all asset includes
4. Set up PPU registers for Mode 1 with 2 active background layers
5. Load background tiles, palette, and tilemap to VRAM/CGRAM via DMA
6. Load font tiles and palette to VRAM/CGRAM
7. Configure the main loop with VBlank synchronization
8. Produce a buildable ROM that displays the static background and text

## Context

### SNES PPU Architecture

The PPU (Picture Processing Unit) manages all video output:

**Video Modes**: Set via register $2105 (BGMODE)
- Mode 1: Three BG layers -- BG1 (16-color 4bpp), BG2 (16-color 4bpp), BG3 (4-color 2bpp)
- We use BG1 for the animated background and BG2 for text
- BG3 is unused

**VRAM** (64KB, addressed in 16-bit words = 32K words):
- Contains tile (character) data and tilemaps
- Addressed via $2116-$2117 (VMADDL/VMADDH) in 16-bit word units
- Data written via $2118-$2119 (VMDATAL/VMDATAH)
- DMA can transfer data to VRAM efficiently

**CGRAM** (512 bytes = 256 colors):
- Contains all palettes
- 15-bit color format: `0bbbbbgg gggrrrrr`
- Addressed via $2121 (CGADD) in color units (0-255)
- Written via $2122 (CGDATA), two bytes per color (low then high)

**OAM** (544 bytes for sprites -- unused in our demo)

### VRAM Memory Map (Our Layout)

```
Word Address  |  Size    | Contents
--------------+----------+---------------------------
$0000-$0FFF   | 4096W    | BG1 tile data (background, 4bpp)
$1000-$13FF   | 1024W    | BG1 tilemap (32x32 entries)
$1400-$17FF   | 1024W    | BG2 tilemap (32x32 entries)
$4000-$5FFF   | 8192W    | BG2 tile data (font, 4bpp)
```

This layout is set by PPU registers:
- BG1 tile base: `$2107` (BG1SC) -- tilemap address and size
- BG2 tile base: `$2108` (BG2SC) -- tilemap address and size
- BG12 character base: `$210B` (BG12NBA) -- tile data addresses for BG1 and BG2

### PPU Register Configuration

Key registers to set during initialization:

| Register | Address | Value | Purpose |
|----------|---------|-------|---------|
| INIDISP  | $2100   | $8F   | Force blank ON (bit 7), max brightness |
| BGMODE   | $2105   | $01   | Mode 1, 8x8 tiles |
| BG1SC    | $2107   | $10   | BG1 tilemap at VRAM $1000, 32x32 |
| BG2SC    | $2108   | $14   | BG2 tilemap at VRAM $1400, 32x32 |
| BG12NBA  | $210B   | $40   | BG1 tiles at $0000, BG2 tiles at $4000 |
| TM       | $212C   | $03   | Enable BG1 and BG2 on main screen |
| NMITIMEN | $4200   | $81   | Enable NMI (VBlank interrupt) and auto-joypad |
| INIDISP  | $2100   | $0F   | Force blank OFF, max brightness |

### DMA Transfers

DMA is used to efficiently copy large blocks of data to VRAM and CGRAM:

**DMA to VRAM**:
```c
// Set VRAM address
REG_VMADDL = addr & 0xFF;
REG_VMADDH = addr >> 8;

// Configure DMA channel 0
REG_DMAP0 = 0x01;    // Transfer mode: 2 registers, write twice (word write to $2118/$2119)
REG_BBAD0 = 0x18;    // Destination: VRAM data register ($2118)
REG_A1T0L = src & 0xFF;
REG_A1T0H = (src >> 8) & 0xFF;
REG_A1B0  = src >> 16;
REG_DAS0L = size & 0xFF;
REG_DAS0H = size >> 8;

// Execute DMA
REG_HDMAEN = 0x00;   // Disable HDMA first
REG_MDMAEN = 0x01;   // Start DMA on channel 0
```

PVSnesLib provides wrapper functions that handle this:
- `dmaCopyVram(source, vramAddr, size)` -- Copy data to VRAM
- `dmaCopyCGram(source, cgramAddr, size)` -- Copy data to CGRAM

### PVSnesLib API Functions

Key functions from the PVSnesLib SDK:

```c
// Initialization
void consoleInit(void);           // Initialize PPU to known state
void setMode(u8 mode, u8 size);  // Set BG mode

// Background setup
void bgSetGfxPtr(u8 bgNumber, u16 vramAddr);    // Set tile data address
void bgSetMapPtr(u8 bgNumber, u16 vramAddr, u8 mapSize);  // Set tilemap address
void bgInitTileSet(u8 bgNumber, u8 *tileSource, u8 *palSource,
                   u8 paletteEntry, u16 tileSize, u16 palSize,
                   u16 address);  // Load tiles + palette
void bgInitMapSet(u8 bgNumber, u8 *mapSource, u16 mapSize, u8 mapType);

// DMA
void dmaCopyVram(u8 *source, u16 address, u16 size);
void dmaCopyCGram(u8 *source, u16 address, u16 size);

// Video
void setScreenOn(void);          // Enable display
void WaitForVBlank(void);        // Wait for VBlank interrupt
void setBrightness(u8 level);    // Set screen brightness (0-15)
```

## Tasks

### Task 7.1: Update ROM Header (hdr.asm)

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\hdr.asm`

**Description**: Finalize the ROM header. If Phase 4's version is already correct, no changes are needed. Verify that:
- Memory map is LoROM
- ROM size is correct (4Mbit / 512KB)
- ROM title is "HELLO SNES WORLD"
- Interrupt vectors point to correct handlers
- The `tcc__start` reset vector matches PVSnesLib's C runtime entry point

**Implementation Details**:

Review the hdr.asm from Phase 4 against PVSnesLib's own example headers. The critical thing is that the header format matches exactly what wla-65816 and PVSnesLib expect.

After installing PVSnesLib, check the examples directory for reference headers:
```
J:\code\snes\snes-build-tools\tools\pvsneslib\pvsneslib\snes-examples\hello_world\hdr.asm
```

If the PVSnesLib example uses different syntax or directives, update our hdr.asm to match.

**Important**: PVSnesLib may include a default hdr.asm in its build process. Check `snes_rules` to see if it automatically includes a header. If so, our custom hdr.asm may need to be structured differently (possibly just overriding specific fields).

---

### Task 7.2: Finalize data.asm

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\data.asm`

**Description**: Update data.asm to ensure all `.incbin` paths are correct and labels match the C code's `extern` declarations.

**Code Example** (finalized version):

```asm
;==============================================================================
; Data Includes - Hello SNES World
; All binary asset data for tiles, palettes, and tilemaps
;==============================================================================

.include "hdr.asm"

.BANK 1 SLOT 0
.ORG 0
.SECTION "GfxData" SUPERFREE

;--- Background tiles (4bpp) ---
bg_tiles:
    .INCBIN "assets/backgrounds/bg_earthbound.pic"
bg_tiles_end:

;--- Background palette ---
bg_palette:
    .INCBIN "assets/backgrounds/bg_earthbound.pal"
bg_palette_end:

;--- Background tilemap ---
bg_map:
    .INCBIN "assets/backgrounds/bg_earthbound.map"
bg_map_end:

;--- Font tiles (4bpp) ---
font_tiles:
    .INCBIN "assets/fonts/font_large.pic"
font_tiles_end:

;--- Font palette ---
font_palette:
    .INCBIN "assets/fonts/font_large.pal"
font_palette_end:

.ENDS
```

**Note**: The `.include "hdr.asm"` at the top may or may not be needed depending on how PVSnesLib's build system works. Some PVSnesLib projects include the header in data.asm; others handle it in the Makefile/linker script. Check the SDK examples.

---

### Task 7.3: Write Complete main.c Initialization

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c`

**Description**: Replace the Phase 4 stub with the complete hardware initialization code. This file initializes the SNES, loads all graphics data, configures the PPU layers, and enters the main loop.

**Implementation Details**:

The initialization sequence:
1. Call `consoleInit()` to reset PPU to known state (force blank is ON)
2. Set video mode to Mode 1
3. Configure BG1 and BG2 tile data and tilemap VRAM addresses
4. DMA copy background tiles, palette, and tilemap to VRAM/CGRAM
5. DMA copy font tiles and palette to VRAM/CGRAM
6. Write font tilemap entries for "HELLO SNES WORLD" text
7. Enable BG1 and BG2 on the main screen
8. Turn off force blank (enable display)
9. Enter main loop: update animation, wait for VBlank

**Code Example**:

```c
/*
 * Hello SNES World - Main Source
 *
 * Displays an Earthbound-style animated background (BG1) with
 * "HELLO SNES WORLD" text (BG2) centered on screen.
 *
 * SNES Mode 1: BG1 = animated background, BG2 = text overlay
 */

#include <snes.h>

/* Include effect parameters and data tables */
#include "bg_effect.h"
#include "sine_table.h"
#include "font_tiles.h"
#include "text_layout.h"

/* ==========================================================================
 * External data labels (defined in data.asm)
 * ========================================================================== */
extern char bg_tiles, bg_tiles_end;
extern char bg_palette, bg_palette_end;
extern char bg_map, bg_map_end;
extern char font_tiles, font_tiles_end;
extern char font_palette, font_palette_end;

/* ==========================================================================
 * VRAM Layout Constants
 * ========================================================================== */

/* BG1 (background): tiles at word $0000, tilemap at word $1000 */
#define BG1_TILE_ADDR    0x0000
#define BG1_MAP_ADDR     0x1000

/* BG2 (text): tiles at word $4000, tilemap at word $1400 */
#define BG2_TILE_ADDR    0x4000
#define BG2_MAP_ADDR     0x1400

/* ==========================================================================
 * Global State
 * ========================================================================== */

/* Animation frame counter */
u16 tick = 0;

/* HDMA table for BG1 horizontal scroll (224 scanlines + terminator) */
/* Each entry: 1 byte count, 2 bytes scroll value (low, high) */
/* For continuous mode: bit 7 of count is set */
u8 hdma_scroll_table[224 * 3 + 1];

/* Background scroll position (for constant scrolling) */
u16 bg1_scroll_x = 0;
u16 bg1_scroll_y = 0;

/* Phase accumulator for sine wave animation */
u16 wave_phase = 0;

/* Palette cycling state */
u8 pal_cycle_counter = 0;
u8 pal_cycle_position = 0;

/* Working copy of background palette for cycling */
u16 bg_pal_buffer[16];

/* ==========================================================================
 * Function Prototypes
 * ========================================================================== */
void initGraphics(void);
void initBackground(void);
void initText(void);
void writeTextTilemap(const char *text, u8 startCol, u8 startRow);
void updateBackgroundAnimation(void);
void updateHDMATable(void);
void updatePaletteCycle(void);

/* ==========================================================================
 * Initialization
 * ========================================================================== */

void initGraphics(void) {
    /*
     * Initialize PPU and load all graphics data.
     * Called once at startup with force blank enabled.
     */

    /* Set Mode 1: BG1=4bpp, BG2=4bpp, BG3=2bpp (unused) */
    setMode(BG_MODE1, 0);

    /* Configure BG1: background layer */
    bgSetGfxPtr(0, BG1_TILE_ADDR);
    bgSetMapPtr(0, BG1_MAP_ADDR, SC_32x32);

    /* Configure BG2: text layer */
    bgSetGfxPtr(1, BG2_TILE_ADDR);
    bgSetMapPtr(1, BG2_MAP_ADDR, SC_32x32);

    /* Load background data */
    initBackground();

    /* Load font data and write text */
    initText();

    /* Enable BG1 and BG2 on main screen */
    setTileMapLocation(BG1_MAP_ADDR, SC_32x32, 0);
    setTileMapLocation(BG2_MAP_ADDR, SC_32x32, 1);

    /* Turn on BG1 and BG2 */
    REG_TM = 0x03;  /* Main screen: BG1 + BG2 */
}

void initBackground(void) {
    u16 tileSize = (u16)(&bg_tiles_end - &bg_tiles);
    u16 palSize  = (u16)(&bg_palette_end - &bg_palette);
    u16 mapSize  = (u16)(&bg_map_end - &bg_map);

    /* Copy background tiles to VRAM */
    dmaCopyVram((u8 *)&bg_tiles, BG1_TILE_ADDR, tileSize);

    /* Copy background palette to CGRAM (palette 0, starting at color 0) */
    dmaCopyCGram((u8 *)&bg_palette, 0, palSize);

    /* Copy background tilemap to VRAM */
    dmaCopyVram((u8 *)&bg_map, BG1_MAP_ADDR, mapSize);

    /* Initialize palette buffer for cycling */
    /* Copy the palette data into our working buffer */
    u16 i;
    u8 *palPtr = (u8 *)&bg_palette;
    for (i = 0; i < 16 && i * 2 < palSize; i++) {
        bg_pal_buffer[i] = palPtr[i * 2] | (palPtr[i * 2 + 1] << 8);
    }
}

void initText(void) {
    u16 tileSize = (u16)(&font_tiles_end - &font_tiles);
    u16 palSize  = (u16)(&font_palette_end - &font_palette);

    /* Copy font tiles to VRAM (BG2 tile area) */
    dmaCopyVram((u8 *)&font_tiles, BG2_TILE_ADDR, tileSize);

    /* Copy font palette to CGRAM (palette 1 = colors 16-31, byte offset 32) */
    dmaCopyCGram((u8 *)&font_palette, FONT_CGRAM_ADDR, palSize);

    /* Write tilemap entries for the text */
    writeTextTilemap(LINE1_TEXT, LINE1_COL_START, LINE1_ROW_START);
    writeTextTilemap(LINE2_TEXT, LINE2_COL_START, LINE2_ROW_START);
}

/* ==========================================================================
 * Text Tilemap Writer
 * ========================================================================== */

void writeTextTilemap(const char *text, u8 startCol, u8 startRow) {
    /*
     * Write tilemap entries for a line of text.
     * Each character is FONT_CHAR_TILES_W x FONT_CHAR_TILES_H tiles.
     *
     * Tilemap entry format (16 bits):
     *   VHOp pptt tttt tttt
     *   V = vertical flip
     *   H = horizontal flip
     *   O = priority (1 = in front of BG1)
     *   ppp = palette number (1 for font palette)
     *   tttttttttt = tile number
     */
    u16 col, tileRow, tileCol;
    u16 tilemapAddr;
    u16 tileIndex;
    u16 tilemapEntry;
    s16 charCol;
    u16 curCol = startCol;

    /* Set VRAM address increment mode (increment after writing high byte) */
    /* This is typically set by PVSnesLib init, but ensure it is correct */

    while (*text) {
        charCol = fontCharToCol(*text);

        if (charCol >= 0) {
            /* Write the tiles for this character */
            for (tileRow = 0; tileRow < FONT_CHAR_TILES_H; tileRow++) {
                for (tileCol = 0; tileCol < FONT_CHAR_TILES_W; tileCol++) {
                    /* Calculate tile index in the font spritesheet */
                    tileIndex = FONT_TILE(charCol, tileCol, tileRow);

                    /* Build tilemap entry */
                    /* Priority bit set (O=1) so text appears in front */
                    /* Palette 1 (ppp = 001) */
                    tilemapEntry = tileIndex
                        | (TEXT_TILE_PALETTE << 10)
                        | (TEXT_TILE_PRIORITY << 13);

                    /* Calculate VRAM address for this tilemap position */
                    /* Tilemap is 32 entries per row, 2 bytes per entry */
                    /* VRAM word address = base + row*32 + col */
                    tilemapAddr = BG2_MAP_ADDR
                        + (startRow + tileRow) * 32
                        + (curCol + tileCol);

                    /* Write to VRAM */
                    /* Use direct register writes since we need precise addressing */
                    REG_VMADDL = tilemapAddr & 0xFF;
                    REG_VMADDH = (tilemapAddr >> 8) & 0xFF;
                    REG_VMDATAL = tilemapEntry & 0xFF;
                    REG_VMDATAH = (tilemapEntry >> 8) & 0xFF;
                }
            }
        }
        /* Advance to next character position */
        curCol += FONT_CHAR_TILES_W;
        text++;
    }
}

/* ==========================================================================
 * Main Entry Point
 * ========================================================================== */

int main(void) {
    /* Initialize console (resets PPU, force blank ON) */
    consoleInit();

    /* Load all graphics and configure PPU */
    initGraphics();

    /* Enable screen at full brightness */
    setScreenOn();

    /* Main loop */
    while (1) {
        /* Update background animation (distortion + scroll + palette) */
        /* This will be implemented in Phase 8 */
        /* updateBackgroundAnimation(); */

        /* Wait for VBlank */
        WaitForVBlank();

        /* Increment animation counter */
        tick++;
    }

    return 0;
}
```

**Important Notes**:
- The actual PVSnesLib API may differ from what is shown above. After installation, check the SDK headers at `J:\code\snes\snes-build-tools\tools\pvsneslib\devkitsnes\include\snes\` for exact function signatures.
- Register names like `REG_VMADDL`, `REG_TM`, etc. are defined in PVSnesLib's `video.h` or equivalent header.
- The `writeTextTilemap` function writes directly to VRAM. On actual SNES hardware, VRAM writes should only happen during VBlank or force blank. Since we call this during initialization (force blank is on), this is safe.
- The animation functions (`updateBackgroundAnimation`, `updateHDMATable`, `updatePaletteCycle`) are stubs that will be implemented in Phase 8.

**References**:
- PVSnesLib API reference: Check headers in `$(PVSNESLIB_HOME)/devkitsnes/include/snes/`
- PVSnesLib examples: Check `$(PVSNESLIB_HOME)/pvsneslib/snes-examples/`
- SNES PPU register reference: https://snes.nesdev.org/wiki/PPU_Registers

---

### Task 7.4: Build and Test Static Display

**File(s)**: All project files (build output: `J:\code\snes\snes-build-tools\projects\hello-snes-world\hello_snes_world.sfc`)

**Description**: Build the ROM and verify it displays the static background and text. At this point, the background is not animated (that comes in Phase 8), but tiles, palettes, and tilemaps should be correctly loaded and visible.

**Implementation Details**:

```bash
cd J:\code\snes\snes-build-tools
call env.bat
cd projects\hello-snes-world
make clean
make
```

If the build succeeds, test in an emulator:
```bash
# If Mesen2 is installed:
..\..\tools\emulators\mesen2\Mesen.exe hello_snes_world.sfc

# Or open the .sfc file in any SNES emulator
```

Expected visual result:
- The background pattern should be visible (static, no animation yet)
- "HELLO SNES WORLD" text should be visible (may need palette/priority adjustments)
- If text is not visible, check: tile addresses, tilemap entries, palette index, priority bit

**Debugging checklist**:
1. Blank screen: Check initialization sequence, force blank toggling
2. Corrupted graphics: Check VRAM addresses, DMA sizes, tile format (4bpp vs 2bpp)
3. Wrong colors: Check CGRAM addresses, palette indices in tilemap entries
4. Text behind background: Check priority bits in tilemap entries
5. Build errors: Check extern label names match data.asm labels exactly

---

## Acceptance Criteria

- [ ] `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c` contains complete initialization code
- [ ] `J:\code\snes\snes-build-tools\projects\hello-snes-world\hdr.asm` is correct for LoROM
- [ ] `J:\code\snes\snes-build-tools\projects\hello-snes-world\data.asm` includes all asset binaries
- [ ] Running `make` produces `hello_snes_world.sfc`
- [ ] The ROM boots without crashing in Mesen2
- [ ] Background tiles are visible on BG1
- [ ] Font tiles are visible on BG2
- [ ] Text is readable and appears in front of the background
- [ ] No VRAM address conflicts between BG1 and BG2 data
- [ ] The ROM header passes validation (check with snestools or emulator ROM info)

## File Manifest

| File | Action | Description |
|------|--------|-------------|
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c` | REPLACE | Complete initialization code |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\hdr.asm` | VERIFY/UPDATE | ROM header (finalized) |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\data.asm` | VERIFY/UPDATE | Asset includes (finalized) |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\hello_snes_world.sfc` | GENERATE | Built ROM |

## Dependencies

- **Depends on**: Phase 1-6 (all previous phases)
- **Depended on by**: Phase 8 (animation extends the initialization), Phase 9 (text rendering builds on the display setup)
