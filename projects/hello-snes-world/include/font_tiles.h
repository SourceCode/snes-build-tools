/*
 * Font Tile Mapping - Generated from font_large.png
 *
 * Spritesheet layout: 240x32 pixels = 30 tile columns x 4 tile rows = 120 tiles
 * Each character is 3 tiles wide x 4 tiles tall (24x32 pixels)
 * Characters in order: H, E, L, O, S, N, W, R, D, SPACE
 *
 * gfx4snes flags: -s 8 -o 16 -u 16 -e 0 -p -m -R
 * Tile ordering: sequential row-major (confirmed by map output)
 *
 * Tile index formula:
 *   tile_index = tile_row * FONT_SHEET_COLS + (char_col_offset + tile_col)
 *
 * where tile_row = 0..3, tile_col = 0..2
 */

#ifndef FONT_TILES_H
#define FONT_TILES_H

#include <snes.h>

/* Spritesheet dimensions in tiles */
#define FONT_SHEET_COLS     30   /* Total tile columns in spritesheet */
#define FONT_SHEET_ROWS     4    /* Total tile rows in spritesheet */
#define FONT_TOTAL_TILES    120  /* 30 x 4 */

/* Character dimensions in tiles */
#define FONT_CHAR_TILES_W   3    /* 3 tiles wide = 24 pixels */
#define FONT_CHAR_TILES_H   4    /* 4 tiles tall = 32 pixels */
#define FONT_CHAR_TILES     12   /* Total tiles per character */

/* Character dimensions in pixels */
#define FONT_CHAR_PX_W      24
#define FONT_CHAR_PX_H      32

/* Number of unique characters in font */
#define FONT_NUM_CHARS      10

/* Column offset for each character in the spritesheet (in tiles) */
#define CHAR_COL_H      0
#define CHAR_COL_E      3
#define CHAR_COL_L      6
#define CHAR_COL_O      9
#define CHAR_COL_S      12
#define CHAR_COL_N      15
#define CHAR_COL_W      18
#define CHAR_COL_R      21
#define CHAR_COL_D      24
#define CHAR_COL_SP     27

/*
 * Get the tile index for a specific position within a character.
 *
 * char_col: starting tile column of the character (CHAR_COL_*)
 * tc:       tile column within character (0-2)
 * tr:       tile row within character (0-3)
 *
 * Returns: tile index in the .pic file (0-119)
 */
#define FONT_TILE(char_col, tc, tr) \
    ((tr) * FONT_SHEET_COLS + (char_col) + (tc))

/*
 * Look up the column offset for a character.
 * Returns -1 for unsupported characters.
 */
static inline s16 fontCharToCol(char c)
{
    switch (c) {
        case 'H': return CHAR_COL_H;
        case 'E': return CHAR_COL_E;
        case 'L': return CHAR_COL_L;
        case 'O': return CHAR_COL_O;
        case 'S': return CHAR_COL_S;
        case 'N': return CHAR_COL_N;
        case 'W': return CHAR_COL_W;
        case 'R': return CHAR_COL_R;
        case 'D': return CHAR_COL_D;
        case ' ': return CHAR_COL_SP;
        default:  return -1;
    }
}

#endif /* FONT_TILES_H */
