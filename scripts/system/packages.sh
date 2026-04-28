#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

main() {
  require_wsl

  log_info "Installing base packages (apt)..."
  sudo apt update
  sudo apt install -y --no-install-recommends \
    build-essential curl git unzip gh zoxide fzf jq socat

  mkdir -p \
    "$HOME/projects" \
    "$HOME/.ssh" \
    "$HOME/.local/bin" \
    "$HOME/.config/oh-my-posh/themes"

  log_ok "Base packages and directories are ready."
}

main "$@"
