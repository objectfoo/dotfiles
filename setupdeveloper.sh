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

ensure_bashrc_source_line() {
    local file_path="$1"

    if [ ! -f "$HOME/.bashrc" ]; then
        touch "$HOME/.bashrc"
    fi

    if grep -qF "$file_path" "$HOME/.bashrc"; then
        log_info "~/.bashrc already sources: $file_path"
        return
    fi

    printf "\n[ -f \"%s\" ] && . \"%s\"\n" "$file_path" "$file_path" >> "$HOME/.bashrc"
    log_ok "Added source line to ~/.bashrc: $file_path"
}

setup_shell_sources() {
    local aliases_source="$WSL_DIR/shell/.aliases"
    local exports_source="$WSL_DIR/shell/.exports"

    link_file "$aliases_source" "$HOME/.aliases"
    link_file "$exports_source" "$HOME/.exports"

    ensure_bashrc_source_line "$HOME/.aliases"
    ensure_bashrc_source_line "$HOME/.exports"

    if [ -f "$HOME/.exports" ]; then
        # shellcheck source=/dev/null
        . "$HOME/.exports"
    fi

    if [ -f "$HOME/.aliases" ]; then
        # shellcheck source=/dev/null
        . "$HOME/.aliases"
    fi

    log_ok "Aliases and exports configured."
}

install_theme() {
    local source_theme="$DOTFILES_DIR/oh-my-posh/themes/high-contrast.omp.json"
    local target_theme_dir="$HOME/.config/oh-my-posh/themes"
    local target_theme="$target_theme_dir/high-contrast.omp.json"

    if [ ! -f "$source_theme" ]; then
        log_warn "Managed theme missing, skipping: $source_theme"
        return
    fi

    mkdir -p "$target_theme_dir"

    if [ -f "$target_theme" ] && cmp -s "$source_theme" "$target_theme"; then
        log_info "oh-my-posh theme already up to date: $target_theme"
        return
    fi

    cp "$source_theme" "$target_theme"
    log_ok "Installed managed oh-my-posh theme: $target_theme"
}

main() {
    log_info "Starting developer setup from: $DOTFILES_DIR"

    setup_shell_sources
    install_theme

    cat <<'EOF'

setupdeveloper.sh complete.

Next step:
  source ~/.bashrc
EOF
}

main "$@"
