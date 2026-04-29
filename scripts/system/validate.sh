#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

main() {
  require_wsl

  local pass=0
  local warn=0

  log_info "=== WSL Dotfiles Validation ==="
  printf "\n"

  # 1. WSL environment check
  log_info "1. WSL environment"
  log_ok "WSL environment verified."
  pass=$((pass + 1))
  printf "\n"

  # 2. Managed symlinks and files in $HOME
  log_info "2. Managed files and symlinks in \$HOME"
  local symlink_checks=(
    ".gitconfig"
    ".gitignore_global"
    ".aliases"
    ".exports"
  )
  local file_checks=(
    ".bashrc"
    ".editorconfig"
  )

  for item in "${symlink_checks[@]}"; do
    if [ -L "$HOME/$item" ]; then
      log_ok "  ✓ $item is symlinked"
      pass=$((pass + 1))
    else
      log_warn "  ✗ $item is not symlinked"
      warn=$((warn + 1))
    fi
  done

  for item in "${file_checks[@]}"; do
    if [ -f "$HOME/$item" ]; then
      log_ok "  ✓ $item exists"
      pass=$((pass + 1))
    else
      log_warn "  ✗ $item is missing"
      warn=$((warn + 1))
    fi
  done
  printf "\n"

  # 3. System configuration
  log_info "3. System configuration"
  if sudo test -L /etc/wsl.conf; then
    log_ok "  ✓ /etc/wsl.conf is symlinked"
    pass=$((pass + 1))
  else
    log_warn "  ✗ /etc/wsl.conf is not symlinked"
    warn=$((warn + 1))
  fi
  printf "\n"

  # 4. fstab mount entry (critical: exactly one /mnt/winhome entry)
  log_info "4. /etc/fstab mount configuration"
  local winhome_count
  winhome_count="$(sudo grep -c "winhome" /etc/fstab 2>/dev/null || true)"

  if [ "$winhome_count" -eq 1 ]; then
    log_ok "  ✓ Exactly one /mnt/winhome entry in /etc/fstab"
    pass=$((pass + 1))
  elif [ "$winhome_count" -eq 0 ]; then
    log_warn "  ✗ No /mnt/winhome entry in /etc/fstab"
    warn=$((warn + 1))
  else
    log_warn "  ✗ Multiple /mnt/winhome entries in /etc/fstab (found: $winhome_count)"
    warn=$((warn + 1))
  fi

  if is_mount_active /mnt/winhome; then
    log_ok "  ✓ /mnt/winhome mount is active"
    pass=$((pass + 1))
  else
    log_warn "  ✗ /mnt/winhome mount is not active"
    warn=$((warn + 1))
  fi
  printf "\n"

  # 5. Mount state verification
  log_info "5. Mount state (non-destructive check)"
  if sudo mount -a 2>/dev/null; then
    log_ok "  ✓ mount -a succeeded"
    pass=$((pass + 1))
  else
    log_warn "  ✗ mount -a reported an issue; inspect /etc/fstab"
    warn=$((warn + 1))
  fi
  printf "\n"

  # 6. Git precedence verification guidance
  log_info "6. Git configuration precedence"
  log_warn "  (Manual verification required)"
  printf "  Run: git config --list --show-origin\n"
  printf "  Verify that host .gitconfig (if present) is listed last\n"
  printf "  for highest precedence in config resolution.\n"
  printf "\n"

  # Summary
  printf "\n"
  log_info "=== Validation Summary ==="
  printf "  Passed: %d | Warnings: %d\n" "$pass" "$warn"

  if [ "$warn" -eq 0 ]; then
    log_ok "All validation checks passed!"
    exit 0
  else
    log_warn "Some checks reported warnings; review above."
    exit 0
  fi
}

main "$@"
