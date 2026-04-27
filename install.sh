#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WSL_DIR="$DOTFILES_DIR/wsl"

log_info() {
    printf "[INFO] %s\n" "$1"
}

log_warn() {
    printf "[WARN] %s\n" "$1"
}

log_ok() {
    printf "[ OK ] %s\n" "$1"
}

require_wsl() {
    if ! grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; then
        log_warn "This installer is intended for WSL. Exiting."
        exit 1
    fi
}

ensure_apt_packages() {
    log_info "Installing base packages (apt)..."
    sudo apt update
    sudo apt install -y --no-install-recommends \
        build-essential curl git unzip gh zoxide fzf jq socat

    mkdir -p \
        "$HOME/projects" \
        "$HOME/.ssh" \
        "$HOME/.local/bin" \
        "$HOME/.config/oh-my-posh/themes"

    log_ok "Base packages and directories are ready."
}

resolve_windows_user() {
    local candidate

    if command -v cmd.exe >/dev/null 2>&1; then
        candidate="$(cmd.exe /c echo %USERNAME% 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
    fi

    if [ -z "${candidate:-}" ] && command -v wslvar >/dev/null 2>&1; then
        candidate="$(wslvar USERNAME 2>/dev/null | tr -d '\r' || true)"
    fi

    if [ -n "${candidate:-}" ]; then
        printf "%s" "$candidate"
    fi
}

normalize_windows_path_for_drvfs() {
    local candidate="$1"

    # drvfs accepts forward slashes in fstab source paths.
    candidate="${candidate//$'\r'/}"
    candidate="${candidate//\\//}"
    printf "%s" "$candidate"
}

resolve_windows_home_path() {
    local candidate=""

    if command -v cmd.exe >/dev/null 2>&1; then
        candidate="$(cmd.exe /c echo %USERPROFILE% 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
    fi

    if [ -n "${candidate:-}" ]; then
        normalize_windows_path_for_drvfs "$candidate"
    fi
}

link_file() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        log_warn "Source missing, skipping link: $source"
        return
    fi

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        if [ "$(readlink "$target")" = "$source" ]; then
            log_info "Link already correct: $target"
            return
        fi

        ln -sfn "$source" "$target"
        log_ok "Updated symlink: $target -> $source"
        return
    fi

    if [ -e "$target" ]; then
        log_warn "Target exists and is not a symlink, skipping: $target"
        return
    fi

    ln -s "$source" "$target"
    log_ok "Linked: $target -> $source"
}

link_file_sudo() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        log_warn "Source missing, skipping privileged link: $source"
        return
    fi

    sudo mkdir -p "$(dirname "$target")"

    if sudo test -L "$target"; then
        if [ "$(sudo readlink "$target")" = "$source" ]; then
            log_info "Privileged link already correct: $target"
            return
        fi

        sudo ln -sfn "$source" "$target"
        log_ok "Updated privileged symlink: $target -> $source"
        return
    fi

    if sudo test -e "$target"; then
        log_warn "Privileged target exists and is not a symlink, skipping: $target"
        return
    fi

    sudo ln -s "$source" "$target"
    log_ok "Linked privileged file: $target -> $source"
}

deploy_file() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        log_warn "Source missing, skipping file deploy: $source"
        return
    fi

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        rm -f "$target"
        cp "$source" "$target"
        log_ok "Replaced symlink with managed file: $target"
        return
    fi

    if [ -e "$target" ]; then
        if cmp -s "$source" "$target"; then
            log_info "Managed file already up to date: $target"
        else
            log_warn "Target exists and differs, skipping file deploy: $target"
        fi
        return
    fi

    cp "$source" "$target"
    log_ok "Deployed managed file: $target"
}

ensure_oh_my_posh() {
    log_info "Installing oh-my-posh..."

    if command -v oh-my-posh >/dev/null 2>&1; then
        log_info "oh-my-posh already installed, skipping."
    else
        mkdir -p "$HOME/.local/bin"
        curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"

        log_ok "oh-my-posh installed to ~/.local/bin."
    fi

    local omp_theme="powerlevel10k_rainbow.omp.json"
    local omp_theme_path="$HOME/.config/oh-my-posh/themes/p10k.omp.json"
    local omp_theme_url="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/${omp_theme}"

    if [ ! -f "$omp_theme_path" ]; then
        log_info "Downloading default oh-my-posh theme..."
        curl -fsSL "$omp_theme_url" -o "$omp_theme_path"
        log_ok "Default oh-my-posh theme ready: $omp_theme_path"
    else
        log_info "oh-my-posh theme already present, skipping download."
    fi
}

link_managed_files() {
    log_info "Linking managed dotfiles directly from repository..."

    deploy_file "$WSL_DIR/shell/.bashrc" "$HOME/.bashrc"
    link_file "$WSL_DIR/shell/.aliases" "$HOME/.aliases"
    link_file "$WSL_DIR/shell/.exports" "$HOME/.exports"
    link_file "$WSL_DIR/git/.gitconfig" "$HOME/.gitconfig"
    link_file "$WSL_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
    link_file "$WSL_DIR/config/.editorconfig" "$HOME/.editorconfig"

    link_file_sudo "$WSL_DIR/config/wsl.conf" "/etc/wsl.conf"

    log_ok "Managed links complete."
}

ensure_fstab_mount() {
    local windows_home_path="$1"

    if [ -z "$windows_home_path" ]; then
        log_warn "Windows home path not resolved; skipping fstab mount setup."
        return
    fi

    local mount_point="/mnt/winhome"
    local entry="${windows_home_path} ${mount_point} drvfs defaults,metadata,umask=22,fmask=11 0 0"

    log_info "Ensuring Windows user home mount in /etc/fstab ($windows_home_path -> $mount_point)..."

    sudo touch /etc/fstab

    # Idempotent: replace existing entry for this mount point if present,
    # otherwise append. Uses a temp file + mv for atomic write safety.
    if sudo grep -qF "$mount_point" /etc/fstab; then
        local tmp
        tmp="$(sudo mktemp)"
        sudo awk -v entry="$entry" -v mp="$mount_point" '
            BEGIN { written = 0 }
            $2 == mp {
                if (!written) { print entry; written = 1 }
                next
            }
            { print }
            END { if (!written) print entry }
        ' /etc/fstab | sudo tee "$tmp" >/dev/null
        sudo mv "$tmp" /etc/fstab
    else
        printf "\n%s\n" "$entry" | sudo tee -a /etc/fstab >/dev/null
    fi

    sudo mkdir -p "$mount_point"
    if sudo mount -a; then
        log_ok "fstab entry ensured and mounts refreshed."
    else
        log_warn "mount -a reported an issue; inspect /etc/fstab and permissions."
    fi
}

link_windows_wslconfig() {
    local windows_user="$1"

    if [ -z "$windows_user" ]; then
        log_warn "Unable to resolve Windows username; skipping .wslconfig host link."
        return
    fi

    local source="$WSL_DIR/config/.wslconfig"
    local target="/mnt/winhome/.wslconfig"

    link_file_sudo "$source" "$target"
}

post_install_guidance() {
    cat <<'EOF'

Installation complete.

Next steps:
1. Restart WSL to apply /etc/wsl.conf changes:
  wsl.exe --shutdown
2. If needed, re-apply mounts in the current session:
  sudo mount -a
3. Verify git configuration precedence:
  git config --list --show-origin
EOF
}

main() {
    require_wsl

    log_info "Starting WSL dotfiles installation from: $DOTFILES_DIR"

    ensure_apt_packages
    ensure_oh_my_posh
    link_managed_files

    local windows_user
    windows_user="$(resolve_windows_user || true)"
    if [ -n "$windows_user" ]; then
        log_info "Detected Windows user: $windows_user"
    fi

    local windows_home_path
    windows_home_path="$(resolve_windows_home_path || true)"
    ensure_fstab_mount "$windows_home_path"
    link_windows_wslconfig "$windows_user"

    log_info "Cleaning up apt cache..."
    sudo apt autoremove -y
    sudo apt clean
    sudo rm -rf /var/lib/apt/lists/*

    post_install_guidance
}

main "$@"
