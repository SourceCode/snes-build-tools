# Security Policy

## Use of Binaries

This toolchain orchestrates the use of third-party binaries:

1.  **PVSnesLib** (Compiler/Assembler): Downloaded from GitHub Releases.
2.  **Make**: System installed.
3.  **Python**: System installed.

## Risk Assessment

- **External Downloads**: The install script fetches files from `https://github.com/alekmaul/pvsneslib/releases`. We rely on GitHub's HTTPS security.
- **No Credentials**: This project is a local development toolchain. It does not handle passwords, API keys, or user data.
- **No User Roles**: There are no "admin" or "user" accounts. The user has full control over their local file system.

## Safe Usage

1.  **Review Scripts**: Always review `install.bat` and `install.sh` before running them.
2.  **VS Code Trust**: Only open this repository in VS Code if you trust the source, as `tasks.json` can execute arbitrary commands.

## Reporting Vulnerabilities

If you discover a security issue with the toolchain scripts (e.g., they can be tricked into downloading malware), please open a **GitHub Issue** immediately.
