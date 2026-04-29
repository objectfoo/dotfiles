.PHONY: install install-minimal validate \
	check-wsl packages shell git editorconfig system-config \
	oh-my-posh winhome-mount ssh-copy host-wslconfig \
	help

SCRIPTS_SYSTEM := scripts/system
SCRIPTS_SECURITY := scripts/security
SCRIPTS_SHELL := scripts/shell
SHELL := bash

help:
	@printf "WSL Dotfiles Installer\n\n"
	@printf "Composite targets:\n"
	@printf "  make install           Install all dotfiles and configure WSL\n"
	@printf "  make install-minimal   Install core dotfiles only (skip packages, oh-my-posh, ssh-copy)\n"
	@printf "  make validate          Run functional validation checks\n"
	@printf "\nIndividual tasks:\n"
	@printf "  make check-wsl         Verify WSL environment\n"
	@printf "  make packages          Install apt packages and create directories\n"
	@printf "  make shell             Link shell dotfiles (.bashrc, .aliases, .exports)\n"
	@printf "  make git               Link git configuration files\n"
	@printf "  make editorconfig      Link .editorconfig to home directory\n"
	@printf "  make system-config     Link /etc/wsl.conf (privileged)\n"
	@printf "  make oh-my-posh        Install and configure oh-my-posh\n"
	@printf "  make winhome-mount     Configure /etc/fstab for Windows home mount\n"
	@printf "  make ssh-copy          Copy SSH files from Windows .ssh directory\n"
	@printf "  make host-wslconfig    Copy .wslconfig to Windows home (privileged)\n"

# Full installation: mirrors current install.sh sequence
install: check-wsl packages oh-my-posh shell git editorconfig system-config winhome-mount ssh-copy host-wslconfig
	@printf "\n[ OK ] WSL dotfiles installation complete.\n"
	@printf "\nNext steps:\n"
	@printf "1. Restart WSL to apply /etc/wsl.conf changes: wsl.exe --shutdown\n"
	@printf "2. If needed, re-apply mounts in current session: sudo mount -a\n"
	@printf "3. Verify git precedence: git config --list --show-origin\n"

# Minimal installation: core dotfiles without packages/oh-my-posh/ssh-copy
install-minimal: check-wsl packages shell git editorconfig system-config winhome-mount host-wslconfig
	@printf "\n[ OK ] WSL dotfiles minimal installation complete.\n"
	@printf "\nNext steps:\n"
	@printf "1. Restart WSL to apply /etc/wsl.conf changes: wsl.exe --shutdown\n"
	@printf "2. Verify git precedence: git config --list --show-origin\n"

# Individual task targets
check-wsl:
	@bash $(SCRIPTS_SYSTEM)/check-wsl.sh

packages:
	@bash $(SCRIPTS_SYSTEM)/packages.sh

shell:
	@bash $(SCRIPTS_SHELL)/shell.sh

git:
	@bash $(SCRIPTS_SHELL)/git.sh

editorconfig:
	@bash $(SCRIPTS_SHELL)/editorconfig.sh

system-config:
	@bash $(SCRIPTS_SYSTEM)/system-config.sh

oh-my-posh:
	@bash $(SCRIPTS_SHELL)/oh-my-posh.sh

winhome-mount:
	@bash $(SCRIPTS_SYSTEM)/winhome-mount.sh

ssh-copy:
	@bash $(SCRIPTS_SECURITY)/ssh-copy.sh

host-wslconfig:
	@bash $(SCRIPTS_SYSTEM)/host-wslconfig.sh

# Validation target
validate: check-wsl
	@bash $(SCRIPTS_SYSTEM)/validate.sh
