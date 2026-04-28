#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

main() {
  require_wsl

  local windows_user
  windows_user="$(resolve_windows_user || true)"
  if [ -z "$windows_user" ]; then
    log_warn "Unable to resolve Windows username; skipping .wslconfig host link."
    return
  fi

  local source="$WSL_DIR/config/.wslconfig"
  local target="/mnt/winhome/.wslconfig"

  link_file_sudo "$source" "$target"
}

main "$@"
