#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

main() {
  require_wsl

  log_info "Linking system config..."
  link_file_sudo "$WSL_DIR/config/wsl.conf" "/etc/wsl.conf"
  log_ok "System config task complete."
}

main "$@"
