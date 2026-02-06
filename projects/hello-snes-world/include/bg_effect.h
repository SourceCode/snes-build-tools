/*
 * Background Effect Parameters
 *
 * Ported from Earthbound Battle Backgrounds JS:
 *   tmp/Earthbound-Battle-Backgrounds-JS/src/rom/distorter.js
 *   tmp/Earthbound-Battle-Backgrounds-JS/src/rom/distortion_effect.js
 *   tmp/Earthbound-Battle-Backgrounds-JS/src/rom/palette_cycle.js
 *
 * JS distortion formula (distorter.js lines 28-48):
 *   C1 = 1/512
 *   C2 = 8*PI / (1024*256)
 *   C3 = PI / 60
 *
 *   amplitude = C1 * (amplitude_param + amplitudeAccel * ticks * 2)
 *   frequency = C2 * (frequency_param + frequencyAccel * ticks * 2)
 *   speed     = C3 * speed_param * ticks
 *   offset(y) = round(amplitude * sin(frequency * y + speed))
 *
 * SNES implementation (Phase 8):
 *   Uses 256-entry sine LUT and 8.8 fixed-point math.
 *   Per frame: phase += speed_increment
 *   Per scanline y: index = ((y * freq_fp8) >> 8 + phase) & 0xFF
 *                   offset = (sine_table[index] * amplitude) >> 7
 *   Applied via HDMA writing to BG1HOFS ($210D).
 */

#ifndef BG_EFFECT_H
#define BG_EFFECT_H

#include <snes.h>

/* --- Distortion Types (distortion_effect.js lines 2-4) --- */
#define DISTORT_HORIZONTAL             1
#define DISTORT_HORIZONTAL_INTERLACED  2
#define DISTORT_VERTICAL               3

/* --- Selected Effect Type --- */
#define BG_EFFECT_TYPE      DISTORT_HORIZONTAL

/*
 * --- Raw Earthbound-style Parameters ---
 * These mirror the 17-byte ROM data structure.
 * Used as reference; the SNES constants below are derived from these.
 *
 * Sensible ranges (from Earthbound ROM data):
 *   amplitude:   512 - 4096  (subtle to extreme)
 *   frequency:   512 - 4096  (few waves to many)
 *   speed:       1 - 4       (slow to fast)
 *   compression: 0           (no vertical compression for HORIZONTAL)
 */
#define BG_RAW_AMPLITUDE    2048
#define BG_RAW_FREQUENCY    2048
#define BG_RAW_SPEED        2
#define BG_RAW_COMPRESSION  0
#define BG_RAW_AMP_ACCEL    0
#define BG_RAW_FREQ_ACCEL   0
#define BG_RAW_COMP_ACCEL   0

/*
 * --- SNES Fixed-Point Constants ---
 *
 * Instead of computing the full JS formula per-scanline,
 * we pre-compute simplified parameters for the 65816:
 *
 * Sine table: 256 entries of s8 (-127 to +127)
 * Phase: u16 (upper byte indexes sine table, wraps naturally)
 *
 * Per frame:
 *   bg_phase += BG_WAVE_SPEED
 *
 * Per scanline y (0..223):
 *   table_index = (u8)((y * BG_WAVE_FREQ + bg_phase) >> 8)
 *   offset = (sine_table[table_index] * BG_WAVE_AMP) >> 7
 *   -> write offset to BG1HOFS via HDMA
 *
 * Derivation from JS constants:
 *   JS amplitude = C1 * 2048 = 2048/512 = 4.0 pixels
 *     -> BG_WAVE_AMP = 4 (can increase for more dramatic effect)
 *   JS frequency = C2 * 2048 = 8*pi*2048/262144 = ~0.196 radians/pixel
 *     -> Over 224 scanlines: 0.196 * 224 / (2*pi) = ~7 cycles
 *     -> In 8.8 fp: 7 * 256 / 224 = ~8.0 -> BG_WAVE_FREQ = 0x0800
 *   JS speed = C3 * 2 = pi/30 radians/frame
 *     -> Cycles per 256 frames: (pi/30 * 256) / (2*pi) = ~1.36
 *     -> In 16-bit: 256 * 1.36 = ~348 -> BG_WAVE_SPEED = 0x015C
 */

/* Amplitude: max pixel displacement (+/-) */
#define BG_WAVE_AMP         6

/* Frequency: controls sine cycles across screen (8.8 fixed-point) */
/* Higher = more wave crests visible */
#define BG_WAVE_FREQ        0x0800

/* Speed: phase increment per frame (16-bit, wraps at 0xFFFF) */
/* Higher = faster animation */
#define BG_WAVE_SPEED       0x015C

/* --- Palette Cycling (palette_cycle.js) --- */
/*
 * Type 1: Forward rotation - colors shift forward by one each cycle
 * Type 2: Dual ranges - two independent rotations
 * Type 3: Bounce/ping-pong - colors oscillate back and forth
 */
#define PAL_CYCLE_TYPE      1      /* Forward rotation */
#define PAL_CYCLE_START     1      /* First color index to cycle (skip 0=transparent) */
#define PAL_CYCLE_END       15     /* Last color index to cycle */
#define PAL_CYCLE_SPEED     4      /* Frames between each palette shift */

/* --- Constant Background Scroll --- */
/* Applied in addition to distortion effect */
#define BG_SCROLL_H         0      /* Horizontal pixels per frame */
#define BG_SCROLL_V         1      /* Vertical pixels per frame (slow upward drift) */

#endif /* BG_EFFECT_H */
