/*
 * Text Layout Constants - Screen positioning for "HELLO SNES WORLD"
 *
 * Screen: 256x224 pixels = 32x28 visible tile columns/rows
 * Tilemap: 32x32 entries (only 32x28 visible on NTSC)
 *
 * Two-line layout:
 *   Line 1: "HELLO SNES" (10 chars x 3 tiles = 30 tiles wide)
 *           Start at tile column 1 (8px left margin)
 *   Line 2: "WORLD" (5 chars x 3 tiles = 15 tiles wide)
 *           Start at tile column 8 (approximately centered)
 *
 * Vertical centering:
 *   Line 1 top:    tile row 10 (pixel 80)
 *   Line 1 bottom: tile row 13 (pixel 111)
 *   Gap:           tile row 14 (8 pixels)
 *   Line 2 top:    tile row 15 (pixel 120)
 *   Line 2 bottom: tile row 18 (pixel 151)
 *   Total block:   rows 10-18 = 9 tile rows = 72 pixels
 *   Centered in 224px: (224-72)/2 = 76px ~ row 9.5, using row 10
 */

#ifndef TEXT_LAYOUT_H
#define TEXT_LAYOUT_H

/* Tilemap dimensions */
#define TILEMAP_COLS        32
#define TILEMAP_ROWS        32
#define VISIBLE_COLS        32   /* NTSC visible columns */
#define VISIBLE_ROWS        28   /* NTSC visible rows */

/* Line 1: "HELLO SNES" */
#define LINE1_TEXT           "HELLO SNES"
#define LINE1_NUM_CHARS      10
#define LINE1_COL_START      1   /* Tile column (8px left margin) */
#define LINE1_ROW_START      10  /* Tile row (pixel 80) */

/* Line 2: "WORLD" */
#define LINE2_TEXT           "WORLD"
#define LINE2_NUM_CHARS      5
#define LINE2_COL_START      8   /* Tile column (approximately centered) */
#define LINE2_ROW_START      15  /* Tile row (pixel 120) */

/* Font character dimensions in tiles */
#define TEXT_CHAR_W          3   /* Tiles per character horizontally */
#define TEXT_CHAR_H          4   /* Tiles per character vertically */

/* BG2 tile attributes for text */
#define TEXT_TILE_PRIORITY   1   /* High priority (text over background) */
#define TEXT_TILE_PALETTE    1   /* Palette 1 (colors 16-31 in CGRAM) */

/*
 * VRAM Layout (word addresses):
 *   BG1 tilemap: 0x0000 (background map, 32x32)
 *   BG2 tilemap: 0x0400 (text map, 32x32)
 *   BG1 tiles:   0x2000 (background graphics)
 *   BG2 tiles:   0x4000 (font graphics)
 *
 * These addresses are provisional and will be finalized in Phase 7.
 */
#define BG1_TILEMAP_VRAM    0x0000
#define BG2_TILEMAP_VRAM    0x0400
#define BG1_TILES_VRAM      0x2000
#define BG2_TILES_VRAM      0x4000

/* Font palette CGRAM address */
/* Palette 0: colors 0-15 (BG1 background) */
/* Palette 1: colors 16-31 (BG2 font) */
#define FONT_CGRAM_ADDR     32   /* Byte offset = palette 1 * 16 colors * 2 bytes */

#endif /* TEXT_LAYOUT_H */
