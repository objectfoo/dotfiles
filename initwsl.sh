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
    log_info "Updating apt cache and installing base packages..."
    sudo apt update
    sudo apt install -y --no-install-recommends \
        build-essential curl git unzip

    mkdir -p \
        "$HOME/.local/bin" \
        "$HOME/.config/oh-my-posh/themes"

    log_ok "Base packages and directories are ready."
}

normalize_windows_path_for_drvfs() {
    local candidate="$1"

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

setup_wsl_conf() {
    local source="$WSL_DIR/config/wsl.conf"
    local target="/etc/wsl.conf"

    log_info "Linking managed wsl.conf..."
    link_file_sudo "$source" "$target"
}

ensure_fstab_mount() {
    local windows_home_path="$1"

    if [ -z "$windows_home_path" ]; then
        log_warn "Windows home path not resolved; skipping fstab mount setup."
        return
    fi

    local mount_point="/mnt/winhome"
    local entry="${windows_home_path} ${mount_point} drvfs defaults,metadata,umask=22,fmask=11 0 0"

    log_info "Ensuring Windows home mount in /etc/fstab ($windows_home_path -> $mount_point)..."

    sudo touch /etc/fstab

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

link_windows_home_files() {
    local windows_home_root="/mnt/winhome"
    local windows_ssh="$windows_home_root/.ssh"
    local windows_gitconfig="$windows_home_root/.gitconfig"

    log_info "Linking Windows home SSH and Git config into Linux home..."
    link_file "$windows_ssh" "$HOME/.ssh"
    link_file "$windows_gitconfig" "$HOME/.gitconfig"
}

post_install_guidance() {
    cat <<'EOF'

initwsl.sh complete.

Next steps:
1. Restart WSL manually from Windows:
  wsl.exe --shutdown
2. Re-open Ubuntu and clone dotfiles into home:
  cd ~
  git clone <your-dotfiles-repo-url> dotfiles
3. Run the second stage:
  cd ~/dotfiles
  ./setupdeveloper.sh
EOF
}

main() {
    require_wsl

    log_info "Starting WSL initialization from: $DOTFILES_DIR"

    ensure_apt_packages
    setup_wsl_conf

    local windows_home_path
    windows_home_path="$(resolve_windows_home_path || true)"
    ensure_fstab_mount "$windows_home_path"
    link_windows_home_files

    post_install_guidance
}

main "$@"
