#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

main() {
  require_wsl

  local windows_ssh_dir="/mnt/winhome/.ssh"
  local target_ssh_dir="$HOME/.ssh"

  if [ ! -d "$windows_ssh_dir" ]; then
    log_warn "Windows .ssh directory not found, skipping SSH copy: $windows_ssh_dir"
    return
  fi

  mkdir -p "$target_ssh_dir"
  chmod 700 "$target_ssh_dir"

  local copied=0
  local skipped=0

  shopt -s nullglob dotglob
  for source_path in "$windows_ssh_dir"/*; do
    [ -f "$source_path" ] || continue

    local file_name
    local target_path
    file_name="$(basename "$source_path")"
    target_path="$target_ssh_dir/$file_name"

    if [ -e "$target_path" ]; then
      log_info "SSH file exists, skipping: $target_path"
      skipped=$((skipped + 1))
      continue
    fi

    cp -p "$source_path" "$target_path"

    case "$file_name" in
      *.pub|known_hosts|config)
        chmod 644 "$target_path"
        ;;
      *)
        chmod 600 "$target_path"
        ;;
    esac

    copied=$((copied + 1))
    log_ok "Copied SSH file: $target_path"
  done
  shopt -u nullglob dotglob

  log_info "SSH copy summary: copied=$copied skipped=$skipped"
}

main "$@"
