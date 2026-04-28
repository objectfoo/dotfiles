#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

ensure_fstab_mount() {
  local windows_home_path="$1"

  if [ -z "$windows_home_path" ]; then
    log_warn "Windows home path not resolved; skipping fstab mount setup."
    return
  fi

  local mount_point="/mnt/winhome"
  local entry="${windows_home_path} ${mount_point} drvfs defaults,metadata,umask=22,fmask=11 0 0"

  log_info "Ensuring Windows user home mount in /etc/fstab ($windows_home_path -> $mount_point)..."

  sudo touch /etc/fstab

  if sudo grep -qF "$mount_point" /etc/fstab; then
    local tmp
    tmp="$(sudo mktemp)"
    sudo awk -v entry="$entry" -v mp="$mount_point" '
      BEGIN { written = 0 }
      $2 == mp {
        if (!written) { print entry; written = 1 }
        next
      }
      { print }
      END { if (!written) print entry }
    ' /etc/fstab | sudo tee "$tmp" >/dev/null
    sudo mv "$tmp" /etc/fstab
  else
    printf "\n%s\n" "$entry" | sudo tee -a /etc/fstab >/dev/null
  fi

  sudo mkdir -p "$mount_point"
  if sudo mount -a; then
    log_ok "fstab entry ensured and mounts refreshed."
  else
    log_warn "mount -a reported an issue; inspect /etc/fstab and permissions."
  fi
}

main() {
  require_wsl
  ensure_fstab_mount "$(resolve_windows_home_path || true)"
}

main "$@"
