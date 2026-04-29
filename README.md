# Dotfiles

Personal dotfiles for a Windows 11 + WSL2 frontend development environment.

This repository now uses a **make-first** installer with modular task orchestration.

## Structure

```
dotfiles/
├── install.sh                     # Compatibility wrapper (calls make install)
├── Makefile                       # Primary orchestration entrypoint
├── .editorconfig                  # Root editor config (LF/CRLF rules)
│
├── wsl/                           # Managed dotfiles (linked/deployed to $HOME)
│   ├── config/
│   │   ├── wsl.conf              # WSL system config → /etc/wsl.conf
│   │   ├── .wslconfig            # Windows WSL config → /mnt/winhome/.wslconfig
│   │   └── .editorconfig         # Editor config → ~/.editorconfig
│   ├── git/
│   │   ├── .gitconfig            # Git config → ~/.gitconfig
│   │   ├── .gitignore_global     # Global ignores → ~/.gitignore_global
│   │   └── copilot-instructions.md
│   └── shell/
│       ├── .bashrc               # Shell config (deployed, not symlinked)
│       ├── .aliases              # Shell aliases → ~/.aliases
│       ├── .exports              # Shell exports → ~/.exports
│
├── oh-my-posh/                    # Theme files
│   └── themes/
│       └── high-contrast.omp.json # Managed theme
│
├── scripts/                       # Installation scripts (organized by concern)
│   ├── lib/                       # Shared libraries
│   │   ├── common.sh             # Bootstrap + exports (DOTFILES_DIR, WSL_DIR)
│   │   ├── log.sh                # Logging functions
│   │   ├── link.sh               # File linking/deploy operations
│   │   └── windows.sh            # Windows path resolution utilities
│   ├── system/                    # System configuration tasks
│   │   ├── check-wsl.sh          # Verify WSL environment
│   │   ├── host-wslconfig.ps1    # Install host %USERPROFILE%\.wslconfig from repo
│   │   ├── packages.sh           # Install apt packages
│   │   ├── system-config.sh      # Link /etc/wsl.conf
│   │   ├── host-wslconfig.sh     # Link /mnt/winhome/.wslconfig
│   │   ├── winhome-mount.sh      # Configure /etc/fstab
│   │   └── validate.sh           # Validation checks
│   ├── shell/                     # Shell configuration tasks
│   │   ├── shell.sh              # Link shell dotfiles
│   │   ├── git.sh                # Link git config
│   │   ├── editorconfig.sh       # Link .editorconfig
│   │   └── oh-my-posh.sh         # Install oh-my-posh
│   ├── security/                  # Security-related tasks
│   │   └── ssh-copy.sh           # Copy SSH files from Windows
│   └── development/               # Reserved for future dev tools
│       └── (Node.js, PHP, etc. setup scripts)
│
├── support/                       # Non-installation support files
│   ├── templates/                # Configuration templates
│   │   └── (Reserved for future templates with placeholders)
│   ├── examples/                 # Example configurations
│   │   └── (Reserved for example files)
│   ├── data/                     # Application data
│   │   └── (Reserved for VSCode extensions lists, etc.)
│   └── utils/                    # Utility scripts
│       └── (Reserved for helper tools)
│
└── profiles/                      # Installation profiles
    ├── minimal.conf              # Core tools only
    ├── development.conf          # Full dev environment
    └── (full.conf, wordpress.conf, server.conf reserved for future)
```

## Quick Start

### Prerequisites

**On Windows**: Run the PowerShell helper to install the managed `.wslconfig` into your Windows profile before first run.

```powershell
pwsh -NoProfile -File .\install-windows.ps1
```

Alternate root alias:

```powershell
pwsh -NoProfile -File .\install-powershell.ps1
```

Useful options:

```powershell
# Preview actions only (no changes)
pwsh -NoProfile -File .\install-windows.ps1 -WhatIf

# Replace existing target when it differs
pwsh -NoProfile -File .\install-windows.ps1 -Force
```

```pwsh
> wsl --install Ubuntu
```

### From WSL

Run from inside your WSL distro:

```bash
cd dotfiles
make install
```

Or for core dotfiles only:

```bash
make install-minimal
```

For selective installation by task:

```bash
make shell         # Link shell dotfiles only
make git           # Link git config only
make validate      # Run validation checks
```

For all available targets:

```bash
make help
```

## Installation Targets

### Composite Targets

- **make install** — Full installation (mirrors current install.sh behavior)
- **make install-minimal** — Core dotfiles only (skip packages, oh-my-posh, ssh-copy)
- **make validate** — Run functional validation checks

### Individual Task Targets

- **make check-wsl** — Verify WSL environment
- **make packages** — Install apt packages and directories
- **make shell** — Link shell dotfiles (.bashrc, .aliases, .exports)
- **make git** — Link git configuration
- **make editorconfig** — Link .editorconfig
- **make system-config** — Link /etc/wsl.conf (privileged)
- **make oh-my-posh** — Install and configure oh-my-posh
- **make winhome-mount** — Configure /etc/fstab for Windows home mount
- **make ssh-copy** — Copy SSH files from Windows
- **make host-wslconfig** — Link .wslconfig to Windows home (privileged)

## Dotfile Linking Model (No Stow)

Most managed files are symlinked directly with idempotent checks. Existing non-symlink targets are never overwritten automatically; scripts log warnings and skip.

### Special Cases

- **~/.bashrc** is deployed as a regular file (copied, not symlinked) to avoid shell startup issues.

### Primary User Links

| Source | Target | Type |
| --- | --- | --- |
| `wsl/shell/.bashrc` | `~/.bashrc` | Copied |
| `wsl/shell/.aliases` | `~/.aliases` | Symlinked |
| `wsl/shell/.exports` | `~/.exports` | Symlinked |
| `wsl/git/.gitconfig` | `~/.gitconfig` | Symlinked |
| `wsl/git/.gitignore_global` | `~/.gitignore_global` | Symlinked |
| `wsl/config/.editorconfig` | `~/.editorconfig` | Symlinked |

### System Links (Privileged)

| Source | Target | Type |
| --- | --- | --- |
| `wsl/config/wsl.conf` | `/etc/wsl.conf` | Symlinked |
| `wsl/config/.wslconfig` | `/mnt/winhome/.wslconfig` | Symlinked |

## Git Configuration Precedence

`wsl/git/.gitconfig` includes the Windows host `.gitconfig` after local sections:

```ini
[include]
    path = /mnt/winhome/.gitconfig
```

Because the include is last, host values take precedence when duplicated.

## WSL Mount Policy

- Automatic Windows drive mounting is disabled in `wsl/config/wsl.conf`.
- `/etc/fstab` mounting remains enabled (`mountFsTab=true`).
- The installer ensures a single explicit `/mnt/winhome` entry in fstab.

After changing WSL config:

```bash
# Restart WSL from Windows
wsl.exe --shutdown

# Or apply fstab changes in current session
sudo mount -a
```

## Validation

Run validation checks to verify installation state:

```bash
make validate
```

Checks include:
1. WSL environment verification
2. Managed symlinks and files in $HOME
3. System configuration (/etc/wsl.conf)
4. /etc/fstab mount entry (exactly one /mnt/winhome)
5. Mount state (mount -a succeeds)
6. Git precedence guidance

## Backward Compatibility

`install.sh` is now a thin compatibility wrapper that calls `make install`. It shows a deprecation notice directing users to use `make` directly. The wrapper is retained for one transition cycle; removal is planned for a future cleanup.

## Future Expansion

The modular structure supports future additions:

- **Development tools**: Node.js setup, PHP/Laravel, Neovim, WordPress WSL
- **Security setup**: GPG key generation, advanced SSH configuration
- **Application data**: VSCode extensions lists, templates with placeholders
- **Profiles**: WordPress, server, full environment configs

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
* [makefile tut](https://makefiletutorial.com/)
* [top](#dotfiles)

