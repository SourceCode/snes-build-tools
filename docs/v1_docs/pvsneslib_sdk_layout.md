# PVSnesLib SDK Layout Reference

Version: 4.5.0 | Last verified: 2025-02-06

This document describes the internal structure of the PVSnesLib SDK after extraction from the release ZIP. The install script extracts the SDK to `J:\code\snes\snes-build-tools\tools\pvsneslib\`.

## Release Archive Contents

The release ZIP contains a root directory `pvsneslib/` with everything inside. After extraction to `tools/pvsneslib/`, the layout is:

```
tools/pvsneslib/
├── devkitsnes/
│   ├── bin/                        # Compiler and assembler executables
│   │   ├── 816-tcc(.exe)          # C compiler — C source to 65816 ASM
│   │   ├── wla-65816(.exe)        # Assembler — 65816 ASM to OBJ
│   │   ├── wla-spc700(.exe)       # Assembler — SPC700 sound ASM to OBJ
│   │   └── wlalink(.exe)          # Linker — OBJ files to .sfc ROM
│   │
│   ├── tools/                      # Conversion and optimization tools
│   │   ├── gfx4snes(.exe)         # PNG to SNES tiles/palette/map
│   │   ├── gfx2snes(.exe)         # Legacy graphics converter
│   │   ├── 816-opt(.exe)          # ASM optimizer (post-tcc)
│   │   ├── constify(.exe)         # Moves C constants to ROM
│   │   ├── snestools(.exe)        # ROM header and checksum tool
│   │   ├── smconv(.exe)           # Sound module (.it) converter
│   │   ├── snesbrr(.exe)          # WAV to BRR audio converter
│   │   ├── bin2txt(.exe)          # Binary to text converter
│   │   └── tmx2snes(.exe)         # Tiled JSON map converter
│   │
│   ├── include/                    # C standard library headers
│   │   ├── stdio.h
│   │   ├── stdlib.h
│   │   ├── string.h
│   │   ├── stdint.h
│   │   ├── stdbool.h
│   │   ├── stdarg.h
│   │   ├── stddef.h
│   │   ├── math.h
│   │   ├── limits.h
│   │   ├── float.h
│   │   ├── ctype.h
│   │   ├── setjmp.h
│   │   ├── strings.h
│   │   └── hdr.asm                # Default ROM header template
│   │
│   ├── snes_rules                  # Makefile include — build rules
│   └── readme.txt
│
├── pvsneslib/
│   ├── include/
│   │   └── snes/                   # SNES API headers
│   │       ├── video.h             # Video modes, brightness, HDMA, Mode 7
│   │       ├── background.h        # BG layers, tilemaps, scrolling
│   │       ├── console.h           # Text console (consoleInitText, consoleDrawText)
│   │       ├── dma.h               # DMA and HDMA transfers
│   │       ├── sprite.h            # OAM sprite management
│   │       ├── input.h             # Controller/pad reading
│   │       ├── interrupt.h         # NMI, IRQ, VBlank
│   │       ├── sound.h             # Audio/music playback
│   │       ├── map.h               # Tilemap engine
│   │       ├── object.h            # Object/entity management
│   │       ├── scores.h            # Score display helpers
│   │       ├── pixel.h             # Pixel-level drawing
│   │       ├── lzss.h              # LZSS decompression
│   │       ├── snestypes.h         # Type definitions (u8, u16, u32, s8, s16, bool)
│   │       └── libversion.h        # Library version
│   │
│   ├── lib/                        # Pre-compiled library objects (per memory map)
│   │   ├── LoROM_SlowROM/          # Default: LoROM + SlowROM
│   │   │   ├── crt0_snes.obj       # C runtime startup
│   │   │   ├── libc.obj            # C standard library
│   │   │   ├── libm.obj            # Math library
│   │   │   ├── sm_spc.obj          # SPC sound driver
│   │   │   └── linkfile            # Linker configuration
│   │   ├── LoROM_FastROM/
│   │   ├── HiROM_SlowROM/
│   │   └── HiROM_FastROM/
│   │
│   ├── docs/                       # API documentation (HTML)
│   ├── PVSnesLib_Logo.png
│   ├── pvsneslib_license.txt
│   └── pvsneslib_version.txt
│
├── snes-examples/                  # Example projects
│   ├── hello_world/
│   ├── graphics/
│   │   ├── Backgrounds/
│   │   │   ├── Mode0/
│   │   │   ├── Mode1/
│   │   │   ├── Mode3/
│   │   │   ├── Mode5/
│   │   │   ├── Mode7/
│   │   │   └── Mode7Perspective/
│   │   ├── Sprites/
│   │   ├── Effects/
│   │   │   ├── Fading/
│   │   │   ├── HDMAGradient/
│   │   │   ├── Parallax/
│   │   │   ├── Transparency/
│   │   │   ├── Waves/
│   │   │   └── Window/
│   │   └── Palette/
│   ├── audio/
│   ├── input/
│   ├── maps/
│   ├── objects/
│   ├── games/
│   ├── timer/
│   ├── sram/
│   ├── scoring/
│   └── debug/
│
└── vscode-template/                # VS Code project template
```

## Critical Paths Referenced by snes_rules

The `snes_rules` Makefile include (at `devkitsnes/snes_rules`) defines these tool paths:

| Variable | Path | Purpose |
|----------|------|---------|
| `$(CC)` | `$(PVSNESLIB_HOME)/devkitsnes/bin/816-tcc` | C compiler |
| `$(AS)` | `$(PVSNESLIB_HOME)/devkitsnes/bin/wla-65816` | 65816 assembler |
| `$(AS700)` | `$(PVSNESLIB_HOME)/devkitsnes/bin/wla-spc700` | SPC700 assembler |
| `$(LD)` | `$(PVSNESLIB_HOME)/devkitsnes/bin/wlalink` | Linker |
| `$(GFXCONV)` | `$(PVSNESLIB_HOME)/devkitsnes/tools/gfx4snes` | Graphics converter |
| `$(GFX2CONV)` | `$(PVSNESLIB_HOME)/devkitsnes/tools/gfx2snes` | Legacy graphics converter |
| `$(OPT)` | `$(PVSNESLIB_HOME)/devkitsnes/tools/816-opt` | ASM optimizer |
| `$(CTF)` | `$(PVSNESLIB_HOME)/devkitsnes/tools/constify` | Constant mover |
| `$(SNTOOLS)` | `$(PVSNESLIB_HOME)/devkitsnes/tools/snestools` | ROM header tool |
| `$(SMCONV)` | `$(PVSNESLIB_HOME)/devkitsnes/tools/smconv` | Sound converter |
| `$(BRCONV)` | `$(PVSNESLIB_HOME)/devkitsnes/tools/snesbrr` | BRR audio converter |
| `$(TXCONV)` | `$(PVSNESLIB_HOME)/devkitsnes/tools/bin2txt` | Binary to text |
| `$(TMXCONV)` | `$(PVSNESLIB_HOME)/devkitsnes/tools/tmx2snes` | Tiled map converter |

Include paths added to CFLAGS automatically:
```
-I$(PVSNESLIB_HOME)/pvsneslib/include
-I$(PVSNESLIB_HOME)/devkitsnes/include
```

Library objects directory (selected by HIROM/FASTROM flags):
```
$(PVSNESLIB_HOME)/pvsneslib/lib/LoROM_SlowROM/   (default)
$(PVSNESLIB_HOME)/pvsneslib/lib/LoROM_FastROM/
$(PVSNESLIB_HOME)/pvsneslib/lib/HiROM_SlowROM/
$(PVSNESLIB_HOME)/pvsneslib/lib/HiROM_FastROM/
```

## Environment Variable Requirements

| Variable | Value | Notes |
|----------|-------|-------|
| `PVSNESLIB_HOME` | Absolute path to `tools/pvsneslib` | **MUST use Unix-style forward slashes** on all platforms. Example: `/j/code/snes/snes-build-tools/tools/pvsneslib` (NOT `J:\code\...`). The snes_rules file checks for backslashes and errors out. |
| `PATH` (prepend) | `$PVSNESLIB_HOME/devkitsnes/bin` | Makes 816-tcc, wla-65816, wlalink accessible |
| `PATH` (prepend) | `$PVSNESLIB_HOME/devkitsnes/tools` | Makes gfx4snes, 816-opt, etc. accessible |

Optional debug flag:
| `PVSNESLIB_DEBUG` | `1` | Enables debug symbols in builds |

## Compilation Pipeline (from snes_rules)

```
1. C source (.c)
   └─▶ 816-tcc ──▶ PowerPC-style ASM (.ps)
       └─▶ 816-opt ──▶ Optimized ASM (.asp)
           └─▶ constify ──▶ Final ASM (.asm)
               └─▶ wla-65816 ──▶ Object file (.obj)

2. ASM source (.asm)
   └─▶ wla-65816 ──▶ Object file (.obj)

3. All .obj files
   └─▶ wlalink + linkfile ──▶ ROM (.sfc)

4. PNG/BMP graphics
   └─▶ gfx4snes ──▶ .pic (tiles) + .pal (palette) + .map (tilemap)
       └─▶ included via data.asm ──▶ linked into ROM
```

## Makefile Pattern for Projects

```makefile
ifeq ($(strip $(PVSNESLIB_HOME)),)
$(error "Please set PVSNESLIB_HOME environment variable")
endif

include ${PVSNESLIB_HOME}/devkitsnes/snes_rules

export ROMNAME := myproject

all: bitmaps $(ROMNAME).sfc

clean: cleanBuildRes cleanRom cleanGfx

# Graphics conversion rules
myimage.pic: myimage.png
	$(GFXCONV) -i $< -p -t -m -s 8 -b 4 -R -o $(basename $<)

bitmaps: myimage.pic
```

## Verification Commands

After installation, run these to verify the SDK is working:

```bash
# Check compiler
$PVSNESLIB_HOME/devkitsnes/bin/816-tcc --version
# Expected: contains "tcc"

# Check assembler
$PVSNESLIB_HOME/devkitsnes/bin/wla-65816 -v
# Expected: contains "WLA"

# Check linker
$PVSNESLIB_HOME/devkitsnes/bin/wlalink
# Expected: contains "WLALINK"

# Check graphics converter
$PVSNESLIB_HOME/devkitsnes/tools/gfx4snes
# Expected: contains "gfx4snes"

# Check snes_rules exists
test -f $PVSNESLIB_HOME/devkitsnes/snes_rules && echo "OK"

# Check SNES headers exist
test -f $PVSNESLIB_HOME/pvsneslib/include/snes/video.h && echo "OK"

# Check library objects exist
test -d $PVSNESLIB_HOME/pvsneslib/lib/LoROM_SlowROM && echo "OK"
```
