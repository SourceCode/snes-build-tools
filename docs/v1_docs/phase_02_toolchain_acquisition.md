# Phase 2: Toolchain Acquisition & Dependency Management

## Overview

This phase defines the complete inventory of tools, SDKs, and dependencies required to build SNES ROMs, along with their exact versions, download URLs, expected file locations, and verification procedures. This phase produces a dependency manifest -- a single source of truth that the install scripts (Phase 3) will consume.

No tools are actually downloaded in this phase. The output is a comprehensive specification document and a machine-readable dependency configuration file that the install scripts will use.

## Prerequisites

- Phase 1 completed (directory structure exists)
- Internet access to verify download URLs are valid
- Understanding of the PVSnesLib build pipeline

## Objectives

1. Document every required tool with version, URL, SHA256 hash, and install location
2. Create a machine-readable dependency manifest (`J:\code\snes\snes-build-tools\scripts\dependencies.json`)
3. Document the expected PATH layout after installation
4. Define verification commands for each tool
5. Document optional tools (emulators) separately from required tools

## Context

### PVSnesLib SDK

PVSnesLib is the primary SDK for SNES development in C. It provides:

- **816-tcc**: A fork of TinyCC that targets the WDC 65816 processor. Compiles C to 65816 assembly.
- **816-opt**: An optimizer that processes the assembly output of 816-tcc.
- **wla-65816**: The WLA DX assembler targeting the 65816 processor. Assembles .asm files into object files.
- **wlalink**: The WLA DX linker. Links object files into the final ROM (.sfc file).
- **gfx4snes**: A graphics conversion tool that converts PNG images into SNES-compatible tile data (.pic), palettes (.pal), and tilemaps (.map).
- **snestools**: ROM header manipulation tool.
- **constify**: Converts C data into ASM constants.
- **snes_rules**: Makefile include that provides standard build rules.

The SDK ships as a single ZIP/tarball containing all of the above plus headers, libraries, and example projects.

**Download source**: https://github.com/alekmaul/pvsneslib/releases

### Build Environment Requirements

On Windows, PVSnesLib requires:
- **MSYS2** or compatible Make environment (GNU Make)
- PATH configured to include PVSnesLib's `devkitsnes/tools` directory
- The environment variable `PVSNESLIB_HOME` pointing to the SDK root

On Linux/macOS:
- Standard build tools (make, gcc for host tools if building from source)
- PVSnesLib may need to be built from source for non-Windows platforms

### Python (for helper scripts)

Python 3.x is used for:
- Font PNG generation (Phase 5)
- Asset pipeline helper scripts
- The Pillow (PIL) library for image manipulation

## Tasks

### Task 2.1: Create Dependency Manifest

**File(s)**: `J:\code\snes\snes-build-tools\scripts\dependencies.json`

**Description**: Create a JSON file that describes every dependency with machine-readable metadata. The install scripts in Phase 3 will parse this file to know what to download and where to put it.

**Implementation Details**:

The manifest should include for each dependency:
- `name`: Human-readable name
- `required`: Whether it is mandatory or optional
- `version`: Exact version string
- `platform`: Which platforms it applies to (`windows`, `linux`, `macos`, `all`)
- `url`: Download URL(s) per platform
- `sha256`: Expected hash per platform (for integrity verification)
- `extractTo`: Where to extract/install relative to repo root
- `verifyCommand`: Command to run to verify installation
- `expectedOutput`: Regex or substring to match in verify output
- `envVars`: Environment variables to set

**Code Example**:

```json
{
  "$schema": "dependency-manifest-v1",
  "description": "SNES Build Tools dependency manifest",
  "lastUpdated": "2025-01-01",
  "dependencies": {
    "pvsneslib": {
      "name": "PVSnesLib SDK",
      "required": true,
      "version": "4.5.0",
      "description": "Complete SNES development SDK with compiler, assembler, linker, and graphics tools",
      "platforms": {
        "windows": {
          "url": "https://github.com/alekmaul/pvsneslib/releases/download/4.5.0/pvsneslib-windows-4.5.0.zip",
          "archiveType": "zip",
          "sha256": "VERIFY_AND_UPDATE_HASH_AFTER_DOWNLOAD"
        },
        "linux": {
          "url": "https://github.com/alekmaul/pvsneslib/releases/download/4.5.0/pvsneslib-linux-4.5.0.tar.gz",
          "archiveType": "tar.gz",
          "sha256": "VERIFY_AND_UPDATE_HASH_AFTER_DOWNLOAD",
          "note": "Linux builds may require building from source. Check release page."
        }
      },
      "extractTo": "tools/pvsneslib",
      "envVars": {
        "PVSNESLIB_HOME": "{repoRoot}/tools/pvsneslib"
      },
      "verifyCommand": {
        "windows": "tools\\pvsneslib\\devkitsnes\\tools\\816-tcc.exe --version",
        "linux": "tools/pvsneslib/devkitsnes/tools/816-tcc --version"
      },
      "expectedOutput": "tcc",
      "provides": [
        "816-tcc",
        "816-opt",
        "wla-65816",
        "wlalink",
        "gfx4snes",
        "snestools",
        "constify",
        "snes_rules"
      ],
      "postInstall": {
        "description": "After extraction, the SDK root should contain devkitsnes/ with tools/, include/, and lib/ subdirectories"
      }
    },
    "python3": {
      "name": "Python 3",
      "required": true,
      "version": "3.8+",
      "description": "Required for font generation and helper scripts",
      "platforms": {
        "windows": {
          "checkCommand": "python --version",
          "installInstructions": "Download from https://www.python.org/downloads/ or install via winget: winget install Python.Python.3.12"
        },
        "linux": {
          "checkCommand": "python3 --version",
          "installInstructions": "Install via package manager: sudo apt install python3 python3-pip"
        },
        "macos": {
          "checkCommand": "python3 --version",
          "installInstructions": "Install via Homebrew: brew install python3"
        }
      },
      "note": "Python is a system prerequisite. The install script checks for it but does not install it automatically.",
      "pipPackages": [
        {
          "name": "Pillow",
          "version": ">=10.0.0",
          "description": "Image manipulation library for font PNG generation"
        }
      ]
    },
    "make": {
      "name": "GNU Make",
      "required": true,
      "version": "4.0+",
      "description": "Build automation tool",
      "platforms": {
        "windows": {
          "checkCommand": "make --version",
          "note": "Provided by MSYS2, Chocolatey (make), or Git for Windows",
          "installInstructions": "Option 1: Install MSYS2 from https://www.msys2.org/ then run: pacman -S make\nOption 2: choco install make\nOption 3: Use make from Git for Windows (usually at C:\\Program Files\\Git\\usr\\bin\\make.exe)"
        },
        "linux": {
          "checkCommand": "make --version",
          "installInstructions": "sudo apt install build-essential"
        },
        "macos": {
          "checkCommand": "make --version",
          "installInstructions": "xcode-select --install"
        }
      }
    },
    "git": {
      "name": "Git",
      "required": true,
      "version": "2.0+",
      "description": "Version control (also needed for cloning reference repos)",
      "platforms": {
        "windows": {
          "checkCommand": "git --version"
        },
        "linux": {
          "checkCommand": "git --version"
        },
        "macos": {
          "checkCommand": "git --version"
        }
      }
    },
    "mesen2": {
      "name": "Mesen2 Emulator",
      "required": false,
      "version": "latest",
      "description": "Primary development emulator with debugging support",
      "platforms": {
        "windows": {
          "url": "https://github.com/SourMesen/Mesen2/releases",
          "note": "Download latest Windows release manually. Place in tools/emulators/mesen2/"
        },
        "linux": {
          "url": "https://github.com/SourMesen/Mesen2/releases",
          "note": "Download latest Linux AppImage. Place in tools/emulators/mesen2/"
        }
      },
      "extractTo": "tools/emulators/mesen2",
      "optional": true
    },
    "bsnes": {
      "name": "bsnes Emulator",
      "required": false,
      "version": "latest",
      "description": "Accuracy-focused emulator for final testing",
      "platforms": {
        "windows": {
          "url": "https://github.com/bsnes-emu/bsnes/releases",
          "note": "Download latest Windows release manually. Place in tools/emulators/bsnes/"
        }
      },
      "extractTo": "tools/emulators/bsnes",
      "optional": true
    }
  }
}
```

**References**:
- PVSnesLib releases: https://github.com/alekmaul/pvsneslib/releases
- Mesen2 releases: https://github.com/SourMesen/Mesen2/releases
- Python downloads: https://www.python.org/downloads/

---

### Task 2.2: Document PVSnesLib SDK Internal Structure

**File(s)**: `J:\code\snes\snes-build-tools\docs\v1_docs\pvsneslib_sdk_layout.md` (reference document, not a phase)

**Description**: Document the expected internal structure of the PVSnesLib SDK after extraction. This is critical for the install script to verify correct installation and for the Makefile to find tools.

**Implementation Details**:

After extracting PVSnesLib, the expected layout under `J:\code\snes\snes-build-tools\tools\pvsneslib\` is:

```
tools/pvsneslib/
├── devkitsnes/
│   ├── tools/
│   │   ├── 816-tcc.exe          # C compiler (C → 65816 ASM)
│   │   ├── 816-opt.exe          # ASM optimizer
│   │   ├── wla-65816.exe        # Assembler (ASM → OBJ)
│   │   ├── wlalink.exe          # Linker (OBJ → ROM)
│   │   ├── gfx4snes.exe         # Graphics converter (PNG → tiles/pal/map)
│   │   ├── snestools.exe        # ROM header tool
│   │   ├── constify.exe         # C constant converter
│   │   ├── bin2txt.exe          # Binary to text converter
│   │   └── smconv.exe           # Sound converter
│   ├── include/
│   │   └── snes/
│   │       ├── snes.h            # Main include header
│   │       ├── background.h      # Background functions
│   │       ├── dma.h             # DMA functions
│   │       ├── interrupts.h      # NMI/IRQ handlers
│   │       ├── input.h           # Controller input
│   │       ├── sprite.h          # Sprite/OAM functions
│   │       ├── video.h           # Video mode, HDMA
│   │       ├── console.h         # Text console functions
│   │       ├── sound.h           # Audio functions
│   │       └── snestypes.h       # Type definitions (u8, u16, s16, etc.)
│   └── lib/
│       ├── snes_rules            # Makefile include with build rules
│       ├── crt0_snes.asm         # C runtime startup
│       ├── libc.asm              # C standard library (SNES)
│       ├── libm.asm              # Math library
│       └── hdr.asm               # Default ROM header template
└── pvsneslib/
    └── (source code if building from source)
```

Key paths that the Makefile and build system reference:
- `$(PVSNESLIB_HOME)/devkitsnes/tools/` - All executable tools
- `$(PVSNESLIB_HOME)/devkitsnes/include/snes/` - C headers
- `$(PVSNESLIB_HOME)/devkitsnes/lib/` - Libraries and build rules
- `$(PVSNESLIB_HOME)/devkitsnes/lib/snes_rules` - Makefile include

The `snes_rules` file expects `PVSNESLIB_HOME` to be set and defines:
- `$(PVSNESLIB_TOOLS)` = `$(PVSNESLIB_HOME)/devkitsnes/tools`
- Compiler flags, assembler flags, linker configuration
- Pattern rules for `.c → .asm → .obj → .sfc`
- Graphics conversion rules

**Code Example** (verifying SDK structure):

```bash
# Windows verification commands
dir tools\pvsneslib\devkitsnes\tools\816-tcc.exe
dir tools\pvsneslib\devkitsnes\tools\wla-65816.exe
dir tools\pvsneslib\devkitsnes\tools\wlalink.exe
dir tools\pvsneslib\devkitsnes\tools\gfx4snes.exe
dir tools\pvsneslib\devkitsnes\lib\snes_rules
dir tools\pvsneslib\devkitsnes\include\snes\snes.h
```

**References**:
- PVSnesLib GitHub wiki: https://github.com/alekmaul/pvsneslib/wiki
- PVSnesLib snes_rules source: https://github.com/alekmaul/pvsneslib/blob/master/devkitsnes/lib/snes_rules

---

### Task 2.3: Document Tool PATH and Environment Variable Requirements

**File(s)**: Part of `J:\code\snes\snes-build-tools\scripts\dependencies.json` (already created in Task 2.1)

**Description**: Define the exact environment variables and PATH modifications needed for the toolchain to function.

**Implementation Details**:

The following environment setup is required:

| Variable | Value | Purpose |
|----------|-------|---------|
| `PVSNESLIB_HOME` | `J:\code\snes\snes-build-tools\tools\pvsneslib` | SDK root, used by snes_rules Makefile |
| `PATH` (addition) | `%PVSNESLIB_HOME%\devkitsnes\tools` | Makes 816-tcc, wla-65816, etc. available |

For a session-based setup (not modifying system PATH permanently), the install script should create a shell wrapper:

**Windows** (`J:\code\snes\snes-build-tools\env.bat`):
```batch
@echo off
set PVSNESLIB_HOME=%~dp0tools\pvsneslib
set PATH=%PVSNESLIB_HOME%\devkitsnes\tools;%PATH%
echo SNES Build Tools environment configured.
echo PVSNESLIB_HOME=%PVSNESLIB_HOME%
```

**Linux/macOS** (`J:\code\snes\snes-build-tools\env.sh`):
```bash
#!/bin/bash
export PVSNESLIB_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tools/pvsneslib"
export PATH="$PVSNESLIB_HOME/devkitsnes/tools:$PATH"
echo "SNES Build Tools environment configured."
echo "PVSNESLIB_HOME=$PVSNESLIB_HOME"
```

These environment wrapper scripts will be created by the install script in Phase 3.

---

### Task 2.4: Document gfx4snes Usage for Asset Pipeline

**File(s)**: Documentation within this phase document (referenced by Phases 5 and 6)

**Description**: Document the exact gfx4snes command-line usage for converting PNG images to SNES tile format, as this is critical for Phases 5 (font) and 6 (background).

**Implementation Details**:

`gfx4snes` converts PNG images to SNES-compatible binary data:

```
gfx4snes [options] input.png
```

Key options:
- `-i input.png` : Input PNG file
- `-p` : Generate palette file (.pal)
- `-t` : Generate tile/character data file (.pic)
- `-m` : Generate tilemap file (.map)
- `-s 8` : Tile size (8x8 pixels, default for SNES)
- `-b 4` : Bits per pixel (4bpp = 16 colors per palette)
- `-R` : Reduce/optimize tiles (remove duplicates)
- `-f` : Flip detection (detect and flag mirrored tiles)
- `-o output` : Output file base name

Example usage for a 256x256 background:
```bash
gfx4snes -i background.png -p -t -m -s 8 -b 4 -R -o background
# Produces: background.pic (tiles), background.pal (palette), background.map (tilemap)
```

Example usage for a font spritesheet:
```bash
gfx4snes -i font.png -p -t -s 8 -b 4 -o font
# Produces: font.pic (tiles), font.pal (palette)
# Tilemap is generated manually for text rendering
```

Output file formats:
- `.pic` - Raw tile data in SNES planar format (2bpp or 4bpp)
- `.pal` - SNES color palette (15-bit RGB: `0bbbbbgg gggrrrrr`)
- `.map` - Tilemap entries (16-bit per tile: `VHOppptt tttttttt`)
  - V = vertical flip, H = horizontal flip, O = priority
  - ppp = palette number, tttttttttt = tile index

**References**:
- gfx4snes source: https://github.com/alekmaul/pvsneslib/tree/master/tools/gfx4snes
- SNES tile format documentation: https://snes.nesdev.org/wiki/Tile_data

---

### Task 2.5: Verify Download URLs Are Current

**File(s)**: Update `J:\code\snes\snes-build-tools\scripts\dependencies.json` if needed

**Description**: Before moving to Phase 3, verify that all download URLs in the dependency manifest are accessible and point to the correct versions. Update the SHA256 hashes after verifying downloads.

**Implementation Details**:

Run these verification steps:

1. Check PVSnesLib releases page:
   ```bash
   curl -sI https://github.com/alekmaul/pvsneslib/releases/tag/4.5.0
   # Should return 200 OK
   ```

2. Check actual release asset URL:
   ```bash
   # Visit https://github.com/alekmaul/pvsneslib/releases/tag/4.5.0
   # Note the exact filename and URL of the Windows zip
   # Update dependencies.json with the correct URL
   ```

3. If version 4.5.0 is not available, check the latest release and update the version throughout:
   ```bash
   curl -s https://api.github.com/repos/alekmaul/pvsneslib/releases/latest | python -c "import json,sys;print(json.load(sys.stdin)['tag_name'])"
   ```

4. After downloading (during Phase 3 development), compute SHA256:
   ```bash
   # Windows (PowerShell)
   Get-FileHash pvsneslib-windows-4.5.0.zip -Algorithm SHA256

   # Linux
   sha256sum pvsneslib-linux-4.5.0.tar.gz
   ```

**Important**: The SHA256 values in `dependencies.json` are placeholders (`VERIFY_AND_UPDATE_HASH_AFTER_DOWNLOAD`). They MUST be updated during Phase 3 development after actually downloading the files. The install script should warn if hash verification fails but not block installation (since hashes change with new releases).

---

## Acceptance Criteria

- [ ] `J:\code\snes\snes-build-tools\scripts\dependencies.json` exists and is valid JSON
- [ ] The manifest lists PVSnesLib with version, URL, and extract location
- [ ] The manifest lists Python 3 as a prerequisite with version check commands
- [ ] The manifest lists GNU Make as a prerequisite with version check commands
- [ ] The manifest lists Git as a prerequisite
- [ ] The manifest lists Mesen2 and bsnes as optional dependencies
- [ ] The expected SDK directory layout is documented
- [ ] Environment variable requirements (PVSNESLIB_HOME, PATH) are specified
- [ ] gfx4snes command-line usage is documented for both font and background conversion
- [ ] All download URLs have been verified as accessible (or flagged for update)
- [ ] `J:\code\snes\snes-build-tools\docs\v1_docs\pvsneslib_sdk_layout.md` exists with SDK structure documentation

## File Manifest

| File | Action | Description |
|------|--------|-------------|
| `J:\code\snes\snes-build-tools\scripts\dependencies.json` | CREATE | Machine-readable dependency manifest |
| `J:\code\snes\snes-build-tools\docs\v1_docs\pvsneslib_sdk_layout.md` | CREATE | SDK internal structure reference |

## Dependencies

- **Depends on**: Phase 1 (directory structure must exist)
- **Depended on by**: Phase 3 (install script reads the manifest), Phase 4 (Makefile references SDK paths), Phase 5 (gfx4snes usage), Phase 6 (gfx4snes usage)
