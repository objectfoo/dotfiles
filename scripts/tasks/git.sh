#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

main() {
  require_wsl

  log_info "Linking git config files..."
  link_file "$WSL_DIR/git/.gitconfig" "$HOME/.gitconfig"
  link_file "$WSL_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
  log_ok "Git config task complete."
}

main "$@"
