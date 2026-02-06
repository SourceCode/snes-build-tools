# Setup & Configuration

Once installed, you must configure your shell environment to point to the SDK.

## Environment Variables

The build system relies on one critical environment variable: `PVSNESLIB_HOME`.

| Variable         | Description                                                                                                                                                                                          |
| :--------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PVSNESLIB_HOME` | The absolute path to the `tools/pvsneslib` directory. On Windows, this must be converted to a Unix-style path (e.g., `/c/code/snes/...`) for the Makefiles to work correctly with `pvsneslib` rules. |

## Activating the Environment

The install script generates a helper file in the root of the repo. You must run this **every time you open a new terminal** to work on the project.

### Windows (Command Prompt)

```cmd
call env.bat
```

- Sets `PVSNESLIB_HOME`.
- Adds `tools\pvsneslib\devkitsnes\bin` to your `%PATH%`.

### Linux / macOS / Git Bash

```bash
source env.sh
```

- Sets `PVSNESLIB_HOME`.
- Adds binaries to your `$PATH`.

> **Note**: If you use VS Code, you can configure a task to run this automatically, or add it to your profile, but we recommend manual activation to avoid polluting your global path.

## Local Configuration

### VS Code

This repository is pre-configured for VS Code if you open the root folder.

- **.vscode/c_cpp_properties.json**: configured to find PVSnesLib headers for IntelliSense.
- **.vscode/tasks.json**: (Optional) can be added to run `make`.

### Customizing Paths

If you move the repository, you must re-run `install.bat` / `install.sh` or manually update `env.bat` / `env.sh` to point to the new location. The scripts use absolute paths.
