# Contributing

Thank you for considering contributing to SNES Build Tools!

## Workflow

1.  **Fork** the repository.
2.  **Clone** your fork locally.
3.  **Create a branch** for your feature or fix (`git checkout -b feat/new-demo`).
4.  **Make changes**.
5.  **Test** by building the demo ROM (`make clean all`) and verifying in Mesen.
6.  **Commit** with clear messages.
7.  **Push** to your fork.
8.  **Open a Pull Request**.

## Code Style

### C Code

- Use `816-tcc` compatible syntax (mostly C99).
- Indentation: 4 spaces.
- Comments: Use `/* ... */` for block comments.

### Assembly

- Use `wla-65816` syntax.
- Capitals for opcodes (`LDA`, `STA`).
- Lower case for labels (`main_loop:`).

### Documentation

- Update `docs/` if you change build behavior.
- Keep `README.md` concise.

## Review Process

All PRs are reviewed for:

- **Build Integrity**: Must compile without warnings.
- **Compatibility**: Must work on both Windows and Linux logic (if modifying scripts).
