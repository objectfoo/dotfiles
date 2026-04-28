.PHONY: install install-minimal validate \
	check-wsl packages shell git editorconfig system-config \
	oh-my-posh winhome-mount ssh-copy host-wslconfig \
	help

SCRIPTS_DIR := scripts/tasks
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
	@printf "  make host-wslconfig    Link .wslconfig to Windows home (privileged)\n"

# Full installation: mirrors current install.sh sequence
install: check-wsl packages oh-my-posh shell git editorconfig system-config winhome-mount ssh-copy host-wslconfig
	@printf "\n[ OK ] WSL dotfiles installation complete.\n"
	@printf "\nNext steps:\n"
	@printf "1. Restart WSL to apply /etc/wsl.conf changes: wsl.exe --shutdown\n"
	@printf "2. If needed, re-apply mounts in current session: sudo mount -a\n"
	@printf "3. Verify git precedence: git config --list --show-origin\n"

# Minimal installation: core dotfiles without packages/oh-my-posh/ssh-copy
install-minimal: check-wsl shell git editorconfig system-config winhome-mount host-wslconfig
	@printf "\n[ OK ] WSL dotfiles minimal installation complete.\n"
	@printf "\nNext steps:\n"
	@printf "1. Restart WSL to apply /etc/wsl.conf changes: wsl.exe --shutdown\n"
	@printf "2. Verify git precedence: git config --list --show-origin\n"

# Individual task targets
check-wsl:
	@bash $(SCRIPTS_DIR)/check-wsl.sh

packages:
	@bash $(SCRIPTS_DIR)/packages.sh

shell:
	@bash $(SCRIPTS_DIR)/shell.sh

git:
	@bash $(SCRIPTS_DIR)/git.sh

editorconfig:
	@bash $(SCRIPTS_DIR)/editorconfig.sh

system-config:
	@bash $(SCRIPTS_DIR)/system-config.sh

oh-my-posh:
	@bash $(SCRIPTS_DIR)/oh-my-posh.sh

winhome-mount:
	@bash $(SCRIPTS_DIR)/winhome-mount.sh

ssh-copy:
	@bash $(SCRIPTS_DIR)/ssh-copy.sh

host-wslconfig:
	@bash $(SCRIPTS_DIR)/host-wslconfig.sh

# Validation target (step 5 will expand this)
validate: check-wsl
	@printf "\n[INFO] Validation checks:\n"
	@printf "[INFO] 1. WSL environment verified.\n"
	@printf "[INFO] 2. Checking symlinks in \$$HOME...\n"
	@test -L $$HOME/.gitconfig && printf "[ OK ] .gitconfig is symlinked\n" || printf "[WARN] .gitconfig not symlinked\n"
	@test -L $$HOME/.aliases && printf "[ OK ] .aliases is symlinked\n" || printf "[WARN] .aliases not symlinked\n"
	@test -L $$HOME/.exports && printf "[ OK ] .exports is symlinked\n" || printf "[WARN] .exports not symlinked\n"
	@test -f $$HOME/.bashrc && printf "[ OK ] .bashrc exists\n" || printf "[WARN] .bashrc missing\n"
	@test -f $$HOME/.editorconfig && printf "[ OK ] .editorconfig exists\n" || printf "[WARN] .editorconfig missing\n"
	@printf "[INFO] 3. Checking /etc/wsl.conf...\n"
	@sudo test -L /etc/wsl.conf && printf "[ OK ] /etc/wsl.conf is symlinked\n" || printf "[WARN] /etc/wsl.conf not symlinked\n"
	@printf "[INFO] 4. Checking /etc/fstab for /mnt/winhome entry...\n"
	@sudo grep -c "winhome.*drvfs" /etc/fstab >/dev/null 2>&1 && printf "[ OK ] /etc/fstab contains winhome mount\n" || printf "[WARN] /etc/fstab missing winhome mount\n"
	@printf "[INFO] 5. Git precedence guidance:\n"
	@printf "     Run: git config --list --show-origin\n"
	@printf "     Verify host .gitconfig is listed last (highest precedence).\n"
	@printf "\n[ OK ] Validation checks complete.\n"
