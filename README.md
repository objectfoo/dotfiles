# Dotfiles
<a name="#dotfiles"></a>

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
  oh-my-posh/
    themes/
      high-contrast.omp.json
```


## Quick Start (WSL Only)

**Begin**: copy `~/dotfiles/wsl/config/.wslconfig` to `~/.wslconfig` in the windows host system. To configure your instance a bit.

**Install Ubuntu**, and launch
```pwsh
> wsl --install Ubuntu
```

**Run from inside your WSL distro**:

```bash
> chmod +x install.sh
  ./install.sh
```

The installer:
- Installs required base packages via apt.
- Creates direct symlinks from repository-managed dotfiles to target locations.
- Installs managed oh-my-posh theme from `oh-my-posh/themes/high-contrast.omp.json`.
- Links `wsl/config/wsl.conf` to `/etc/wsl.conf`.
- Ensures explicit Windows home mount via `/etc/fstab` (`/mnt/winhome` using `drvfs`).
- Copies SSH files from `/mnt/winhome/.ssh` to `$HOME/.ssh` with secure permissions.
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
- `wsl/config/.wslconfig` -> `/mnt/winhome/.wslconfig`

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


If you have a `.gitconfig` at the root with your name and email set those settings will override WSL `.gitconfig`.

SSH files are copied from `/mnt/winhome/.ssh` into `~/.ssh` if they do not already exist.

Otherwise `~/.gitconfig` and set your identity:

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

## Links

* [dotfiles/marcovega](https://github.com/marcovega/dotfiles)
* [dotfiles/davidgasquez](https://github.com/davidgasquez/dotfiles/blob/main/Makefile) (for the makefile)
* [top](#dotfiles)

## WSL2 Setup Agent Skill

- The canonical agent skill for WSL2 Ubuntu 24.04 setup is in [wsl/setup-wsl2-env/SKILL.md](wsl/setup-wsl2-env/SKILL.md).
- Example configuration files for `.wslconfig` and `/etc/wsl.conf` are in [wsl/setup-wsl2-env/examples/](wsl/setup-wsl2-env/examples/).
- All agent-driven setup and documentation should reference these files for consistency.

