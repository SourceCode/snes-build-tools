# Phase 6: Background Graphics & Effect Data

## Overview

This phase creates the background graphics, palette, and effect parameter data needed for the Earthbound-style animated background. We will create (or extract) a visually striking background tile pattern, define its color palette with cycling parameters, and prepare all data for SNES format conversion.

The background will be displayed on BG1 and animated using HDMA-driven sine-wave distortion (implemented in Phase 8). This phase focuses on the static assets and the effect configuration data.

## Prerequisites

- Phase 1 completed (directory structure exists)
- Phase 3 completed (gfx4snes available)
- Phase 4 completed (Makefile with background conversion rules)
- The reference repository cloned at `J:\code\snes\snes-build-tools\tmp\Earthbound-Battle-Backgrounds-JS\`

## Objectives

1. Create a background tile pattern PNG at `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\backgrounds\bg_earthbound.png`
2. Define the color palette with cycling-friendly color arrangement
3. Convert background assets to SNES format using gfx4snes
4. Create an effect parameter header file with distortion constants
5. Create a palette cycling data structure

## Context

### Earthbound Background Architecture

From studying the reference code at `J:\code\snes\snes-build-tools\tmp\Earthbound-Battle-Backgrounds-JS\src\rom\`:

**Background Layer Structure** (from `background_layer.js`, lines 8-14):
- A 256x256 pixel source bitmap (32x32 tiles)
- A distortion effect applied per-scanline via HDMA
- A palette cycle that rotates colors over time

**Distortion Effect Parameters** (from `distortion_effect.js`, lines 9-94):
The effect is defined by a 17-byte data structure:
- Bytes 0-1: Duration (unused in our implementation)
- Byte 2: Type (1=HORIZONTAL, 2=HORIZONTAL_INTERLACED, 3=VERTICAL)
- Bytes 3-4: Frequency (int16)
- Bytes 5-6: Amplitude (int16)
- Byte 7: Unused
- Bytes 8-9: Compression (int16)
- Bytes 10-11: Frequency acceleration (int16)
- Bytes 12-13: Amplitude acceleration (int16)
- Byte 14: Speed (int8)
- Bytes 15-16: Compression acceleration (int16)

**Core Distortion Formula** (from `distorter.js`, lines 33-48):
```
Constants:
  C1 = 1/512
  C2 = 8*pi / (1024*256)
  C3 = pi / 60

Per-frame computation:
  t2 = ticks * 2
  amplitude = C1 * (amplitude_param + amplitudeAcceleration * t2)
  frequency = C2 * (frequency_param + frequencyAcceleration * t2)
  compression = 1 + (compression_param + compressionAcceleration * t2) / 256
  speed = C3 * speed_param * ticks

Per-scanline offset:
  S(y) = round(amplitude * sin(frequency * y + speed))
```

**For HORIZONTAL distortion** (from `distorter.js`, lines 68-79):
- Each scanline `y` gets a horizontal scroll offset = `S(y)`
- This creates a wavy/ripple effect across the background
- On SNES hardware, this is achieved via HDMA writing to BG1HOFS ($210D)

### Background Pattern Design

For our demo, we need a 256x256 pixel background that:
1. Tiles seamlessly (wraps both horizontally and vertically)
2. Looks interesting when distorted by sine waves
3. Has colors suitable for palette cycling
4. Is visually distinct from the white/black text overlay

Good pattern choices:
- **Horizontal stripes** or bands of color -- emphasize the wave distortion
- **Diagonal checker/plaid** pattern -- creates Moire-like effects when distorted
- **Concentric circles** or radial pattern -- creates organic warping
- **Gradient bands** with cycling-friendly color ramps

We will create a **horizontal color band** pattern (similar to many Earthbound battle backgrounds). This consists of horizontal stripes of varying width and color, which produces a striking visual when horizontally distorted.

### Palette Cycling

From `palette_cycle.js` in the reference code:

**Type 1** (Forward rotation, lines 46-58):
- Colors within a range (start..end) shift forward by one position each cycle
- Color at the end wraps to the start position
- This creates a smooth flowing effect

**Type 2** (Dual rotation, lines 59-71):
- Same as Type 1 but with two independent color ranges cycling simultaneously

**Type 3** (Bounce, lines 72-90):
- Colors shift forward then reverse direction at the end
- Creates a pulsing/breathing effect

For our demo, we will use **Type 1 (forward rotation)** for simplicity, cycling through a range of background colors.

### VRAM Layout

Background tiles go to VRAM alongside the font tiles. We need to plan the layout:
- BG1 character data (background tiles): VRAM address $0000
- BG1 tilemap: VRAM address $1000
- BG2 character data (font tiles): VRAM address $4000
- BG2 tilemap: VRAM address $1400

This gives us:
- Background tiles: $0000-$0FFF (up to 4096 words = 8192 bytes = 512 tiles at 4bpp)
- Background tilemap: $1000-$13FF (32x32 entries = 2048 bytes)
- Font tilemap: $1400-$17FF
- Font tiles: $4000+

## Tasks

### Task 6.1: Create Background Pattern PNG

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\backgrounds\bg_earthbound.png`

**Description**: Create a 256x256 pixel PNG with a horizontal color band pattern suitable for sine-wave distortion and palette cycling.

**Implementation Details**:

Create a Python script to generate the background pattern, or create it manually. The pattern should:
- Be exactly 256x256 pixels
- Use at most 16 colors (4bpp limit)
- Arrange colors so that adjacent palette indices create smooth gradients
- Use horizontal bands that will look good when distorted

**Code Example** (generator script):

Create `J:\code\snes\snes-build-tools\scripts\generate_background.py`:

```python
#!/usr/bin/env python3
"""
Background Pattern Generator for SNES Earthbound-style demo.
Creates a 256x256 pixel horizontal color band pattern.

The pattern uses 16 colors arranged as a gradient,
designed to look good with sine-wave distortion and palette cycling.
"""

import sys
import os
import math
from PIL import Image

# --- Configuration ---
WIDTH = 256
HEIGHT = 256
NUM_COLORS = 16

def generate_palette():
    """
    Generate a 16-color palette of blue/purple/cyan hues.
    Colors are arranged so that cycling produces smooth transitions.
    """
    palette = []
    for i in range(NUM_COLORS):
        # Create a smooth gradient from deep blue through purple to cyan
        t = i / NUM_COLORS
        # Cycle through hue range: blue (240) -> purple (280) -> cyan (180)
        # Using HSV-like approach manually:
        r = int(32 + 128 * (0.5 + 0.5 * math.sin(2 * math.pi * t + 0)))
        g = int(16 + 96 * (0.5 + 0.5 * math.sin(2 * math.pi * t + 2.094)))
        b = int(80 + 175 * (0.5 + 0.5 * math.sin(2 * math.pi * t + 4.189)))
        palette.append((
            max(0, min(255, r)),
            max(0, min(255, g)),
            max(0, min(255, b))
        ))
    return palette


def generate_pattern(palette):
    """
    Generate a 256x256 image with horizontal color bands.
    Each band is a different palette color, creating a smooth gradient
    that wraps vertically. The bands vary in width using a sine function
    to create more visual interest.
    """
    img = Image.new('RGB', (WIDTH, HEIGHT))

    for y in range(HEIGHT):
        # Map y position to a color index with some variation
        # Base: divide 256 rows into 16 bands of 16 rows each
        # Add sine variation to create uneven band widths
        band_offset = math.sin(y * 2 * math.pi / 256) * 2
        color_index = int((y / HEIGHT * NUM_COLORS + band_offset) % NUM_COLORS)
        color = palette[color_index]

        for x in range(WIDTH):
            # Add subtle horizontal variation:
            # Slightly shift color index based on x to create a diagonal feel
            x_shift = math.sin(x * 4 * math.pi / 256) * 0.5
            final_index = int((color_index + x_shift) % NUM_COLORS)
            img.putpixel((x, y), palette[final_index])

    return img


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    default_output = os.path.join(
        repo_root, 'projects', 'hello-snes-world',
        'assets', 'backgrounds', 'bg_earthbound.png'
    )

    output_path = sys.argv[1] if len(sys.argv) > 1 else default_output
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    print("Generating Earthbound-style background pattern...")
    palette = generate_palette()

    print(f"  Palette ({NUM_COLORS} colors):")
    for i, (r, g, b) in enumerate(palette):
        snes_r = r >> 3
        snes_g = g >> 3
        snes_b = b >> 3
        snes_color = snes_r | (snes_g << 5) | (snes_b << 10)
        print(f"    Color {i:2d}: RGB({r:3d},{g:3d},{b:3d}) -> SNES ${snes_color:04X}")

    img = generate_pattern(palette)
    img.save(output_path)

    print(f"\n  Background saved to: {output_path}")
    print(f"  Size: {WIDTH}x{HEIGHT} pixels")
    print(f"  Colors: {NUM_COLORS}")


if __name__ == '__main__':
    main()
```

**Execution**:
```bash
python J:\code\snes\snes-build-tools\scripts\generate_background.py
```

**References**:
- Earthbound battle backgrounds visualizer: https://gjtorikian.github.io/Earthbound-Battle-Backgrounds-JS/

---

### Task 6.2: Convert Background PNG to SNES Format

**File(s)**:
- `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\backgrounds\bg_earthbound.pic`
- `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\backgrounds\bg_earthbound.pal`
- `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\backgrounds\bg_earthbound.map`

**Description**: Convert the background PNG to SNES tile format using gfx4snes.

**Implementation Details**:

```bash
cd J:\code\snes\snes-build-tools\projects\hello-snes-world
call ..\..\env.bat

gfx4snes -i assets/backgrounds/bg_earthbound.png -o assets/backgrounds/bg_earthbound -p -t -m -s 8 -b 4 -R
```

Verify outputs:
- `bg_earthbound.pic` - tile data (should be < 8192 bytes to fit in allocated VRAM)
- `bg_earthbound.pal` - palette (32 bytes for 16 colors at 2 bytes each)
- `bg_earthbound.map` - tilemap (2048 bytes for 32x32 map at 2 bytes per entry)

If tile data exceeds the VRAM budget (8192 bytes = 256 tiles at 4bpp 8x8):
- Increase the `-R` optimization to merge more duplicate tiles
- Simplify the background pattern (fewer unique tiles)
- Consider using 2bpp mode (4 colors) for the background to halve tile data size

---

### Task 6.3: Create Effect Parameters Header

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\bg_effect.h`

**Description**: Define the distortion effect parameters as C constants, ported from the Earthbound JS reference. These parameters control the sine-wave distortion behavior.

**Implementation Details**:

The effect parameters are derived from the reference code's `DistortionEffect` class. We choose values that produce a visually pleasing horizontal wave effect.

For reference, here are some known Earthbound background effect parameters (extracted from the ROM):
- Background 270 (classic wavy): type=HORIZONTAL, freq=2048, amp=3072, speed=2, compression=0
- Background 225 (subtle ripple): type=HORIZONTAL, freq=1024, amp=1536, speed=1, compression=0

We will use a moderate-intensity horizontal distortion.

**Code Example**:

```c
/*
 * Background Effect Parameters
 * Ported from Earthbound Battle Backgrounds JS:
 *   J:\code\snes\snes-build-tools\tmp\Earthbound-Battle-Backgrounds-JS\src\rom\distorter.js
 *   J:\code\snes\snes-build-tools\tmp\Earthbound-Battle-Backgrounds-JS\src\rom\distortion_effect.js
 *
 * Distortion formula (from distorter.js lines 28-48):
 *   C1 = 1/512
 *   C2 = 8*PI / (1024*256)
 *   C3 = PI / 60
 *
 *   amplitude = C1 * (amplitude_param + amplitudeAccel * ticks*2)
 *   frequency = C2 * (frequency_param + frequencyAccel * ticks*2)
 *   speed     = C3 * speed_param * ticks
 *   offset(y) = round(amplitude * sin(frequency * y + speed))
 *
 * On SNES, we use fixed-point math and pre-computed sine tables.
 */

#ifndef BG_EFFECT_H
#define BG_EFFECT_H

#include <snes.h>

/* --- Distortion Types --- */
/* From distortion_effect.js lines 1-4 */
#define DISTORT_HORIZONTAL             1
#define DISTORT_HORIZONTAL_INTERLACED  2
#define DISTORT_VERTICAL               3

/* --- Effect Parameters --- */
/* Choose HORIZONTAL type for the best visual effect on SNES */
#define BG_EFFECT_TYPE          DISTORT_HORIZONTAL

/*
 * These values control the sine wave distortion.
 * Higher amplitude = wider waves
 * Higher frequency = more waves per screen
 * Higher speed = faster animation
 *
 * Sensible ranges (from studying Earthbound ROM data):
 *   amplitude:   512 - 4096  (subtle to extreme)
 *   frequency:   512 - 4096  (few waves to many)
 *   speed:       1 - 4       (slow to fast)
 *   compression: 0 (no vertical compression for HORIZONTAL mode)
 */
#define BG_EFFECT_AMPLITUDE         2048
#define BG_EFFECT_FREQUENCY         2048
#define BG_EFFECT_SPEED             2
#define BG_EFFECT_COMPRESSION       0

/* Acceleration values (0 = constant, non-zero = effect changes over time) */
#define BG_EFFECT_AMP_ACCEL         0
#define BG_EFFECT_FREQ_ACCEL        0
#define BG_EFFECT_COMP_ACCEL        0

/* --- Fixed-Point Constants --- */
/*
 * We convert the floating-point JS constants to 16-bit fixed-point.
 *
 * C1 = 1/512 = 0.001953125
 * In 8.8 fixed point: 0.001953125 * 256 = 0.5 -> round to 1
 * Better: use 16.16 fixed point or compute differently.
 *
 * For SNES (65816 at 3.58 MHz), we simplify the math:
 *
 * Instead of computing the full formula per-scanline each frame,
 * we pre-compute a sine table and index into it.
 *
 * SNES approach:
 *   sine_table[256] = pre-computed sine values (8-bit signed, -128 to +127)
 *   For each frame:
 *     phase += speed_increment  (16-bit, wraps)
 *   For each scanline y (0..223):
 *     index = (y * freq_scale + phase) >> 8  (use upper byte as table index)
 *     offset = (sine_table[index & 0xFF] * amplitude) >> 8
 *     Apply offset as BG1 horizontal scroll via HDMA
 */

/* Sine table size (must be power of 2) */
#define SINE_TABLE_SIZE     256

/* Amplitude of wave in pixels (max horizontal shift) */
/* This is the actual pixel displacement, not the raw parameter */
#define BG_WAVE_AMPLITUDE   8     /* +/- 8 pixels of horizontal scroll */

/* Frequency: how many full sine cycles across 224 scanlines */
/* Higher = more wave crests visible on screen */
/* In 8.8 fixed point: (cycles * 256) / 224 */
#define BG_WAVE_FREQ_FP8    291   /* ~1.14 cycles per screen (256/224) */

/* Speed: phase increment per frame (in 8.8 fixed-point) */
/* Higher = faster animation */
/* 256 = one full sine cycle per 256 frames (~4.3 sec at 60fps) */
/* 512 = one full cycle per 128 frames (~2.1 sec) */
#define BG_WAVE_SPEED_FP8   384   /* ~1.5 cycles per 256 frames */

/* --- Palette Cycling --- */
/*
 * From palette_cycle.js in the reference code:
 *
 * Type 1: Forward rotation -- colors shift forward in the palette
 * Type 2: Dual ranges -- two independent ranges cycle
 * Type 3: Bounce -- colors shift forward then reverse
 *
 * We use Type 1 with a color range that covers most of the background palette.
 */
#define PAL_CYCLE_TYPE       1     /* Forward rotation */
#define PAL_CYCLE_START      1     /* First color index to cycle (skip 0 = transparent) */
#define PAL_CYCLE_END        15    /* Last color index to cycle */
#define PAL_CYCLE_SPEED      4     /* Frames between each palette shift (lower = faster) */

/* Background scroll speed (constant scroll in addition to distortion) */
#define BG_SCROLL_H_SPEED   0     /* Horizontal pixels per frame (0 = no constant scroll) */
#define BG_SCROLL_V_SPEED   1     /* Vertical pixels per frame (slow upward scroll) */

#endif /* BG_EFFECT_H */
```

**References**:
- Distorter source: `J:\code\snes\snes-build-tools\tmp\Earthbound-Battle-Backgrounds-JS\src\rom\distorter.js` (lines 28-48 for constants, lines 68-79 for offset calculation)
- DistortionEffect source: `J:\code\snes\snes-build-tools\tmp\Earthbound-Battle-Backgrounds-JS\src\rom\distortion_effect.js` (lines 27-87 for parameter getters)
- PaletteCycle source: `J:\code\snes\snes-build-tools\tmp\Earthbound-Battle-Backgrounds-JS\src\rom\palette_cycle.js` (lines 32-91 for cycling algorithms)

---

### Task 6.4: Create Sine Lookup Table Data

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\sine_table.h`

**Description**: Create a pre-computed sine lookup table for the distortion engine. On the 65816 CPU at 3.58 MHz, computing trigonometric functions in real-time is too expensive. A 256-entry table provides adequate resolution.

**Code Example**:

```c
/*
 * Pre-computed Sine Lookup Table
 * 256 entries, 8-bit signed values (-128 to +127)
 * Represents sin(x) for x = 0..255 mapping to 0..2*PI
 *
 * Generated with:
 *   for i in range(256):
 *       value = round(127 * sin(2 * pi * i / 256))
 *       print(f"{value:4d},", end='\n' if (i+1) % 16 == 0 else ' ')
 */

#ifndef SINE_TABLE_H
#define SINE_TABLE_H

#include <snes.h>

/* Sine table: 256 entries of signed 8-bit values */
/* Index: 0-255 maps to angle 0 to 2*PI */
/* Value: -127 to +127 represents -1.0 to +1.0 */
const s8 sine_table[256] = {
       0,    3,    6,    9,   12,   16,   19,   22,
      25,   28,   31,   34,   37,   40,   43,   46,
      49,   51,   54,   57,   60,   63,   65,   68,
      71,   73,   76,   78,   81,   83,   85,   88,
      90,   92,   94,   96,   98,  100,  102,  104,
     106,  108,  109,  111,  112,  114,  115,  117,
     118,  119,  120,  121,  122,  123,  124,  124,
     125,  126,  126,  127,  127,  127,  127,  127,
     127,  127,  127,  127,  127,  127,  126,  126,
     125,  124,  124,  123,  122,  121,  120,  119,
     118,  117,  115,  114,  112,  111,  109,  108,
     106,  104,  102,  100,   98,   96,   94,   92,
      90,   88,   85,   83,   81,   78,   76,   73,
      71,   68,   65,   63,   60,   57,   54,   51,
      49,   46,   43,   40,   37,   34,   31,   28,
      25,   22,   19,   16,   12,    9,    6,    3,
       0,   -3,   -6,   -9,  -12,  -16,  -19,  -22,
     -25,  -28,  -31,  -34,  -37,  -40,  -43,  -46,
     -49,  -51,  -54,  -57,  -60,  -63,  -65,  -68,
     -71,  -73,  -76,  -78,  -81,  -83,  -85,  -88,
     -90,  -92,  -94,  -96,  -98, -100, -102, -104,
    -106, -108, -109, -111, -112, -114, -115, -117,
    -118, -119, -120, -121, -122, -123, -124, -124,
    -125, -126, -126, -127, -127, -127, -127, -127,
    -127, -127, -127, -127, -127, -127, -126, -126,
    -125, -124, -124, -123, -122, -121, -120, -119,
    -118, -117, -115, -114, -112, -111, -109, -108,
    -106, -104, -102, -100,  -98,  -96,  -94,  -92,
     -90,  -88,  -85,  -83,  -81,  -78,  -76,  -73,
     -71,  -68,  -65,  -63,  -60,  -57,  -54,  -51,
     -49,  -46,  -43,  -40,  -37,  -34,  -31,  -28,
     -25,  -22,  -19,  -16,  -12,   -9,   -6,   -3
};

#endif /* SINE_TABLE_H */
```

**Verification**: You can verify this table with Python:
```python
import math
for i in range(256):
    val = round(127 * math.sin(2 * math.pi * i / 256))
    print(f"{val:4d},", end='\n' if (i+1) % 8 == 0 else ' ')
```

---

### Task 6.5: Update data.asm with Correct Asset Paths

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\data.asm`

**Description**: After generating and converting all assets, verify that data.asm references the correct file paths for `.incbin` directives. This was created in Phase 4 but should be verified against actual generated files.

**Implementation Details**:

Check that these files exist and are non-empty before building:
- `assets/backgrounds/bg_earthbound.pic`
- `assets/backgrounds/bg_earthbound.pal`
- `assets/backgrounds/bg_earthbound.map`
- `assets/fonts/font_large.pic`
- `assets/fonts/font_large.pal`

The `.incbin` paths in data.asm are relative to the project directory (where wla-65816 runs). Verify these match the actual file locations.

---

## Acceptance Criteria

- [ ] `J:\code\snes\snes-build-tools\scripts\generate_background.py` exists and runs without errors
- [ ] `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\backgrounds\bg_earthbound.png` exists (256x256 pixels)
- [ ] Background PNG uses at most 16 colors
- [ ] gfx4snes conversion produces `bg_earthbound.pic`, `bg_earthbound.pal`, `bg_earthbound.map`
- [ ] Background tile data fits within the VRAM budget (< 8192 bytes or 256 tiles)
- [ ] `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\bg_effect.h` exists with effect parameters
- [ ] `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\sine_table.h` exists with 256-entry sine table
- [ ] Sine table values are correct (verify against mathematical computation)
- [ ] Effect parameters use HORIZONTAL distortion type
- [ ] Palette cycling parameters are defined (type 1, range 1-15, speed 4)
- [ ] data.asm `.incbin` paths match actual file locations

## File Manifest

| File | Action | Description |
|------|--------|-------------|
| `J:\code\snes\snes-build-tools\scripts\generate_background.py` | CREATE | Background PNG generator |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\backgrounds\bg_earthbound.png` | GENERATE | Background pattern image |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\backgrounds\bg_earthbound.pic` | GENERATE | SNES tile data |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\backgrounds\bg_earthbound.pal` | GENERATE | SNES palette |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\backgrounds\bg_earthbound.map` | GENERATE | SNES tilemap |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\bg_effect.h` | CREATE | Effect parameters |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\sine_table.h` | CREATE | Pre-computed sine table |

## Dependencies

- **Depends on**: Phase 1 (directories), Phase 3 (gfx4snes, Python), Phase 4 (Makefile rules, data.asm structure)
- **Depended on by**: Phase 7 (hardware init loads background data), Phase 8 (distortion engine uses effect parameters and sine table)
