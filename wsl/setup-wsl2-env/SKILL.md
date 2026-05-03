---
name: setup-wsl2-env
description: Guide a Windows developer through WSL2 Ubuntu 24.04 setup and configuration for front-end development.
---

# WSL2 Dev Environment Setup Agent Skill

This skill describes a reusable WSL2 Ubuntu 24.04 development environment setup workflow for front-end development on Windows.

## Purpose

Guide the user through safe, repeatable WSL2 setup and distro configuration, including:
- global WSL2 host configuration
- WSL installation or update
- Ubuntu 24.04 distro installation
- distro `wsl.conf` configuration
- package update and cleanup
- Git user configuration and SSH key setup
- verification via repo clone
- backup and restore of the distro

## Preconditions

- Running on Windows 11 with WSL support
- User has access to PowerShell and the Windows user profile directory
- User can install or update WSL components
- Distro install and SSH workflows may require interactive input

## Skill Steps

1. Configure global WSL2 settings
	- Create or update `C:\Users\<YourUsername>\.wslconfig`
	- Apply recommended values for `networkingMode`, `dnsTunneling`, `autoProxy`, and experimental features
	- Keep settings compatible with the repository's WSL-only install model

2. Install or update WSL
	- Run `wsl --version` to verify installation
	- If installed, update with `wsl --update`
	- If missing, install the store-backed package with `wsl --install --web-download`
	- Set WSL2 as the default runtime with `wsl --set-default-version 2`

3. Install Ubuntu 24.04 distro
	- Install the distro with `wsl --install Ubuntu-24.04`
	- Create the Unix username and password when prompted
	- Confirm the home directory is `/home/<username>` after setup

4. Configure the distro
	- Edit `/etc/wsl.conf` inside WSL
	- Add or update the sections:
		- `[user]` with the default user
		- `[boot]` with `systemd=true`
		- `[interop]` with `appendWindowsPath=true`
		- `[automount]` with `options="metadata,umask=22,fmask=11"`
	- Save the file and close the editor

5. Restart WSL
	- Exit the distro shell
	- From PowerShell run `wsl --shutdown`
	- Restart WSL by launching the distro again

6. Update packages
	- Inside WSL run:
		- `sudo apt update && sudo apt upgrade -y`
		- `sudo apt autoremove -y`
	- Restart WSL again after major upgrades if needed

7. Configure Git and SSH
	- Prompt the user for `git user.name` and `git user.email`
	- Set those values globally in `~/.gitconfig`
	- Generate SSH keys if none exist at `~/.ssh/id_ed25519`
	- Guide the user to add the public key to their Git hosting provider
	- Test SSH connectivity with `ssh -T git@github.com` or the relevant host

8. Verify setup
	- Clone a test repository to confirm Git and SSH are working
	- Example: `cd ~ && git clone <ssh-repo-url>`

9. Backup and restore the distro
	- Export the distro tarball from PowerShell after `wsl --shutdown`
	- Use `wsl --export Ubuntu-24.04 "C:\Backups\ubuntu-dev.tar"`
	- Import from a tarball with `wsl --import Ubuntu-24.04-dev "D:\WSL\Ubuntu-24.04-dev" "C:\Backups\ubuntu-dev.tar"`
	- Restore or set the default user inside the restored distro and restart WSL

## Example Configuration Files

Reference configuration files are available in the `examples/` directory:

- **example_wslconfig** — Full-featured `.wslconfig` with comprehensive settings for modern Windows 11 (22H2+) and resource allocation tuning
- **example_wslconfig_minimal** — Conservative `.wslconfig` for Windows 11 (21H2+) or resource-constrained systems; enables advanced features incrementally
- **example-wsl-conf** — Example `/etc/wsl.conf` for distro-level configuration with systemd, Windows interop, and filesystem mount options; place in `/etc/wsl.conf` inside the WSL distro

Agents should:
1. Select the appropriate `.wslconfig` variant based on the user's Windows version and resource constraints
2. Guide the user to customize processor/memory allocations for their machine
3. Use `example-wsl-conf` as a reference when editing `/etc/wsl.conf` inside the distro
4. Remind the user to replace `<USER_NAME>` with their actual Unix username and restart WSL after editing

## Notes

- Some `.wslconfig` features require Windows 11 22H2 or later.
- This skill is intended as a guided workflow, not a fully unattended script.
- User input is required for Git identity, SSH key management, and repo clone verification.
- Backup/restore requires administrative access to PowerShell and valid paths outside the Windows user profile if possible.

## Example prompts

- "Use the WSL2 Dev Environment Setup skill to guide me through installing Ubuntu 24.04 and configuring WSL for front-end development."
- "Walk me through updating WSL, configuring `/etc/wsl.conf`, and setting up Git with SSH keys."
- "Help me backup my Ubuntu-24.04 WSL distro and restore it to a new distro name."
