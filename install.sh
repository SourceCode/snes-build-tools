#!/bin/bash
# ============================================
# SNES Build Tools - Linux/macOS Install Script
# ============================================

set -euo pipefail

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
BIN_DIR="$PVSNESLIB_DIR/devkitsnes/bin"
TOOLS_DIR="$PVSNESLIB_DIR/devkitsnes/tools"
TMP_DIR="$REPO_ROOT/tmp"

# --- Detect platform ---
OS_NAME="$(uname -s)"
case "$OS_NAME" in
    Linux*)  PLATFORM="linux" ;;
    Darwin*) PLATFORM="darwin" ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
    *)       PLATFORM="unknown" ;;
esac

echo "Detected platform: $PLATFORM ($OS_NAME)"
echo ""

# --- Color output helpers ---
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' NC=''
fi

pass() { echo -e "  ${GREEN}[OK]${NC}   $1"; }
warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; exit 1; }
fail_noexit() { echo -e "  ${RED}[FAIL]${NC} $1"; }

# --- Step 1: Check Prerequisites ---
echo "[1/7] Checking prerequisites..."
echo ""

# Check git
if command -v git &>/dev/null; then
    pass "$(git --version)"
else
    fail "git is not installed. Install it with your package manager."
fi

# Check make
if command -v make &>/dev/null; then
    pass "$(make --version | head -n1)"
else
    warn "GNU Make is not installed."
    echo "         Install with: sudo apt install build-essential (Linux)"
    echo "         Install with: xcode-select --install (macOS)"
    echo "         Continuing..."
fi

# Check Python
PYTHON_CMD=""
if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
    pass "$(python3 --version)"
elif command -v python &>/dev/null; then
    PYTHON_CMD="python"
    pass "$(python --version)"
else
    warn "Python 3 is not installed. Font generation will not work."
    echo "         Install with: sudo apt install python3 python3-pip (Linux)"
    echo "         Install with: brew install python3 (macOS)"
fi

# Check curl or wget
DOWNLOAD_CMD=""
if command -v curl &>/dev/null; then
    DOWNLOAD_CMD="curl"
    pass "curl available"
elif command -v wget &>/dev/null; then
    DOWNLOAD_CMD="wget"
    pass "wget available"
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

pass "Directories ready."
echo ""

# --- Step 3: Download PVSnesLib ---
echo "[3/7] Downloading PVSnesLib v${PVSNESLIB_VERSION}..."

# Check if already installed (compiler in bin/, not tools/)
if [ -f "$BIN_DIR/816-tcc" ] || [ -f "$BIN_DIR/816-tcc.exe" ]; then
    echo "  PVSnesLib is already installed. Skipping download."
    echo "  To force reinstall, delete $PVSNESLIB_DIR and run again."
    SKIP_DOWNLOAD=1
else
    SKIP_DOWNLOAD=0

    # Determine download URL and archive name based on platform
    case "$PLATFORM" in
        linux)
            ARCHIVE_NAME="pvsneslib_450_64b_linux.zip"
            ;;
        darwin)
            ARCHIVE_NAME="pvsneslib_450_64b_darwin.zip"
            ;;
        windows)
            ARCHIVE_NAME="pvsneslib_450_64b_windows.zip"
            ;;
        *)
            warn "Unknown platform. Trying Linux build..."
            ARCHIVE_NAME="pvsneslib_450_64b_linux.zip"
            ;;
    esac

    PVSNESLIB_URL="https://github.com/alekmaul/pvsneslib/releases/download/${PVSNESLIB_VERSION}/${ARCHIVE_NAME}"
    PVSNESLIB_ARCHIVE="$TMP_DIR/$ARCHIVE_NAME"

    echo "  Downloading from: $PVSNESLIB_URL"
    echo "  Saving to: $PVSNESLIB_ARCHIVE"
    echo ""

    if [ "$DOWNLOAD_CMD" = "curl" ]; then
        curl -L --progress-bar -o "$PVSNESLIB_ARCHIVE" "$PVSNESLIB_URL"
    else
        wget --show-progress -O "$PVSNESLIB_ARCHIVE" "$PVSNESLIB_URL"
    fi

    if [ $? -ne 0 ]; then
        fail "Download failed. Check your internet connection and the URL above."
    fi

    pass "Download complete."
    echo ""

    # --- Step 4: Extract ---
    echo "[4/7] Extracting PVSnesLib..."

    # Clean existing installation (preserve .gitkeep)
    for subdir in devkitsnes pvsneslib snes-examples vscode-template; do
        [ -d "$PVSNESLIB_DIR/$subdir" ] && rm -rf "$PVSNESLIB_DIR/$subdir"
    done

    # Extract to a temporary staging directory first, then move contents.
    # This avoids the same-name collision problem: the ZIP root is "pvsneslib/"
    # which contains an inner "pvsneslib/" subdir (the library with headers).
    EXTRACT_STAGING="$TMP_DIR/_pvsneslib_extract_staging"
    rm -rf "$EXTRACT_STAGING"
    mkdir -p "$EXTRACT_STAGING"

    # All PVSnesLib 4.5.0 releases are ZIP format
    if command -v unzip &>/dev/null; then
        unzip -o -q "$PVSNESLIB_ARCHIVE" -d "$EXTRACT_STAGING"
    else
        # Fallback: try python
        if [ -n "$PYTHON_CMD" ]; then
            $PYTHON_CMD -c "import zipfile; zipfile.ZipFile('$PVSNESLIB_ARCHIVE').extractall('$EXTRACT_STAGING')"
        else
            fail "Neither unzip nor python available. Cannot extract archive."
        fi
    fi

    # Find the actual SDK root (may be nested one level in a "pvsneslib/" dir)
    SDK_ROOT="$EXTRACT_STAGING"
    if [ ! -d "$SDK_ROOT/devkitsnes" ]; then
        for candidate in "$EXTRACT_STAGING"/*/; do
            if [ -d "$candidate/devkitsnes" ]; then
                SDK_ROOT="$candidate"
                echo "  Found SDK in $(basename "$candidate")/"
                break
            fi
        done
    fi

    if [ ! -d "$SDK_ROOT/devkitsnes" ]; then
        rm -rf "$EXTRACT_STAGING"
        fail "Could not find devkitsnes/ directory after extraction. Archive structure may have changed."
    fi

    # Move each subdirectory from staging to final location
    for item in "$SDK_ROOT"/*; do
        item_name="$(basename "$item")"
        mv "$item" "$PVSNESLIB_DIR/$item_name"
    done

    # Clean up staging
    rm -rf "$EXTRACT_STAGING"

    # Make binaries executable
    if [ -d "$BIN_DIR" ]; then
        chmod +x "$BIN_DIR"/* 2>/dev/null || true
    fi
    if [ -d "$TOOLS_DIR" ]; then
        chmod +x "$TOOLS_DIR"/* 2>/dev/null || true
    fi

    pass "Extraction complete."
fi

echo ""

# --- Step 5: Verify ---
echo "[5/7] Verifying PVSnesLib installation..."

VERIFY_FAILED=0

check_file() {
    local path="$1"
    local label="$2"
    if [ -f "$path" ] || [ -f "${path}.exe" ]; then
        pass "$label"
    else
        fail_noexit "MISSING: $label ($path)"
        VERIFY_FAILED=1
    fi
}

# Compilers in devkitsnes/bin/
check_file "$BIN_DIR/816-tcc"   "816-tcc      (C compiler)"
check_file "$BIN_DIR/wla-65816" "wla-65816    (assembler)"
check_file "$BIN_DIR/wlalink"   "wlalink      (linker)"

# Tools in devkitsnes/tools/
check_file "$TOOLS_DIR/gfx4snes" "gfx4snes     (graphics converter)"
check_file "$TOOLS_DIR/816-opt"  "816-opt      (ASM optimizer)"

# Build rules at devkitsnes/snes_rules (not in lib/)
check_file "$PVSNESLIB_DIR/devkitsnes/snes_rules" "snes_rules   (Makefile include)"

# SNES headers
check_file "$PVSNESLIB_DIR/pvsneslib/include/snes/video.h" "SNES headers (pvsneslib/include/snes/)"

if [ "$VERIFY_FAILED" -eq 1 ]; then
    echo ""
    warn "PVSnesLib installation may be incomplete."
    echo "         Some files are missing. Check the release or build from source."
    echo "         https://github.com/alekmaul/pvsneslib/releases/tag/${PVSNESLIB_VERSION}"
else
    echo ""
    pass "PVSnesLib v${PVSNESLIB_VERSION} verified successfully."
fi

echo ""

# --- Step 6: Python dependencies ---
echo "[6/7] Installing Python dependencies..."

if [ -n "$PYTHON_CMD" ]; then
    if $PYTHON_CMD -m pip install --quiet Pillow 2>/dev/null; then
        pass "Pillow installed."
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PVSNESLIB_HOME="$SCRIPT_DIR/tools/pvsneslib"
export PATH="$PVSNESLIB_HOME/devkitsnes/bin:$PVSNESLIB_HOME/devkitsnes/tools:$PATH"

echo "SNES Build Tools environment configured."
echo "  PVSNESLIB_HOME=$PVSNESLIB_HOME"
ENVEOF

chmod +x "$REPO_ROOT/env.sh"
pass "Created env.sh"

echo ""

# --- Done ---
echo "========================================"
echo " Installation Complete!"
echo "========================================"
echo ""
echo "PVSnesLib v${PVSNESLIB_VERSION} installed to:"
echo "  $PVSNESLIB_DIR"
echo ""
echo "Next steps:"
echo ""
echo "  1. Set up your environment:"
echo "     source env.sh"
echo ""
echo "  2. Build the demo ROM:"
echo "     source env.sh"
echo "     cd projects/hello-snes-world"
echo "     make"
echo ""
echo "  3. Verify tools:"
echo "     bash scripts/verify_install.sh"
echo ""
