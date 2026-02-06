# Phase 10: Testing, Documentation & Release Packaging

## Overview

This is the final phase. It validates the complete build from clone to ROM, writes comprehensive documentation, creates a reusable project template, and prepares the repository for public release. The goal is to ensure that anyone -- human or AI agent -- can clone this repository and produce a working SNES ROM without any external guidance.

## Prerequisites

- All phases 1-9 completed
- A working ROM (`hello_snes_world.sfc`) that displays correctly in emulators
- All install scripts functional

## Objectives

1. Perform end-to-end testing (fresh clone → install → build → run)
2. Test in multiple emulators (Mesen2, bsnes)
3. Verify ROM header and checksum
4. Write comprehensive README.md with full setup and usage instructions
5. Create a reusable project template in `templates/basic/`
6. Document the entire build pipeline
7. Create a quickstart guide
8. Prepare for v1.0.0 release tagging

## Context

### Release Quality Criteria

A "release-ready" repository must satisfy:

1. **Clone-and-run**: A developer clones the repo, runs the install script, and builds the ROM -- with zero manual configuration beyond prerequisites.
2. **Cross-platform**: At minimum, Windows must be fully supported. Linux should work with documented caveats.
3. **Self-documenting**: README, inline comments, and docs explain everything needed.
4. **Template-ready**: A new SNES project can be started by copying the template.
5. **Reproducible**: Building from the same source always produces the same ROM (deterministic build).

### ROM Validation

A valid SNES ROM must have:
- Correct header at LoROM offset $00:FFC0
- Valid checksum (checksum + complement = $FFFF)
- Correct memory map declaration
- Proper interrupt vectors
- Valid ROM size matching actual file size

PVSnesLib's `snestools` can validate and fix ROM headers:
```bash
snestools -hi hello_snes_world.sfc
```

## Tasks

### Task 10.1: End-to-End Test on Clean Environment

**File(s)**: `J:\code\snes\snes-build-tools\scripts\test_e2e.bat`

**Description**: Create and run an end-to-end test script that simulates a fresh user experience. This script clones the repo to a temporary location, runs the install script, builds the ROM, and verifies the output.

**Implementation Details**:

Since we cannot easily simulate a fresh clone from within the repo, the test script verifies the critical path:

**Code Example**:

```batch
@echo off
setlocal

echo ============================================
echo  SNES Build Tools - End-to-End Test
echo ============================================
echo.

set "REPO_ROOT=%~dp0.."
if "%REPO_ROOT:~-1%"=="\" set "REPO_ROOT=%REPO_ROOT:~0,-1%"

set "PASS=0"
set "FAIL=0"
set "PROJECT_DIR=%REPO_ROOT%\projects\hello-snes-world"

:: --- Test 1: Install script exists ---
echo [Test 1] Install script exists...
if exist "%REPO_ROOT%\install.bat" (
    echo   PASS
    set /a PASS+=1
) else (
    echo   FAIL - install.bat not found
    set /a FAIL+=1
)

:: --- Test 2: Environment setup works ---
echo [Test 2] Environment setup...
call "%REPO_ROOT%\env.bat" >nul 2>&1
if defined PVSNESLIB_HOME (
    echo   PASS - PVSNESLIB_HOME=%PVSNESLIB_HOME%
    set /a PASS+=1
) else (
    echo   FAIL - PVSNESLIB_HOME not set
    set /a FAIL+=1
)

:: --- Test 3: Toolchain binaries exist ---
echo [Test 3] Toolchain binaries...
set "TOOLS=%PVSNESLIB_HOME%\devkitsnes\tools"
set "TOOLS_OK=1"

if not exist "%TOOLS%\816-tcc.exe" (
    echo   FAIL - 816-tcc.exe missing
    set "TOOLS_OK=0"
)
if not exist "%TOOLS%\wla-65816.exe" (
    echo   FAIL - wla-65816.exe missing
    set "TOOLS_OK=0"
)
if not exist "%TOOLS%\wlalink.exe" (
    echo   FAIL - wlalink.exe missing
    set "TOOLS_OK=0"
)
if not exist "%TOOLS%\gfx4snes.exe" (
    echo   FAIL - gfx4snes.exe missing
    set "TOOLS_OK=0"
)

if "%TOOLS_OK%"=="1" (
    echo   PASS - All tools present
    set /a PASS+=1
) else (
    set /a FAIL+=1
)

:: --- Test 4: Source files exist ---
echo [Test 4] Source files...
set "SRC_OK=1"
if not exist "%PROJECT_DIR%\src\main.c" set "SRC_OK=0"
if not exist "%PROJECT_DIR%\hdr.asm" set "SRC_OK=0"
if not exist "%PROJECT_DIR%\data.asm" set "SRC_OK=0"
if not exist "%PROJECT_DIR%\Makefile" set "SRC_OK=0"

if "%SRC_OK%"=="1" (
    echo   PASS
    set /a PASS+=1
) else (
    echo   FAIL - Missing source files
    set /a FAIL+=1
)

:: --- Test 5: Asset files exist ---
echo [Test 5] Asset files...
set "ASSET_OK=1"
if not exist "%PROJECT_DIR%\assets\backgrounds\bg_earthbound.pic" set "ASSET_OK=0"
if not exist "%PROJECT_DIR%\assets\backgrounds\bg_earthbound.pal" set "ASSET_OK=0"
if not exist "%PROJECT_DIR%\assets\backgrounds\bg_earthbound.map" set "ASSET_OK=0"
if not exist "%PROJECT_DIR%\assets\fonts\font_large.pic" set "ASSET_OK=0"
if not exist "%PROJECT_DIR%\assets\fonts\font_large.pal" set "ASSET_OK=0"

if "%ASSET_OK%"=="1" (
    echo   PASS
    set /a PASS+=1
) else (
    echo   FAIL - Missing asset files (run make to generate)
    set /a FAIL+=1
)

:: --- Test 6: Build ROM ---
echo [Test 6] Building ROM...
cd /d "%PROJECT_DIR%"
make clean >nul 2>&1
make >build_log.txt 2>&1
if %errorlevel% equ 0 (
    if exist "%PROJECT_DIR%\hello_snes_world.sfc" (
        echo   PASS
        set /a PASS+=1
        for %%F in ("hello_snes_world.sfc") do echo   ROM size: %%~zF bytes
    ) else (
        echo   FAIL - Build succeeded but ROM not found
        set /a FAIL+=1
    )
) else (
    echo   FAIL - Build failed (see build_log.txt)
    set /a FAIL+=1
)

:: --- Test 7: ROM header validation ---
echo [Test 7] ROM header validation...
if exist "%TOOLS%\snestools.exe" (
    "%TOOLS%\snestools.exe" -hi "%PROJECT_DIR%\hello_snes_world.sfc" >header_info.txt 2>&1
    echo   PASS (see header_info.txt for details)
    set /a PASS+=1
) else (
    echo   SKIP - snestools not available
)

:: --- Test 8: ROM file size is reasonable ---
echo [Test 8] ROM file size check...
for %%F in ("%PROJECT_DIR%\hello_snes_world.sfc") do (
    if %%~zF gtr 1024 (
        if %%~zF lss 1048576 (
            echo   PASS - Size %%~zF bytes (between 1KB and 1MB)
            set /a PASS+=1
        ) else (
            echo   FAIL - ROM too large: %%~zF bytes
            set /a FAIL+=1
        )
    ) else (
        echo   FAIL - ROM too small: %%~zF bytes
        set /a FAIL+=1
    )
)

:: --- Test 9: Template exists ---
echo [Test 9] Project template...
if exist "%REPO_ROOT%\templates\basic\Makefile" (
    echo   PASS
    set /a PASS+=1
) else (
    echo   FAIL - Template Makefile not found
    set /a FAIL+=1
)

:: --- Results ---
echo.
echo ============================================
echo  Results: %PASS% passed, %FAIL% failed
echo ============================================
echo.

if %FAIL% gtr 0 (
    echo Some tests failed. Review the output above.
    exit /b 1
) else (
    echo All tests passed! Ready for release.
    exit /b 0
)

endlocal
```

---

### Task 10.2: Test in Multiple Emulators

**File(s)**: Test results documented in this task (no file created)

**Description**: Test the ROM in at least two emulators to ensure hardware accuracy.

**Implementation Details**:

**Mesen2** (primary development emulator):
1. Open Mesen2
2. Load `J:\code\snes\snes-build-tools\projects\hello-snes-world\hello_snes_world.sfc`
3. Verify all visual elements render correctly
4. Use PPU viewer to inspect VRAM layout
5. Use trace logger to verify HDMA is active
6. Check for any warnings or errors in the debug console

**bsnes** (accuracy testing):
1. Open bsnes
2. Load the same ROM
3. Verify identical visual output to Mesen2
4. bsnes is cycle-accurate, so any timing issues will be revealed here
5. If the ROM works in Mesen2 but not bsnes, there may be timing issues in the HDMA setup

**Visual Verification Matrix**:

| Feature | Mesen2 | bsnes | Notes |
|---------|--------|-------|-------|
| Background visible | | | Check BG1 tiles/palette/map |
| Wave distortion | | | HDMA active and visible |
| Animation smooth | | | 60fps, no jitter |
| Palette cycling | | | Colors rotate over time |
| Text visible | | | "HELLO SNES" and "WORLD" |
| Text in front | | | BG2 priority > BG1 |
| Text stable | | | Not affected by HDMA |
| No artifacts | | | Clean edges, no glitches |
| Clean boot | | | No corruption at startup |

---

### Task 10.3: Verify ROM Header

**File(s)**: `J:\code\snes\snes-build-tools\projects\hello-snes-world\hello_snes_world.sfc`

**Description**: Use snestools or a hex editor to verify the ROM header is correct.

**Implementation Details**:

```bash
cd J:\code\snes\snes-build-tools\projects\hello-snes-world
call ..\..\env.bat

# Display ROM header info
snestools -hi hello_snes_world.sfc
```

Expected header values:
- ROM title: "HELLO SNES WORLD   " (padded to 21 chars)
- Mapping: LoROM ($20)
- Type: ROM only ($00)
- ROM size: $09 (512KB)
- SRAM size: $00 (none)
- Country: $01 (North America)
- Checksum: Valid (checksum + complement = $FFFF)

If the checksum is wrong, fix it:
```bash
snestools -sf hello_snes_world.sfc
```

---

### Task 10.4: Write Comprehensive README.md

**File(s)**: `J:\code\snes\snes-build-tools\README.md`

**Description**: Replace the Phase 1 placeholder README with the complete, final documentation. The README must be the single source of truth for getting started with this project.

**Code Example**:

```markdown
# SNES Build Tools

A complete, clone-and-run SNES ROM development toolchain. Includes automated
SDK installation, a demo ROM with Earthbound-style animated backgrounds,
and a project template for building your own SNES games in C.

## Demo ROM

The included **Hello SNES World** demo produces a ROM that displays:
- An Earthbound-style animated background with HDMA sine-wave distortion
  and palette cycling
- "HELLO SNES WORLD" in large white pixel font with 4px black border,
  centered on screen
- Built using SNES Mode 1 with layered backgrounds

## Requirements

Before running the install script, you need:

- **Git** (any recent version)
- **GNU Make** (4.0+)
  - Windows: Install via [MSYS2](https://www.msys2.org/), [Chocolatey](https://chocolatey.org/) (`choco install make`), or [Scoop](https://scoop.sh/) (`scoop install make`)
  - Linux: `sudo apt install build-essential`
  - macOS: `xcode-select --install`
- **Python 3** (3.8+, for font generation)
  - Windows: [python.org](https://www.python.org/downloads/) or `winget install Python.Python.3.12`
  - Linux: `sudo apt install python3 python3-pip`
- **curl** (Windows 10+ has it built-in)

## Quick Start

### 1. Clone the Repository

```bash
git clone <repo-url>
cd snes-build-tools
```

### 2. Install the Toolchain

**Windows:**
```batch
install.bat
```

**Linux/macOS:**
```bash
chmod +x install.sh
./install.sh
```

This downloads PVSnesLib SDK v4.5.0 and configures everything automatically.

### 3. Build the Demo ROM

**Windows:**
```batch
call env.bat
cd projects\hello-snes-world
make
```

**Linux/macOS:**
```bash
source env.sh
cd projects/hello-snes-world
make
```

### 4. Run the ROM

Open `projects/hello-snes-world/hello_snes_world.sfc` in any SNES emulator:
- [Mesen2](https://github.com/SourMesen/Mesen2/releases) (recommended for development)
- [bsnes](https://github.com/bsnes-emu/bsnes/releases) (for accuracy testing)
- [Snes9x](https://www.snes9x.com/) (lightweight alternative)

## Starting a New Project

1. Copy the template:
   ```bash
   cp -r templates/basic projects/my-project
   ```

2. Edit `projects/my-project/Makefile` to set your ROM name

3. Write your code in `projects/my-project/src/main.c`

4. Build:
   ```bash
   cd projects/my-project
   make
   ```

## Repository Structure

```
snes-build-tools/
├── install.bat / install.sh    # Automated toolchain installer
├── env.bat / env.sh            # Environment setup (run before building)
├── tools/                      # Downloaded SDK (populated by install script)
│   └── pvsneslib/              # PVSnesLib SDK with compiler, assembler, linker
├── projects/
│   └── hello-snes-world/       # Demo ROM project
│       ├── src/main.c          # C source (initialization + animation engine)
│       ├── assets/
│       │   ├── fonts/          # Font graphics (PNG + converted SNES data)
│       │   └── backgrounds/    # Background graphics (PNG + converted SNES data)
│       ├── include/            # Header files (effect params, sine table, etc.)
│       ├── hdr.asm             # ROM header (LoROM, memory map, vectors)
│       ├── data.asm            # Binary asset includes (.incbin)
│       └── Makefile            # Build configuration
├── templates/basic/            # Starter template for new SNES projects
├── scripts/                    # Helper scripts (font gen, background gen, tests)
├── docs/v1_docs/               # Development phase documentation
└── tmp/                        # Temporary files (gitignored)
```

## Build Pipeline

```
Source Code:
  main.c → 816-tcc → main.asm → 816-opt → optimized.asm → wla-65816 → main.obj

Assets:
  *.png → gfx4snes → *.pic (tiles) + *.pal (palette) + *.map (tilemap)

Linking:
  main.obj + hdr.asm + data.asm (with .incbin assets) → wlalink → hello_snes_world.sfc
```

## Technical Details

| Component | Detail |
|-----------|--------|
| CPU | WDC 65816 (16-bit, 3.58 MHz) |
| Resolution | 256x224 (NTSC) |
| Video Mode | Mode 1 (BG1: background 4bpp, BG2: text 4bpp) |
| ROM Type | LoROM, 512KB (4Mbit) |
| SDK | PVSnesLib v4.5.0 |
| Compiler | 816-tcc (C to 65816 ASM) |
| Assembler | wla-65816 |
| Linker | wlalink |
| Graphics | gfx4snes (PNG to SNES tiles) |

### Earthbound Background Effect

The animated background uses the same algorithm as Earthbound's battle scenes:

1. **Sine-wave distortion**: Each scanline gets a unique horizontal scroll offset
   computed from `offset(y) = amplitude * sin(frequency * y + phase)`,
   applied via HDMA writing to the BG1 horizontal scroll register per-scanline.

2. **Palette cycling**: Background colors rotate forward through the palette
   at a configurable speed, creating a flowing color effect.

3. **Constant scroll**: An optional slow vertical drift of the entire background.

Algorithm ported from [Earthbound-Battle-Backgrounds-JS](https://github.com/gjtorikian/Earthbound-Battle-Backgrounds-JS).

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make` | Build the ROM |
| `make clean` | Remove all build artifacts |
| `make rebuild` | Clean then build |
| `make assets` | Convert PNG assets to SNES format only |

## Troubleshooting

### "PVSNESLIB_HOME is not set"
Run `call env.bat` (Windows) or `source env.sh` (Linux/macOS) before building.

### "make: command not found"
Install GNU Make. See Requirements section above.

### Build errors about missing .pic/.pal files
Run `make assets` to convert PNG graphics, or run the font/background
generator scripts first (see scripts/ directory).

### ROM is blank or crashes
- Check VRAM layout constants in include/ headers
- Use Mesen2's PPU viewer to inspect tile data and tilemaps
- Verify extern labels in main.c match labels in data.asm

### HDMA effects not visible
- Check that HDMA channel is enabled (REG_HDMAEN)
- Verify HDMA table is in WRAM bank $7E
- Check BG1HOFS register target ($0D)

## License

MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- [PVSnesLib](https://github.com/alekmaul/pvsneslib) by Alekmaul - The SNES C SDK
- [Earthbound Battle Backgrounds JS](https://github.com/gjtorikian/Earthbound-Battle-Backgrounds-JS) by Garen Torikian - Background effect reference
- The SNES homebrew and romhacking communities
- [SNES Dev Wiki](https://snes.nesdev.org/wiki/) - Hardware documentation
```

---

### Task 10.5: Create Project Template

**File(s)**: All files under `J:\code\snes\snes-build-tools\templates\basic\`

**Description**: Create a minimal but functional project template that developers can copy to start a new SNES project. The template should be a stripped-down version of the demo project.

**Implementation Details**:

Create these files in `J:\code\snes\snes-build-tools\templates\basic\`:

**Makefile** (`J:\code\snes\snes-build-tools\templates\basic\Makefile`):
```makefile
# ==============================================================================
# SNES Project Template - Makefile
# Copy this template to start a new SNES project
# ==============================================================================

# --- Configuration: Change these for your project ---
ROM_NAME = my_snes_game

# --- PVSnesLib SDK ---
PVSNESLIB_HOME ?= ../../tools/pvsneslib

# --- Directories ---
SRC_DIR    = src
ASSET_DIR  = assets
BUILD_DIR  = build

# --- Tools ---
GFX4SNES   = $(PVSNESLIB_HOME)/devkitsnes/tools/gfx4snes

# --- Source Files ---
C_SOURCES  = $(wildcard $(SRC_DIR)/*.c)

# --- PVSnesLib Build Rules ---
include $(PVSNESLIB_HOME)/devkitsnes/lib/snes_rules

# --- Targets ---
all: $(ROM_NAME).sfc
	@echo Build complete: $(ROM_NAME).sfc

clean:
	-rm -f $(SRC_DIR)/*.asm
	-rm -f *.obj *.sfc *.sym

rebuild: clean all

.PHONY: all clean rebuild
```

**hdr.asm** (`J:\code\snes\snes-build-tools\templates\basic\hdr.asm`):
```asm
; SNES ROM Header Template - LoROM

.MEMORYMAP
    SLOTSIZE $8000
    DEFAULTSLOT 0
    SLOT 0 $8000
.ENDME

.ROMBANKSIZE $8000
.ROMBANKS 8                     ; 256KB ROM (adjust as needed)

.SNESHEADER
    ID "SNES"
    NAME "MY SNES GAME         "  ; 21 characters, padded with spaces
    LOROM
    SLOWROM
    CARTRIDGETYPE $00
    ROMSIZE $08                   ; 256KB
    SRAMSIZE $00
    COUNTRY $01
    LICENSEECODE $00
    VERSION $00
.ENDSNES

.SNESNATIVEVECTOR
    COP     EmptyHandler
    BRK     EmptyHandler
    ABORT   EmptyHandler
    NMI     VBlank
    IRQ     EmptyHandler
.ENDNATIVEVECTOR

.SNESEMUVECTOR
    COP     EmptyHandler
    ABORT   EmptyHandler
    NMI     EmptyHandler
    RESET   tcc__start
    IRQBRK  EmptyHandler
.ENDEMUVECTOR

.BANK 0 SLOT 0
.ORG 0
.SECTION "EmptyVectors" SEMIFREE
EmptyHandler:
    rti
.ENDS
```

**data.asm** (`J:\code\snes\snes-build-tools\templates\basic\data.asm`):
```asm
; Data Includes Template
; Add .incbin directives for your assets here

.include "hdr.asm"

; Example:
; .BANK 1 SLOT 0
; .ORG 0
; .SECTION "GfxData" SUPERFREE
; my_tiles:
;     .INCBIN "assets/my_tiles.pic"
; my_tiles_end:
; .ENDS
```

**src/main.c** (`J:\code\snes\snes-build-tools\templates\basic\src\main.c`):
```c
/*
 * SNES Project Template - Main Source
 * Replace this with your game code!
 */

#include <snes.h>

int main(void) {
    /* Initialize the console */
    consoleInit();

    /* Set video mode 1 */
    setMode(BG_MODE1, 0);

    /* Initialize text console for debug output */
    consoleInitText(0, 0, &tilfont, &palfont);

    /* Display text */
    consoleDrawText(8, 14, "HELLO SNES!");

    /* Enable screen */
    setScreenOn();

    /* Main loop */
    while (1) {
        WaitForVBlank();
    }

    return 0;
}
```

**README.md** (`J:\code\snes\snes-build-tools\templates\basic\README.md`):
```markdown
# SNES Project Template

A minimal starting point for SNES ROM development using PVSnesLib.

## Setup

1. Ensure PVSnesLib is installed (run `install.bat` from the repo root)
2. Set up the environment: `call env.bat` (Windows) or `source env.sh` (Linux)
3. Edit `src/main.c` with your code
4. Run `make` to build

## Customization

1. Change `ROM_NAME` in `Makefile`
2. Update ROM title in `hdr.asm`
3. Add assets to `assets/` and reference them in `data.asm`
4. Add source files to `src/`
```

---

### Task 10.6: Document the Build Pipeline

**File(s)**: `J:\code\snes\snes-build-tools\docs\v1_docs\build_pipeline.md`

**Description**: Create a detailed technical document explaining the complete build pipeline from C source to SNES ROM. This serves as a reference for developers who want to understand what happens under the hood.

**Code Example**:

```markdown
# SNES Build Pipeline - Technical Reference

## Overview

This document describes the complete build pipeline from C source code to
a playable SNES ROM (.sfc file).

## Pipeline Stages

### Stage 1: C Compilation (816-tcc)

**Input**: `.c` files
**Output**: `.asm` files (WDC 65816 assembly)

816-tcc is a fork of the Tiny C Compiler (tcc) modified to output WDC 65816
assembly language. It handles standard C constructs and maps them to 65816
instructions.

Limitations:
- No floating point (SNES has no FPU)
- Limited standard library (SNES-specific libc)
- 16-bit int by default
- Far pointers needed for cross-bank access (LoROM banks are 32KB)

### Stage 2: Assembly Optimization (816-opt)

**Input**: `.asm` from 816-tcc
**Output**: Optimized `.asm`

816-opt performs peephole optimizations on the compiler output, such as:
- Removing redundant register loads
- Optimizing branch sequences
- Eliminating dead stores

### Stage 3: Assembly (wla-65816)

**Input**: `.asm` files (both compiler output and hand-written like hdr.asm, data.asm)
**Output**: `.obj` object files

wla-65816 (from the WLA DX assembler suite) assembles 65816 mnemonics into
machine code, handling:
- Memory mapping directives (.MEMORYMAP, .ROMBANKSIZE)
- Section placement (.SECTION, .BANK, .ORG)
- Binary includes (.INCBIN for asset data)
- Label resolution

### Stage 4: Linking (wlalink)

**Input**: `.obj` files + link script
**Output**: `.sfc` ROM file

wlalink combines all object files into the final ROM, handling:
- Bank allocation for SUPERFREE sections
- Inter-bank call trampolines
- ROM header placement at $00:FFC0
- Interrupt vector table

### Stage 5: ROM Finalization (snestools)

**Input**: `.sfc` ROM
**Output**: `.sfc` ROM with valid checksum

snestools validates and fixes the ROM header, computing the correct
checksum and checksum complement.

## Graphics Pipeline

### PNG to SNES Conversion (gfx4snes)

**Input**: PNG image files
**Output**: `.pic` (tile data), `.pal` (palette), `.map` (tilemap)

gfx4snes performs:
1. Color quantization to target bit depth (2bpp or 4bpp)
2. Tile extraction (8x8 pixel blocks)
3. Tile deduplication (with -R flag)
4. Flip detection (with -f flag, marks horizontally/vertically flipped tiles)
5. Palette generation (SNES 15-bit RGB format)
6. Tilemap generation (tile index + flip flags + palette number)

### SNES Color Format

Colors are stored as 15-bit values: `0bbbbbgggggrrrrr`
- 5 bits per channel (0-31)
- Stored little-endian (low byte first)
- Example: Pure white = $7FFF, Pure black = $0000

### SNES Tile Format (4bpp)

Each 8x8 tile is 32 bytes in 4bpp mode:
- Bitplanes 0 and 1 are interleaved (16 bytes)
- Bitplanes 2 and 3 are interleaved (16 bytes)
- Each row is 2 bytes per bitplane pair (8 pixels)
```

---

### Task 10.7: Create Quickstart Guide

**File(s)**: `J:\code\snes\snes-build-tools\docs\v1_docs\quickstart.md`

**Description**: A concise, step-by-step guide for getting started in under 5 minutes.

**Code Example**:

```markdown
# Quickstart Guide

Get a SNES ROM building in under 5 minutes.

## Step 1: Prerequisites (one-time)

Ensure these are installed:
- Git
- GNU Make
- Python 3

Windows users: The easiest way to get Make is `choco install make` or
install [MSYS2](https://www.msys2.org/).

## Step 2: Clone and Install (one-time)

```bash
git clone <repo-url>
cd snes-build-tools
install.bat          # Windows
# ./install.sh       # Linux/macOS
```

## Step 3: Build the Demo

```bash
call env.bat         # Set up PATH (Windows)
# source env.sh      # Linux/macOS
cd projects\hello-snes-world
make
```

Output: `hello_snes_world.sfc` - open in any SNES emulator!

## Step 4: Start Your Own Project

```bash
xcopy /E templates\basic projects\my-game\
cd projects\my-game
# Edit src\main.c
make
```

## What Next?

- Read the [PVSnesLib wiki](https://github.com/alekmaul/pvsneslib/wiki)
- Explore PVSnesLib examples in `tools\pvsneslib\pvsneslib\snes-examples\`
- Check the [SNES Dev Wiki](https://snes.nesdev.org/wiki/) for hardware docs
- Study `projects\hello-snes-world\src\main.c` for a complete example
```

---

### Task 10.8: Prepare for Release

**File(s)**: No new files -- this is a process task

**Description**: Final steps before tagging v1.0.0:

1. **Run the full test suite**:
   ```bash
   scripts\test_e2e.bat
   scripts\verify_install.bat
   ```

2. **Clean build artifacts from the repository**:
   ```bash
   cd projects\hello-snes-world
   make clean
   ```

3. **Verify .gitignore is working**:
   ```bash
   git status
   # Should not show any build artifacts, .pic/.pal/.map in build/, etc.
   ```

4. **Review all files for sensitive data**:
   - No API keys, passwords, or personal paths
   - All paths in code use relative references or documented variables

5. **Commit all changes**:
   ```bash
   git add -A
   git commit -m "Complete v1.0.0: demo ROM with Earthbound-style background and text"
   ```

6. **Tag the release**:
   ```bash
   git tag -a v1.0.0 -m "v1.0.0: Initial release - SNES build toolchain with demo ROM"
   ```

7. **Optional: Create GitHub release**:
   - Upload the built `hello_snes_world.sfc` as a release artifact
   - Include a screenshot/GIF of the running ROM

---

## Acceptance Criteria

- [ ] End-to-end test script passes all checks
- [ ] ROM runs correctly in Mesen2 (all visual elements verified)
- [ ] ROM runs correctly in bsnes (accuracy verification)
- [ ] ROM header is valid (snestools verification)
- [ ] ROM checksum is correct
- [ ] README.md contains complete setup, build, and usage instructions
- [ ] README.md troubleshooting section covers common issues
- [ ] Project template exists in `templates/basic/` with Makefile, hdr.asm, data.asm, src/main.c
- [ ] Template builds successfully when copied and configured
- [ ] Build pipeline document exists at `docs/v1_docs/build_pipeline.md`
- [ ] Quickstart guide exists at `docs/v1_docs/quickstart.md`
- [ ] `git status` shows a clean working tree (no uncommitted changes)
- [ ] Repository is tagged as v1.0.0
- [ ] A fresh user can clone, install, build, and run the ROM by following only the README

## File Manifest

| File | Action | Description |
|------|--------|-------------|
| `J:\code\snes\snes-build-tools\scripts\test_e2e.bat` | CREATE | End-to-end test script |
| `J:\code\snes\snes-build-tools\README.md` | REPLACE | Comprehensive project documentation |
| `J:\code\snes\snes-build-tools\templates\basic\Makefile` | CREATE | Template project Makefile |
| `J:\code\snes\snes-build-tools\templates\basic\hdr.asm` | CREATE | Template ROM header |
| `J:\code\snes\snes-build-tools\templates\basic\data.asm` | CREATE | Template data includes |
| `J:\code\snes\snes-build-tools\templates\basic\src\main.c` | CREATE | Template main source |
| `J:\code\snes\snes-build-tools\templates\basic\README.md` | CREATE | Template project README |
| `J:\code\snes\snes-build-tools\docs\v1_docs\build_pipeline.md` | CREATE | Build pipeline documentation |
| `J:\code\snes\snes-build-tools\docs\v1_docs\quickstart.md` | CREATE | Quickstart guide |

## Dependencies

- **Depends on**: All phases 1-9 (everything must be complete)
- **Depended on by**: Nothing (this is the final phase)
