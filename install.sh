#!/usr/bin/env bash
set -euo pipefail

# Compatibility wrapper for make-first refactor.
# The modular installer has been migrated to Makefile orchestration.
# See README.md and 'make help' for current usage.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf "\n[DEPRECATION NOTICE]\n"
printf "install.sh is now a compatibility wrapper.\n"
printf "Please use 'make install' instead:\n\n"
printf "  cd %s\n" "$DOTFILES_DIR"
printf "  make install\n\n"
printf "For more options, run: make help\n\n"

cd "$DOTFILES_DIR"
make install "$@"
