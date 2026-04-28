#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WSL_DIR="$DOTFILES_DIR/wsl"

source "$DOTFILES_DIR/scripts/lib/log.sh"
source "$DOTFILES_DIR/scripts/lib/link.sh"
source "$DOTFILES_DIR/scripts/lib/windows.sh"

require_wsl() {
  if ! grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; then
    log_warn "This installer is intended for WSL. Exiting."
    exit 1
  fi
}
