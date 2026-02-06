# Phase 3: Install Script Development

## Overview

This phase creates cross-platform install scripts that transform a fresh clone of the repository into a fully functional SNES development environment. The scripts download PVSnesLib, verify prerequisites, configure environment variables, and validate the installation by running a minimal test. The goal is a zero-friction "clone and run" experience.

Two scripts are created:
- `install.bat` for Windows (primary platform)
- `install.sh` for Linux/macOS

Both scripts must be idempotent -- running them multiple times should not break anything or re-download tools that are already present.

## Prerequisites

- Phase 1 completed (directory structure exists)
- Phase 2 completed (dependency manifest exists at `J:\code\snes\snes-build-tools\scripts\dependencies.json`)

## Objectives

1. Create `J:\code\snes\snes-build-tools\install.bat` (Windows install script)
2. Create `J:\code\snes\snes-build-tools\install.sh` (Linux/macOS install script)
3. Create `J:\code\snes\snes-build-tools\env.bat` (Windows environment setup)
4. Create `J:\code\snes\snes-build-tools\env.sh` (Linux/macOS environment setup)
5. Create a minimal test to verify the installation works
6. Handle all error conditions gracefully with informative messages

## Context

### Install Script Responsibilities

The install scripts perform these steps in order:

1. **Detect platform** and set platform-specific variables
2. **Check prerequisites**: git, make, python3
3. **Download PVSnesLib** SDK from GitHub releases
4. **Extract** to `tools/pvsneslib/`
5. **Verify extraction** by checking for key executables
6. **Install Python dependencies** (Pillow via pip)
7. **Create environment scripts** (env.bat / env.sh)
8. **Run verification** test (invoke 816-tcc --version)
9. **Print success message** with next steps

### Error Handling Strategy

Every step that can fail must:
- Check the exit code
- Print a clear error message explaining what failed and how to fix it
- Exit with a non-zero code

The script should NOT silently continue past failures.

### Idempotency

- Before downloading, check if `tools/pvsneslib/devkitsnes/tools/816-tcc.exe` already exists
- If tools are already present, print "Already installed" and skip download
- Always re-run verification even if skipping download

## Tasks

### Task 3.1: Create Windows Install Script

**File(s)**: `J:\code\snes\snes-build-tools\install.bat`

**Description**: A Windows batch script that sets up the complete SNES development environment. This is the primary install script since PVSnesLib is primarily a Windows SDK.

**Implementation Details**:

The script must handle:
- Running from any directory (use `%~dp0` to find repo root)
- Downloading with `curl` (available on Windows 10+) or `powershell Invoke-WebRequest`
- Extracting ZIP files with `powershell Expand-Archive`
- Setting environment variables for the current session
- Creating the `env.bat` helper script

**Code Example**:

```batch
@echo off
setlocal enabledelayedexpansion

:: ============================================
:: SNES Build Tools - Windows Install Script
:: ============================================

echo.
echo ========================================
echo  SNES Build Tools Installer (Windows)
echo ========================================
echo.

:: --- Determine repo root (directory containing this script) ---
set "REPO_ROOT=%~dp0"
:: Remove trailing backslash
if "%REPO_ROOT:~-1%"=="\" set "REPO_ROOT=%REPO_ROOT:~0,-1%"

echo Repository root: %REPO_ROOT%
echo.

:: --- Configuration ---
set "PVSNESLIB_VERSION=4.5.0"
set "PVSNESLIB_URL=https://github.com/alekmaul/pvsneslib/releases/download/%PVSNESLIB_VERSION%/pvsneslib-windows-%PVSNESLIB_VERSION%.zip"
set "PVSNESLIB_DIR=%REPO_ROOT%\tools\pvsneslib"
set "PVSNESLIB_ZIP=%REPO_ROOT%\tmp\pvsneslib-%PVSNESLIB_VERSION%.zip"
set "TOOLS_DIR=%PVSNESLIB_DIR%\devkitsnes\tools"

:: --- Step 1: Check Prerequisites ---
echo [1/7] Checking prerequisites...
echo.

:: Check for git
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: git is not installed or not in PATH.
    echo Install Git from https://git-scm.com/download/win
    exit /b 1
)
for /f "tokens=*" %%i in ('git --version') do echo   git: %%i

:: Check for make
where make >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo WARNING: GNU Make is not installed or not in PATH.
    echo You will need Make to build ROM projects.
    echo.
    echo Install options:
    echo   1. MSYS2: https://www.msys2.org/ then: pacman -S make
    echo   2. Chocolatey: choco install make
    echo   3. scoop: scoop install make
    echo.
    echo Continuing installation anyway...
    echo.
) else (
    for /f "tokens=*" %%i in ('make --version 2^>^&1') do (
        echo   make: %%i
        goto :make_done
    )
    :make_done
)

:: Check for Python
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo WARNING: Python is not installed or not in PATH.
    echo Python is needed for font generation scripts.
    echo Install from https://www.python.org/downloads/
    echo.
    echo Continuing installation anyway...
    echo.
) else (
    for /f "tokens=*" %%i in ('python --version') do echo   python: %%i
)

echo.
echo   Prerequisites check complete.
echo.

:: --- Step 2: Create directories ---
echo [2/7] Creating directories...

if not exist "%REPO_ROOT%\tools\pvsneslib" mkdir "%REPO_ROOT%\tools\pvsneslib"
if not exist "%REPO_ROOT%\tools\emulators" mkdir "%REPO_ROOT%\tools\emulators"
if not exist "%REPO_ROOT%\tools\bin" mkdir "%REPO_ROOT%\tools\bin"
if not exist "%REPO_ROOT%\tmp" mkdir "%REPO_ROOT%\tmp"

echo   Directories ready.
echo.

:: --- Step 3: Download PVSnesLib ---
echo [3/7] Downloading PVSnesLib v%PVSNESLIB_VERSION%...

:: Check if already installed
if exist "%TOOLS_DIR%\816-tcc.exe" (
    echo   PVSnesLib is already installed. Skipping download.
    echo   To force reinstall, delete %PVSNESLIB_DIR% and run again.
    goto :skip_download
)

:: Download using curl (available on Windows 10 1803+)
echo   Downloading from: %PVSNESLIB_URL%
echo   Saving to: %PVSNESLIB_ZIP%
echo.

curl -L -o "%PVSNESLIB_ZIP%" "%PVSNESLIB_URL%"
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Download failed.
    echo.
    echo Possible causes:
    echo   - No internet connection
    echo   - URL has changed (check https://github.com/alekmaul/pvsneslib/releases)
    echo   - curl is not available (requires Windows 10 1803+)
    echo.
    echo Manual download: Download PVSnesLib from the URL above
    echo and extract to: %PVSNESLIB_DIR%
    exit /b 1
)

echo   Download complete.
echo.

:: --- Step 4: Extract PVSnesLib ---
echo [4/7] Extracting PVSnesLib...

:: Clean target directory first
if exist "%PVSNESLIB_DIR%\devkitsnes" (
    echo   Removing existing installation...
    rmdir /s /q "%PVSNESLIB_DIR%\devkitsnes"
)

:: Extract using PowerShell
powershell -NoProfile -Command "Expand-Archive -Path '%PVSNESLIB_ZIP%' -DestinationPath '%PVSNESLIB_DIR%' -Force"
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Extraction failed.
    echo Try extracting manually: %PVSNESLIB_ZIP% to %PVSNESLIB_DIR%
    exit /b 1
)

:: Handle case where ZIP contains a root folder
:: PVSnesLib releases sometimes extract to pvsneslib-x.y.z/ subfolder
:: We need devkitsnes/ to be directly under tools/pvsneslib/
if not exist "%PVSNESLIB_DIR%\devkitsnes" (
    echo   Checking for nested directory structure...
    for /d %%d in ("%PVSNESLIB_DIR%\*") do (
        if exist "%%d\devkitsnes" (
            echo   Found SDK in %%d, moving to correct location...
            xcopy "%%d\*" "%PVSNESLIB_DIR%\" /s /e /y /q >nul
            rmdir /s /q "%%d" 2>nul
            goto :extract_done
        )
    )
)
:extract_done

echo   Extraction complete.
echo.

:skip_download

:: --- Step 5: Verify SDK installation ---
echo [5/7] Verifying PVSnesLib installation...

set "VERIFY_FAILED=0"

if not exist "%TOOLS_DIR%\816-tcc.exe" (
    echo   MISSING: 816-tcc.exe (C compiler)
    set "VERIFY_FAILED=1"
)
if not exist "%TOOLS_DIR%\wla-65816.exe" (
    echo   MISSING: wla-65816.exe (assembler)
    set "VERIFY_FAILED=1"
)
if not exist "%TOOLS_DIR%\wlalink.exe" (
    echo   MISSING: wlalink.exe (linker)
    set "VERIFY_FAILED=1"
)
if not exist "%TOOLS_DIR%\gfx4snes.exe" (
    echo   MISSING: gfx4snes.exe (graphics converter)
    set "VERIFY_FAILED=1"
)
if not exist "%PVSNESLIB_DIR%\devkitsnes\lib\snes_rules" (
    echo   MISSING: snes_rules (Makefile include)
    set "VERIFY_FAILED=1"
)

if %VERIFY_FAILED%==1 (
    echo.
    echo ERROR: PVSnesLib installation is incomplete.
    echo Some required files are missing from: %TOOLS_DIR%
    echo.
    echo Try:
    echo   1. Delete %PVSNESLIB_DIR%
    echo   2. Re-run this script
    echo   3. If the problem persists, download manually from:
    echo      https://github.com/alekmaul/pvsneslib/releases
    exit /b 1
)

echo   816-tcc.exe   ... OK
echo   wla-65816.exe ... OK
echo   wlalink.exe   ... OK
echo   gfx4snes.exe  ... OK
echo   snes_rules    ... OK
echo.
echo   PVSnesLib v%PVSNESLIB_VERSION% verified successfully.
echo.

:: --- Step 6: Install Python dependencies ---
echo [6/7] Installing Python dependencies...

where python >nul 2>&1
if %errorlevel% equ 0 (
    python -m pip install --quiet Pillow 2>nul
    if %errorlevel% equ 0 (
        echo   Pillow installed successfully.
    ) else (
        echo   WARNING: Failed to install Pillow. Font generation may not work.
        echo   Try manually: python -m pip install Pillow
    )
) else (
    echo   Skipping (Python not found). Install Python to enable font generation.
)
echo.

:: --- Step 7: Create environment script ---
echo [7/7] Creating environment configuration...

:: Create env.bat
(
    echo @echo off
    echo :: SNES Build Tools - Environment Setup
    echo :: Run this before building: call env.bat
    echo set "PVSNESLIB_HOME=%PVSNESLIB_DIR%"
    echo set "PATH=%%PVSNESLIB_HOME%%\devkitsnes\tools;%%PATH%%"
    echo echo SNES Build Tools environment configured.
    echo echo PVSNESLIB_HOME=%%PVSNESLIB_HOME%%
) > "%REPO_ROOT%\env.bat"

echo   Created env.bat
echo.

:: --- Done ---
echo ========================================
echo  Installation Complete!
echo ========================================
echo.
echo PVSnesLib v%PVSNESLIB_VERSION% installed to:
echo   %PVSNESLIB_DIR%
echo.
echo To set up your build environment, run:
echo   call env.bat
echo.
echo To build the demo ROM:
echo   call env.bat
echo   cd projects\hello-snes-world
echo   make
echo.
echo To test the toolchain:
echo   call env.bat
echo   816-tcc.exe --version
echo.

endlocal
exit /b 0
```

**References**:
- Windows batch scripting: https://ss64.com/nt/
- curl on Windows: https://curl.se/windows/
- PowerShell Expand-Archive: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.archive/expand-archive

---

### Task 3.2: Create Linux/macOS Install Script

**File(s)**: `J:\code\snes\snes-build-tools\install.sh`

**Description**: A Bash script that sets up the SNES development environment on Linux and macOS. PVSnesLib has limited Linux support, so this script may need to build from source or guide the user through additional steps.

**Implementation Details**:

The script follows the same 7-step structure as the Windows version but uses Bash-specific commands for downloading (curl/wget), extracting (unzip/tar), and checking prerequisites.

**Code Example**:

```bash
#!/bin/bash
# ============================================
# SNES Build Tools - Linux/macOS Install Script
# ============================================

set -e

echo ""
echo "========================================"
echo " SNES Build Tools Installer (Unix)"
echo "========================================"
echo ""

# --- Determine repo root ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

echo "Repository root: $REPO_ROOT"
echo ""

# --- Configuration ---
PVSNESLIB_VERSION="4.5.0"
PVSNESLIB_DIR="$REPO_ROOT/tools/pvsneslib"
TOOLS_DIR="$PVSNESLIB_DIR/devkitsnes/tools"
TMP_DIR="$REPO_ROOT/tmp"

# Detect platform
OS="$(uname -s)"
case "$OS" in
    Linux*)  PLATFORM="linux" ;;
    Darwin*) PLATFORM="macos" ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
    *)       PLATFORM="unknown" ;;
esac

echo "Detected platform: $PLATFORM ($OS)"
echo ""

# --- Color output helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ok()    { echo -e "  ${GREEN}OK${NC}: $1"; }
warn()  { echo -e "  ${YELLOW}WARNING${NC}: $1"; }
fail()  { echo -e "  ${RED}ERROR${NC}: $1"; exit 1; }

# --- Step 1: Check Prerequisites ---
echo "[1/7] Checking prerequisites..."
echo ""

# Check git
if command -v git &>/dev/null; then
    ok "$(git --version)"
else
    fail "git is not installed. Install it with your package manager."
fi

# Check make
if command -v make &>/dev/null; then
    ok "GNU Make $(make --version | head -n1)"
else
    warn "GNU Make is not installed."
    echo "         Install with: sudo apt install build-essential (Linux)"
    echo "         Install with: xcode-select --install (macOS)"
fi

# Check Python
PYTHON_CMD=""
if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
    ok "$(python3 --version)"
elif command -v python &>/dev/null; then
    PYTHON_CMD="python"
    ok "$(python --version)"
else
    warn "Python 3 is not installed. Font generation will not work."
    echo "         Install with: sudo apt install python3 python3-pip (Linux)"
    echo "         Install with: brew install python3 (macOS)"
fi

# Check curl or wget
DOWNLOAD_CMD=""
if command -v curl &>/dev/null; then
    DOWNLOAD_CMD="curl -L -o"
    ok "curl available"
elif command -v wget &>/dev/null; then
    DOWNLOAD_CMD="wget -O"
    ok "wget available"
else
    fail "Neither curl nor wget is installed. Cannot download tools."
fi

echo ""
echo "  Prerequisites check complete."
echo ""

# --- Step 2: Create directories ---
echo "[2/7] Creating directories..."

mkdir -p "$PVSNESLIB_DIR"
mkdir -p "$REPO_ROOT/tools/emulators"
mkdir -p "$REPO_ROOT/tools/bin"
mkdir -p "$TMP_DIR"

ok "Directories ready."
echo ""

# --- Step 3: Download PVSnesLib ---
echo "[3/7] Downloading PVSnesLib v${PVSNESLIB_VERSION}..."

if [ -f "$TOOLS_DIR/816-tcc" ] || [ -f "$TOOLS_DIR/816-tcc.exe" ]; then
    echo "  PVSnesLib is already installed. Skipping download."
    echo "  To force reinstall, delete $PVSNESLIB_DIR and run again."
else
    # Determine download URL based on platform
    if [ "$PLATFORM" = "linux" ]; then
        PVSNESLIB_URL="https://github.com/alekmaul/pvsneslib/releases/download/${PVSNESLIB_VERSION}/pvsneslib-linux-${PVSNESLIB_VERSION}.tar.gz"
        PVSNESLIB_ARCHIVE="$TMP_DIR/pvsneslib-${PVSNESLIB_VERSION}.tar.gz"
    elif [ "$PLATFORM" = "macos" ]; then
        # macOS may need the Linux build or source build
        PVSNESLIB_URL="https://github.com/alekmaul/pvsneslib/releases/download/${PVSNESLIB_VERSION}/pvsneslib-linux-${PVSNESLIB_VERSION}.tar.gz"
        PVSNESLIB_ARCHIVE="$TMP_DIR/pvsneslib-${PVSNESLIB_VERSION}.tar.gz"
        warn "macOS builds may require building PVSnesLib from source."
        echo "         Check: https://github.com/alekmaul/pvsneslib/wiki/Compiling-from-sources"
    else
        PVSNESLIB_URL="https://github.com/alekmaul/pvsneslib/releases/download/${PVSNESLIB_VERSION}/pvsneslib-windows-${PVSNESLIB_VERSION}.zip"
        PVSNESLIB_ARCHIVE="$TMP_DIR/pvsneslib-${PVSNESLIB_VERSION}.zip"
    fi

    echo "  Downloading from: $PVSNESLIB_URL"
    echo "  Saving to: $PVSNESLIB_ARCHIVE"
    echo ""

    $DOWNLOAD_CMD "$PVSNESLIB_ARCHIVE" "$PVSNESLIB_URL"

    if [ $? -ne 0 ]; then
        fail "Download failed. Check your internet connection and the URL above."
    fi

    ok "Download complete."
    echo ""

    # --- Step 4: Extract ---
    echo "[4/7] Extracting PVSnesLib..."

    if [ -d "$PVSNESLIB_DIR/devkitsnes" ]; then
        echo "  Removing existing installation..."
        rm -rf "$PVSNESLIB_DIR/devkitsnes"
    fi

    case "$PVSNESLIB_ARCHIVE" in
        *.tar.gz|*.tgz)
            tar -xzf "$PVSNESLIB_ARCHIVE" -C "$PVSNESLIB_DIR"
            ;;
        *.zip)
            unzip -o "$PVSNESLIB_ARCHIVE" -d "$PVSNESLIB_DIR"
            ;;
        *)
            fail "Unknown archive format: $PVSNESLIB_ARCHIVE"
            ;;
    esac

    # Handle nested directory
    if [ ! -d "$PVSNESLIB_DIR/devkitsnes" ]; then
        echo "  Checking for nested directory structure..."
        for dir in "$PVSNESLIB_DIR"/*/; do
            if [ -d "$dir/devkitsnes" ]; then
                echo "  Moving SDK from $dir to correct location..."
                cp -r "$dir"/* "$PVSNESLIB_DIR/"
                rm -rf "$dir"
                break
            fi
        done
    fi

    # Make tools executable
    if [ -d "$TOOLS_DIR" ]; then
        chmod +x "$TOOLS_DIR"/* 2>/dev/null || true
    fi

    ok "Extraction complete."
fi

echo ""

# --- Step 5: Verify ---
echo "[5/7] Verifying PVSnesLib installation..."

VERIFY_FAILED=0

check_tool() {
    local tool="$1"
    if [ -f "$TOOLS_DIR/$tool" ] || [ -f "$TOOLS_DIR/${tool}.exe" ]; then
        ok "$tool"
    else
        warn "MISSING: $tool"
        VERIFY_FAILED=1
    fi
}

check_tool "816-tcc"
check_tool "816-opt"
check_tool "wla-65816"
check_tool "wlalink"
check_tool "gfx4snes"

if [ ! -f "$PVSNESLIB_DIR/devkitsnes/lib/snes_rules" ]; then
    warn "MISSING: snes_rules"
    VERIFY_FAILED=1
else
    ok "snes_rules"
fi

if [ "$VERIFY_FAILED" -eq 1 ]; then
    echo ""
    warn "PVSnesLib installation may be incomplete."
    echo "         Some tools are missing. Check the release or build from source."
    echo "         https://github.com/alekmaul/pvsneslib/releases"
fi

echo ""

# --- Step 6: Python dependencies ---
echo "[6/7] Installing Python dependencies..."

if [ -n "$PYTHON_CMD" ]; then
    $PYTHON_CMD -m pip install --quiet Pillow 2>/dev/null
    if [ $? -eq 0 ]; then
        ok "Pillow installed."
    else
        warn "Failed to install Pillow. Try: $PYTHON_CMD -m pip install Pillow"
    fi
else
    echo "  Skipping (Python not found)."
fi

echo ""

# --- Step 7: Create environment script ---
echo "[7/7] Creating environment configuration..."

cat > "$REPO_ROOT/env.sh" << 'ENVEOF'
#!/bin/bash
# SNES Build Tools - Environment Setup
# Source this before building: source env.sh
export PVSNESLIB_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tools/pvsneslib"
export PATH="$PVSNESLIB_HOME/devkitsnes/tools:$PATH"
echo "SNES Build Tools environment configured."
echo "PVSNESLIB_HOME=$PVSNESLIB_HOME"
ENVEOF

chmod +x "$REPO_ROOT/env.sh"
ok "Created env.sh"

echo ""

# --- Done ---
echo "========================================"
echo " Installation Complete!"
echo "========================================"
echo ""
echo "PVSnesLib v${PVSNESLIB_VERSION} installed to:"
echo "  $PVSNESLIB_DIR"
echo ""
echo "To set up your build environment, run:"
echo "  source env.sh"
echo ""
echo "To build the demo ROM:"
echo "  source env.sh"
echo "  cd projects/hello-snes-world"
echo "  make"
echo ""
```

**Post-creation step**: Make the script executable:
```bash
chmod +x J:\code\snes\snes-build-tools\install.sh
```

**References**:
- Bash scripting guide: https://www.gnu.org/software/bash/manual/
- PVSnesLib Linux build: https://github.com/alekmaul/pvsneslib/wiki

---

### Task 3.3: Create Environment Setup Scripts

**File(s)**:
- `J:\code\snes\snes-build-tools\env.bat` (Windows)
- `J:\code\snes\snes-build-tools\env.sh` (Linux/macOS)

**Description**: Lightweight scripts that set up environment variables for a build session. These are generated by the install scripts but should also be checked into the repo as templates.

Note: The actual env.bat and env.sh are generated dynamically by the install scripts with absolute paths. The versions checked into Git use relative paths and are overwritten by the install script.

**Code Example for env.bat** (template version):

```batch
@echo off
:: SNES Build Tools - Environment Setup
:: Run this before building: call env.bat
set "PVSNESLIB_HOME=%~dp0tools\pvsneslib"
set "PATH=%PVSNESLIB_HOME%\devkitsnes\tools;%PATH%"
echo SNES Build Tools environment configured.
echo PVSNESLIB_HOME=%PVSNESLIB_HOME%
```

**Code Example for env.sh** (template version):

```bash
#!/bin/bash
# SNES Build Tools - Environment Setup
# Source this before building: source env.sh
export PVSNESLIB_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tools/pvsneslib"
export PATH="$PVSNESLIB_HOME/devkitsnes/tools:$PATH"
echo "SNES Build Tools environment configured."
echo "PVSNESLIB_HOME=$PVSNESLIB_HOME"
```

---

### Task 3.4: Create Installation Verification Test

**File(s)**: `J:\code\snes\snes-build-tools\scripts\verify_install.bat` and `J:\code\snes\snes-build-tools\scripts\verify_install.sh`

**Description**: A standalone verification script that can be run at any time to confirm the toolchain is properly installed and functional. This is useful for debugging install issues.

**Code Example (verify_install.bat)**:

```batch
@echo off
setlocal

echo SNES Build Tools - Installation Verification
echo ==============================================
echo.

set "REPO_ROOT=%~dp0.."
if "%REPO_ROOT:~-1%"=="\" set "REPO_ROOT=%REPO_ROOT:~0,-1%"

call "%REPO_ROOT%\env.bat" >nul 2>&1

set "PASS=0"
set "FAIL=0"

:: Check each tool
call :check_tool "816-tcc" "816-tcc.exe --version"
call :check_tool "wla-65816" "wla-65816 --version"
call :check_tool "wlalink" "wlalink --version"
call :check_tool "gfx4snes" "gfx4snes --version"
call :check_tool "python" "python --version"
call :check_tool "make" "make --version"

echo.
echo Results: %PASS% passed, %FAIL% failed
echo.

if %FAIL% gtr 0 (
    echo Some tools are missing. Run install.bat to fix.
    exit /b 1
) else (
    echo All tools verified successfully!
    exit /b 0
)

:check_tool
where %~1 >nul 2>&1
if %errorlevel% equ 0 (
    echo   [PASS] %~1
    set /a PASS+=1
) else (
    echo   [FAIL] %~1 - not found in PATH
    set /a FAIL+=1
)
exit /b 0
```

**Code Example (verify_install.sh)**:

```bash
#!/bin/bash
# SNES Build Tools - Installation Verification

echo "SNES Build Tools - Installation Verification"
echo "=============================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

source "$REPO_ROOT/env.sh" 2>/dev/null

PASS=0
FAIL=0

check_tool() {
    if command -v "$1" &>/dev/null; then
        echo "  [PASS] $1"
        ((PASS++))
    else
        echo "  [FAIL] $1 - not found in PATH"
        ((FAIL++))
    fi
}

check_tool "816-tcc"
check_tool "wla-65816"
check_tool "wlalink"
check_tool "gfx4snes"
check_tool "python3"
check_tool "make"

echo ""
echo "Results: $PASS passed, $FAIL failed"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "Some tools are missing. Run install.sh to fix."
    exit 1
else
    echo "All tools verified successfully!"
    exit 0
fi
```

---

## Acceptance Criteria

- [ ] `J:\code\snes\snes-build-tools\install.bat` exists and is syntactically valid batch script
- [ ] `J:\code\snes\snes-build-tools\install.sh` exists and is executable (`chmod +x`)
- [ ] Running `install.bat` on Windows with internet access downloads PVSnesLib to `tools\pvsneslib\`
- [ ] Running `install.bat` a second time detects existing installation and skips download
- [ ] `env.bat` is created after installation and correctly sets `PVSNESLIB_HOME` and `PATH`
- [ ] After running `call env.bat`, `816-tcc.exe --version` runs successfully
- [ ] After running `call env.bat`, `gfx4snes.exe --version` runs successfully
- [ ] `scripts\verify_install.bat` runs and reports status of all tools
- [ ] The install script prints clear error messages when prerequisites are missing
- [ ] The install script prints a success message with next steps upon completion

## File Manifest

| File | Action | Description |
|------|--------|-------------|
| `J:\code\snes\snes-build-tools\install.bat` | CREATE | Windows install script |
| `J:\code\snes\snes-build-tools\install.sh` | CREATE | Linux/macOS install script |
| `J:\code\snes\snes-build-tools\env.bat` | CREATE | Windows environment setup (template) |
| `J:\code\snes\snes-build-tools\env.sh` | CREATE | Linux/macOS environment setup (template) |
| `J:\code\snes\snes-build-tools\scripts\verify_install.bat` | CREATE | Windows verification script |
| `J:\code\snes\snes-build-tools\scripts\verify_install.sh` | CREATE | Linux/macOS verification script |

## Dependencies

- **Depends on**: Phase 1 (directory structure), Phase 2 (dependency manifest)
- **Depended on by**: Phase 4 (Makefile needs `PVSNESLIB_HOME` set), Phase 5 (gfx4snes needed), Phase 6 (gfx4snes needed), Phase 7 (compiler/assembler/linker needed)
