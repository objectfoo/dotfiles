#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib.sh
source "$DOTFILES_DIR/lib.sh"

main() {
    require_wsl

    local linux_user
    linux_user="$(whoami)"

    log_info "Writing /etc/wsl.conf (user: $linux_user)..."

    sudo tee /etc/wsl.conf > /dev/null <<EOF
# Managed by dotfiles/init-wsl.sh
[user]
default=$linux_user

[boot]
systemd=true

[interop]
appendWindowsPath=true

[automount]
options="metadata,umask=22,fmask=11"
EOF

    log_ok "/etc/wsl.conf written."

    cat <<'BANNER'

  WSL config deployed. A restart is required for changes to take effect.

  From PowerShell or CMD:
    wsl.exe --shutdown

  Then reopen WSL and run:
    ./wsl-setup.sh --profile home
    ./wsl-setup.sh --profile work

BANNER
}

main "$@"
