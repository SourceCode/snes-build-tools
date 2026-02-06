# Documentation Hub

Welcome to the **SNES Build Tools** documentation. This guide is organized to help you go from zero to a running SNES ROM as quickly as possible, while providing deep dives into the architecture for advanced users.

## Getting Started

- [**Installation**](install.md): Complete setup guide for your OS.
- [**Setup & Configuration**](setup.md): Environment variables (`PVSNESLIB_HOME`) and path configuration.
- [**First Run**](first-run.md): Walkthrough of building and running the `hello-snes-world` demo.

## Core Concepts

- [**Functionality Overview**](functionality.md): What this toolchain actually does.
- [**Architecture & Implementation**](implementation.md): Deep dive into the build pipeline (`Makefile`, `816-tcc`, `wlalink`).
- [**SNES Hardware Schema**](schema.md): Memory maps, VRAM layout, and Mode 1 details.

## Development

- [**API Reference**](api.md): Common PVSnesLib functions and C standard library availability.
- [**Integrations**](integrations.md): setting up VS Code, emulators, and debugging tools.
- [**Troubleshooting**](troubleshooting.md): Solutions for common build errors (`file not found`, `bank overflow`).

## Quality & Process

- [**Testing Strategy**](testing.md): Verification methods and emulator fidelity.
- [**Security**](security.md): Toolchain binary safety and checksums.
- [**Contributing**](contributing.md): How to submit PRs and report bugs.
- [**Changelog**](changelog.md): History of changes.

---

## FAQ

**Q: C or Assembly?**
A: This toolchain focuses on **C development** using PVSnesLib, but allows inline Assembly and pure ASM modules (like `hdr.asm`).

**Q: Which emulator should I use?**
A: **Mesen** (S) or **bsnes** for accuracy. **snes9x** for general playability.

**Q: Can I make a commercial game?**
A: Yes, provided you respect the MIT license of this toolchain and the licenses of PVSnesLib.
