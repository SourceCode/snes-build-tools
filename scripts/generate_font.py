#!/usr/bin/env python3
"""
Font Generator for SNES Hello World Demo

Generates a large pixel font spritesheet aligned to 8x8 SNES tile grid.
Output: Indexed-color PNG (3 colors: transparent/magenta, white fill, black outline).
Each character is 24x32 pixels (3 tiles wide x 4 tiles tall).

Usage:
    python generate_font.py [output_path]
    Default output: ../projects/hello-snes-world/assets/fonts/font_large.png
"""

import sys
import os
from PIL import Image

# --- Configuration ---
TILE_SIZE = 8
CHAR_WIDTH_TILES = 3
CHAR_HEIGHT_TILES = 4
CHAR_WIDTH = CHAR_WIDTH_TILES * TILE_SIZE   # 24 pixels
CHAR_HEIGHT = CHAR_HEIGHT_TILES * TILE_SIZE  # 32 pixels
SCALE = 2           # Each grid cell becomes SCALE x SCALE pixels
OUTLINE_WIDTH = 3   # Outline thickness in pixels

# Palette indices
IDX_TRANSPARENT = 0
IDX_WHITE = 1
IDX_BLACK = 2

# Characters needed for "HELLO SNES" + "WORLD"
UNIQUE_CHARS = ['H', 'E', 'L', 'O', 'S', 'N', 'W', 'R', 'D', ' ']

# --- Block Font Definitions ---
# Each character: 8 columns x 12 rows grid. Scale 2 -> 16x24 body centered in 24x32.
# 1 = white fill, 0 = transparent. Outline is applied algorithmically.
FONT_DATA = {
    'H': [
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "11111111",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
    ],
    'E': [
        "11111111",
        "10000000",
        "10000000",
        "10000000",
        "10000000",
        "11111100",
        "10000000",
        "10000000",
        "10000000",
        "10000000",
        "10000000",
        "11111111",
    ],
    'L': [
        "10000000",
        "10000000",
        "10000000",
        "10000000",
        "10000000",
        "10000000",
        "10000000",
        "10000000",
        "10000000",
        "10000000",
        "10000000",
        "11111111",
    ],
    'O': [
        "01111110",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "01111110",
    ],
    'S': [
        "01111110",
        "10000001",
        "10000000",
        "10000000",
        "01111110",
        "00000001",
        "00000001",
        "00000001",
        "00000001",
        "00000001",
        "10000001",
        "01111110",
    ],
    'N': [
        "10000001",
        "11000001",
        "11000001",
        "10100001",
        "10100001",
        "10010001",
        "10010001",
        "10001001",
        "10001001",
        "10000101",
        "10000011",
        "10000001",
    ],
    'W': [
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10010001",
        "10010001",
        "10101001",
        "10101001",
        "11111111",
        "01000010",
    ],
    'R': [
        "11111100",
        "10000010",
        "10000010",
        "10000010",
        "10000010",
        "11111100",
        "10010000",
        "10001000",
        "10000100",
        "10000010",
        "10000001",
        "10000001",
    ],
    'D': [
        "11111100",
        "10000010",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000001",
        "10000010",
        "11111100",
    ],
    ' ': [
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
        "00000000",
    ],
}


def render_character(char_data):
    """Render character grid at SCALE into a CHAR_WIDTH x CHAR_HEIGHT cell.
    Returns 2D list: 1=white, 0=transparent."""
    grid_rows = len(char_data)
    grid_cols = len(char_data[0])
    body_w = grid_cols * SCALE
    body_h = grid_rows * SCALE
    x_off = (CHAR_WIDTH - body_w) // 2
    y_off = (CHAR_HEIGHT - body_h) // 2

    cell = [[0] * CHAR_WIDTH for _ in range(CHAR_HEIGHT)]
    for r, row_str in enumerate(char_data):
        for c, ch in enumerate(row_str):
            if ch == '1':
                for dy in range(SCALE):
                    for dx in range(SCALE):
                        px = x_off + c * SCALE + dx
                        py = y_off + r * SCALE + dy
                        if 0 <= px < CHAR_WIDTH and 0 <= py < CHAR_HEIGHT:
                            cell[py][px] = 1
    return cell


def apply_outline(cell, width):
    """For each transparent pixel near a white pixel (Chebyshev distance <= width),
    set it to 2 (black outline). Returns new grid with values 0/1/2."""
    h = len(cell)
    w_px = len(cell[0])
    result = [row[:] for row in cell]

    for y in range(h):
        for x in range(w_px):
            if cell[y][x] == 0:
                found = False
                for dy in range(-width, width + 1):
                    if found:
                        break
                    for dx in range(-width, width + 1):
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < h and 0 <= nx < w_px and cell[ny][nx] == 1:
                            found = True
                            break
                if found:
                    result[y][x] = 2
    return result


def create_spritesheet(output_path):
    """Create the indexed-color font spritesheet PNG."""
    num_chars = len(UNIQUE_CHARS)
    sheet_w = num_chars * CHAR_WIDTH   # 240
    sheet_h = CHAR_HEIGHT              # 32

    # Tile-align (both already multiples of 8)
    sheet_w = ((sheet_w + 7) // 8) * 8
    sheet_h = ((sheet_h + 7) // 8) * 8

    # Create indexed-color image
    img = Image.new('P', (sheet_w, sheet_h), IDX_TRANSPARENT)

    # Set palette: 0=magenta(transparent), 1=white, 2=black
    palette = [0] * 768
    palette[0:3] = [255, 0, 255]      # magenta
    palette[3:6] = [255, 255, 255]    # white
    palette[6:9] = [0, 0, 0]          # black
    img.putpalette(palette)

    pixels = img.load()

    for idx, ch in enumerate(UNIQUE_CHARS):
        char_data = FONT_DATA.get(ch)
        if not char_data:
            print(f"Warning: No font data for '{ch}', skipping.")
            continue

        cell = render_character(char_data)
        cell = apply_outline(cell, OUTLINE_WIDTH)

        x_base = idx * CHAR_WIDTH
        for y in range(CHAR_HEIGHT):
            for x in range(CHAR_WIDTH):
                px = x_base + x
                if px < sheet_w:
                    pixels[px, y] = cell[y][x]

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)

    # Print results
    total_tile_cols = sheet_w // TILE_SIZE
    total_tile_rows = sheet_h // TILE_SIZE
    total_tiles = total_tile_cols * total_tile_rows
    tiles_per_char = CHAR_WIDTH_TILES * CHAR_HEIGHT_TILES

    print(f"Font spritesheet saved to: {output_path}")
    print(f"  Image size: {sheet_w}x{sheet_h} pixels")
    print(f"  Characters: {num_chars} unique")
    print(f"  Char cell:  {CHAR_WIDTH}x{CHAR_HEIGHT} px ({CHAR_WIDTH_TILES}x{CHAR_HEIGHT_TILES} tiles)")
    print(f"  Sheet tiles: {total_tile_cols}x{total_tile_rows} = {total_tiles} total")
    print(f"  Tiles per char: {tiles_per_char}")
    print()
    print("  Tile mapping (row-major, sheet is {} cols wide):".format(total_tile_cols))
    for i, ch in enumerate(UNIQUE_CHARS):
        col_start = i * CHAR_WIDTH_TILES
        name = "SPACE" if ch == ' ' else ch
        print(f"    '{name}': start col {col_start}, "
              f"tiles [{col_start}..{col_start + CHAR_WIDTH_TILES - 1}] x 4 rows")


if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    default_output = os.path.join(
        repo_root, 'projects', 'hello-snes-world',
        'assets', 'fonts', 'font_large.png'
    )
    output_path = sys.argv[1] if len(sys.argv) > 1 else default_output
    create_spritesheet(output_path)
