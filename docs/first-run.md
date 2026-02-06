# First Run Guide

Let's build the **Hello SNES World** demo to confirm everything is working.

## 1. Activate Environment

**Windows:**

```cmd
cd snes-build-tools
call env.bat
```

**Unix:**

```bash
cd snes-build-tools
source env.sh
```

## 2. Navigate to Project

```bash
cd projects/hello-snes-world
```

## 3. Build

Run the standard Make command:

```bash
make
```

**Expected Output:**

```text
convert font ... font_large.png
convert background ... bg_earthbound.png
...
wdc 65816 Assembler v9.10 ...
...
OK  : data.obj
OK  : main.obj
Linking ...
...
OK  : hello_snes_world.sfc
```

## 4. Troubleshooting Build Failures

- **`make: command not found`**: You didn't install Make. See [Installation](install.md).
- **`816-tcc: command not found`**: You didn't run `env.bat` / `source env.sh`.
- **`fatal error: snes.h: No such file`**: `PVSNESLIB_HOME` is not set or points to the wrong place.
- **`ModuleNotFoundError: No module named 'PIL'`**: You didn't install Python or Pillow. Run `pip install Pillow`.

## 5. Run the ROM

You should now see `hello_snes_world.sfc` in the project directory.

1.  Open your SNES Emulator (Mesen, snes9x, etc.).
2.  Drag and drop the `.sfc` file into the emulator window.
3.  **Success**: You see "HELLO SNES WORLD" floating over a wavy Earthbound-style background.

## 6. How to Reset

To clean build artifacts and start fresh:

```bash
make clean
```

This removes `.obj`, `.sfc`, and all converted `.pic/.pal` asset files.
