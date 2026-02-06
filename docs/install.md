# Installation Guide

This guide details how to set up the **SNES Build Tools** environment on Windows, Linux, and macOS.

## 1. Prerequisites

Before running the installer, ensure you have the following tools:

### Windows

- **Git**: [Download Git for Windows](https://git-scm.com/download/win) (Git Bash recommended)
- **Python**: [Download Python 3.12+](https://www.python.org/downloads/) (Check "Add Python to PATH" during install)
- **Make**: Not included in Windows by default.
  - _Option A (Recommended)_: Use **Chocolatey**: `choco install make`
  - _Option B_: Use **Scoop**: `scoop install make`
  - _Option C_: Install **MSYS2** and run `pacman -S make`.

### Linux (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install git make python3 python3-pip curl unzip build-essential
```

### macOS

1.  **Xcode Command Line Tools**:
    ```bash
    xcode-select --install
    ```
2.  **Homebrew** (Optional but recommended):
    ```bash
    brew install python3
    ```

---

## 2. Automated Installation

The repository includes scripts to fetch and configure the **PVSnesLib** toolchain automatically.

### Windows

1.  Open Command Prompt or PowerShell.
2.  Navigate to the cloned repository.
3.  Run the installer:
    ```cmd
    install.bat
    ```

**What it does:**

- Checks for Git, Make, Python, and Curl.
- Downloads the PVSnesLib Windows binaries.
- Extracts them to `tools/pvsneslib`.
- Verifies that `816-tcc.exe`, `wla-65816.exe`, and `wlalink.exe` are present.
- Installs Python `Pillow` library (required for font tools).
- Generates `env.bat` for environment configuration.

### Linux / macOS

1.  Open a terminal.
2.  Navigate to the cloned repository.
3.  Make the script executable (if needed) and run it:
    ```bash
    chmod +x install.sh
    ./install.sh
    ```

**What it does:**

- Checks for Git, Make, Python3, and Curl/Wget.
- Downloads the appropriate PVSnesLib release for your OS (Linux/Darwin).
- Extracts them to `tools/pvsneslib`.
- Sets executable permissions on binaries.
- Installs `Pillow` via pip.
- Generates `env.sh` for environment configuration.

---

## 3. Verification

After installation, verify that the tools are correctly placed:

**Check Directory Structure:**

```text
snes-build-tools/
├── tools/
│   ├── pvsneslib/
│   │   ├── devkitsnes/
│   │   │   ├── bin/       <-- Compilers (816-tcc, wla-65816)
│   │   │   ├── tools/     <-- Converters (gfx4snes)
│   │   │   └── snes_rules <-- Makefile include
```

If these files are missing, delete the `tools/pvsneslib` directory and re-run the install script.

---

## 4. Next Steps

Proceed to [Setup & Configuration](setup.md) to initialize your environment variables.
