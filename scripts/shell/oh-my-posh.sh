#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

main() {
  require_wsl

  log_info "Installing oh-my-posh..."
  if command -v oh-my-posh >/dev/null 2>&1; then
    log_info "oh-my-posh already installed, skipping."
  else
    mkdir -p "$HOME/.local/bin"
    curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
    log_ok "oh-my-posh installed to ~/.local/bin."
  fi

  local source_theme="$DOTFILES_DIR/oh-my-posh/themes/high-contrast.omp.json"
  local target_theme="$HOME/.config/oh-my-posh/themes/high-contrast.omp.json"

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

main "$@"
