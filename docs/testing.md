# Testing Strategy

In retro-console development, "Unit Testing" is often replaced by "Emulator Verification" due to the visual and hardware-dependent nature of the code.

## 1. Unit Testing

**Status**: Not Implemented.

- **Reason**: Writing C unit tests for 816-tcc that mock SNES hardware registers (`$2100`) is complex and rarely done for small homebrew projects.
- **Future**: Could implement minimal logic tests (math, physics) using native GCC builds if game logic is separated from hardware logic.

## 2. Integration / Build Verification

**Status**: Automated via Make.

- **Command**: `make clean all`
- **Verification**: Ensures that the entire pipeline (Asset Conversion -> Compilation -> Assembly -> Link) works without error.
- **Failure Conditions**:
  - Missing assets.
  - Bank overflow (code too large for ROM bank).
  - Syntax errors.

## 3. Manual Verification (Acceptance Testing)

Verified manually using **Mesen** or **bsnes**.

| Feature       | Test Case      | Success Criteria                                                        |
| :------------ | :------------- | :---------------------------------------------------------------------- |
| **Boot**      | Open ROM       | Shows black screen, then fades in or cuts to graphics. No crash/freeze. |
| **Graphics**  | Observe BG1    | Wavy distortion effect is smooth. No "glitch" tiles.                    |
| **Text**      | Observe BG2    | "HELLO SNES WORLD" is centered, legible, white with black border.       |
| **Animation** | Wait 30s       | Distortion pattern changes (Preset 1 -> Preset 2).                      |
| **Palette**   | Observe Colors | Colors cycle smoothly (Earthbound effect).                              |

## 4. Hardware Testing

The gold standard is running on real hardware via a flash cart (e.g., FXPAK Pro).

- **Requirement**: A CRT TV or high-quality upscaler (Retrotink).
- **Procedure**: Copy `.sfc` to SD card, boot on console.
- **Pass**: Identical behavior to bsnes.
