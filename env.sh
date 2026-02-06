#!/bin/bash
# SNES Build Tools - Environment Setup
# Source this before building: source env.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PVSNESLIB_HOME="$SCRIPT_DIR/tools/pvsneslib"
export PATH="$PVSNESLIB_HOME/devkitsnes/bin:$PVSNESLIB_HOME/devkitsnes/tools:$PATH"

echo "SNES Build Tools environment configured."
echo "  PVSNESLIB_HOME=$PVSNESLIB_HOME"
