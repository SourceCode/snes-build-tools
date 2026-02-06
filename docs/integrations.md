# Integrations & Tools

Developing for SNES requires a suite of specialized tools.

## Emulators

Precise emulation is critical for development. We recommend the following:

| Emulator               | Accuracy    | Debugger  | Usage                                                                            |
| :--------------------- | :---------- | :-------- | :------------------------------------------------------------------------------- |
| **Mesen** (or Mesen-S) | High        | Excellent | **Primary Recommendation**. Great break-points, VRAM viewers, and event logging. |
| **bsnes** (higan)      | Cycle-Exact | Good      | Gold standard for accuracy verification. If it runs here, it runs on hardware.   |
| **snes9x**             | Medium      | Good      | Generic testing. Good for "will it play on most emulators?"                      |

## VS Code Integration

This repository includes a `.vscode` folder pre-configured for C development.

### IntelliSense

`c_cpp_properties.json` is set to include:

- `${env:PVSNESLIB_HOME}/pvsneslib/include`
- `${env:PVSNESLIB_HOME}/devkitsnes/include`

This ensures that functions like `WaitForVBlank()` and types like `u16` are recognized by the editor.

### Build Tasks

You can define a build task in `.vscode/tasks.json` to run `make` directly from the editor:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build SNES ROM",
      "type": "shell",
      "command": "make",
      "options": {
        "cwd": "${workspaceFolder}/projects/hello-snes-world"
      },
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "problemMatcher": ["$gcc"]
    }
  ]
}
```

## Graphics Tools

The toolchain uses **gfx4snes** (CLI) automatically, but for asset creation, you need:

- **Aseprite** / **Photoshop** / **GIMP**: To create indexed PNGs.
- **Constraints**:
  - Image must be indexed color (4bpp = 16 colors, 8bpp = 256 colors).
  - Dimensions must be multiples of 8.
