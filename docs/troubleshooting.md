# Troubleshooting

## Common Build Errors

### `make: command not found`

- **Cause**: Make is not installed or not in `%PATH%`.
- **Fix**: See [Installation](install.md).

### `816-tcc: command not found`

- **Cause**: The PVSnesLib binaries are not in your path.
- **Fix**: Run `call env.bat` (Windows) or `source env.sh` (Unix).

### `fatal error: snes.h: No such file or directory`

- **Cause**: `PVSNESLIB_HOME` environment variable is unset or incorrect.
- **Fix**: Run the environment script again. Ensure it points to `snes-build-tools/tools/pvsneslib`.

### `file not found` during `gfx4snes`

- **Cause**: Python is missing or `Pillow` is not installed.
- **Fix**: `pip install Pillow`.

### `Bank overflow`

- **Cause**: Your code/data is too large for the ROM bank.
- **Fix**: Move data to `data.asm` or optimize C code. SNES banks are 32KB (LoROM) or 64KB (HiROM).

## Runtime / Emulator Issues

### Black Screen

- **Cause 1**: Interrupts disabled (`CLI` executed but NMI not enabled).
- **Cause 2**: VRAM not initialized.
- **Cause 3**: `WaitForVBlank()` not called in loop.
- **Fix**: Check `main.c` initialization sequence.

### Garbled Graphics

- **Cause**: Wrong Video Mode (Mode 1 vs Mode 7) or wrong Bit Depth (4bpp vs 8bpp).
- **Fix**: Check `gfx4snes` command flags in `Makefile`.
  - `-p`: Output palette.
  - `-m`: Output map.
  - `-s 8`: 8x8 tiles.

## Getting Help

Open a GitHub Issue with:

1.  Your OS version.
2.  Output of `make`.
3.  Emulator used.
