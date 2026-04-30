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

ensure_bashrc_oh_my_posh_block() {
    local theme_path="$HOME/.config/oh-my-posh/themes/high-contrast.omp.json"
    local block_start="# >>> dotfiles oh-my-posh >>>"
    local block_end="# <<< dotfiles oh-my-posh <<<"
    local bashrc_tmp

    if [ ! -f "$HOME/.bashrc" ]; then
        touch "$HOME/.bashrc"
    fi

    if grep -qF "$block_start" "$HOME/.bashrc"; then
        bashrc_tmp=$(mktemp)
        awk -v start="$block_start" -v end="$block_end" '
            $0 == start { in_block = 1; next }
            $0 == end { in_block = 0; next }
            !in_block { print }
        ' "$HOME/.bashrc" > "$bashrc_tmp"
        mv "$bashrc_tmp" "$HOME/.bashrc"
        log_info "Updated managed oh-my-posh init in ~/.bashrc"
    fi

    cat >> "$HOME/.bashrc" <<EOF

$block_start
if command -v oh-my-posh >/dev/null 2>&1; then
    if [ -f "$theme_path" ]; then
        export POSH_THEME="$theme_path"
    else
        unset POSH_THEME
    fi

    eval "\$(oh-my-posh init bash)"
fi
$block_end
EOF

    log_ok "Added managed oh-my-posh init to ~/.bashrc"
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

install_omz_posh() {
    if command -v oh-my-posh >/dev/null 2>&1; then
        log_info "oh-my-posh already installed"
        return
    fi

    log_info "Installing oh-my-posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
    
    if command -v oh-my-posh >/dev/null 2>&1; then
        log_ok "oh-my-posh installed successfully"
    else
        log_warn "oh-my-posh installation may have failed, continuing anyway"
    fi
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
    install_omz_posh
    install_theme
    ensure_bashrc_oh_my_posh_block

    cat <<'EOF'

setupdeveloper.sh complete.

Next steps:
  source ~/.bashrc
  # If no prompt appears, try: exec bash
EOF
}

main "$@"
