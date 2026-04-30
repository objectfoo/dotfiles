# Dotfiles Agent Guidelines

Personal dotfiles for a Windows 11 + WSL2 frontend development environment.
These instructions apply to all AI agent interactions in this repository.

## Scope

Use this file as the project-wide behavior source for this repository.
Keep instructions concise, actionable, and specific to this workspace.

## Repository Layout

- initwsl.sh: stage 1 WSL bootstrap and host integration setup.
- setupdeveloper.sh: stage 2 developer shell and theme setup.
- install.sh: compatibility wrapper for stage scripts.
- wsl/: WSL-managed dotfiles and configuration.
- .editorconfig: root formatting and line-ending rules for this repository.

For detailed setup and usage, see README.md.

## Architecture Model

- Two-stage installer model: `initwsl.sh` bootstraps WSL system setup and `setupdeveloper.sh` completes developer dotfile setup.
- Direct-link model: managed files are linked directly from `wsl/` into target locations (no GNU Stow workflow).
- Explicit mount model: automatic drive mounting is disabled; Windows home is mounted via `/etc/fstab` at `/mnt/winhome`.
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

1. Run `initwsl.sh` in WSL.
2. Verify system link behavior for `/etc/wsl.conf`.
3. Confirm `/etc/fstab` contains a single `/mnt/winhome` `drvfs` entry and `mount -a` succeeds.
4. Verify `~/.ssh` and `~/.gitconfig` link to `/mnt/winhome`.
5. Restart WSL, then run `setupdeveloper.sh` and verify shell/theme setup behavior.

No formal automated test suite is required; functional validation is the acceptance path.

## Operating Principle

Prioritize consistency, security, and developer experience.
Prefer established repository patterns over one-off custom behavior.
