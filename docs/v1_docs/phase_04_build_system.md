# Phase 4: Build System Configuration

## Overview

This phase creates the complete build infrastructure for the hello-snes-world demo project. This includes the Makefile, ROM header file (hdr.asm), data include file (data.asm), and any supporting build configuration. The build system must integrate with PVSnesLib's `snes_rules` Makefile include while adding custom rules for our asset pipeline.

After this phase, running `make` in the project directory should attempt to build a ROM (it will fail because source files and assets do not exist yet -- those come in Phases 5-9 -- but the build system itself must be structurally correct and ready).

## Prerequisites

- Phase 1 completed (directory structure exists)
- Phase 2 completed (SDK layout is documented)
- Phase 3 completed (PVSnesLib installed, `PVSNESLIB_HOME` is set)
- Understanding of PVSnesLib's `snes_rules` build flow

## Objectives

1. Create the project Makefile at `J:\code\snes\snes-build-tools\projects\hello-snes-world\Makefile`
2. Create the ROM header file at `J:\code\snes\snes-build-tools\projects\hello-snes-world\hdr.asm`
3. Create the data include file at `J:\code\snes\snes-build-tools\projects\hello-snes-world\data.asm`
4. Ensure the build pipeline supports: C compilation, ASM assembly, graphics conversion, ROM linking
5. Define clean, build, and rebuild targets

## Context

### PVSnesLib Build Pipeline

The build pipeline follows this flow:

```
C source (.c)
    |
    v
816-tcc (C compiler -> 65816 ASM)
    |
    v
ASM source (.asm)
    |
    v
816-opt (optimizer)
    |
    v
Optimized ASM (.asm)
    |
    v
wla-65816 (assembler -> object file)
    |
    v
Object file (.obj)
    |
    v
wlalink (linker, combines all .obj + hdr.asm + data.asm)
    |
    v
ROM file (.sfc)
```

Graphics pipeline (runs before or alongside the main build):
```
PNG file (.png)
    |
    v
gfx4snes (converter)
    |
    v
.pic (tile data) + .pal (palette) + .map (tilemap)
    |
    v
Referenced in data.asm via .incbin
    |
    v
Assembled and linked into ROM
```

### PVSnesLib snes_rules

The file `$(PVSNESLIB_HOME)/devkitsnes/lib/snes_rules` is a Makefile include that provides:

- Tool path variables (`PVSNESLIB_TOOLS`, etc.)
- Pattern rules for `.c` -> `.asm` -> `.obj`
- Standard compiler and assembler flags
- The `sfc` target that produces the final ROM

The project Makefile `include`s this file and adds project-specific configuration.

### ROM Memory Map (LoROM)

Our ROM uses the LoROM memory map:
- Bank $00-$7D: ROM data (lower 32KB per bank: $8000-$FFFF)
- Interrupt vectors at $00:FFE0-$00:FFFF
- SRAM (if used) at $70:0000-$7D:7FFF
- ROM size: 4Mbit (512KB) -- more than enough for our demo

### SNES ROM Header

The ROM header sits at LoROM offset $00:FFC0 and contains:
- ROM title (21 bytes, padded with spaces)
- ROM makeup byte (LoROM = $20)
- ROM type (ROM only = $00, ROM+SRAM = $02)
- ROM size (2^N KB, $09 = 512KB = 4Mbit)
- SRAM size ($00 = no SRAM)
- Country code ($01 = North America)
- Developer ID
- Version
- Checksum complement + checksum (calculated by snestools)
- Interrupt vectors (NMI, RESET, IRQ, etc.)

## Tasks

### Task 4.1: Create the Project Makefile

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\Makefile`

**Description**: Create the main Makefile that orchestrates the entire build. It must include PVSnesLib's snes_rules, define the ROM name, set up graphics conversion rules, and provide standard targets (all, clean, rebuild).

**Implementation Details**:

The Makefile must:
1. Set the `PVSNESLIB_HOME` variable (from environment or default)
2. Include `snes_rules` from the SDK
3. Define the output ROM name
4. Add custom rules for converting PNG assets to SNES format using gfx4snes
5. Declare dependencies so assets are converted before the ROM is linked
6. Provide `clean`, `all`, and `rebuild` targets

**Code Example**:

```makefile
# ==============================================================================
# SNES Build Tools - Hello SNES World
# Makefile for building the demo ROM using PVSnesLib
# ==============================================================================

# --- ROM Configuration ---
ROM_NAME   = hello_snes_world
SNES_TYPE  = lorom

# --- PVSnesLib SDK Path ---
# This should be set by env.bat/env.sh, but provide a default relative path
PVSNESLIB_HOME ?= ../../tools/pvsneslib

# --- Directory Configuration ---
SRC_DIR    = src
ASSET_DIR  = assets
BUILD_DIR  = build
FONT_DIR   = $(ASSET_DIR)/fonts
BG_DIR     = $(ASSET_DIR)/backgrounds

# --- Tool Paths ---
GFX4SNES   = $(PVSNESLIB_HOME)/devkitsnes/tools/gfx4snes

# --- Source Files ---
C_SOURCES  = $(wildcard $(SRC_DIR)/*.c)

# --- Asset Files (PNGs that need conversion) ---
FONT_PNG   = $(FONT_DIR)/font_large.png
BG_PNG     = $(BG_DIR)/bg_earthbound.png

# --- Generated Asset Files ---
# Font tiles and palette (no tilemap - we generate that programmatically)
FONT_TILES = $(FONT_DIR)/font_large.pic
FONT_PAL   = $(FONT_DIR)/font_large.pal

# Background tiles, palette, and tilemap
BG_TILES   = $(BG_DIR)/bg_earthbound.pic
BG_PAL     = $(BG_DIR)/bg_earthbound.pal
BG_MAP     = $(BG_DIR)/bg_earthbound.map

# Collect all generated assets
GENERATED_ASSETS = $(FONT_TILES) $(FONT_PAL) $(BG_TILES) $(BG_PAL) $(BG_MAP)

# --- Include PVSnesLib build rules ---
# snes_rules provides: compiler flags, pattern rules, sfc target
include $(PVSNESLIB_HOME)/devkitsnes/lib/snes_rules

# ==============================================================================
# Targets
# ==============================================================================

# Default target
all: assets $(ROM_NAME).sfc
	@echo.
	@echo ============================================
	@echo  Build complete: $(ROM_NAME).sfc
	@echo ============================================

# Build all assets before compiling
assets: $(GENERATED_ASSETS)
	@echo Assets converted successfully.

# --- Font Asset Conversion ---
# Convert font PNG to SNES 4bpp tiles + palette
# -b 4 = 4 bits per pixel (16 colors)
# -s 8 = 8x8 tile size
# -R = reduce/optimize duplicate tiles
$(FONT_DIR)/font_large.pic $(FONT_DIR)/font_large.pal: $(FONT_PNG)
	@echo Converting font: $(FONT_PNG)
	$(GFX4SNES) -i $(FONT_PNG) -o $(FONT_DIR)/font_large -p -t -s 8 -b 4 -R

# --- Background Asset Conversion ---
# Convert background PNG to SNES 4bpp tiles + palette + tilemap
# -m = generate tilemap
$(BG_DIR)/bg_earthbound.pic $(BG_DIR)/bg_earthbound.pal $(BG_DIR)/bg_earthbound.map: $(BG_PNG)
	@echo Converting background: $(BG_PNG)
	$(GFX4SNES) -i $(BG_PNG) -o $(BG_DIR)/bg_earthbound -p -t -m -s 8 -b 4 -R

# --- Clean ---
clean:
	@echo Cleaning build artifacts...
	-rm -f $(SRC_DIR)/*.asm
	-rm -f *.obj
	-rm -f *.sfc
	-rm -f *.sym
	-rm -f $(GENERATED_ASSETS)
	@echo Clean complete.

# --- Rebuild ---
rebuild: clean all

# --- Phony targets ---
.PHONY: all assets clean rebuild

# ==============================================================================
# Build Dependencies
# ==============================================================================

# The ROM depends on all generated assets being available
# data.asm includes the binary assets via .incbin
$(ROM_NAME).sfc: $(GENERATED_ASSETS)
```

**Important Notes**:
- The exact syntax of the Makefile may need adjustment based on the specific version of PVSnesLib's `snes_rules`. The `snes_rules` file defines its own pattern rules and may expect certain variable names.
- Check `$(PVSNESLIB_HOME)/devkitsnes/lib/snes_rules` after installation to see what variables and targets it expects.
- PVSnesLib's snes_rules typically expects: the project Makefile to define `SNESLIB`, source files, and the target name.
- The Makefile above is a starting template. After Phase 3 installs PVSnesLib, read the actual `snes_rules` file and adjust variable names and rules accordingly.

**References**:
- PVSnesLib example Makefiles: https://github.com/alekmaul/pvsneslib/tree/master/snes-examples
- GNU Make manual: https://www.gnu.org/software/make/manual/

---

### Task 4.2: Create ROM Header File (hdr.asm)

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\hdr.asm`

**Description**: Create the assembly file that defines the SNES ROM header, memory map, and interrupt vectors. This file is assembled by wla-65816 and linked into the ROM at the correct position.

**Implementation Details**:

The ROM header for a LoROM cartridge must define:
- Memory map directives for wla-65816
- ROM registration data at $00:FFC0
- Interrupt vector table at $00:FFE0
- Proper SNES header fields (title, type, size, etc.)

**Code Example**:

```asm
;==============================================================================
; SNES ROM Header - Hello SNES World
; LoROM mapping, 4Mbit (512KB), no SRAM
;==============================================================================

.MEMORYMAP
    SLOTSIZE $8000          ; Each bank is 32KB in LoROM
    DEFAULTSLOT 0
    SLOT 0 $8000            ; ROM slot starts at $8000
.ENDME

.ROMBANKSIZE $8000          ; 32KB per bank
.ROMBANKS 16                ; 16 banks = 512KB = 4Mbit

;==============================================================================
; SNES Header (at LoROM offset $00:FFC0)
;==============================================================================

.SNESHEADER
    ID "SNES"                          ; 4-byte ID (optional, for tools)

    NAME "HELLO SNES WORLD   "         ; 21 bytes, padded with spaces

    LOROM                              ; LoROM memory mapping
    SLOWROM                            ; SlowROM speed (2.68 MHz access)

    CARTRIDGETYPE $00                  ; ROM only (no SRAM, no battery)
    ROMSIZE $09                        ; 2^9 = 512 KB = 4 Mbit
    SRAMSIZE $00                       ; No SRAM
    COUNTRY $01                        ; North America (NTSC)
    LICENSEECODE $00                   ; No license (homebrew)
    VERSION $00                        ; Version 1.0
.ENDSNES

;==============================================================================
; Interrupt Vectors
;==============================================================================

.SNESNATIVEVECTOR
    COP     EmptyHandler
    BRK     EmptyHandler
    ABORT   EmptyHandler
    NMI     VBlank                      ; VBlank/NMI interrupt handler
    IRQ     EmptyHandler
.ENDNATIVEVECTOR

.SNESEMUVECTOR
    COP     EmptyHandler
    ABORT   EmptyHandler
    NMI     EmptyHandler
    RESET   tcc__start                  ; Reset vector -> C runtime entry
    IRQBRK  EmptyHandler
.ENDEMUVECTOR

;==============================================================================
; Empty interrupt handler
;==============================================================================

.BANK 0 SLOT 0
.ORG 0
.SECTION "EmptyVectors" SEMIFREE

EmptyHandler:
    rti

.ENDS
```

**Important Notes**:
- The `tcc__start` label is the C runtime entry point defined by PVSnesLib's `crt0_snes.asm`.
- The `VBlank` label is the NMI handler that PVSnesLib expects. It is defined in the PVSnesLib library.
- wla-65816 requires `.MEMORYMAP`, `.ROMBANKSIZE`, and `.ROMBANKS` directives.
- The actual header format may vary slightly depending on the PVSnesLib version. Check the SDK's example `hdr.asm` files after installation.
- PVSnesLib may provide its own `hdr.asm` template in `devkitsnes/lib/`. If so, use that as the base and customize only the ROM name and settings.

**References**:
- WLA DX assembler documentation: https://wla-dx.readthedocs.io/en/latest/
- SNES ROM header format: https://snes.nesdev.org/wiki/ROM_header
- PVSnesLib hdr.asm examples: Check `$(PVSNESLIB_HOME)/pvsneslib/snes-examples/` after installation

---

### Task 4.3: Create Data Include File (data.asm)

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\data.asm`

**Description**: Create the assembly file that includes all binary asset data (tiles, palettes, tilemaps) into the ROM. This file uses `.incbin` directives to embed the converted graphics data.

**Implementation Details**:

`data.asm` serves as the bridge between the asset pipeline output and the ROM. Each `.incbin` creates a labeled block of data that C code can reference via `extern` declarations.

The labels must match what the C code expects. PVSnesLib convention is to use the filename (without extension) as the label prefix.

**Code Example**:

```asm
;==============================================================================
; Data Includes - Hello SNES World
; Binary asset data embedded into ROM
;==============================================================================

.BANK 1 SLOT 0
.ORG 0
.SECTION "GfxData" SUPERFREE

;----------------------------------------------------------------------
; Background tiles (4bpp, produced by gfx4snes from bg_earthbound.png)
;----------------------------------------------------------------------
bg_earthbound_tiles:
    .INCBIN "assets/backgrounds/bg_earthbound.pic"
bg_earthbound_tiles_end:

;----------------------------------------------------------------------
; Background palette (SNES 15-bit color format)
;----------------------------------------------------------------------
bg_earthbound_palette:
    .INCBIN "assets/backgrounds/bg_earthbound.pal"
bg_earthbound_palette_end:

;----------------------------------------------------------------------
; Background tilemap (32x32 tile entries, 2 bytes each = 2048 bytes)
;----------------------------------------------------------------------
bg_earthbound_map:
    .INCBIN "assets/backgrounds/bg_earthbound.map"
bg_earthbound_map_end:

.ENDS

.SECTION "FontData" SUPERFREE

;----------------------------------------------------------------------
; Font tiles (4bpp, large pixel font for "HELLO SNES WORLD")
;----------------------------------------------------------------------
font_large_tiles:
    .INCBIN "assets/fonts/font_large.pic"
font_large_tiles_end:

;----------------------------------------------------------------------
; Font palette
;----------------------------------------------------------------------
font_large_palette:
    .INCBIN "assets/fonts/font_large.pal"
font_large_palette_end:

.ENDS

;==============================================================================
; Size calculation labels (for DMA transfer sizes in C code)
; Access from C: extern char label, label_end;
;                u16 size = &label_end - &label;
;==============================================================================
```

**Important Notes on C Access**:
In PVSnesLib, C code references data.asm labels like this:

```c
// In main.c or a header file
extern char bg_earthbound_tiles, bg_earthbound_tiles_end;
extern char bg_earthbound_palette, bg_earthbound_palette_end;
extern char bg_earthbound_map, bg_earthbound_map_end;
extern char font_large_tiles, font_large_tiles_end;
extern char font_large_palette, font_large_palette_end;
```

To get the size of a data block:
```c
u16 tileSize = &bg_earthbound_tiles_end - &bg_earthbound_tiles;
```

To DMA copy:
```c
dmaCopyVram(&bg_earthbound_tiles, 0x0000, tileSize);
```

**References**:
- WLA DX .INCBIN documentation: https://wla-dx.readthedocs.io/en/latest/asmdiv.html
- PVSnesLib data.asm examples: Check SDK examples after installation

---

### Task 4.4: Create a Minimal main.c Stub

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c`

**Description**: Create a minimal C source file that compiles but does nothing meaningful. This is a build system validation stub that will be replaced in Phase 7 with the real initialization code.

**Implementation Details**:

The stub should:
- Include the PVSnesLib header
- Have a `main()` function
- Enter an infinite loop (standard for SNES programs)
- Compile without errors when the build system is correctly configured

**Code Example**:

```c
/*
 * Hello SNES World - Main Source
 * Phase 4: Build system stub (will be replaced in Phase 7+)
 */

#include <snes.h>

int main(void) {
    /* Initialize console (sets up basic PPU state) */
    consoleInit();

    /* Set video mode 1 (3 BG layers) */
    setMode(BG_MODE1, 0);

    /* Enable screen */
    setScreenOn();

    /* Main loop - SNES programs never exit */
    while (1) {
        WaitForVBlank();
    }

    return 0;
}
```

**Notes**:
- This stub validates that the build system can find headers, compile C, assemble, and link.
- The `consoleInit()` function initializes the PPU to a known state.
- `WaitForVBlank()` halts until the next NMI (vertical blank), which is the standard SNES main loop pattern.
- This file will be heavily modified in Phases 7-9.

---

### Task 4.5: Create a Build Test Script

**File(s)**: `J:\code\snes\snes-build-tools\scripts\test_build.bat`

**Description**: A script that runs the build and verifies the output ROM exists. This is used to validate the build system configuration independently of the ROM content.

**Code Example**:

```batch
@echo off
setlocal

echo SNES Build Tools - Build Test
echo ==============================
echo.

set "REPO_ROOT=%~dp0.."
if "%REPO_ROOT:~-1%"=="\" set "REPO_ROOT=%REPO_ROOT:~0,-1%"

:: Set up environment
call "%REPO_ROOT%\env.bat" >nul 2>&1

:: Navigate to project
set "PROJECT_DIR=%REPO_ROOT%\projects\hello-snes-world"

echo Building in: %PROJECT_DIR%
echo.

:: Clean first
cd /d "%PROJECT_DIR%"
make clean 2>nul

:: Build
make
if %errorlevel% neq 0 (
    echo.
    echo BUILD FAILED
    echo Check the error messages above.
    exit /b 1
)

:: Check for output ROM
if exist "%PROJECT_DIR%\hello_snes_world.sfc" (
    echo.
    echo BUILD SUCCEEDED
    echo ROM: %PROJECT_DIR%\hello_snes_world.sfc
    for %%F in ("%PROJECT_DIR%\hello_snes_world.sfc") do echo Size: %%~zF bytes
) else (
    echo.
    echo BUILD FAILED - ROM file not found
    exit /b 1
)

endlocal
exit /b 0
```

---

## Acceptance Criteria

- [ ] `J:\code\snes\snes-build-tools\projects\hello-snes-world\Makefile` exists and includes `snes_rules`
- [ ] `J:\code\snes\snes-build-tools\projects\hello-snes-world\hdr.asm` exists with valid LoROM header
- [ ] `J:\code\snes\snes-build-tools\projects\hello-snes-world\data.asm` exists with `.incbin` directives
- [ ] `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c` exists with minimal stub
- [ ] The Makefile defines `all`, `clean`, and `rebuild` targets
- [ ] The Makefile includes graphics conversion rules for both font and background PNGs
- [ ] The hdr.asm defines the correct LoROM memory map with 16 banks (512KB)
- [ ] The hdr.asm ROM title reads "HELLO SNES WORLD"
- [ ] The data.asm labels match the extern declarations documented for C code access
- [ ] Running `make` (with assets present) should produce `hello_snes_world.sfc`
- [ ] Running `make clean` removes all generated files

## File Manifest

| File | Action | Description |
|------|--------|-------------|
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\Makefile` | CREATE | Project build configuration |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\hdr.asm` | CREATE | ROM header with LoROM memory map |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\data.asm` | CREATE | Binary asset includes |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\main.c` | CREATE | Minimal C stub for build validation |
| `J:\code\snes\snes-build-tools\scripts\test_build.bat` | CREATE | Build test script |

## Dependencies

- **Depends on**: Phase 1 (directories), Phase 2 (SDK layout knowledge), Phase 3 (PVSnesLib installed)
- **Depended on by**: Phase 5 (font conversion uses Makefile rules), Phase 6 (background conversion uses Makefile rules), Phase 7 (ROM bootstrap extends main.c and hdr.asm), Phase 8 (background engine uses build system), Phase 9 (text rendering uses build system)
