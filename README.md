# dotfiles

Personal dotfiles for a Windows 11 + WSL2 frontend development environment.

This repository now uses a single WSL-driven install flow.

## Structure

```
dotfiles/
  install.sh                       # single installer entrypoint (run from WSL)
  wsl/
    shell/
      .bashrc
      .aliases
      .exports
    git/
      .gitconfig
      .gitignore_global
      copilot-instructions.md
    config/
      .editorconfig
      .wslconfig                   # Windows config file for wsl
      wsl.conf
```

## Quick Start (WSL Only)

Run from inside your WSL distro:

```bash
> chmod +x install.sh
  ./install.sh
```

The installer:
- Installs required base packages via apt.
- Creates direct symlinks from repository-managed dotfiles to target locations.
- Links `wsl/config/wsl.conf` to `/etc/wsl.conf`.
- Ensures explicit Windows home mount via `/etc/fstab` (`/mnt/winhome` using `drvfs`).
- Links `wsl/config/.wslconfig` to the Windows host profile path.

## Dotfile Linking Model (No Stow)

Most managed files are linked directly with idempotent checks. Existing non-symlink targets are never overwritten automatically.

Special case:
- `~/.bashrc` is deployed as a regular file (copied from `wsl/shell/.bashrc`) to avoid prompt/theme resolution issues observed with symlinked shell startup files.

Primary user links:
- `wsl/shell/.bashrc` -> `~/.bashrc` (copied, not symlinked)
- `wsl/shell/.aliases` -> `~/.aliases`
- `wsl/shell/.exports` -> `~/.exports`
- `wsl/git/.gitconfig` -> `~/.gitconfig`
- `wsl/git/.gitignore_global` -> `~/.gitignore_global`
- `wsl/config/.editorconfig` -> `~/.editorconfig`

System/host links:
- `wsl/config/wsl.conf` -> `/etc/wsl.conf`
- `wsl/config/.wslconfig` -> `/mnt/c/Users/<windows-user>/.wslconfig`

## Git Configuration Precedence

`wsl/git/.gitconfig` includes the host Git config after local sections:

```ini
[include]
    path = /mnt/winhome/.gitconfig
```

Because the include is last, host values win when duplicated.

## WSL Mount Policy

- Automatic Windows drive mounting is disabled in `wsl/config/wsl.conf`.
- `/etc/fstab` remains enabled (`mountFsTab=true`).
- `install.sh` ensures a single explicit `/mnt/winhome` entry.

After changing WSL config:
1. Run `wsl.exe --shutdown` from Windows to restart WSL.
2. Run `sudo mount -a` in WSL to apply fstab updates in the current session.

## First-Time Git Personalization

Edit `wsl/git/.gitconfig` and set your identity:

```ini
[user]
    name = Your Name
    email = your@email
```

## Prerequisites

| Tool | Where |
|------|-------|
| WSL2 (Ubuntu) | `wsl --install` |
| curl, apt, sudo | Available in distro |

## Validation Checklist

1. Run `./install.sh` from WSL and ensure no `stow` dependency remains.
2. Verify symlinks using `ls -l` for expected files in `$HOME`.
3. Confirm `/etc/fstab` has a single `/mnt/winhome` `drvfs` entry and `sudo mount -a` succeeds.
4. Run `git config --list --show-origin` and verify host values override local duplicates.
5. Restart WSL and verify automount is disabled while `/mnt/winhome` remains available via fstab.
