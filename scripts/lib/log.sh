#!/usr/bin/env bash
set -euo pipefail

log_info() {
  printf "[INFO] %s\n" "$1"
}

log_warn() {
  printf "[WARN] %s\n" "$1"
}

log_ok() {
  printf "[ OK ] %s\n" "$1"
}

log_error() {
  printf "[ERR ] %s\n" "$1" >&2
}
