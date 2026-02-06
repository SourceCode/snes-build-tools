# SNES Hardware Schema

This document outlines the hardware specifications and memory layout of the Super Nintendo Entertainment System (SNES) as relevant to this toolchain.

## 1. System Specifications

| Component | Specification            | Notes                                           |
| :-------- | :----------------------- | :---------------------------------------------- |
| **CPU**   | Ricoh 5A22 (65c816 core) | Run at 3.58 MHz (FastROM) or 2.68 MHz (SlowROM) |
| **RAM**   | 128KB WRAM               | Work RAM for variables and stack                |
| **VRAM**  | 64KB                     | Video RAM (Tiles, Maps)                         |
| **CGRAM** | 512 Bytes                | Color RAM (256 colors x 16 bits)                |
| **OAM**   | 544 Bytes                | Object Attribute Memory (Sprites)               |

## 2. Memory Map (LoROM)

This project uses the **LoROM** mapping, which is the standard for smaller homebrew games (up to 32Mbit).

| Bank      | Address Range | Description                             |
| :-------- | :------------ | :-------------------------------------- |
| `$00-$3F` | `$8000-$FFFF` | **Program ROM** (Mirrored)              |
| `$00-$3F` | `$0000-$1FFF` | **Low RAM** (Mirrored WRAM)             |
| `$00-$3F` | `$2000-$5FFF` | **Hardware Registers** (PPU, DMA, etc.) |
| `$7E`     | `$0000-$FFFF` | **WRAM** (Low 64KB)                     |
| `$7F`     | `$0000-$FFFF` | **WRAM** (High 64KB)                    |

## 3. VRAM Layout (Mode 1)

In SNES development, YOU define the VRAM layout. PVSnesLib allows dynamic allocation, but this project uses a fixed layout for stability.

| Address | Size | Usage                               |
| :------ | :--- | :---------------------------------- |
| `$0000` | 16KB | **BG1 Tiles** (Background Patterns) |
| `$4000` | 16KB | **BG2 Tiles** (Font Patterns)       |
| `$6000` | 2KB  | **BG1 Map** (32x32 Tilemap)         |
| `$6800` | 2KB  | **BG2 Map** (32x32 Tilemap)         |

> **Note**: These addresses are Word addresses (16-bit). In bytes, multiply by 2.

## 4. Hardware Registers

Key memory-mapped registers used in the C code:

- **`$2100` (INIDISP)**: Screen brightness and Force Blank.
- **`$2105` (BGMODE)**: Video mode settings (Mode 0-7).
- **`$210D` (BG1HOFS)**: BG1 Horizontal Scroll (Write twice).
- **`$210E` (BG1VOFS)**: BG1 Vertical Scroll (Write twice).
- **`$4200` (NMITIMEN)**: Interrupt enable (VBlank NMI).
- **`$43x0` (DMAPx)**: DMA/HDMA Control.
