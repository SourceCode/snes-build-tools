# Code Coverage

## Analysis

Automated code coverage tools (like lcov) are not compatible with the 816-tcc compiler / SNES architecture. Therefore, we track **Feature Coverage** via manual inspection.

## Coverage Matrix (Demo ROM)

| Module             | Source File         | Status   | Notes                               |
| :----------------- | :------------------ | :------- | :---------------------------------- |
| **Main Loop**      | `main.c`            | **100%** | Runs continuously.                  |
| **HDMA Builder**   | `main.c`            | **100%** | Re-calculated every frame.          |
| **Palette Cycle**  | `main.c`            | **100%** | Updates every VBlank.               |
| **Text Rendering** | `main.c`            | **100%** | Static strings rendered at boot.    |
| **Font Assets**    | `font_large.png`    | **100%** | All required characters are loaded. |
| **BG Assets**      | `bg_earthbound.png` | **100%** | Full image used for background.     |

## Gap Analysis

- **Audio**: 0% Coverage. The demo does not currently implement SPC700 audio (music/sfx).
- **Input**: 0% Coverage. Controller input is not read or used.
- **SRAM**: 0% Coverage. No save functionality.

## Recommendation

For a standard game project, maintain a tracking sheet of:

1.  Game States (Intro, Menu, Gameplay).
2.  Entities (Player, Enemy A, Enemy B).
3.  Systems (Physics, Collisions, Events).
