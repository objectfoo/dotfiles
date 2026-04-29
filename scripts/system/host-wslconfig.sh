#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

main() {
  require_wsl

  local mount_point
  mount_point="$(winhome_mount_point)"

  if ! is_mount_active "$mount_point"; then
    log_warn "Windows home mount is not active at $mount_point; skipping .wslconfig host deploy."
    return
  fi

  local source="$WSL_DIR/config/.wslconfig"
  local target="$mount_point/.wslconfig"

  deploy_file_sudo "$source" "$target"
}

main "$@"
