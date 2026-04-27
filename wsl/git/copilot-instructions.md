---
description: Use when working in this dotfiles repository to enforce formatting and style conventions.
name: copilot instructions
---

## Formatting Rules

- Line endings:
	- Windows-side files should use `CRLF`.
	- WSL/Linux/*nix files should use `LF`.

- If a root `.editorconfig` file is present, follow it as the source of truth for:
	- `end_of_line`
	- `indent_style`
	- `indent_size`
	- related file-specific overrides

- When these rules conflict, prefer `.editorconfig` values for the target file.
