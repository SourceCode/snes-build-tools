#!/bin/bash
# SNES Build Tools - Installation Verification

echo ""
echo "SNES Build Tools - Installation Verification"
echo "=============================================="
echo ""

# --- Determine repo root ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Source environment
source "$REPO_ROOT/env.sh" 2>/dev/null || true

# --- Color output ---
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' NC=''
fi

PASS=0
FAIL=0
WARN=0

check_file() {
    local path="$1"
    local label="$2"
    if [ -f "$path" ] || [ -f "${path}.exe" ]; then
        echo -e "  ${GREEN}[PASS]${NC} $label"
        ((PASS++))
    else
        echo -e "  ${RED}[FAIL]${NC} $label - not found"
        echo "         Expected: $path"
        ((FAIL++))
    fi
}

check_cmd() {
    local cmd="$1"
    local label="$2"
    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}[PASS]${NC} $label"
        ((PASS++))
    else
        echo -e "  ${YELLOW}[WARN]${NC} $label - not found in PATH"
        ((WARN++))
    fi
}

# --- Check SDK files ---
echo "Checking PVSnesLib SDK files..."
echo ""

SDK="$REPO_ROOT/tools/pvsneslib"

check_file "$SDK/devkitsnes/bin/816-tcc"       "816-tcc (C compiler)"
check_file "$SDK/devkitsnes/bin/wla-65816"     "wla-65816 (assembler)"
check_file "$SDK/devkitsnes/bin/wlalink"       "wlalink (linker)"
check_file "$SDK/devkitsnes/tools/gfx4snes"    "gfx4snes (graphics converter)"
check_file "$SDK/devkitsnes/tools/816-opt"     "816-opt (ASM optimizer)"
check_file "$SDK/devkitsnes/tools/constify"    "constify (constant mover)"
check_file "$SDK/devkitsnes/tools/snestools"   "snestools (ROM header tool)"
check_file "$SDK/devkitsnes/snes_rules"        "snes_rules (Makefile include)"
check_file "$SDK/pvsneslib/include/snes/video.h" "SNES headers"

echo ""
echo "Checking system tools..."
echo ""

# --- Check system prerequisites ---
check_cmd "git"    "git"
check_cmd "make"   "GNU Make"

# Check python3 or python
PYTHON_CMD=""
if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
    echo -e "  ${GREEN}[PASS]${NC} Python 3 (python3)"
    ((PASS++))
elif command -v python &>/dev/null; then
    PYTHON_CMD="python"
    echo -e "  ${GREEN}[PASS]${NC} Python (python)"
    ((PASS++))
else
    echo -e "  ${YELLOW}[WARN]${NC} Python - not found"
    ((WARN++))
fi

echo ""
echo "Checking Python packages..."
echo ""

# --- Check Pillow ---
if [ -n "$PYTHON_CMD" ]; then
    PIL_VERSION=$($PYTHON_CMD -c "import PIL; print(PIL.__version__)" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}[PASS]${NC} Pillow v${PIL_VERSION}"
        ((PASS++))
    else
        echo -e "  ${YELLOW}[WARN]${NC} Pillow not installed (needed for font generation)"
        echo "         Install with: $PYTHON_CMD -m pip install Pillow"
        ((WARN++))
    fi
else
    echo -e "  ${YELLOW}[WARN]${NC} Skipping Pillow check (Python not found)"
    ((WARN++))
fi

echo ""
echo "=============================================="
echo "Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "=============================================="
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "Some required tools are missing. Run install.sh to fix."
    exit 1
else
    if [ "$WARN" -gt 0 ]; then
        echo "All required tools present. Some optional tools have warnings."
    else
        echo "All tools verified successfully!"
    fi
    exit 0
fi
