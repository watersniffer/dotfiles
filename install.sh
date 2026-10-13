#!/usr/bin/env bash
# Dotfiles installer.
#
#   git clone https://github.com/watersniffer/dotfiles.git ~/dotfiles
#   cd ~/dotfiles
#   ./install.sh --link      # symlink configs only (fast, no packages)
#   ./install.sh --packages  # install all system + AUR packages
#   ./install.sh --list      # show the package list
#   ./install.sh             # packages + symlink

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=packages.sh
source "$REPO_DIR/packages.sh"

# Wayland session check — these configs are Hyprland-only.
if [[ -n ${WAYLAND_DISPLAY:-} ]]; then :; fi

main() {
  case "${1:-all}" in
    --list)     print_list ;;
    --packages) install_all ;;
    --link)     link_configs "$REPO_DIR" ;;
    all)        install_all; link_configs "$REPO_DIR" ;;
    *)          echo "Usage: $0 [--packages|--link|--list|all]"; exit 1 ;;
  esac
}

main "$@"
