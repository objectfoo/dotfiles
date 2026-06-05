#!/usr/bin/env bash
set -euo pipefail

WSL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$WSL_DIR")"

# shellcheck source=lib.sh
source "$WSL_DIR/lib.sh"

resolve_profile() {
    local profile=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile)
                profile="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ -z "$profile" ]; then
        read -rp "Profile [home/work]: " profile
    fi

    case "$profile" in
        home|work) ;;
        *)
            printf "[ERROR] Unknown profile '%s'. Must be 'home' or 'work'.\n" "$profile" >&2
            exit 1
            ;;
    esac

    printf "%s" "$profile"
}

ensure_apt_packages() {
    log_info "Installing base packages (apt)..."
    sudo apt update
    sudo apt install -y --no-install-recommends \
        build-essential curl git unzip

    mkdir -p \
        "$HOME/.ssh" \
        "$HOME/.local/bin" \
        "$HOME/.config/oh-my-posh/themes"

    log_ok "Base packages and directories are ready."
}

ensure_oh_my_posh() {
    log_info "Installing oh-my-posh..."

    curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
    log_ok "oh-my-posh installed to ~/.local/bin."

    local source_theme="$DOTFILES_DIR/oh-my-posh/winner.omp.json"
    local target_theme="$HOME/.config/oh-my-posh/themes/winner.omp.json"

    if [ ! -f "$source_theme" ]; then
        log_warn "Managed theme missing, skipping: $source_theme"
        return
    fi

    if [ -f "$target_theme" ] && cmp -s "$source_theme" "$target_theme"; then
        log_info "oh-my-posh theme already up to date: $target_theme"
        return
    fi

    mkdir -p "$(dirname "$target_theme")"
    cp "$source_theme" "$target_theme"
    log_ok "Installed managed oh-my-posh theme: $target_theme"
}

link_managed_files() {
    local profile="$1"

    log_info "Linking managed dotfiles (profile: $profile)..."

    deploy_file "$WSL_DIR/shell/.bashrc"           "$HOME/.bashrc"
    deploy_file "$WSL_DIR/git/$profile/.gitconfig"  "$HOME/.gitconfig"

    link_file "$WSL_DIR/shell/.aliases"            "$HOME/.aliases"
    link_file "$WSL_DIR/shell/.exports"            "$HOME/.exports"
    link_file "$WSL_DIR/git/.gitignore_global"     "$HOME/.gitignore_global"
    link_file "$WSL_DIR/config/.editorconfig"      "$HOME/.editorconfig"

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


post_install_guidance() {
    cat <<'EOF'

Setup complete.

--- Create SSH keys for Git ---

  ssh-keygen -t ed25519 -C "your@email.com"
  cat ~/.ssh/id_ed25519.pub

Add the printed key at:
  https://github.com/settings/ssh/new

Then verify the connection:
  ssh -T git@github.com

--- Other next steps ---

  Verify git identity:
    git config --list --show-origin

  Reload shell config:
    source ~/.bashrc

EOF
}

main() {
    require_wsl

    local profile
    profile="$(resolve_profile "$@")"

    log_info "Starting WSL setup (profile: $profile) from: $DOTFILES_DIR"

    ensure_apt_packages
    ensure_oh_my_posh
    link_managed_files "$profile"

    local windows_home_path
    windows_home_path="$(resolve_windows_home_path || true)"
    ensure_fstab_mount "$windows_home_path"


    log_info "Cleaning up apt cache..."
    sudo apt autoremove -y
    sudo apt clean
    sudo rm -rf /var/lib/apt/lists/*

    post_install_guidance
}

main "$@"
