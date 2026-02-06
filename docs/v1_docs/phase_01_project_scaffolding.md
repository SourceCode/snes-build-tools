# Phase 1: Project Scaffolding & Repository Structure

## Overview

This phase establishes the complete directory structure, repository metadata, and configuration files for the SNES build toolchain project. Every subsequent phase depends on this foundation. The goal is to create a clean, well-organized repository that serves both as a working build environment and as a template for future SNES projects.

This phase produces zero executable code -- it is purely structural. All directories, placeholder files, and repository metadata are created here so that later phases can focus on content without worrying about where files belong.

## Prerequisites

- Git installed and available on PATH
- A text editor or AI coding agent capable of creating files
- Write access to `J:\code\snes\snes-build-tools\`

## Objectives

1. Create the complete directory tree for the repository
2. Write a comprehensive README.md with project description and placeholder sections
3. Create an MIT LICENSE file
4. Create a .gitignore tuned for SNES development (C, ASM, build artifacts, emulator files)
5. Create placeholder files in key directories to ensure Git tracks them
6. Initialize the Git repository (if not already initialized)

## Context

The repository follows a monorepo pattern where the toolchain, build scripts, documentation, and demo project all live together. This is intentional -- the goal is a "clone and run" experience where a developer clones one repo and gets everything they need.

The directory structure separates concerns into clear layers:
- **tools/**: Downloaded binary dependencies (not checked into Git, downloaded by install scripts)
- **projects/**: Actual SNES ROM projects that use the toolchain
- **templates/**: Skeleton projects for starting new SNES projects
- **scripts/**: Helper scripts for build, asset conversion, etc.
- **docs/**: Documentation including these phase documents
- **tmp/**: Temporary files, cloned reference repos (not checked into Git)

## Tasks

### Task 1.1: Create Directory Structure

**File(s)**: All directories under `J:\code\snes\snes-build-tools\`

**Description**: Create the complete directory tree. Empty directories in Git require a placeholder file (conventionally `.gitkeep`).

**Implementation Details**:

Create the following directories. For each leaf directory that will initially be empty, create a `.gitkeep` file inside it.

```
J:\code\snes\snes-build-tools\
├── tools\
│   ├── pvsneslib\                  # PVSnesLib SDK (downloaded by install script)
│   ├── emulators\                  # Optional emulator binaries
│   └── bin\                        # Symlinks/copies of key executables
├── projects\
│   └── hello-snes-world\           # Demo ROM project
│       ├── src\                    # C source files
│       ├── assets\
│       │   ├── fonts\              # Font PNGs and converted tile data
│       │   └── backgrounds\        # Background PNGs and converted data
│       ├── include\                # Header files
│       └── build\                  # Build output (ROM, intermediate files)
├── templates\
│   └── basic\                      # Template for new SNES projects
│       ├── src\
│       ├── assets\
│       ├── include\
│       └── build\
├── docs\
│   └── v1_docs\                    # Phase planning documents
├── scripts\                        # Helper scripts (font gen, asset pipeline)
└── tmp\                            # Temporary/cloned repos (gitignored)
```

**Commands to execute**:

```bash
cd J:\code\snes\snes-build-tools

# Tools directories
mkdir -p tools/pvsneslib
mkdir -p tools/emulators
mkdir -p tools/bin

# Demo project directories
mkdir -p projects/hello-snes-world/src
mkdir -p projects/hello-snes-world/assets/fonts
mkdir -p projects/hello-snes-world/assets/backgrounds
mkdir -p projects/hello-snes-world/include
mkdir -p projects/hello-snes-world/build

# Template directories
mkdir -p templates/basic/src
mkdir -p templates/basic/assets
mkdir -p templates/basic/include
mkdir -p templates/basic/build

# Documentation
mkdir -p docs/v1_docs

# Scripts and temp
mkdir -p scripts
mkdir -p tmp
```

Place `.gitkeep` files in directories that would otherwise be empty:

```bash
touch tools/pvsneslib/.gitkeep
touch tools/emulators/.gitkeep
touch tools/bin/.gitkeep
touch projects/hello-snes-world/build/.gitkeep
touch projects/hello-snes-world/include/.gitkeep
touch templates/basic/src/.gitkeep
touch templates/basic/assets/.gitkeep
touch templates/basic/include/.gitkeep
touch templates/basic/build/.gitkeep
touch scripts/.gitkeep
```

**References**:
- Git documentation on tracking empty directories: https://git.wiki.kernel.org/index.php/Git_FAQ#Can_I_add_empty_directories.3F

---

### Task 1.2: Create .gitignore

**File(s)**: `J:\code\snes\snes-build-tools\.gitignore`

**Description**: Create a comprehensive .gitignore that excludes build artifacts, downloaded tools, temporary files, emulator save states, and OS-specific junk files -- while preserving the source structure.

**Implementation Details**:

The .gitignore must handle:
- C/ASM build artifacts (*.o, *.obj, *.sfc, *.smc)
- PVSnesLib intermediates (*.pic, *.pal, *.map generated files in build/)
- Downloaded toolchain binaries (tools/pvsneslib/*, tools/emulators/*)
- Temporary clones (tmp/)
- IDE and OS files (.vscode/settings.json, Thumbs.db, .DS_Store)
- Emulator files (save states, config)
- Python bytecode (__pycache__, *.pyc)

**Code Example**:

```gitignore
# ============================================
# SNES Build Tools - .gitignore
# ============================================

# --- Build Artifacts ---
*.o
*.obj
*.sfc
*.smc
*.sym
*.brr
*.pc7
*.mp7

# Build output directories
projects/*/build/*
!projects/*/build/.gitkeep

# PVSnesLib intermediate files (generated during build)
# These are produced alongside source files by gfx4snes and the assembler
*.pic
*.pal
*.map
*.til

# WLA assembler/linker intermediates
*.lib
*.lst

# --- Downloaded Tools (install script fetches these) ---
tools/pvsneslib/*
!tools/pvsneslib/.gitkeep
tools/emulators/*
!tools/emulators/.gitkeep
tools/bin/*
!tools/bin/.gitkeep

# --- Temporary Files ---
tmp/*
!tmp/.gitkeep

# --- Python ---
__pycache__/
*.py[cod]
*$py.class
*.egg-info/
venv/
.env

# --- OS Files ---
.DS_Store
Thumbs.db
ehthumbs.db
Desktop.ini
*.swp
*.swo
*~

# --- IDE / Editor ---
.vscode/
.idea/
*.sublime-project
*.sublime-workspace

# --- Emulator Files ---
*.srm
*.sav
*.mss
*.bst
*.ips
*.bps

# --- Logs ---
*.log
```

**References**:
- GitHub's gitignore templates: https://github.com/github/gitignore

---

### Task 1.3: Create LICENSE (MIT)

**File(s)**: `J:\code\snes\snes-build-tools\LICENSE`

**Description**: Create a standard MIT license file. The year should be 2025 and the copyright holder should be "SNES Build Tools Contributors".

**Code Example**:

```
MIT License

Copyright (c) 2025 SNES Build Tools Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

### Task 1.4: Create README.md

**File(s)**: `J:\code\snes\snes-build-tools\README.md`

**Description**: Create the initial README with project overview, directory structure explanation, and placeholder sections that will be filled in during Phase 10. The README should be informative even at this early stage.

**Code Example**:

```markdown
# SNES Build Tools

A clone-and-run SNES ROM build toolchain featuring a demo ROM with an Earthbound-style animated background and large pixel text.

## What This Is

This repository provides everything you need to start building SNES ROMs in C:

- **Automated install script** that downloads and configures the complete toolchain
- **PVSnesLib SDK** with 816-tcc compiler, wla-65816 assembler, and wlalink linker
- **Demo ROM** ("Hello SNES World") showcasing animated backgrounds and text rendering
- **Project template** for starting your own SNES projects

## Demo ROM

The included `hello-snes-world` project produces a ROM that displays:
- An Earthbound-style animated background with sine-wave distortion and palette cycling
- "HELLO SNES WORLD" in large white pixel font with black border, centered on screen
- Uses SNES Mode 1 with layered backgrounds and HDMA effects

## Quick Start

> **TODO**: Complete setup instructions will be added in Phase 10.

```bash
# Clone the repository
git clone <repo-url>
cd snes-build-tools

# Run the install script (Windows)
install.bat

# Run the install script (Linux/macOS)
./install.sh

# Build the demo ROM
cd projects/hello-snes-world
make
```

## Repository Structure

```
snes-build-tools/
├── install.bat / install.sh    # Automated toolchain installer
├── tools/                      # Downloaded SDK and emulators
│   ├── pvsneslib/              # PVSnesLib SDK
│   ├── emulators/              # Optional test emulators
│   └── bin/                    # Key executables
├── projects/
│   └── hello-snes-world/       # Demo ROM project
│       ├── src/main.c          # C source
│       ├── assets/             # Graphics (PNG and converted)
│       ├── hdr.asm             # ROM header
│       ├── data.asm            # Binary asset includes
│       └── Makefile            # Build configuration
├── templates/basic/            # Starter template for new projects
├── scripts/                    # Helper scripts
├── docs/                       # Documentation
└── tmp/                        # Temporary files (gitignored)
```

## Technical Details

- **SDK**: PVSnesLib v4.5.0
- **Compiler**: 816-tcc (C to 65816 ASM)
- **Assembler**: wla-65816
- **Linker**: wlalink
- **Graphics**: gfx4snes (PNG to SNES tile format)
- **Target**: SNES / Super Famicom (WDC 65816, 3.58 MHz)
- **Video Mode**: Mode 1 (BG1: 16-color animated, BG2: 16-color text)
- **ROM Type**: LoROM, 4Mbit

## Build Pipeline

```
C source (.c) --> 816-tcc --> ASM (.asm) --> 816-opt --> wla-65816 --> wlalink --> ROM (.sfc)
PNG graphics  --> gfx4snes --> .pic/.pal/.map --> included via data.asm --> linked into ROM
```

## License

MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- [PVSnesLib](https://github.com/alekmaul/pvsneslib) by Alekmaul
- [Earthbound Battle Backgrounds JS](https://github.com/gjtorikian/Earthbound-Battle-Backgrounds-JS) by Garen Torikian
- The SNES homebrew community
```

---

### Task 1.5: Initialize Git Repository

**File(s)**: `J:\code\snes\snes-build-tools\.git\` (created by git init)

**Description**: Initialize the Git repository if not already initialized. Create an initial commit with the scaffolding.

**Implementation Details**:

```bash
cd J:\code\snes\snes-build-tools

# Initialize if needed (safe to run if already initialized)
git init

# Stage all scaffolding files
git add .gitignore LICENSE README.md
git add projects/ templates/ scripts/ docs/ tools/

# Create initial commit
git commit -m "Phase 1: Project scaffolding and repository structure"
```

Note: Only commit if this is a fresh repository. If the repository already has commits, just stage and commit the new files.

**References**:
- Git init documentation: https://git-scm.com/docs/git-init

---

## Acceptance Criteria

- [ ] All directories in the tree exist under `J:\code\snes\snes-build-tools\`
- [ ] `.gitkeep` files exist in all initially-empty leaf directories
- [ ] `.gitignore` exists at `J:\code\snes\snes-build-tools\.gitignore` and correctly excludes build artifacts, tools, and tmp/
- [ ] `LICENSE` exists at `J:\code\snes\snes-build-tools\LICENSE` with MIT license text
- [ ] `README.md` exists at `J:\code\snes\snes-build-tools\README.md` with project overview and structure
- [ ] Running `git status` shows a clean working tree (all files committed)
- [ ] The directory `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\` exists
- [ ] The directory `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\fonts\` exists
- [ ] The directory `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\backgrounds\` exists
- [ ] The directory `J:\code\snes\snes-build-tools\templates\basic\` exists with src/, assets/, include/, build/ subdirectories

## File Manifest

| File | Action | Description |
|------|--------|-------------|
| `J:\code\snes\snes-build-tools\.gitignore` | CREATE | Repository ignore rules |
| `J:\code\snes\snes-build-tools\LICENSE` | CREATE | MIT license |
| `J:\code\snes\snes-build-tools\README.md` | CREATE | Project documentation |
| `J:\code\snes\snes-build-tools\tools\pvsneslib\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\tools\emulators\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\tools\bin\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\src\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\fonts\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\assets\backgrounds\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\include\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\projects\hello-snes-world\build\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\templates\basic\src\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\templates\basic\assets\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\templates\basic\include\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\templates\basic\build\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\scripts\.gitkeep` | CREATE | Directory placeholder |
| `J:\code\snes\snes-build-tools\tmp\.gitkeep` | CREATE | Directory placeholder |

## Dependencies

- **Depends on**: Nothing (this is the first phase)
- **Depended on by**: All subsequent phases (2-10)
