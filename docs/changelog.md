# Changelog

All notable changes to the **SNES Build Tools** project will be documented in this file.

## [Unreleased]

### Added

- **Documentation**: Complete overhaul of project documentation (`docs/`).
- **Installation**: New `install.bat` and `install.sh` for automated setup.
- **Demo**: `hello-snes-world` project with Earthbound-style background effects.
- **Pipeline**: `Makefile` support for automatic asset conversion.

### Changed

- Moved PVSnesLib installation to strictly local `tools/` directory.

### Fixed

- Resolved path issues with `pvsneslib` on Windows by adding `env.bat` path translation.
