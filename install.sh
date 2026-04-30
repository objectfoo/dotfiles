#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

main() {
    case "${1:-}" in
        init)
            exec bash "$DOTFILES_DIR/initwsl.sh"
            ;;
        setup)
            exec bash "$DOTFILES_DIR/setupdeveloper.sh"
            ;;
        *)
            cat <<'EOF'
This installer is split into two scripts:

1) bootstrap WSL base setup:
   ./initwsl.sh

2) after restarting WSL and cloning dotfiles to ~/dotfiles:
   ./setupdeveloper.sh

Optional shortcuts:
  ./install.sh init
  ./install.sh setup
EOF
            ;;
    esac
}

main "$@"
