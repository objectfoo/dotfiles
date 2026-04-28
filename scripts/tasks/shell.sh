#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

main() {
  require_wsl

  log_info "Linking shell dotfiles..."
  deploy_file "$WSL_DIR/shell/.bashrc" "$HOME/.bashrc"
  link_file "$WSL_DIR/shell/.aliases" "$HOME/.aliases"
  link_file "$WSL_DIR/shell/.exports" "$HOME/.exports"
  log_ok "Shell dotfiles task complete."
}

main "$@"
