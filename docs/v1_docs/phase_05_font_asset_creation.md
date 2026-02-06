# Phase 5: Font & Text Asset Creation

## Overview

This phase creates the large pixel font used to display "HELLO SNES WORLD" on screen. The font must be bold, visually striking, and readable over an animated background. Each character is rendered as white fill with a 4-pixel black outline/border, creating high contrast against any background.

The font is created as a PNG spritesheet, then converted to SNES 4bpp tile format using gfx4snes. A Python script generates the font PNG programmatically, ensuring pixel-perfect alignment to the 8x8 tile grid.

## Prerequisites

- Phase 1 completed (directory structure exists)
- Phase 3 completed (Python 3 + Pillow installed, gfx4snes available)
- Phase 4 completed (Makefile with font conversion rules)

## Objectives

1. Create a Python font generator script at `J:\code\snes\snes-build-tools\scripts\generate_font.py`
2. Generate a font PNG spritesheet at `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\fonts\font_large.png`
3. Convert the font PNG to SNES tile format (`.pic` and `.pal` files)
4. Document the tile mapping (which tile indices correspond to which characters)
5. Calculate the centered screen position for "HELLO SNES WORLD"

## Context

### SNES Tile Constraints

- Tiles are 8x8 pixels
- 4bpp mode = 16 colors per tile (including color 0 = transparent)
- A "large" character that is 32 pixels tall uses a 4-tile-high column
- A character that is 24 pixels wide uses a 3-tile-wide column
- The entire tileset for BG2 can hold up to 1024 tiles (but we share VRAM with BG1)

### Font Design Requirements

- Character height: 32 pixels (4 tiles tall) -- large and visually impactful
- Character width: 24 pixels (3 tiles wide) for most letters, variable for narrow letters
- Fill color: White (palette color index 1)
- Outline: 4-pixel black border (palette color index 2)
- Background: Transparent (palette color index 0)
- Required characters: H, E, L, O, S, N, W, R, D, space (10 unique + space)

### Font Palette

The font uses a simple 3-color palette:
- Color 0: Transparent (0x0000 in SNES format)
- Color 1: White fill (0x7FFF in SNES format = RGB 31,31,31)
- Color 2: Black outline (0x0000 in SNES format = RGB 0,0,0)
- Colors 3-15: Unused (set to 0x0000)

### Screen Positioning

- SNES resolution: 256x224 pixels
- Tilemap: 32x32 tiles (256x256 pixels, but only 256x224 visible)
- "HELLO SNES WORLD" = 16 characters (including spaces)
- At 24px per character width = 384px total. This exceeds 256px!

We have two options:
1. **Reduce character width to 16px (2 tiles)** -- 16 chars x 16px = 256px, fills screen
2. **Use smaller font (16px tall, 2 tiles)** -- still impactful, more room

Recommended: **24px wide x 32px tall characters** but split into two lines:
- Line 1: "HELLO SNES" (10 chars x 24px = 240px, fits with 8px margin)
- Line 2: "WORLD" (5 chars x 24px = 120px, centered)

Alternative: **16px wide x 32px tall characters** -- single line:
- "HELLO SNES WORLD" = 16 chars x 16px = 256px, exact fit

Let us go with the **two-line approach** (24x32 per character) for maximum visual impact.

### Centering Calculation (Two-Line Layout)

Line 1: "HELLO SNES" (10 characters)
- Total width: 10 x 24 = 240 pixels
- Left margin: (256 - 240) / 2 = 8 pixels = 1 tile
- Tile column start: 1

Line 2: "WORLD" (5 characters)
- Total width: 5 x 24 = 120 pixels
- Left margin: (256 - 120) / 2 = 68 pixels = 8 tiles + 4px
- Tile column start: 8 (closest tile boundary, 64px margin = slight left offset)
- Better: tile column 8.5 -- not possible. Use 9 tiles (72px margin).
- Actual: (256 - 120) / 2 = 68px. Nearest tile boundary: 8 tiles = 64px or 9 tiles = 72px.
- Use 8 tiles (64px). This gives a 4px sub-tile offset we cannot easily handle with tilemaps.
- Simplification: make each character 24px wide (3 tiles), so widths are tile-aligned.

Line 1: "HELLO SNES" = 10 chars x 3 tiles = 30 tiles. Start at tile col 1 (margin = 1 tile = 8px each side).
Line 2: "WORLD" = 5 chars x 3 tiles = 15 tiles. Start at tile col 8 (margin = 8.5 tiles each side; approximate by 8 tiles left = 64px, 15 tiles wide = 120px, right margin = 72px -- slightly off center).

Better centering for Line 2: Start at tile col 9 (72px left margin), 15 tiles = 120px, right margin = 64px. Still 8px off center. The best we can do with 8x8 tiles for a 120px wide block is tile 8 or 9.

Vertical centering:
- Screen height: 224 pixels = 28 tile rows (tiles 0-27 visible)
- Text block: 2 lines x 4 tiles = 8 tiles, plus 1-2 tile gap = 9-10 tiles total
- With 1-tile gap between lines: 9 tiles tall
- Top margin: (28 - 9) / 2 = 9.5 tiles. Start at tile row 9 or 10.
- Row 10 = pixel 80. Two lines of 4 tiles each with 1-tile gap:
  - Line 1: rows 10-13
  - Gap: row 14
  - Line 2: rows 15-18

## Tasks

### Task 5.1: Create Font Generator Python Script

**File(s)**: `J:\code\snes\snes-build-tools\scripts\generate_font.py`

**Description**: A Python script using Pillow that generates the font PNG spritesheet. Each character is rendered as a bold block letter with white fill and black outline, aligned to an 8x8 pixel grid.

**Implementation Details**:

The script:
1. Creates a PNG image sized to hold all unique character tiles
2. For each character, draws the letter shape using pixel-level operations
3. Applies a 4-pixel black outline around each white-filled letter
4. Arranges characters in a single row spritesheet (each char is 24x32 = 3x4 tiles)
5. Uses indexed color mode with the 3-color palette
6. Saves to the assets/fonts/ directory

The approach for rendering characters:
1. Draw each character as white pixels on a transparent background using a pixel font definition
2. Apply outline by scanning all pixels: for each transparent pixel that is adjacent (within 4px) to a white pixel, set it to black
3. The result is white letters with thick black borders

**Code Example**:

```python
#!/usr/bin/env python3
"""
Font Generator for SNES Hello World Demo
Generates a large pixel font spritesheet aligned to 8x8 SNES tile grid.

Output: A PNG file with indexed colors (3 colors: transparent, white, black)
Each character is 24x32 pixels (3 tiles wide x 4 tiles tall).

Usage:
    python generate_font.py [output_path]
    Default output: ../projects/hello-snes-world/assets/fonts/font_large.png
"""

import sys
import os
from PIL import Image, ImageDraw

# --- Configuration ---
TILE_SIZE = 8
CHAR_WIDTH_TILES = 3    # Each character is 3 tiles wide
CHAR_HEIGHT_TILES = 4   # Each character is 4 tiles tall
CHAR_WIDTH = CHAR_WIDTH_TILES * TILE_SIZE   # 24 pixels
CHAR_HEIGHT = CHAR_HEIGHT_TILES * TILE_SIZE  # 32 pixels
OUTLINE_WIDTH = 4        # 4-pixel black outline

# Colors (RGB tuples)
COLOR_TRANSPARENT = (0, 0, 0, 0)   # Index 0: Transparent (will be magenta in PNG for gfx4snes)
COLOR_WHITE = (255, 255, 255, 255)  # Index 1: White fill
COLOR_BLACK = (0, 0, 0, 255)       # Index 2: Black outline
COLOR_MAGENTA = (255, 0, 255, 255) # Transparent key color for gfx4snes

# Characters we need (in order in the spritesheet)
CHARSET = "HELLOSNSWRD "
# Unique characters: H, E, L, O, S, N, W, R, D, space
# We include duplicates in the string to match tile ordering if needed
UNIQUE_CHARS = list(dict.fromkeys(CHARSET))  # Preserves order, removes dupes

# --- Pixel Font Definitions ---
# Each character is defined as a grid of 1s and 0s
# Grid is 12x16 "fat pixels" (each fat pixel = 2x2 actual pixels to fill 24x32)
# 1 = filled (white), 0 = empty (transparent)
# After rendering, we apply the outline

FONT_DATA = {
    'H': [
        "100001",
        "100001",
        "100001",
        "100001",
        "111111",
        "111111",
        "100001",
        "100001",
        "100001",
        "100001",
        "100001",
        "100001",
    ],
    'E': [
        "111111",
        "111111",
        "100000",
        "100000",
        "111110",
        "111110",
        "100000",
        "100000",
        "100000",
        "100000",
        "111111",
        "111111",
    ],
    'L': [
        "100000",
        "100000",
        "100000",
        "100000",
        "100000",
        "100000",
        "100000",
        "100000",
        "100000",
        "100000",
        "111111",
        "111111",
    ],
    'O': [
        "011110",
        "111111",
        "110011",
        "100001",
        "100001",
        "100001",
        "100001",
        "100001",
        "110011",
        "111111",
        "011110",
        "011110",
    ],
    'S': [
        "011111",
        "111111",
        "110000",
        "110000",
        "011110",
        "001111",
        "000011",
        "000011",
        "000011",
        "100011",
        "111111",
        "111110",
    ],
    'N': [
        "100001",
        "110001",
        "111001",
        "111001",
        "101101",
        "101101",
        "100111",
        "100111",
        "100011",
        "100011",
        "100001",
        "100001",
    ],
    'W': [
        "100001",
        "100001",
        "100001",
        "100001",
        "100001",
        "100001",
        "101101",
        "101101",
        "101101",
        "111111",
        "110011",
        "110011",
    ],
    'R': [
        "111110",
        "111111",
        "100011",
        "100011",
        "100011",
        "111111",
        "111110",
        "101100",
        "100110",
        "100011",
        "100001",
        "100001",
    ],
    'D': [
        "111100",
        "111110",
        "100111",
        "100011",
        "100001",
        "100001",
        "100001",
        "100001",
        "100011",
        "100111",
        "111110",
        "111100",
    ],
    ' ': [
        "000000",
        "000000",
        "000000",
        "000000",
        "000000",
        "000000",
        "000000",
        "000000",
        "000000",
        "000000",
        "000000",
        "000000",
    ],
}


def render_character(char_data, scale=2):
    """
    Render a character from its font data definition into a pixel grid.
    Each '1' in the font data becomes a scale x scale block of white pixels.
    Returns a 2D list of pixel values (0=transparent, 1=white).
    """
    rows = len(char_data)
    cols = len(char_data[0])
    width = cols * scale
    height = rows * scale

    # Pad to CHAR_WIDTH x CHAR_HEIGHT
    grid = [[0] * CHAR_WIDTH for _ in range(CHAR_HEIGHT)]

    # Center the character data in the grid
    x_offset = (CHAR_WIDTH - width) // 2
    y_offset = (CHAR_HEIGHT - height) // 2

    for row_idx, row_str in enumerate(char_data):
        for col_idx, ch in enumerate(row_str):
            if ch == '1':
                for dy in range(scale):
                    for dx in range(scale):
                        px = x_offset + col_idx * scale + dx
                        py = y_offset + row_idx * scale + dy
                        if 0 <= px < CHAR_WIDTH and 0 <= py < CHAR_HEIGHT:
                            grid[py][px] = 1

    return grid


def apply_outline(grid, outline_width=4):
    """
    Apply a black outline around all white pixels.
    For each transparent pixel, if any white pixel is within outline_width
    distance (using Chebyshev / chess-king distance), set it to black (2).
    """
    height = len(grid)
    width = len(grid[0])
    result = [row[:] for row in grid]  # Deep copy

    for y in range(height):
        for x in range(width):
            if grid[y][x] == 0:  # Transparent pixel
                # Check if any white pixel is within outline_width
                found = False
                for dy in range(-outline_width, outline_width + 1):
                    for dx in range(-outline_width, outline_width + 1):
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < height and 0 <= nx < width:
                            if grid[ny][nx] == 1:
                                found = True
                                break
                    if found:
                        break
                if found:
                    result[y][x] = 2  # Black outline

    return result


def create_spritesheet(output_path):
    """
    Create the full font spritesheet PNG.
    Characters are arranged in a single row.
    """
    num_chars = len(UNIQUE_CHARS)
    sheet_width = num_chars * CHAR_WIDTH
    sheet_height = CHAR_HEIGHT

    # Ensure dimensions are multiples of 8 (tile-aligned)
    sheet_width = ((sheet_width + 7) // 8) * 8
    sheet_height = ((sheet_height + 7) // 8) * 8

    # Create RGBA image with magenta background (transparency key for gfx4snes)
    img = Image.new('RGBA', (sheet_width, sheet_height), COLOR_MAGENTA)

    for idx, char in enumerate(UNIQUE_CHARS):
        if char not in FONT_DATA:
            print(f"Warning: No font data for character '{char}', skipping.")
            continue

        # Render character
        grid = render_character(FONT_DATA[char])
        # Apply outline
        grid = apply_outline(grid, OUTLINE_WIDTH)

        # Draw to image
        x_base = idx * CHAR_WIDTH
        for y in range(CHAR_HEIGHT):
            for x in range(CHAR_WIDTH):
                px = x_base + x
                if px < sheet_width and y < sheet_height:
                    val = grid[y][x]
                    if val == 0:
                        img.putpixel((px, y), COLOR_MAGENTA)   # Transparent
                    elif val == 1:
                        img.putpixel((px, y), COLOR_WHITE)     # White fill
                    elif val == 2:
                        img.putpixel((px, y), COLOR_BLACK)     # Black outline

    # Convert to indexed color (palette mode) for gfx4snes compatibility
    # gfx4snes expects indexed PNG or will do its own quantization
    # For best results, keep as RGBA and let gfx4snes handle the palette

    img.save(output_path)
    print(f"Font spritesheet saved to: {output_path}")
    print(f"  Size: {sheet_width}x{sheet_height} pixels")
    print(f"  Characters: {len(UNIQUE_CHARS)} unique ({', '.join(UNIQUE_CHARS)})")
    print(f"  Tiles per character: {CHAR_WIDTH_TILES}x{CHAR_HEIGHT_TILES}")
    print(f"  Total tiles: {(sheet_width // 8) * (sheet_height // 8)}")

    # Print tile index mapping
    print("\n  Character tile mapping:")
    for idx, char in enumerate(UNIQUE_CHARS):
        first_tile = idx * CHAR_WIDTH_TILES
        tile_range = f"{first_tile}-{first_tile + CHAR_WIDTH_TILES - 1}"
        display_char = "SPACE" if char == ' ' else char
        print(f"    '{display_char}': tiles {tile_range} (column of {CHAR_HEIGHT_TILES} rows)")


if __name__ == '__main__':
    # Default output path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    default_output = os.path.join(
        repo_root, 'projects', 'hello-snes-world',
        'assets', 'fonts', 'font_large.png'
    )

    output_path = sys.argv[1] if len(sys.argv) > 1 else default_output

    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    create_spritesheet(output_path)
```

**References**:
- Pillow documentation: https://pillow.readthedocs.io/
- gfx4snes PNG input requirements: Check `gfx4snes --help` after SDK installation

---

### Task 5.2: Run Font Generator

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\fonts\font_large.png`

**Description**: Execute the font generator script to produce the actual PNG file.

**Implementation Details**:

```bash
cd J:\code\snes\snes-build-tools
python scripts\generate_font.py
```

Verify the output:
- File exists at `projects\hello-snes-world\assets\fonts\font_large.png`
- Image dimensions are a multiple of 8 in both directions
- Image contains the correct characters visually (open in an image viewer)
- Colors are correct: white fill, black outline, magenta/transparent background

---

### Task 5.3: Convert Font PNG to SNES Format

**File(s)**:
- `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\fonts\font_large.pic` (tiles)
- `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\fonts\font_large.pal` (palette)

**Description**: Use gfx4snes to convert the font PNG into SNES 4bpp tile data and palette.

**Implementation Details**:

```bash
cd J:\code\snes\snes-build-tools\projects\hello-snes-world

# Set up environment
call ..\..\env.bat

# Convert font
gfx4snes -i assets/fonts/font_large.png -o assets/fonts/font_large -p -t -s 8 -b 4 -R
```

The `-R` flag enables tile reduction (removing duplicate tiles). Since our font has lots of repeated empty/outline tiles, this significantly reduces VRAM usage.

After conversion, verify:
- `font_large.pic` exists and is non-empty
- `font_large.pal` exists and is 32 bytes (16 colors x 2 bytes each for 4bpp)

---

### Task 5.4: Create Tile Mapping Header

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\font_tiles.h`

**Description**: Create a C header file that maps character ASCII values to tile indices in the converted font spritesheet. This header is used by the text rendering code in Phase 9.

**Implementation Details**:

After gfx4snes processes the font, tile indices are assigned sequentially from left to right, top to bottom in the spritesheet. With tile reduction (`-R`), some tiles may be merged. The exact tile indices depend on the gfx4snes output.

This header provides a lookup mechanism: given a character, return the tile indices needed to render it.

**Code Example**:

```c
/*
 * Font Tile Mapping - Auto-generated from font_large.png
 * Each character is 3 tiles wide x 4 tiles tall (24x32 pixels)
 *
 * The font spritesheet arranges characters left to right:
 * H, E, L, O, S, N, W, R, D, SPACE
 *
 * Tile indices assume sequential layout WITHOUT tile reduction.
 * If gfx4snes -R changes tile indices, this file must be updated
 * to match the actual .pic output.
 *
 * NOTE: After running gfx4snes with -R, inspect the output to verify
 * tile indices. If tile reduction merges identical tiles, you may need
 * to manually adjust these mappings or regenerate without -R.
 */

#ifndef FONT_TILES_H
#define FONT_TILES_H

#include <snes.h>

/* Number of tiles per character (width x height) */
#define FONT_CHAR_TILES_W  3
#define FONT_CHAR_TILES_H  4
#define FONT_CHAR_TILES    (FONT_CHAR_TILES_W * FONT_CHAR_TILES_H)  /* 12 tiles per char */

/* Total unique characters in font */
#define FONT_NUM_CHARS     10

/* Character width/height in pixels */
#define FONT_CHAR_PX_W     24
#define FONT_CHAR_PX_H     32

/*
 * Tile index for the first tile of each character.
 * Characters are arranged in a row in the spritesheet.
 * Tiles are numbered left-to-right, then top-to-bottom within
 * the spritesheet.
 *
 * Spritesheet layout (tiles):
 * Row 0: H[0-2] E[3-5] L[6-8] O[9-11] S[12-14] N[15-17] W[18-20] R[21-23] D[24-26] SP[27-29]
 * Row 1: H[30-32] E[33-35] ...
 * Row 2: H[60-62] ...
 * Row 3: H[90-92] ...
 *
 * BUT gfx4snes tiles are numbered column-by-column within each 8x8 grid,
 * laid out in the order they appear in the image data.
 *
 * The actual tile layout depends on gfx4snes output format.
 * Spritesheet width in tiles: num_chars * 3 = 30 tiles wide
 * Spritesheet height in tiles: 4 tiles tall
 * Total tiles (before reduction): 30 * 4 = 120
 *
 * Tile numbering (row-major for a 30-wide x 4-tall sheet):
 * Row 0: tiles 0..29
 * Row 1: tiles 30..59
 * Row 2: tiles 60..89
 * Row 3: tiles 90..119
 */

/* Starting tile index for each character (first tile in top-left) */
/* Character 'H' occupies tiles at columns 0-2, rows 0-3 */
/* With row-major ordering: tile(col, row) = row * 30 + col */
#define FONT_SHEET_COLS  30  /* Total columns in spritesheet */

/* Character column offsets in the spritesheet */
#define CHAR_H_COL    0
#define CHAR_E_COL    3
#define CHAR_L_COL    6
#define CHAR_O_COL    9
#define CHAR_S_COL   12
#define CHAR_N_COL   15
#define CHAR_W_COL   18
#define CHAR_R_COL   21
#define CHAR_D_COL   24
#define CHAR_SP_COL  27

/*
 * Get the tile index for a specific position within a character.
 * col_in_char: 0-2 (horizontal tile within character)
 * row_in_char: 0-3 (vertical tile within character)
 * char_col_offset: the starting column of the character
 */
#define FONT_TILE(char_col, tc, tr) \
    ((tr) * FONT_SHEET_COLS + (char_col) + (tc))

/*
 * Lookup table: ASCII character -> column offset in spritesheet
 * Returns -1 for unsupported characters
 */
static inline s16 fontCharToCol(char c) {
    switch (c) {
        case 'H': return CHAR_H_COL;
        case 'E': return CHAR_E_COL;
        case 'L': return CHAR_L_COL;
        case 'O': return CHAR_O_COL;
        case 'S': return CHAR_S_COL;
        case 'N': return CHAR_N_COL;
        case 'W': return CHAR_W_COL;
        case 'R': return CHAR_R_COL;
        case 'D': return CHAR_D_COL;
        case ' ': return CHAR_SP_COL;
        default:  return -1;
    }
}

#endif /* FONT_TILES_H */
```

**Important Note**: The tile numbering in this header is theoretical. After actually running gfx4snes in Task 5.3, examine the output `.pic` file size and verify tile indices match expectations. If gfx4snes uses a different tile ordering (e.g., 8x8 blocks within larger metatile blocks), this header must be adjusted accordingly.

**References**:
- SNES tilemap format: https://snes.nesdev.org/wiki/Tilemaps
- gfx4snes tile output order: Inspect generated files or check gfx4snes source

---

### Task 5.5: Create Text Layout Constants

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\text_layout.h`

**Description**: Define the exact screen positions where "HELLO SNES WORLD" text will be placed, expressed as tilemap coordinates.

**Code Example**:

```c
/*
 * Text Layout Constants - Screen positioning for "HELLO SNES WORLD"
 *
 * Screen: 256x224 pixels = 32x28 visible tile columns/rows
 * Tilemap: 32x32 entries (but only 32x28 are visible on NTSC)
 *
 * Text layout (two lines):
 *   Line 1: "HELLO SNES" (10 chars x 3 tiles = 30 tiles wide)
 *           Start at tile column 1, giving 8px left margin
 *   Line 2: "WORLD"      (5 chars x 3 tiles = 15 tiles wide)
 *           Start at tile column 8, approximately centered
 *
 * Vertical layout:
 *   Line 1 top: tile row 10 (pixel 80)
 *   Line 1 bottom: tile row 13 (pixel 111)
 *   Gap: tile row 14 (8 pixels)
 *   Line 2 top: tile row 15 (pixel 120)
 *   Line 2 bottom: tile row 18 (pixel 151)
 *   Total block: rows 10-18 = 9 tile rows = 72 pixels
 *   Centered in 224px: (224-72)/2 = 76px = row ~9.5, using row 10
 */

#ifndef TEXT_LAYOUT_H
#define TEXT_LAYOUT_H

/* Tilemap dimensions */
#define TILEMAP_COLS     32
#define TILEMAP_ROWS     32
#define VISIBLE_ROWS     28    /* NTSC visible rows */

/* Line 1: "HELLO SNES" */
#define LINE1_TEXT       "HELLO SNES"
#define LINE1_NUM_CHARS  10
#define LINE1_COL_START  1     /* Tile column to start Line 1 */
#define LINE1_ROW_START  10    /* Tile row to start Line 1 */

/* Line 2: "WORLD" */
#define LINE2_TEXT       "WORLD"
#define LINE2_NUM_CHARS  5
#define LINE2_COL_START  8     /* Tile column to start Line 2 (approximately centered) */
#define LINE2_ROW_START  15    /* Tile row to start Line 2 (line1 + 4 char height + 1 gap) */

/* Tile priority for text layer (BG2 should have higher priority than BG1) */
#define TEXT_TILE_PRIORITY  1
#define TEXT_TILE_PALETTE   1  /* Palette index for font (set in CGRAM) */

/* VRAM address for font tiles (BG2 character data) */
/* BG1 tiles at VRAM word address 0x0000 (backgrounds) */
/* BG2 tiles at VRAM word address 0x4000 (font) */
#define FONT_VRAM_ADDR      0x4000

/* VRAM address for BG2 tilemap */
/* BG1 tilemap at VRAM word address 0x1000 */
/* BG2 tilemap at VRAM word address 0x1400 */
#define TEXT_TILEMAP_VRAM   0x1400

/* Palette CGRAM address for font */
/* BG1 palette: colors 0-15 (CGRAM bytes 0-31) */
/* Font palette: colors 16-31 (CGRAM bytes 32-63), i.e., palette 1 */
#define FONT_CGRAM_ADDR     32    /* Byte offset in CGRAM */

#endif /* TEXT_LAYOUT_H */
```

**Important Note**: The VRAM addresses above are estimates. They must be coordinated with Phase 8 (background engine) to avoid overlapping VRAM allocations. The final VRAM layout will be determined in Phase 7 during hardware initialization.

---

## Acceptance Criteria

- [ ] `J:\code\snes\snes-build-tools\scripts\generate_font.py` exists and runs without errors
- [ ] Running the script produces `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\fonts\font_large.png`
- [ ] The PNG has correct dimensions (multiple of 8 in both axes)
- [ ] The PNG contains visible white letters with black outlines on magenta background
- [ ] All required characters (H, E, L, O, S, N, W, R, D, space) are present
- [ ] After gfx4snes conversion, `font_large.pic` and `font_large.pal` exist
- [ ] `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\font_tiles.h` exists with tile mapping
- [ ] `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\text_layout.h` exists with screen positions
- [ ] The tile mapping in font_tiles.h is consistent with gfx4snes output

## File Manifest

| File | Action | Description |
|------|--------|-------------|
| `J:\code\snes\snes-build-tools\scripts\generate_font.py` | CREATE | Font PNG generator script |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\fonts\font_large.png` | GENERATE | Font spritesheet PNG |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\fonts\font_large.pic` | GENERATE | SNES tile data (from gfx4snes) |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\fonts\font_large.pal` | GENERATE | SNES palette (from gfx4snes) |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\font_tiles.h` | CREATE | Tile index mapping header |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\text_layout.h` | CREATE | Screen layout constants |

## Dependencies

- **Depends on**: Phase 1 (directories), Phase 3 (Python + Pillow + gfx4snes installed), Phase 4 (Makefile has font conversion rules)
- **Depended on by**: Phase 9 (text rendering uses font tiles and layout constants)
