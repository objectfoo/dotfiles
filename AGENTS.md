# Dotfiles Agent Guidelines

Personal dotfiles for a Windows 11 + WSL2 frontend development environment.
These instructions apply to all AI agent interactions in this repository.

## Scope

Use this file as the project-wide behavior source for this repository.
Keep instructions concise, actionable, and specific to this workspace.

## Repository Layout

- install.sh: installation entrypoint and setup automation.
- wsl/: WSL-managed dotfiles and configuration.
- .editorconfig: root formatting and line-ending rules for this repository.

For detailed setup and usage, see README.md.

## Architecture Model

- Single installer model: `install.sh` is the only supported setup flow.
- Direct-link model: managed files are linked directly from `wsl/` into target locations (no GNU Stow workflow).
- Explicit mount model: automatic drive mounting is disabled; C: is mounted via `/etc/fstab` at `/mnt/c`.
- Git precedence model: WSL `.gitconfig` includes host `.gitconfig` last so host values override duplicates.

## Script Conventions

- Bash scripts must use `#!/usr/bin/env bash` and strict mode: `set -euo pipefail`.
- Keep scripts idempotent; avoid destructive overwrite behavior.
- For existing non-symlink targets, prefer warnings and safe skips over forced replacement.
- Use clear user-facing progress output for long-running operations.

## Configuration Ownership

- `/etc/wsl.conf` is managed from `wsl/config/wsl.conf`.
- Host `.wslconfig` is managed from `wsl/config/.wslconfig` and linked to the Windows profile path.
- Repository changes must keep `wsl/config/wsl.conf` compatible with explicit `fstab` mounting.

## Security and Secrets

- Never commit credentials, tokens, or real personal email addresses.
- Use placeholders such as `you@users.noreply.github.com` where examples are needed.
- Prefer documented variables and templates over hardcoded machine secrets.

## Documentation Expectations

- Update README.md whenever installer behavior, mount policy, or managed file paths change.
- Keep AGENTS.md aligned with the current supported architecture.
- Remove references to deprecated workflows when migrations are complete.

## Validation

After significant changes, validate the supported flow:

1. Run `install.sh` in WSL.
2. Verify expected symlinks in `$HOME` and system link behavior for `/etc/wsl.conf`.
3. Confirm `/etc/fstab` contains a single `/mnt/c` `drvfs` entry and `mount -a` succeeds.
4. Verify Git precedence with `git config --list --show-origin`.
5. Confirm documentation references only the current WSL-only workflow.

No formal automated test suite is required; functional validation is the acceptance path.

## Operating Principle

Prioritize consistency, security, and developer experience.
Prefer established repository patterns over one-off custom behavior.
