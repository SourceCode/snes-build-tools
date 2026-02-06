#!/usr/bin/env python3
"""
Background Pattern Generator for SNES Earthbound-style demo.

Creates a 256x256 pixel horizontal color band pattern with 16 indexed colors.
Designed for sine-wave distortion and palette cycling.

The pattern uses pure horizontal bands (no x-variation) for maximum
tile reduction. With 16 colors and 16-row bands, the SNES only needs
~32 unique tiles, well within the 256-tile VRAM budget.

Usage:
    python generate_background.py [output_path]
    Default output: ../projects/hello-snes-world/assets/backgrounds/bg_earthbound.png
"""

import sys
import os
import math
from PIL import Image

# --- Configuration ---
WIDTH = 256
HEIGHT = 256
NUM_COLORS = 16


def generate_palette():
    """Generate a 16-color palette cycling through blue/purple/teal hues.

    Colors are arranged so that forward rotation (palette cycling Type 1)
    creates a smooth flowing effect. The gradient wraps: color 15 transitions
    back toward color 0's hue range.
    """
    palette = []
    for i in range(NUM_COLORS):
        t = i / NUM_COLORS
        # Gradient: deep blue -> indigo -> purple -> magenta -> violet -> deep blue
        # Using sinusoidal RGB channels with phase offsets
        r = int(30 + 100 * (0.5 + 0.5 * math.sin(2 * math.pi * t - 0.5)))
        g = int(5 + 50 * (0.5 + 0.5 * math.sin(2 * math.pi * t + 2.5)))
        b = int(60 + 195 * (0.5 + 0.5 * math.sin(2 * math.pi * t + 4.0)))

        palette.append((
            max(0, min(255, r)),
            max(0, min(255, g)),
            max(0, min(255, b))
        ))
    return palette


def create_background(output_path):
    """Create the 256x256 indexed-color PNG with horizontal color bands."""
    palette_rgb = generate_palette()

    # Build flat palette for PIL (256 entries x 3 channels)
    flat_palette = []
    for r, g, b in palette_rgb:
        flat_palette.extend([r, g, b])
    # Pad remaining 240 entries with black
    flat_palette.extend([0] * (768 - len(flat_palette)))

    # Create indexed-color image
    img = Image.new('P', (WIDTH, HEIGHT))
    img.putpalette(flat_palette)

    pixels = img.load()

    for y in range(HEIGHT):
        # Linear gradient: 256 rows / 16 colors = 16 rows per band
        band = (y * NUM_COLORS) // HEIGHT
        y_in_band = y - (band * HEIGHT // NUM_COLORS)
        band_height = HEIGHT // NUM_COLORS  # 16

        color_idx = band % NUM_COLORS
        next_idx = (band + 1) % NUM_COLORS

        # Dithered transition at band edges for smoother gradients
        # Last 4 rows of each band: dither with next color
        if y_in_band >= band_height - 2:
            # Rows 14-15: mostly next color
            color_idx = next_idx if (y % 2 == 0) else color_idx
        elif y_in_band >= band_height - 4:
            # Rows 12-13: checkerboard dither
            color_idx = next_idx if (y % 4 == 0) else color_idx

        for x in range(WIDTH):
            pixels[x, y] = color_idx

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path)

    # Print results
    print(f"Background pattern saved to: {output_path}")
    print(f"  Size: {WIDTH}x{HEIGHT} pixels")
    print(f"  Colors: {NUM_COLORS}")
    print(f"  Palette (blue/purple/teal gradient):")
    for i, (r, g, b) in enumerate(palette_rgb):
        snes_val = (r >> 3) | ((g >> 3) << 5) | ((b >> 3) << 10)
        print(f"    {i:2d}: RGB({r:3d},{g:3d},{b:3d}) -> SNES ${snes_val:04X}")


if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    default_output = os.path.join(
        repo_root, 'projects', 'hello-snes-world',
        'assets', 'backgrounds', 'bg_earthbound.png'
    )
    output_path = sys.argv[1] if len(sys.argv) > 1 else default_output
    create_background(output_path)
