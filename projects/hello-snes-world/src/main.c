/*
 * Hello SNES World - Main Source
 *
 * Displays an Earthbound-style animated background (BG1) with
 * "HELLO SNES WORLD" text (BG2) centered on screen.
 *
 * SNES Mode 1: BG1 = animated background, BG2 = text overlay
 * Phase 8: HDMA distortion engine with 6 rotating presets
 *
 * Ported from: Earthbound-Battle-Backgrounds-JS
 *   distorter.js    - sine wave distortion (3 types)
 *   palette_cycle.js - palette rotation (3 types)
 */

#include <snes.h>

#include "font_tiles.h"
#include "text_layout.h"
#include "sine_table.h"
#include "bg_effect.h"

/* ==========================================================================
 * External data labels (defined in data.asm)
 * ========================================================================== */
extern char bg_tiles, bg_tiles_end;
extern char bg_palette, bg_palette_end;
extern char bg_map, bg_map_end;
extern char font_tiles, font_tiles_end;
extern char font_palette, font_palette_end;

/* ==========================================================================
 * Configuration
 * ========================================================================== */
#define NUM_PRESETS     6
#define PRESET_FRAMES   1800    /* 30 seconds at 60fps */
#define SCREEN_HEIGHT   224

/* ==========================================================================
 * HDMA Double Buffers
 * Format per entry: 1 byte count + 2 bytes scroll = 3 bytes
 * Total: 224 entries * 3 + 1 terminator = 673 bytes
 * ========================================================================== */
u8 hdma_table_a[SCREEN_HEIGHT * 3 + 1];
u8 hdma_table_b[SCREEN_HEIGHT * 3 + 1];
u8 *hdma_front;
u8 *hdma_back;

/* ==========================================================================
 * Animation State
 * ========================================================================== */
u16 tick;
u16 wave_phase;
u16 bg_scroll_x;
u16 bg_scroll_y;
u16 amp_accum;
u16 freq_bonus;
u16 preset_tick;
u8  cur_preset;

/* ==========================================================================
 * Current Effect Parameters (set by loadPreset)
 * ========================================================================== */
u8  cur_type;
u8  cur_amp;
u16 cur_freq;
u16 cur_speed;
u16 cur_comp;
u8  cur_amp_accel;
u8  cur_freq_accel;
u8  cur_pal_type;
u8  cur_pal_speed;
u8  cur_pal_start1;
u8  cur_pal_end1;
u8  cur_pal_start2;
u8  cur_pal_end2;
s8  cur_scroll_h;
s8  cur_scroll_v;

/* ==========================================================================
 * Palette State
 * ========================================================================== */
u16 original_palette[16];
u16 cycling_palette[16];
u8  pal_countdown;
u16 pal_cycle_count;

/* ==========================================================================
 * Function Prototypes
 * ========================================================================== */
void writeTextLine(char *text, u16 startCol, u16 startRow);
void loadPreset(u8 idx);
void setupHDMA(void);
void buildHDMATable(void);
void swapHDMABuffers(void);
void initPaletteCycle(void);
void updatePaletteCycle(void);
void palCycleForward(u8 start, u8 end);
void palCyclePalindrome(u8 start, u8 end);

/* ==========================================================================
 * Write one line of text to BG2 tilemap in VRAM
 * ========================================================================== */
void writeTextLine(char *text, u16 startCol, u16 startRow)
{
    u16 curCol = startCol;
    u16 tr, tc;
    u16 tileIndex, addr, entry;
    s16 charCol;

    while (*text) {
        charCol = fontCharToCol(*text);
        if (charCol >= 0) {
            for (tr = 0; tr < FONT_CHAR_TILES_H; tr++) {
                for (tc = 0; tc < FONT_CHAR_TILES_W; tc++) {
                    tileIndex = FONT_TILE(charCol, tc, tr);
                    entry = tileIndex
                        | (TEXT_TILE_PALETTE << 10)
                        | (TEXT_TILE_PRIORITY << 13);
                    addr = BG2_TILEMAP_VRAM
                        + (startRow + tr) * 32
                        + (curCol + tc);

                    REG_VMADDLH = addr;
                    REG_VMDATALH = entry;
                }
            }
        }
        curCol += FONT_CHAR_TILES_W;
        text++;
    }
}

/* ==========================================================================
 * Load Effect Preset
 *
 * 6 presets covering all 3 distortion types and all 3 palette cycling types.
 * Each preset runs for 30 seconds before advancing to the next.
 * ========================================================================== */
void loadPreset(u8 idx)
{
    u8 *tmp;

    /* Disable HDMA channel 7 during reconfiguration */
    REG_HDMAEN &= ~HDMA_CHANNEL7;

    switch (idx) {
        case 0: /* Gentle Ocean - soft horizontal waves */
            cur_type = DISTORT_HORIZONTAL;
            cur_amp = 4;
            cur_freq = 0x0500;
            cur_speed = 0x0180;
            cur_comp = 0x0100;
            cur_amp_accel = 0;
            cur_freq_accel = 0;
            cur_pal_type = 1;
            cur_pal_speed = 6;
            cur_pal_start1 = 1;
            cur_pal_end1 = 15;
            cur_pal_start2 = 0;
            cur_pal_end2 = 0;
            cur_scroll_h = 0;
            cur_scroll_v = 1;
            break;

        case 1: /* Psychedelic - interlaced with palindrome palette */
            cur_type = DISTORT_HORIZONTAL_INTERLACED;
            cur_amp = 3;
            cur_freq = 0x0A00;
            cur_speed = 0x0300;
            cur_comp = 0x0100;
            cur_amp_accel = 0;
            cur_freq_accel = 0;
            cur_pal_type = 3;
            cur_pal_speed = 3;
            cur_pal_start1 = 1;
            cur_pal_end1 = 15;
            cur_pal_start2 = 0;
            cur_pal_end2 = 0;
            cur_scroll_h = 0;
            cur_scroll_v = 0;
            break;

        case 2: /* Vertical Warp - vertical distortion with compression */
            cur_type = DISTORT_VERTICAL;
            cur_amp = 5;
            cur_freq = 0x0600;
            cur_speed = 0x0200;
            cur_comp = 0x0140;
            cur_amp_accel = 0;
            cur_freq_accel = 0;
            cur_pal_type = 1;
            cur_pal_speed = 4;
            cur_pal_start1 = 1;
            cur_pal_end1 = 15;
            cur_pal_start2 = 0;
            cur_pal_end2 = 0;
            cur_scroll_h = 1;
            cur_scroll_v = 0;
            break;

        case 3: /* Storm Waves - growing amplitude, dual palette */
            cur_type = DISTORT_HORIZONTAL;
            cur_amp = 3;
            cur_freq = 0x0400;
            cur_speed = 0x0500;
            cur_comp = 0x0100;
            cur_amp_accel = 3;
            cur_freq_accel = 0;
            cur_pal_type = 2;
            cur_pal_speed = 3;
            cur_pal_start1 = 1;
            cur_pal_end1 = 7;
            cur_pal_start2 = 8;
            cur_pal_end2 = 15;
            cur_scroll_h = 0;
            cur_scroll_v = 1;
            break;

        case 4: /* Glitch Lines - accelerating frequency */
            cur_type = DISTORT_HORIZONTAL_INTERLACED;
            cur_amp = 6;
            cur_freq = 0x0E00;
            cur_speed = 0x0400;
            cur_comp = 0x0100;
            cur_amp_accel = 0;
            cur_freq_accel = 1;
            cur_pal_type = 1;
            cur_pal_speed = 2;
            cur_pal_start1 = 1;
            cur_pal_end1 = 15;
            cur_pal_start2 = 0;
            cur_pal_end2 = 0;
            cur_scroll_h = 0;
            cur_scroll_v = 1;
            break;

        case 5: /* Vertical Pulse - strong vertical with palindrome */
            cur_type = DISTORT_VERTICAL;
            cur_amp = 8;
            cur_freq = 0x0300;
            cur_speed = 0x0280;
            cur_comp = 0x0100;
            cur_amp_accel = 0;
            cur_freq_accel = 0;
            cur_pal_type = 3;
            cur_pal_speed = 5;
            cur_pal_start1 = 1;
            cur_pal_end1 = 15;
            cur_pal_start2 = 0;
            cur_pal_end2 = 0;
            cur_scroll_h = 0;
            cur_scroll_v = 1;
            break;

        default:
            loadPreset(0);
            return;
    }

    /* Reset animation state */
    wave_phase = 0;
    bg_scroll_x = 0;
    bg_scroll_y = 0;
    amp_accum = 0;
    freq_bonus = 0;
    preset_tick = 0;

    /* Reset palette cycling */
    pal_countdown = cur_pal_speed;
    pal_cycle_count = 0;

    /* Reset scroll registers (write-twice: low then high) */
    REG_BG1HOFS = 0;
    REG_BG1HOFS = 0;
    REG_BG1VOFS = 0;
    REG_BG1VOFS = 0;

    /* Restore original palette to CGRAM (must be during VBlank/force blank) */
    dmaCopyCGram((u8 *)original_palette, 0, 32);

    /* Configure HDMA target register */
    if (cur_type == DISTORT_VERTICAL) {
        REG_BBAD7 = 0x0E;  /* BG1VOFS */
    } else {
        REG_BBAD7 = 0x0D;  /* BG1HOFS */
    }

    /* Build initial HDMA table into back buffer */
    buildHDMATable();

    /* Swap so front points to the freshly built table */
    tmp = hdma_front;
    hdma_front = hdma_back;
    hdma_back = tmp;

    /* Point HDMA to new front buffer */
    REG_A1T7LH = (u16)hdma_front;
    REG_A1B7 = 0x7E;

    /* Re-enable HDMA channel 7 */
    REG_HDMAEN |= HDMA_CHANNEL7;
}

/* ==========================================================================
 * One-time HDMA Channel 7 Setup
 *
 * Transfer mode $02: write to register twice (for write-twice scroll regs)
 * Channel 7 is unused by PVSnesLib, safe for custom effects.
 * ========================================================================== */
void setupHDMA(void)
{
    hdma_front = hdma_table_a;
    hdma_back = hdma_table_b;

    /* Transfer mode: $02 = write same register twice (handles write-twice) */
    REG_DMAP7 = 0x02;
}

/* ==========================================================================
 * Build HDMA Table (writes to back buffer)
 *
 * Accumulation-based loop: no per-scanline multiply for frequency.
 * phase_acc starts at wave_phase and increments by eff_freq each line.
 *
 * HORIZONTAL:            offset(y) = amp * sin(freq*y + phase)
 * HORIZONTAL_INTERLACED: same but negate offset on even scanlines
 * VERTICAL:              vofs(y) = scroll_y + offset(y) + compression(y)
 * ========================================================================== */
void buildHDMATable(void)
{
    u16 y;
    u16 phase_acc;
    u8  idx;
    s16 sval, offset, scroll;
    u8  eff_amp;
    u16 eff_freq;
    u16 comp_acc, comp_extra;
    u8  *table;
    u16 pos;

    table = hdma_back;
    pos = 0;

    /* Effective amplitude with acceleration */
    eff_amp = cur_amp;
    if (cur_amp_accel) {
        eff_amp = cur_amp + (u8)(amp_accum >> 9);
        if (eff_amp > 20) eff_amp = 20;
    }

    /* Effective frequency with acceleration */
    eff_freq = cur_freq + freq_bonus;

    phase_acc = wave_phase;
    comp_acc = 0;
    comp_extra = cur_comp - 0x0100;

    for (y = 0; y < SCREEN_HEIGHT; y++) {
        /* Sine table index from upper byte of phase accumulator */
        idx = (u8)(phase_acc >> 8);
        sval = (s16)sine_table[idx];

        /* Scale sine value by amplitude: offset = sval * amp / 128 */
        offset = (sval * (s16)eff_amp) >> 7;

        /* Negate on even scanlines for interlaced type */
        if (cur_type == DISTORT_HORIZONTAL_INTERLACED && !(y & 1)) {
            offset = -offset;
        }

        /* Compute final scroll value */
        if (cur_type == DISTORT_VERTICAL) {
            scroll = (s16)bg_scroll_y + offset + (s16)(comp_acc >> 8);
        } else {
            scroll = (s16)bg_scroll_x + offset;
        }

        /* Write HDMA entry: 1 scanline, scroll low, scroll high */
        table[pos] = 1;
        table[pos + 1] = (u8)(scroll & 0xFF);
        table[pos + 2] = (u8)((scroll >> 8) & 0xFF);
        pos += 3;

        /* Advance accumulators */
        phase_acc += eff_freq;
        if (cur_type == DISTORT_VERTICAL) {
            comp_acc += comp_extra;
        }
    }

    /* HDMA table terminator */
    table[pos] = 0;
}

/* ==========================================================================
 * Swap HDMA Double Buffers
 * Called during VBlank to point HDMA at the newly computed table.
 * ========================================================================== */
void swapHDMABuffers(void)
{
    u8 *tmp;
    tmp = hdma_front;
    hdma_front = hdma_back;
    hdma_back = tmp;
    REG_A1T7LH = (u16)hdma_front;
    REG_A1B7 = 0x7E;
}

/* ==========================================================================
 * Initialize Palette Cycling
 * Copies ROM palette data into RAM buffers for runtime modification.
 * ========================================================================== */
void initPaletteCycle(void)
{
    u8 i;
    u8 *palPtr;

    palPtr = (u8 *)&bg_palette;
    for (i = 0; i < 16; i++) {
        original_palette[i] = palPtr[i * 2] | ((u16)palPtr[i * 2 + 1] << 8);
        cycling_palette[i] = original_palette[i];
    }
}

/* ==========================================================================
 * Forward Palette Rotation (Type 1 & 2)
 *
 * Ported from palette_cycle.js cycleColors() type 1:
 *   position = cycleCount % cycleLength
 *   for i = start to end:
 *     newColor = i - position
 *     if newColor < start: newColor += cycleLength
 *     nowColors[i] = originalColors[newColor]
 * ========================================================================== */
void palCycleForward(u8 start, u8 end)
{
    u8 i, cycleLen, position;
    s16 newIdx;

    cycleLen = end - start + 1;
    position = (u8)(pal_cycle_count % cycleLen);

    for (i = start; i <= end; i++) {
        newIdx = (s16)i - (s16)position;
        if (newIdx < (s16)start) {
            newIdx += cycleLen;
        }
        cycling_palette[i] = original_palette[newIdx];
    }
}

/* ==========================================================================
 * Palindromic Palette Oscillation (Type 3)
 *
 * Ported from palette_cycle.js cycleColors() type 3:
 *   position = cycleCount % (cycleLength * 2)
 *   for i = start to end:
 *     newColor = i + position
 *     if newColor > end: bounce back (and potentially forward again)
 *     nowColors[i] = originalColors[newColor]
 * ========================================================================== */
void palCyclePalindrome(u8 start, u8 end)
{
    u8 i, cycleLen;
    u16 position;
    s16 newIdx, diff;

    cycleLen = end - start + 1;
    position = pal_cycle_count % ((u16)cycleLen * 2);

    for (i = start; i <= end; i++) {
        newIdx = (s16)i + (s16)position;
        if (newIdx > (s16)end) {
            diff = newIdx - (s16)end - 1;
            newIdx = (s16)end - diff;
            if (newIdx < (s16)start) {
                diff = (s16)start - newIdx - 1;
                newIdx = (s16)start + diff;
            }
        }
        cycling_palette[i] = original_palette[newIdx];
    }
}

/* ==========================================================================
 * Update Palette Cycling (called during VBlank)
 *
 * Dispatches to the appropriate cycling algorithm based on cur_pal_type:
 *   1 = Forward rotation (single range)
 *   2 = Dual range rotation (two independent forward rotations)
 *   3 = Palindromic oscillation (bounce/ping-pong)
 * ========================================================================== */
void updatePaletteCycle(void)
{
    if (cur_pal_type == 0 || cur_pal_speed == 0) return;

    pal_countdown--;
    if (pal_countdown > 0) return;
    pal_countdown = cur_pal_speed;
    pal_cycle_count++;

    switch (cur_pal_type) {
        case 1:
            palCycleForward(cur_pal_start1, cur_pal_end1);
            break;
        case 2:
            palCycleForward(cur_pal_start1, cur_pal_end1);
            palCycleForward(cur_pal_start2, cur_pal_end2);
            break;
        case 3:
            palCyclePalindrome(cur_pal_start1, cur_pal_end1);
            break;
    }

    /* Upload modified palette to CGRAM (BG1 palette at address 0) */
    dmaCopyCGram((u8 *)cycling_palette, 0, 32);
}

/* ==========================================================================
 * Main Entry Point
 * ========================================================================== */
int main(void)
{
    /* Initialize PPU to known state (force blank ON, VRAM/CGRAM cleared) */
    consoleInit();

    /* Set video mode: Mode 1, 8x8 tiles */
    setMode(BG_MODE1, 0);

    /* --- BG1 (index 0): animated background --- */
    bgInitTileSet(0, &bg_tiles, &bg_palette, 0,
                  (&bg_tiles_end - &bg_tiles),
                  (&bg_palette_end - &bg_palette),
                  BG_16COLORS, BG1_TILES_VRAM);
    bgInitMapSet(0, &bg_map,
                 (&bg_map_end - &bg_map),
                 SC_32x32, BG1_TILEMAP_VRAM);

    /* --- BG2 (index 1): text overlay --- */
    bgInitTileSet(1, &font_tiles, &font_palette, 1,
                  (&font_tiles_end - &font_tiles),
                  (&font_palette_end - &font_palette),
                  BG_16COLORS, BG2_TILES_VRAM);
    bgSetMapPtr(1, BG2_TILEMAP_VRAM, SC_32x32);

    /* Write text tilemap entries to VRAM (safe during force blank) */
    REG_VMAIN = 0x80;
    writeTextLine(LINE1_TEXT, LINE1_COL_START, LINE1_ROW_START);
    writeTextLine(LINE2_TEXT, LINE2_COL_START, LINE2_ROW_START);

    /* Enable BG1 and BG2, disable BG3 */
    bgSetEnable(0);
    bgSetEnable(1);
    bgSetDisable(2);

    /* Initialize palette cycling buffers from ROM data */
    initPaletteCycle();

    /* One-time HDMA channel 7 configuration */
    setupHDMA();

    /* Load first effect preset (configures HDMA target + builds table) */
    cur_preset = 0;
    tick = 0;
    loadPreset(0);

    /* Turn off force blank, display at full brightness */
    setScreenOn();

    /* =======================================================================
     * Main Loop
     *
     * Structure: build HDMA table during active display (slow),
     * then do quick VBlank work (buffer swap, palette, scroll).
     * ======================================================================= */
    while (1) {
        /* During active display: compute next frame's HDMA table */
        buildHDMATable();

        /* Sync to VBlank */
        WaitForVBlank();

        /* --- VBlank: quick updates --- */

        /* Check for preset change (do first, during VBlank for clean transition) */
        preset_tick++;
        if (preset_tick >= PRESET_FRAMES) {
            cur_preset++;
            if (cur_preset >= NUM_PRESETS) cur_preset = 0;
            loadPreset(cur_preset);
        } else {
            /* Normal frame: swap HDMA double buffers */
            swapHDMABuffers();
        }

        /* Update palette cycling */
        updatePaletteCycle();

        /* Update non-HDMA scroll axis (write-twice registers) */
        if (cur_type == DISTORT_VERTICAL) {
            /* HDMA handles VOFS per-scanline; manually set HOFS */
            REG_BG1HOFS = (u8)(bg_scroll_x & 0xFF);
            REG_BG1HOFS = (u8)((bg_scroll_x >> 8) & 0xFF);
        } else {
            /* HDMA handles HOFS per-scanline; manually set VOFS */
            REG_BG1VOFS = (u8)(bg_scroll_y & 0xFF);
            REG_BG1VOFS = (u8)((bg_scroll_y >> 8) & 0xFF);
        }

        /* Advance animation state */
        wave_phase += cur_speed;
        bg_scroll_x += cur_scroll_h;
        bg_scroll_y += cur_scroll_v;

        if (cur_amp_accel) {
            amp_accum += cur_amp_accel;
        }
        if (cur_freq_accel) {
            freq_bonus += cur_freq_accel;
        }

        tick++;
    }

    return 0;
}
