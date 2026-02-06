# Phase 8: Background Distortion Engine

## Overview

This phase implements the Earthbound-style HDMA background animation engine. This is the most technically complex phase of the project. It ports the sine-wave distortion algorithm from the JavaScript reference at `J:\code\snes\snes-build-tools\tmp\Earthbound-Battle-Backgrounds-JS\src\rom\distorter.js` to C code running on the SNES 65816 CPU, using HDMA (Horizontal DMA) to apply per-scanline horizontal scroll offsets to BG1.

The engine has three components:
1. **Sine-wave distortion** -- Per-scanline BG1 horizontal scroll offsets via HDMA
2. **Palette cycling** -- Rotating background colors over time
3. **Constant scroll** -- Optional slow drift of the background

After this phase, the background should animate smoothly at 60fps with visible wave distortion.

## Prerequisites

- Phase 7 completed (ROM boots, displays static background and text)
- Phase 6 completed (effect parameters, sine table defined in headers)
- Understanding of SNES HDMA

## Objectives

1. Implement the HDMA scroll table generator
2. Implement the per-frame wave animation update
3. Implement palette cycling (forward rotation)
4. Implement optional constant background scroll
5. Configure HDMA hardware to apply the scroll table every frame
6. Achieve smooth 60fps animation

## Context

### SNES HDMA (Horizontal DMA)

HDMA is the key hardware feature that makes the Earthbound background effect possible on real SNES hardware. Unlike regular DMA (which transfers blocks of data during VBlank), HDMA transfers small amounts of data to PPU registers **every scanline** during active display.

**How HDMA works**:
1. During VBlank, the CPU sets up an HDMA table in RAM
2. The HDMA controller reads entries from the table during each scanline
3. Each entry writes 1-4 bytes to a specific PPU register
4. This allows changing scroll, color, window, etc. per-scanline

**HDMA Table Format** (Direct mode, 2-byte transfer to register pair):

For writing to BG1HOFS ($210D, a register that takes two sequential writes):

Using DMA transfer mode 2 (write to register, register+1):
```
Each table entry:
  Byte 0: Scanline count (1-127, or 0 = end of table)
           Bit 7: 0 = direct mode (count entries follow)
  Byte 1: Low byte of BG1 horizontal scroll
  Byte 2: High byte of BG1 horizontal scroll
```

**Example HDMA table** (apply different H-scroll to each scanline):
```
01 05 00    ; Scanline 1: scroll = 5
01 08 00    ; Scanline 2: scroll = 8
01 03 00    ; Scanline 3: scroll = 3
...
01 00 00    ; Scanline 224: scroll = 0
00          ; End of table
```

For our effect, each of the 224 visible scanlines gets a unique horizontal scroll value computed from the sine wave formula.

**HDMA Registers**:
- `$4300-$430A`: HDMA channel 0 configuration
- `$4310-$431A`: HDMA channel 1 configuration
- ... up to channel 7
- `$420C` (HDMAEN): Enable HDMA channels (bit mask)

**HDMA Channel Setup for BG1HOFS**:

| Register | Value | Purpose |
|----------|-------|---------|
| DMAPn ($43n0) | $00 | Transfer mode 0: 1 byte to single register |
| BBADn ($43n1) | $0D | PPU register $210D (BG1HOFS) |
| A1TnL ($43n2) | table_addr low | Source address (RAM) low byte |
| A1TnH ($43n3) | table_addr high | Source address (RAM) high byte |
| A1Bn  ($43n4) | $7E | Source bank ($7E = WRAM) |

Wait -- BG1HOFS ($210D) is a "write-twice" register (you write the low byte, then the high byte to the same address). This complicates HDMA setup.

**Corrected approach**: Use DMA transfer mode $02 (write to register twice):
- DMAPn = $02 means: write byte 1 to $210D, write byte 2 to $210D again
- This correctly handles the write-twice nature of BG scroll registers
- Each HDMA table entry is: count (1 byte) + data1 (1 byte) + data2 (1 byte)

Alternatively, PVSnesLib may have helper functions or macros for setting up HDMA.

### Porting the Distortion Algorithm

**Original JS** (from `distorter.js` lines 32-48):
```javascript
this.C1 = 1 / 512;                    // 0.001953125
this.C2 = 8 * PI / (1024 * 256);      // 0.0000096...
this.C3 = PI / 60;                     // 0.05236...

setOffsetConstants(ticks, effect) {
    const t2 = ticks * 2;
    this.amplitude = this.C1 * (amplitude + amplitudeAcceleration * t2);
    this.frequency = this.C2 * (frequency + frequencyAcceleration * t2);
    this.compression = 1 + (compression + compressionAcceleration * t2) / 256;
    this.speed = this.C3 * speed * ticks;
    this.S = y => round(this.amplitude * sin(this.frequency * y + this.speed));
}
```

**SNES-optimized approach**:

Instead of floating-point math, we use a fixed-point representation and the pre-computed sine table from Phase 6. The key insight is that the sine function's argument (`frequency * y + speed * ticks`) just needs to produce an index into our 256-entry sine table.

Simplified formula for SNES:
```
For each frame:
    phase += speed_increment        // 16-bit accumulator, wraps at 65536

For each scanline y (0..223):
    table_index = ((y * freq_scale) + phase) >> 8
    sine_value = sine_table[table_index & 0xFF]    // -127 to +127
    scroll_offset = (sine_value * amplitude) >> 7   // Scale by amplitude
    hdma_entry[y] = base_scroll + scroll_offset
```

This avoids all floating-point math and uses only integer multiply and shift operations, which the 65816 can handle.

### Palette Cycling on SNES

Palette cycling modifies CGRAM (color palette) data each frame. On SNES, CGRAM can only be written during VBlank (or force blank). So the cycle must:

1. During the main loop, compute the new palette values in a RAM buffer
2. During VBlank, DMA copy the buffer to CGRAM

This is exactly the pattern used in the reference code (`palette_cycle.js` lines 46-58 for forward rotation):

```javascript
// Type 1: Forward rotation
const cycleLength = end - start + 1;
const position = cycleCount % cycleLength;
for (i = start; i <= end; i++) {
    let newColor = i - position;
    if (newColor < start) newColor += cycleLength;
    nowColors[i] = originalColors[newColor];
}
```

## Tasks

### Task 8.1: Implement HDMA Table Generator

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c` (add to existing)

**Description**: Implement the function that generates the HDMA scroll table each frame based on the current wave phase and effect parameters.

**Implementation Details**:

Add these functions to main.c (or create a separate `bg_engine.c` / `bg_engine.h`):

**Code Example**:

```c
/* ==========================================================================
 * Background Distortion Engine
 *
 * Ported from: J:\code\snes\snes-build-tools\tmp\
 *              Earthbound-Battle-Backgrounds-JS\src\rom\distorter.js
 *
 * Original algorithm (distorter.js lines 32-48):
 *   S(y) = round(amplitude * sin(frequency * y + speed * ticks))
 *
 * SNES implementation:
 *   Uses pre-computed sine table (256 entries, -127 to +127)
 *   Fixed-point 8.8 arithmetic for phase and frequency
 *   HDMA writes BG1HOFS per-scanline for wave effect
 * ========================================================================== */

/* HDMA table for BG1 horizontal scroll */
/* Format: For each scanline: 1 byte count + 2 bytes scroll value */
/* Total: 224 entries * 3 bytes + 1 byte terminator = 673 bytes */
/* Must be in bank $7E (WRAM) for HDMA to access */
u8 hdma_bg1_table[224 * 3 + 1];

/* Double-buffered table (write to inactive buffer, swap after VBlank) */
/* This prevents visual tearing if table update takes too long */
u8 hdma_bg1_table_b[224 * 3 + 1];
u8 *active_hdma_table = hdma_bg1_table;

/* Animation state */
u16 wave_phase = 0;          /* Current phase of sine wave (8.8 fixed-point) */
u16 bg_scroll_x = 0;         /* Base horizontal scroll (for constant drift) */
u16 bg_scroll_y = 0;         /* Vertical scroll (for constant drift) */

/*
 * updateHDMATable()
 *
 * Generates the HDMA scroll table for the current frame.
 * Each of the 224 visible scanlines gets a unique horizontal scroll value
 * computed from the sine wave distortion.
 *
 * This function corresponds to distorter.js getAppliedOffset() (lines 68-73)
 * for HORIZONTAL distortion type:
 *   offset = round(amplitude * sin(frequency * y + speed))
 *   dx = (x + offset) mod 256
 *
 * SNES version:
 *   For each scanline y:
 *     index = ((y * BG_WAVE_FREQ_FP8) + wave_phase) >> 8
 *     sine_val = sine_table[index & 0xFF]    // -127..+127
 *     offset = (sine_val * BG_WAVE_AMPLITUDE) >> 7
 *     scroll = bg_scroll_x + offset
 */
void updateHDMATable(void) {
    u16 y;
    u16 table_index;
    s16 sine_val;
    s16 offset;
    s16 scroll_val;
    u8 *table = active_hdma_table;
    u16 pos = 0;

    for (y = 0; y < 224; y++) {
        /* Compute sine table index for this scanline */
        /* y * frequency_scale + phase, take upper byte as index */
        table_index = ((u32)y * BG_WAVE_FREQ_FP8 + wave_phase) >> 8;

        /* Look up sine value (-127 to +127) */
        sine_val = (s16)sine_table[table_index & 0xFF];

        /* Scale by amplitude to get pixel offset */
        /* amplitude is in pixels, sine is -127..+127 */
        /* offset = sine_val * amplitude / 128 (use shift for speed) */
        offset = (sine_val * BG_WAVE_AMPLITUDE) >> 7;

        /* Add base scroll position */
        scroll_val = (s16)bg_scroll_x + offset;

        /* Write HDMA table entry */
        /* Count: 1 scanline */
        table[pos++] = 1;
        /* Scroll value low byte */
        table[pos++] = (u8)(scroll_val & 0xFF);
        /* Scroll value high byte */
        table[pos++] = (u8)((scroll_val >> 8) & 0xFF);
    }

    /* End of HDMA table marker */
    table[pos] = 0;
}

/*
 * setupHDMA()
 *
 * Configure HDMA channel 0 to write to BG1HOFS ($210D) every scanline
 * using the scroll table.
 *
 * HDMA channel 0 registers:
 *   $4300 (DMAP0): DMA parameters
 *     - Transfer mode $02: write to register twice (for write-twice registers)
 *     - Direction: A-bus to B-bus
 *   $4301 (BBAD0): B-bus address = $0D (BG1HOFS = $210D, low byte)
 *   $4302-$4304 (A1T0): Source address in WRAM
 *
 * Then enable HDMA channel 0 via $420C
 */
void setupHDMA(void) {
    /* Build initial HDMA table */
    updateHDMATable();

    /* Configure HDMA channel 0 */
    /* Transfer mode: $02 = write 2 bytes to same register (write-twice) */
    REG_DMAP0 = 0x02;

    /* B-bus register: $0D = BG1HOFS ($210D) */
    REG_BBAD0 = 0x0D;

    /* Source address: our HDMA table in WRAM */
    /* PVSnesLib typically places data in bank $7E (WRAM) */
    REG_A1T0L = (u16)active_hdma_table & 0xFF;
    REG_A1T0H = ((u16)active_hdma_table >> 8) & 0xFF;
    REG_A1B0  = 0x7E;  /* Bank $7E = WRAM */

    /* Enable HDMA channel 0 */
    REG_HDMAEN = 0x01;
}

/*
 * updateBackgroundAnimation()
 *
 * Called once per frame in the main loop.
 * Updates the wave phase, regenerates the HDMA table,
 * updates palette cycling, and applies constant scroll.
 *
 * This corresponds to the animation loop in engine.js (lines 33-48):
 *   for each layer: overlayFrame(bitmap, letterbox, tick, alpha, erase)
 *   tick += frameSkip
 */
void updateBackgroundAnimation(void) {
    /* Advance wave phase */
    wave_phase += BG_WAVE_SPEED_FP8;

    /* Advance constant background scroll */
    bg_scroll_x += BG_SCROLL_H_SPEED;
    bg_scroll_y += BG_SCROLL_V_SPEED;

    /* Set BG1 vertical scroll (constant component) */
    /* This must be done during VBlank */
    REG_BG1VOFS = bg_scroll_y & 0xFF;
    REG_BG1VOFS = (bg_scroll_y >> 8) & 0xFF;

    /* Regenerate HDMA table with new phase */
    updateHDMATable();

    /* Update HDMA source address (in case we double-buffer) */
    REG_A1T0L = (u16)active_hdma_table & 0xFF;
    REG_A1T0H = ((u16)active_hdma_table >> 8) & 0xFF;

    /* Update palette cycling */
    updatePaletteCycle();
}
```

**Important Notes**:
- The `u32` multiplication `(u32)y * BG_WAVE_FREQ_FP8` may be slow on the 65816. If it causes frame drops, use a lookup table or accumulation loop instead:
  ```c
  u16 phase_accum = wave_phase;
  for (y = 0; y < 224; y++) {
      table_index = phase_accum >> 8;
      /* ... compute offset ... */
      phase_accum += BG_WAVE_FREQ_FP8;
  }
  ```
  This replaces multiplication with addition, which is much faster.
- HDMA table memory must be accessible to the HDMA controller. WRAM bank $7E is correct.
- Register writes to BG scroll registers are write-twice (write low byte first, then high byte to same address).

**References**:
- SNES HDMA documentation: https://snes.nesdev.org/wiki/DMA_and_HDMA
- BG scroll registers: https://snes.nesdev.org/wiki/PPU_Scrolling

---

### Task 8.2: Implement Palette Cycling Engine

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c` (add to existing)

**Description**: Implement palette forward rotation, ported from `palette_cycle.js` lines 46-58 in the reference code.

**Code Example**:

```c
/*
 * Palette Cycling Engine
 *
 * Ported from: J:\code\snes\snes-build-tools\tmp\
 *              Earthbound-Battle-Backgrounds-JS\src\rom\palette_cycle.js
 *
 * Forward rotation (Type 1, palette_cycle.js lines 46-58):
 *   cycleLength = end - start + 1
 *   position = cycleCount % cycleLength
 *   for i = start to end:
 *       newColor = i - position
 *       if newColor < start: newColor += cycleLength
 *       nowColors[i] = originalColors[newColor]
 */

/* Original palette (loaded from ROM, never modified) */
u16 original_palette[16];
/* Working palette buffer (modified each cycle, uploaded to CGRAM) */
u16 cycling_palette[16];

/* Palette cycling state */
u8 cycle_countdown = PAL_CYCLE_SPEED;
u8 cycle_count = 0;

/*
 * initPaletteCycle()
 *
 * Copy the original background palette into the cycling buffers.
 * Call this once after loading the background palette into CGRAM.
 */
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

/*
 * updatePaletteCycle()
 *
 * Called once per frame. Decrements the countdown timer.
 * When the timer reaches zero, rotates the palette forward by one position
 * and uploads the new palette to CGRAM.
 *
 * Must be called during VBlank (CGRAM writes only allowed during VBlank).
 */
void updatePaletteCycle(void) {
    u8 i;
    u8 cycleLength;
    u8 position;
    s8 newColorIdx;

    /* Check if palette cycling is enabled */
    if (PAL_CYCLE_SPEED == 0) return;

    /* Decrement countdown */
    cycle_countdown--;
    if (cycle_countdown > 0) return;

    /* Reset countdown */
    cycle_countdown = PAL_CYCLE_SPEED;

    /* Advance cycle position */
    cycle_count++;

    /* Compute new palette */
    cycleLength = PAL_CYCLE_END - PAL_CYCLE_START + 1;
    position = cycle_count % cycleLength;

    for (i = PAL_CYCLE_START; i <= PAL_CYCLE_END; i++) {
        /* Forward rotation: shift colors toward lower indices */
        newColorIdx = (s8)(i - position);
        if (newColorIdx < PAL_CYCLE_START) {
            newColorIdx += cycleLength;
        }
        cycling_palette[i] = original_palette[newColorIdx];
    }

    /* Upload modified palette to CGRAM */
    /* BG1 palette starts at CGRAM address 0 */
    dmaCopyCGram((u8 *)cycling_palette, 0, 32);  /* 16 colors * 2 bytes = 32 bytes */
}
```

**References**:
- palette_cycle.js cycleColors() type 1: `J:\code\snes\snes-build-tools\tmp\Earthbound-Battle-Backgrounds-JS\src\rom\palette_cycle.js` lines 46-58

---

### Task 8.3: Integrate Animation into Main Loop

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c`

**Description**: Update the main loop from Phase 7 to call the animation functions. The critical ordering is:

1. Wait for VBlank (to ensure we are in the vertical blank period)
2. Update CGRAM (palette cycling -- must be during VBlank)
3. Update HDMA table (can be done during active display, but safer during VBlank)
4. Re-enable HDMA for next frame

**Code Example** (updated main loop):

```c
int main(void) {
    /* Initialize console (resets PPU, force blank ON) */
    consoleInit();

    /* Load all graphics and configure PPU */
    initGraphics();

    /* Initialize palette cycling buffer */
    initPaletteCycle();

    /* Set up initial HDMA table and configure HDMA hardware */
    setupHDMA();

    /* Enable screen at full brightness */
    setScreenOn();

    /* Main loop - runs at 60fps (NTSC) synced to VBlank */
    while (1) {
        /* Wait for the VBlank interrupt */
        WaitForVBlank();

        /*
         * --- VBlank Processing (must complete within ~2273 scanlines worth of time) ---
         * CGRAM and OAM writes must happen during VBlank.
         * VRAM writes should also happen during VBlank if possible.
         */

        /* Update palette cycling (writes to CGRAM) */
        updatePaletteCycle();

        /* Update vertical scroll (constant drift) */
        bg_scroll_y += BG_SCROLL_V_SPEED;
        REG_BG1VOFS = bg_scroll_y & 0xFF;
        REG_BG1VOFS = (bg_scroll_y >> 8) & 0xFF;

        /* Advance wave animation phase */
        wave_phase += BG_WAVE_SPEED_FP8;

        /* Regenerate HDMA table for next frame */
        updateHDMATable();

        /*
         * Update HDMA source pointer.
         * The HDMA controller reloads from A1T each frame automatically
         * when HDMA is re-enabled, but it is good practice to ensure
         * the address is current.
         */
        REG_A1T0L = (u16)active_hdma_table & 0xFF;
        REG_A1T0H = ((u16)active_hdma_table >> 8) & 0xFF;

        /* Increment animation counter */
        tick++;
    }

    return 0;
}
```

**Important Performance Notes**:

The 65816 at 3.58 MHz has limited time during VBlank (~2273 CPU cycles at fast speed). If the HDMA table generation is too slow to complete within VBlank, we have two options:

1. **Split work**: Generate the HDMA table during active display (after VBlank but before the next VBlank). This is safe because the HDMA controller reads the table at the start of each frame and the current frame's table is already loaded.

2. **Double buffering**: Write to an inactive buffer during active display, swap buffers during VBlank. This prevents tearing.

The recommended approach (if performance is an issue):
```c
while (1) {
    /* During active display: compute next frame's HDMA table */
    wave_phase += BG_WAVE_SPEED_FP8;
    updateHDMATable();   /* Writes to inactive buffer */

    /* Wait for VBlank */
    WaitForVBlank();

    /* Quick VBlank work: palette update + buffer swap */
    updatePaletteCycle();
    swapHDMABuffers();   /* Point HDMA to newly computed table */

    tick++;
}
```

---

### Task 8.4: Handle HDMA Channel Conflicts

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c`

**Description**: Ensure HDMA does not conflict with PVSnesLib's internal DMA/HDMA usage. PVSnesLib may use certain DMA channels for its own purposes.

**Implementation Details**:

- PVSnesLib typically uses DMA channel 0 for general transfers
- We should use HDMA channel 1 (or higher) to avoid conflicts
- Check PVSnesLib documentation for which channels are reserved

If there is a conflict, adjust our HDMA setup to use a different channel:

```c
/* Use HDMA channel 1 instead of 0 to avoid PVSnesLib conflicts */
#define HDMA_CHANNEL  1

void setupHDMA(void) {
    updateHDMATable();

    /* Configure HDMA channel 1 */
    REG_DMAP1 = 0x02;       /* Transfer mode: write-twice */
    REG_BBAD1 = 0x0D;       /* BG1HOFS ($210D) */
    REG_A1T1L = (u16)active_hdma_table & 0xFF;
    REG_A1T1H = ((u16)active_hdma_table >> 8) & 0xFF;
    REG_A1B1  = 0x7E;

    /* Enable HDMA channel 1 (bit 1) */
    REG_HDMAEN |= (1 << HDMA_CHANNEL);
}
```

**References**:
- PVSnesLib DMA channel usage: Check `$(PVSNESLIB_HOME)/devkitsnes/include/snes/dma.h`
- SNES DMA channels: https://snes.nesdev.org/wiki/DMA_and_HDMA

---

### Task 8.5: Alternative -- Use PVSnesLib HDMA Helpers

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c`

**Description**: PVSnesLib may provide HDMA helper functions. If available, use them instead of direct register access for better compatibility.

**Implementation Details**:

Check PVSnesLib headers for HDMA functions:
```bash
grep -r "hdma\|HDMA" J:\code\snes\snes-build-tools\tools\pvsneslib\devkitsnes\include\
```

Possible PVSnesLib HDMA functions:
- `setModeHdmaWaves()` -- May set up wave effects directly
- `setMode7Hdma()` -- Mode 7 HDMA (not what we need)
- Manual HDMA setup may be required

If PVSnesLib has `setModeHdmaWaves()` or similar:
```c
/* PVSnesLib helper (if available) */
setModeHdmaWaves(0, hdma_bg1_table);  /* channel 0, our table */
```

If no helper exists, use the direct register approach from Task 8.1.

**References**:
- PVSnesLib video.h: `$(PVSNESLIB_HOME)/devkitsnes/include/snes/video.h`
- PVSnesLib examples with HDMA: Search `$(PVSNESLIB_HOME)/pvsneslib/snes-examples/` for HDMA usage

---

### Task 8.6: Performance Optimization

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c`

**Description**: Optimize the HDMA table generation to ensure it completes within the available CPU time. The 65816 is slow and the table has 224 entries to compute per frame.

**Implementation Details**:

Key optimization: Replace multiplication with accumulation in the scanline loop.

**Optimized version**:
```c
void updateHDMATable(void) {
    u16 y;
    u8 table_index;
    s16 sine_val;
    s16 offset;
    s16 scroll_val;
    u8 *table = active_hdma_table;
    u16 pos = 0;

    /* Use accumulation instead of multiplication */
    /* freq_accum starts at wave_phase and increments by BG_WAVE_FREQ_FP8 each scanline */
    u16 freq_accum = wave_phase;

    for (y = 0; y < 224; y++) {
        /* Table index is the upper byte of the frequency accumulator */
        table_index = (u8)(freq_accum >> 8);

        /* Sine lookup */
        sine_val = (s16)sine_table[table_index];

        /* Scale by amplitude (use shift instead of division) */
        /* BG_WAVE_AMPLITUDE is max pixel displacement */
        /* sine_val is -127..+127, we want offset in range -amplitude..+amplitude */
        offset = (sine_val * BG_WAVE_AMPLITUDE) >> 7;

        /* Final scroll value */
        scroll_val = (s16)bg_scroll_x + offset;

        /* Write HDMA entry */
        table[pos]     = 1;                        /* 1 scanline */
        table[pos + 1] = (u8)(scroll_val & 0xFF);  /* Scroll low */
        table[pos + 2] = (u8)(scroll_val >> 8);     /* Scroll high (usually 0) */
        pos += 3;

        /* Advance frequency accumulator */
        freq_accum += BG_WAVE_FREQ_FP8;
    }

    /* Table terminator */
    table[pos] = 0;
}
```

This replaces 224 multiplications with 224 additions -- a significant speedup on the 65816.

Additional optimizations:
- Unroll the loop by 2x or 4x
- Use `register` keyword for frequently accessed variables
- Move the table pointer into a local variable (compiler may not optimize this)
- If still too slow, pre-compute the entire table into ROM for fixed-parameter effects

---

## Acceptance Criteria

- [ ] The HDMA table generator produces a valid 673-byte table (224 entries * 3 bytes + 1 terminator)
- [ ] HDMA is correctly configured to write to BG1HOFS ($210D) per-scanline
- [ ] The background visually distorts with a sine-wave pattern when running in an emulator
- [ ] The wave animation is smooth (no visible jitter or frame drops)
- [ ] The wave phase advances each frame, creating continuous animation
- [ ] Palette cycling is visible (background colors shift over time)
- [ ] Vertical scroll works (background slowly drifts upward)
- [ ] Text on BG2 is NOT affected by the HDMA distortion (only BG1 is distorted)
- [ ] The animation runs at 60fps without frame drops
- [ ] HDMA does not conflict with PVSnesLib internal DMA usage
- [ ] The ROM runs correctly in both Mesen2 and bsnes

## File Manifest

| File | Action | Description |
|------|--------|-------------|
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c` | MODIFY | Add animation engine functions and update main loop |

## Dependencies

- **Depends on**: Phase 6 (effect parameters, sine table), Phase 7 (hardware initialization, static display)
- **Depended on by**: Phase 9 (final composition verifies animation + text together), Phase 10 (testing)
