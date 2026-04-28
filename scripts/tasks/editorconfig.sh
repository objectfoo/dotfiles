#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

main() {
  require_wsl

  log_info "Linking editorconfig..."
  link_file "$WSL_DIR/config/.editorconfig" "$HOME/.editorconfig"
  log_ok "EditorConfig task complete."
}

main "$@"
