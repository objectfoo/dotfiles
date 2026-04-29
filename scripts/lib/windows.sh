#!/usr/bin/env bash
set -euo pipefail

resolve_windows_user() {
  local candidate=""

  if command -v cmd.exe >/dev/null 2>&1; then
    candidate="$(cmd.exe /c echo %USERNAME% 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
  fi

  if [ -z "$candidate" ] && command -v wslvar >/dev/null 2>&1; then
    candidate="$(wslvar USERNAME 2>/dev/null | tr -d '\r' || true)"
  fi

  if [ -n "$candidate" ]; then
    printf "%s" "$candidate"
  fi
}

normalize_windows_path_for_drvfs() {
  local candidate="$1"

  candidate="${candidate//$'\r'/}"
  candidate="${candidate//\\//}"
  printf "%s" "$candidate"
}

resolve_windows_home_path() {
  local candidate=""

  if command -v cmd.exe >/dev/null 2>&1; then
    candidate="$(cmd.exe /c echo %USERPROFILE% 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
  fi

  if [ -n "$candidate" ]; then
    normalize_windows_path_for_drvfs "$candidate"
  fi
}

winhome_mount_point() {
  printf "%s" "/mnt/winhome"
}

is_mount_active() {
  local mount_point="$1"

  if command -v mountpoint >/dev/null 2>&1; then
    mountpoint -q "$mount_point"
    return
  fi

  grep -qs " $mount_point " /proc/mounts
}
