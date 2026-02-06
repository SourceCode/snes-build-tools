# Phase 9: Text Rendering & Final Composition

## Overview

This phase brings together all components into the final ROM display: the animated Earthbound-style background on BG1 with the "HELLO SNES WORLD" text on BG2 overlaid on top. While the individual components were created in earlier phases, this phase focuses on the layer composition, ensuring text readability over the animated background, fine-tuning visual parameters, and resolving any integration issues.

This is the "polish" phase where the demo goes from technically functional to visually appealing.

## Prerequisites

- Phase 7 completed (hardware initialization, static display)
- Phase 8 completed (background animation engine)
- Phase 5 completed (font assets)
- All assets converted and data.asm finalized

## Objectives

1. Verify text renders correctly over the animated background
2. Ensure layer priority ordering (text always in front of background)
3. Fine-tune background effect parameters for visual appeal
4. Ensure font palette does not conflict with background palette cycling
5. Optimize final display for NTSC timing (256x224 visible area)
6. Create the final, complete main.c with all components integrated
7. Verify no visual artifacts (HDMA glitches, palette corruption, tile misalignment)

## Context

### Layer Composition on SNES Mode 1

In Mode 1, the layer priority order (back to front) is:

```
Back    BG3 (priority 0)
        BG2 (priority 0)
        BG1 (priority 0)
        BG3 (priority 1)
        BG2 (priority 1)     <-- Our text (priority bit set in tilemap)
        BG1 (priority 1)
Front   Sprites
```

By setting the priority bit in the BG2 tilemap entries (as done in Phase 7's `writeTextTilemap`), the text appears in front of BG1 regardless of BG1's priority settings.

However, there is a subtlety: If BG1 tilemap entries also have priority 1, they will appear in front of BG2 priority 0 tiles but behind BG2 priority 1 tiles. Our text has priority 1, so it will always appear in front of BG1 as long as the priority bit is set correctly.

### Palette Isolation

The font and background use separate palettes:
- BG1 (background): Palette 0 (CGRAM colors 0-15)
- BG2 (font): Palette 1 (CGRAM colors 16-31)

Palette cycling only modifies Palette 0 (colors 0-15), so the font colors (colors 16-31) remain stable. This is critical for text readability.

The tilemap entry for each font tile has `ppp = 001` (palette 1), directing the PPU to use colors 16-31 for text tiles.

### Text Readability

The font has a 4-pixel black outline specifically to ensure readability over any background. The outline creates sufficient contrast against both light and dark background colors. Key considerations:

1. **Transparent tiles**: Empty areas in the font tilemap show the background through. Text tiles with content block the background entirely (no alpha blending on SNES).
2. **Color 0 transparency**: Color 0 in any palette is transparent on SNES. The font's transparent pixels (color 0 of palette 1) will show BG1 through. Only the white fill and black outline pixels are opaque.
3. **No anti-aliasing**: SNES has no sub-pixel rendering. The 4px black border provides the visual equivalent of anti-aliasing by creating a transition zone.

### Centering Verification

From Phase 5, the text layout is:
```
Line 1: "HELLO SNES"  - 10 chars x 3 tiles = 30 tiles - start col 1
Line 2: "WORLD"        - 5 chars x 3 tiles = 15 tiles  - start col 8

Vertical: Line 1 rows 10-13, gap row 14, Line 2 rows 15-18
```

Screen visibility check (NTSC):
- Horizontal: Tiles 0-31 (columns), all visible at 256px
- Vertical: Tiles 0-27 (rows 0-27 = pixels 0-223)
- Line 1 at rows 10-13 = pixels 80-111: VISIBLE
- Line 2 at rows 15-18 = pixels 120-151: VISIBLE

Both lines are within the visible area with comfortable margins.

## Tasks

### Task 9.1: Create Final Integrated main.c

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c`

**Description**: Combine all code from Phases 7 and 8 into the final, complete main.c. This is the definitive version of the source file. All function prototypes, global state, initialization, animation engine, palette cycling, text rendering, and main loop are in this single file.

**Implementation Details**:

The complete file structure should be:

```c
/*
 * ============================================================================
 * Hello SNES World - Final ROM Source
 *
 * Displays "HELLO SNES WORLD" in large white pixel font with black border
 * over an Earthbound-style animated background with sine-wave distortion
 * and palette cycling.
 *
 * Technical: SNES Mode 1, BG1=animated background, BG2=text overlay
 *            HDMA-driven per-scanline horizontal scroll for wave effect
 *
 * Build: PVSnesLib SDK (816-tcc -> wla-65816 -> wlalink)
 * ============================================================================
 */

#include <snes.h>

/* Project headers */
#include "bg_effect.h"
#include "sine_table.h"
#include "font_tiles.h"
#include "text_layout.h"

/* --- External data (from data.asm) --- */
extern char bg_tiles, bg_tiles_end;
extern char bg_palette, bg_palette_end;
extern char bg_map, bg_map_end;
extern char font_tiles, font_tiles_end;
extern char font_palette, font_palette_end;

/* --- VRAM Layout --- */
#define BG1_TILE_ADDR    0x0000
#define BG1_MAP_ADDR     0x1000
#define BG2_TILE_ADDR    0x4000
#define BG2_MAP_ADDR     0x1400

/* --- Global Animation State --- */
u16 tick;
u16 wave_phase;
u16 bg_scroll_x;
u16 bg_scroll_y;
u8  cycle_countdown;
u8  cycle_count;
u16 original_palette[16];
u16 cycling_palette[16];
u8  hdma_table[224 * 3 + 1];

/* --- Function Prototypes --- */
void initGraphics(void);
void initBackground(void);
void initText(void);
void initPaletteCycle(void);
void writeTextLine(const char *text, u8 startCol, u8 startRow);
void setupHDMA(void);
void updateHDMATable(void);
void updatePaletteCycle(void);

/* =========================================================================
 * INITIALIZATION
 * ========================================================================= */

void initGraphics(void) {
    /* Set Mode 1 with 8x8 tiles */
    setMode(BG_MODE1, 0);

    /* Configure BG layer addresses */
    bgSetGfxPtr(0, BG1_TILE_ADDR);
    bgSetMapPtr(0, BG1_MAP_ADDR, SC_32x32);
    bgSetGfxPtr(1, BG2_TILE_ADDR);
    bgSetMapPtr(1, BG2_MAP_ADDR, SC_32x32);

    /* Load background data to VRAM/CGRAM */
    initBackground();

    /* Load font data and write text tilemaps */
    initText();

    /* Enable BG1 + BG2 on main screen */
    REG_TM = 0x03;
}

void initBackground(void) {
    u16 tileSize = (u16)(&bg_tiles_end - &bg_tiles);
    u16 palSize  = (u16)(&bg_palette_end - &bg_palette);
    u16 mapSize  = (u16)(&bg_map_end - &bg_map);

    dmaCopyVram((u8 *)&bg_tiles, BG1_TILE_ADDR, tileSize);
    dmaCopyCGram((u8 *)&bg_palette, 0, palSize);
    dmaCopyVram((u8 *)&bg_map, BG1_MAP_ADDR, mapSize);
}

void initText(void) {
    u16 tileSize = (u16)(&font_tiles_end - &font_tiles);
    u16 palSize  = (u16)(&font_palette_end - &font_palette);

    dmaCopyVram((u8 *)&font_tiles, BG2_TILE_ADDR, tileSize);
    dmaCopyCGram((u8 *)&font_palette, FONT_CGRAM_ADDR, palSize);

    /* Write text tilemap entries */
    writeTextLine(LINE1_TEXT, LINE1_COL_START, LINE1_ROW_START);
    writeTextLine(LINE2_TEXT, LINE2_COL_START, LINE2_ROW_START);
}

/* =========================================================================
 * TEXT TILEMAP WRITER
 * ========================================================================= */

void writeTextLine(const char *text, u8 startCol, u8 startRow) {
    u8 curCol = startCol;
    u16 tileRow, tileCol;
    u16 tileIndex, tilemapAddr, tilemapEntry;
    s16 charCol;

    while (*text) {
        charCol = fontCharToCol(*text);

        if (charCol >= 0) {
            for (tileRow = 0; tileRow < FONT_CHAR_TILES_H; tileRow++) {
                for (tileCol = 0; tileCol < FONT_CHAR_TILES_W; tileCol++) {
                    tileIndex = FONT_TILE(charCol, tileCol, tileRow);

                    tilemapEntry = tileIndex
                        | (TEXT_TILE_PALETTE << 10)
                        | (TEXT_TILE_PRIORITY << 13);

                    tilemapAddr = BG2_MAP_ADDR
                        + (startRow + tileRow) * 32
                        + (curCol + tileCol);

                    REG_VMADDL = tilemapAddr & 0xFF;
                    REG_VMADDH = (tilemapAddr >> 8) & 0xFF;
                    REG_VMDATAL = tilemapEntry & 0xFF;
                    REG_VMDATAH = (tilemapEntry >> 8) & 0xFF;
                }
            }
        }

        curCol += FONT_CHAR_TILES_W;
        text++;
    }
}

/* =========================================================================
 * PALETTE CYCLING ENGINE
 * Ported from palette_cycle.js Type 1 (forward rotation)
 * ========================================================================= */

void initPaletteCycle(void) {
    u8 i;
    u8 *palPtr = (u8 *)&bg_palette;
    for (i = 0; i < 16; i++) {
        original_palette[i] = palPtr[i * 2] | (palPtr[i * 2 + 1] << 8);
        cycling_palette[i] = original_palette[i];
    }
    cycle_countdown = PAL_CYCLE_SPEED;
    cycle_count = 0;
}

void updatePaletteCycle(void) {
    u8 i, cycleLength;
    u8 position;
    s8 newIdx;

    if (PAL_CYCLE_SPEED == 0) return;

    cycle_countdown--;
    if (cycle_countdown > 0) return;

    cycle_countdown = PAL_CYCLE_SPEED;
    cycle_count++;

    cycleLength = PAL_CYCLE_END - PAL_CYCLE_START + 1;
    position = cycle_count % cycleLength;

    for (i = PAL_CYCLE_START; i <= PAL_CYCLE_END; i++) {
        newIdx = (s8)(i - position);
        if (newIdx < PAL_CYCLE_START) {
            newIdx += cycleLength;
        }
        cycling_palette[i] = original_palette[newIdx];
    }

    dmaCopyCGram((u8 *)cycling_palette, 0, 32);
}

/* =========================================================================
 * HDMA BACKGROUND DISTORTION ENGINE
 * Ported from distorter.js getAppliedOffset() for HORIZONTAL type
 * ========================================================================= */

void setupHDMA(void) {
    updateHDMATable();

    /* HDMA Channel 1: write to BG1HOFS ($210D) per scanline */
    REG_DMAP1 = 0x02;       /* Mode 2: write twice to same register */
    REG_BBAD1 = 0x0D;       /* Target: $210D (BG1HOFS) */
    REG_A1T1L = (u16)hdma_table & 0xFF;
    REG_A1T1H = ((u16)hdma_table >> 8) & 0xFF;
    REG_A1B1  = 0x7E;       /* Source bank: WRAM */

    /* Enable HDMA channel 1 */
    REG_HDMAEN |= 0x02;
}

void updateHDMATable(void) {
    u16 y;
    u8  idx;
    s16 sine_val, offset, scroll_val;
    u16 pos = 0;
    u16 freq_accum = wave_phase;

    for (y = 0; y < 224; y++) {
        idx = (u8)(freq_accum >> 8);
        sine_val = (s16)sine_table[idx];
        offset = (sine_val * BG_WAVE_AMPLITUDE) >> 7;
        scroll_val = (s16)bg_scroll_x + offset;

        hdma_table[pos]     = 1;
        hdma_table[pos + 1] = (u8)(scroll_val & 0xFF);
        hdma_table[pos + 2] = (u8)(scroll_val >> 8);
        pos += 3;

        freq_accum += BG_WAVE_FREQ_FP8;
    }

    hdma_table[pos] = 0;
}

/* =========================================================================
 * MAIN
 * ========================================================================= */

int main(void) {
    /* --- Initialize --- */
    consoleInit();

    /* Reset state */
    tick = 0;
    wave_phase = 0;
    bg_scroll_x = 0;
    bg_scroll_y = 0;

    /* Load graphics and configure PPU */
    initGraphics();

    /* Set up animation systems */
    initPaletteCycle();
    setupHDMA();

    /* Turn on display */
    setScreenOn();

    /* --- Main Loop --- */
    while (1) {
        /* Advance animation state */
        wave_phase += BG_WAVE_SPEED_FP8;
        bg_scroll_y += BG_SCROLL_V_SPEED;

        /* Compute next frame's HDMA table (can run during active display) */
        updateHDMATable();

        /* Wait for VBlank */
        WaitForVBlank();

        /* --- VBlank work (time-critical) --- */

        /* Update palette (CGRAM write, must be in VBlank) */
        updatePaletteCycle();

        /* Update vertical scroll */
        REG_BG1VOFS = bg_scroll_y & 0xFF;
        REG_BG1VOFS = (bg_scroll_y >> 8) & 0xFF;

        /* Point HDMA to updated table */
        REG_A1T1L = (u16)hdma_table & 0xFF;
        REG_A1T1H = ((u16)hdma_table >> 8) & 0xFF;

        /* Increment frame counter */
        tick++;
    }

    return 0;
}
```

---

### Task 9.2: Visual Parameter Tuning

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\bg_effect.h`

**Description**: Fine-tune the background effect parameters to achieve the most visually appealing result. This is an iterative process: adjust values, rebuild, test in emulator, repeat.

**Implementation Details**:

Suggested parameter experiments:

| Parameter | Low | Medium | High | Visual Effect |
|-----------|-----|--------|------|---------------|
| `BG_WAVE_AMPLITUDE` | 2 | 8 | 16 | Width of wave displacement |
| `BG_WAVE_FREQ_FP8` | 128 | 291 | 512 | Number of wave crests on screen |
| `BG_WAVE_SPEED_FP8` | 128 | 384 | 768 | Animation speed |
| `PAL_CYCLE_SPEED` | 2 | 4 | 8 | How fast colors shift |
| `BG_SCROLL_V_SPEED` | 0 | 1 | 2 | Vertical drift speed |

Recommended starting point for a visually striking but smooth effect:
```c
#define BG_WAVE_AMPLITUDE   6     /* Moderate wave width */
#define BG_WAVE_FREQ_FP8    256   /* ~1 full cycle per screen */
#define BG_WAVE_SPEED_FP8   320   /* Moderate animation speed */
#define PAL_CYCLE_SPEED      3    /* Noticeable color shifting */
#define BG_SCROLL_V_SPEED    1    /* Gentle upward drift */
```

Test each combination by rebuilding and running in Mesen2:
```bash
cd J:\code\snes\snes-build-tools\projects\hello-snes-world
make
# Launch in emulator and evaluate
```

Look for:
- **Smoothness**: No jitter or stuttering in the wave animation
- **Readability**: Text remains easy to read over the moving background
- **Visual interest**: The effect is eye-catching without being distracting
- **No artifacts**: No glitching at screen edges, no HDMA timing issues

---

### Task 9.3: Verify Layer Ordering and Priority

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c`

**Description**: Verify that text tiles appear in front of background tiles. If text appears behind the background, adjust the priority bits.

**Implementation Details**:

In Mode 1, the default priority ordering (back to front) for tiles with priority bit = 0 is:
```
BG3 → BG2 → BG1
```

With priority bit = 1:
```
BG3(p0) → BG2(p0) → BG1(p0) → BG3(p1) → BG2(p1) → BG1(p1)
```

Our setup:
- BG1 tilemap entries: priority = 0 (background stays in back)
- BG2 tilemap entries: priority = 1 (text comes to front)

This means BG2 text (priority 1) appears in front of BG1 background (priority 0).

To verify, check the tilemap entry in `writeTextLine()`:
```c
tilemapEntry = tileIndex
    | (TEXT_TILE_PALETTE << 10)   /* Palette 1 */
    | (TEXT_TILE_PRIORITY << 13); /* Priority 1 -> bit 13 set */
```

With `TEXT_TILE_PRIORITY = 1`, bit 13 is set, placing text tiles at priority 1 level.

If text is still behind the background:
1. Check that `TEXT_TILE_PRIORITY` is actually 1 in `text_layout.h`
2. Check that BG1 tilemap entries do NOT have the priority bit set
3. Try toggling the Mode 1 BG3 priority bit in register $2105 (bit 3)
4. Use Mesen2's tile viewer to inspect actual tilemap entries in VRAM

---

### Task 9.4: Handle Edge Cases and Visual Artifacts

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c`

**Description**: Address potential visual artifacts that may appear during testing.

**Known Issues and Solutions**:

**Issue 1: HDMA glitch on first scanline**
The first visible scanline (line 1) may show incorrect scroll if HDMA is not initialized before the first frame.
- **Fix**: Initialize the HDMA table during force blank, before enabling the screen.

**Issue 2: Text palette corrupted by palette cycling**
If the font palette overlaps with the cycling range.
- **Fix**: Ensure `FONT_CGRAM_ADDR` (32) places font colors at palette 1 (colors 16-31), and cycling only modifies palette 0 (colors 0-15). Verify this in `updatePaletteCycle()`.

**Issue 3: Background wrapping artifacts**
When HDMA shifts a scanline, the background wraps horizontally. If the background pattern does not tile seamlessly, a seam may be visible.
- **Fix**: Ensure the background PNG tiles seamlessly. The 256x256 pixel source image wraps at 256 pixels both horizontally and vertically. Our horizontal bands naturally tile horizontally.

**Issue 4: HDMA table timing**
If the table is not fully written before the frame starts reading it, partial updates may cause glitches.
- **Fix**: Double-buffer the HDMA table, or ensure table generation completes before VBlank ends.

**Issue 5: BG2 tilemap not cleared**
Uninitialized BG2 tilemap entries may show garbage tiles.
- **Fix**: Clear the entire BG2 tilemap to tile 0 (transparent) before writing text entries:

```c
void clearBG2Tilemap(void) {
    u16 i;
    u16 addr = BG2_MAP_ADDR;

    for (i = 0; i < 1024; i++) {  /* 32x32 = 1024 entries */
        REG_VMADDL = addr & 0xFF;
        REG_VMADDH = (addr >> 8) & 0xFF;
        REG_VMDATAL = 0x00;
        REG_VMDATAH = 0x00;
        addr++;
    }
}
```

Call this in `initText()` before writing text entries. A more efficient approach uses DMA:

```c
void clearBG2Tilemap(void) {
    /* Fill BG2 tilemap with zeros (transparent empty tiles) */
    /* Use a small zero buffer and DMA it repeatedly, or use */
    /* the VRAM fill capability */
    u16 i;
    /* Set VRAM address */
    REG_VMADDL = BG2_MAP_ADDR & 0xFF;
    REG_VMADDH = (BG2_MAP_ADDR >> 8) & 0xFF;
    /* Write 2048 bytes of zeros (1024 entries * 2 bytes) */
    for (i = 0; i < 1024; i++) {
        REG_VMDATAL = 0x00;
        REG_VMDATAH = 0x00;
    }
}
```

---

### Task 9.5: Build and Visual Verification

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\hello_snes_world.sfc`

**Description**: Build the final ROM and verify all visual elements work together.

**Implementation Details**:

```bash
cd J:\code\snes\snes-build-tools\projects\hello-snes-world
call ..\..\env.bat
make clean
make
```

**Visual Verification Checklist** (test in Mesen2):

- [ ] Background is visible and fills the screen
- [ ] Background has a wavy/sine-wave distortion effect
- [ ] The wave animation is smooth and continuous
- [ ] Background colors cycle over time (smooth palette rotation)
- [ ] Background optionally scrolls vertically (slow drift)
- [ ] "HELLO SNES" text is visible on the upper portion of the screen
- [ ] "WORLD" text is visible on the lower portion, approximately centered
- [ ] Text has white fill with black outline, readable over the background
- [ ] Text does not move or distort (only BG1 is affected by HDMA)
- [ ] Text palette remains stable (not affected by palette cycling)
- [ ] No visible artifacts at screen edges
- [ ] No flickering or tearing
- [ ] ROM boots cleanly without graphical corruption during initialization

**Mesen2 Debugging Tools**:
- PPU Viewer: Inspect VRAM contents, see tile data and tilemaps
- Palette Viewer: Verify CGRAM colors and cycling
- Tilemap Viewer: Check BG1 and BG2 tilemap entries
- HDMA Status: Some debuggers show HDMA channel activity

---

### Task 9.6: Code Cleanup and Comments

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c`

**Description**: Final code cleanup. Ensure the source is well-commented, organized, and serves as a good example for other SNES developers.

**Implementation Details**:

Review the final main.c for:
1. **Comment quality**: Every function has a doc comment explaining purpose and parameters
2. **Constant documentation**: Magic numbers are replaced with named constants
3. **Section organization**: Code is grouped into logical sections with separator comments
4. **Reference attribution**: Comments reference the original JS source files for ported algorithms
5. **Build instructions**: File header includes brief build instructions
6. **No dead code**: Remove any debugging code, unused variables, or commented-out experiments
7. **Consistent style**: Consistent indentation, naming conventions, brace style

---

## Acceptance Criteria

- [ ] Final `main.c` compiles without warnings
- [ ] ROM builds successfully with `make`
- [ ] Background displays with sine-wave distortion animation
- [ ] Palette cycling is visible and smooth
- [ ] "HELLO SNES WORLD" text is centered and readable
- [ ] Text appears in front of the animated background
- [ ] Text palette is not affected by background palette cycling
- [ ] Animation runs at 60fps without frame drops
- [ ] No visual artifacts (tearing, glitches, corruption)
- [ ] BG2 tilemap is properly cleared (no garbage tiles visible)
- [ ] ROM runs correctly in Mesen2
- [ ] Code is well-commented and organized for readability

## File Manifest

| File | Action | Description |
|------|--------|-------------|
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c` | FINALIZE | Complete, final source file |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\bg_effect.h` | TUNE | Fine-tuned effect parameters |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\hello_snes_world.sfc` | GENERATE | Final built ROM |

## Dependencies

- **Depends on**: Phase 5 (font), Phase 6 (background), Phase 7 (init), Phase 8 (animation)
- **Depended on by**: Phase 10 (testing and documentation)
