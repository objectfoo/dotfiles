# Dotfiles
<a name="#dotfiles"></a>

Personal dotfiles for a Windows 11 + WSL2 frontend development environment.

This repository uses a two-stage WSL-driven install flow.

## Structure

```
dotfiles/
  install.sh                       # helper entrypoint for split install scripts
  initwsl.sh                       # stage 1: base WSL bootstrap
  setupdeveoper.sh                 # stage 2: developer shell/theme setup
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
> chmod +x initwsl.sh setupdeveoper.sh install.sh
  ./initwsl.sh
```

Stage 1 (`initwsl.sh`) does the bootstrap work:
- Runs `apt update` and installs `build-essential`, `curl`, `git`, `unzip`.
- Links `wsl/config/wsl.conf` to `/etc/wsl.conf`.
- Ensures explicit Windows home mount via `/etc/fstab` (`/mnt/winhome` using `drvfs`).
- Links `/mnt/winhome/.ssh` to `~/.ssh`.
- Links `/mnt/winhome/.gitconfig` to `~/.gitconfig`.

After stage 1:
1. Restart WSL manually: `wsl.exe --shutdown`
2. Start Ubuntu again.
3. Clone dotfiles into home (if needed):

```bash
cd ~
git clone <your-dotfiles-repo-url> dotfiles
```

4. Run stage 2:

```bash
cd ~/dotfiles
./setupdeveoper.sh
```

Stage 2 (`setupdeveoper.sh`) performs developer setup:
- Links `wsl/shell/.aliases` to `~/.aliases`.
- Links `wsl/shell/.exports` to `~/.exports`.
- Ensures `~/.bashrc` sources `~/.aliases` and `~/.exports`.
- Copies managed oh-my-posh theme from `oh-my-posh/themes/high-contrast.omp.json` to `~/.config/oh-my-posh/themes`.

## Dotfile Linking Model (No Stow)

Managed files are linked directly with idempotent checks. Existing non-symlink targets are never overwritten automatically.

Stage 1 (`initwsl.sh`) creates system/host links:
- `wsl/config/wsl.conf` -> `/etc/wsl.conf`
- `/mnt/winhome/.ssh` -> `~/.ssh`
- `/mnt/winhome/.gitconfig` -> `~/.gitconfig`

Stage 2 (`setupdeveoper.sh`) creates shell links:
- `wsl/shell/.aliases` -> `~/.aliases`
- `wsl/shell/.exports` -> `~/.exports`

## Git Configuration Source

`initwsl.sh` links your Linux home Git config directly to `/mnt/winhome/.gitconfig`.

## WSL Mount Policy

- Automatic Windows drive mounting is disabled in `wsl/config/wsl.conf`.
- `/etc/fstab` remains enabled (`mountFsTab=true`).
- `initwsl.sh` ensures a single explicit `/mnt/winhome` entry.

After changing WSL config:
1. Run `wsl.exe --shutdown` from Windows to restart WSL.
2. Run `sudo mount -a` in WSL to apply fstab updates in the current session.

## First-Time Git Personalization


Ensure your Windows-side `/mnt/winhome/.gitconfig` has your identity.

`initwsl.sh` links:
- `~/.gitconfig` -> `/mnt/winhome/.gitconfig`
- `~/.ssh` -> `/mnt/winhome/.ssh`

If needed, set identity in your host `.gitconfig`:

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

1. Run `./initwsl.sh` from WSL.
2. Confirm `/etc/fstab` has a single `/mnt/winhome` `drvfs` entry and `sudo mount -a` succeeds.
3. Verify `~/.ssh` and `~/.gitconfig` link to `/mnt/winhome`.
4. Restart WSL and verify automount is disabled while `/mnt/winhome` remains available via fstab.
5. Run `./setupdeveoper.sh` and verify `~/.bashrc` sources `~/.aliases` and `~/.exports`.

## Links

* [dotfiles/marcovega](https://github.com/marcovega/dotfiles)
* [dotfiles/davidgasquez](https://github.com/davidgasquez/dotfiles/blob/main/Makefile) (for the makefile)
* [top](#dotfiles)

