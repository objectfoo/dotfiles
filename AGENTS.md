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

- **Make-first installer**: `make install` is the primary entrypoint; `install.sh` is a compatibility wrapper.
- **Modular scripts**: Installation organized by concern (system, shell, security, development) with independent executable tasks.
- **Direct-link model**: Managed files are linked directly from `wsl/` into target locations (no GNU Stow workflow).
- **Explicit mount model**: Automatic drive mounting is disabled; Windows home is mounted via `/etc/fstab` at `/mnt/winhome`.
- **Git precedence model**: WSL `.gitconfig` includes host `.gitconfig` last so host values override duplicates.

## Script Conventions

- Bash scripts must use `#!/usr/bin/env bash` and strict mode: `set -euo pipefail`.
- Keep scripts idempotent; avoid destructive overwrite behavior.
- For existing non-symlink targets, prefer warnings and safe skips over forced replacement.
- Use clear user-facing progress output for long-running operations.

### Modular Organization

Scripts are organized by concern (no monolithic installer):

| Directory | Purpose | Examples |
| --- | --- | --- |
| `scripts/lib/` | Shared libraries sourced by all tasks | `log.sh`, `link.sh`, `windows.sh`, `common.sh` |
| `scripts/system/` | System configuration tasks | `check-wsl.sh`, `packages.sh`, `system-config.sh`, `validate.sh` |
| `scripts/shell/` | Shell and development config | `shell.sh`, `git.sh`, `oh-my-posh.sh`, `editorconfig.sh` |
| `scripts/security/` | Security-related setup | `ssh-copy.sh` (future: GPG, advanced SSH) |
| `scripts/development/` | Development tool setup | (Reserved: Node.js, PHP, Neovim, etc.) |

Each task script:
- Is independently executable and idempotent.
- Sources `scripts/lib/common.sh` to access shared functions and constants.
- Can be run directly via `bash scripts/[category]/[task].sh` or via `make [task-name]`.

### Bootstrap Pattern

All task scripts follow this bootstrap pattern:

```bash
#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

main() {
  require_wsl
  # Task logic here
}

main "$@"
```

This pattern ensures:
- Strict mode is enforced.
- Shared libraries are loaded relative to script location.
- DOTFILES_DIR and WSL_DIR are available.
- WSL environment is verified before any operations.

## Configuration Ownership

- `/etc/wsl.conf` is managed from `wsl/config/wsl.conf`.
- Host `.wslconfig` is managed from `wsl/config/.wslconfig` and copied to the Windows profile path.
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

1. Run `make install` in WSL and confirm successful end-to-end setup.
2. Run `make validate` and confirm all functional checks pass.
3. Verify expected symlinks in `$HOME` for all managed dotfiles.
4. Verify `/etc/fstab` contains exactly one `/mnt/winhome` drvfs entry and `mount -a` succeeds.
5. Confirm Git precedence with `git config --list --show-origin` (host .gitconfig listed last).
6. Run `make install` again to verify idempotency and absence of destructive overwrites.

Individual task isolation:
- `make shell` — Verify only shell dotfiles are linked.
- `make git` — Verify only git config is linked.
- `make validate` — Non-destructive checks only; does not modify system state.

## Operating Principle

Prioritize consistency, security, and developer experience.
Prefer established repository patterns over one-off custom behavior.
