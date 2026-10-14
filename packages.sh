# System packages required by this dotfile setup.
# Split into: distro packages (pacman) and AUR packages (yay/paru).
#
#   ./install.sh --packages   # install only the packages
#   ./install.sh               # packages + symlink the configs

# --- Base system ---
base=(
  base-devel git curl wget
  python python-pip jq
)

# --- Hyprland session ---
hyprland=(
  hyprland
  xorg-xwayland
  waybar
  mako
  eww-wayland
  hyprlock
  hypridle
  hyprpicker
  dunst
  wofi
  rofi
  grim slurp
  swappy
  ffmpeg
  # Hardware video decode for the HD 520's QuickSync. Without this, mpv/ffplay
  # silently fall back to SOFTWARE decoding and burn a full core on video.
  # Measured: 130% CPU -> 22% CPU for a 1080p clip.
  intel-media-driver
  libva-utils
)

# --- Shell / tools ---
tools=(
  zsh fish starship
  kitty alacritty
  thunar
  git-delta
  btop fastfetch
  cava
  playerctl
  pamixer
  wpctl
  brightnessctl
  wl-clipboard
  cliphist
  matugen
  matuwall
  awww
  swww
  hypr3d-git
  mpv
  cava
)

# --- Fonts ---
fonts=(
  ttf-iosevka-nerd
  ttf-jetbrains-mono-nerd
  noto-fonts
  noto-fonts-emoji
)

# --- GTK / Qt theming ---
gui=(
  gtk3
  gtk4
  libadwaita
  qt5ct
  qt6ct
  qt5-wayland
  qt6-wayland
  adwaita-icon-theme
  papirus-icon-theme
  bibata-modern-ice
)

# --- Login / session ---
session=(
  hyprlock
  hypridle
  wlogout
  greetd-tuigreet
)

# --- AUR ---
aur=(
  eww-git
  matuwall-git
  awww-git
  hypr3d-git
  hyprlock-git
)

install_pacman() {
  echo "==> Installing pacman packages"
  sudo pacman -S --needed --noconfirm "${base[@]}" "${hyprland[@]}" "${tools[@]}" \
    "${fonts[@]}" "${gui[@]}" "${session[@]}"
}

install_aur() {
  local helper
  if command -v paru >/dev/null 2>&1; then helper=paru
  elif command -v yay >/dev/null 2>&1; then helper=yay
  else echo "!! No AUR helper (paru/yay) found — skipping AUR packages"; return; fi
  echo "==> Installing AUR packages via $helper"
  "$helper" -S --needed --noconfirm "${aur[@]}"
}

install_all() {
  install_pacman
  install_aur
}

# Print the package list without installing (for review).
print_list() {
  echo "pacman:"
  printf '  %s\n' "${base[@]}" "${hyprland[@]}" "${tools[@]}" "${fonts[@]}" "${gui[@]}" "${session[@]}"
  echo "AUR:"
  printf '  %s\n' "${aur[@]}"
}

# Symlink the tracked configs into place.
link_configs() {
  local repo="${1:-$HOME/dotfiles}"
  echo "==> Linking configs from $repo"

  for d in waybar eww rofi hyprlock gtk-3.0 gtk-4.0 nvim qt6ct fastfetch systemd btop hypr; do
    [ -d "$repo/config/$d" ] || continue
    mkdir -p "$HOME/.config"
    ln -sfn "$repo/config/$d" "$HOME/.config/$d"
    echo "    ~/.config/$d"
  done

  ln -sfn "$repo/local/bin" "$HOME/.local/bin"
  echo "    ~/.local/bin"

  for f in .zshrc .vimrc .tmux.conf .inputrc .gtkrc-2.0 .gitconfig; do
    [ -f "$repo/$f" ] || continue
    ln -sfn "$repo/$f" "$HOME/$f"
    echo "    ~/$f"
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${1:-all}" in
    --packages) install_all ;;
    --link)     link_configs "${2:-$HOME/dotfiles}" ;;
    --list)     print_list ;;
    all)        install_all; link_configs ;;
    *)          echo "Usage: $0 [--packages|--link|--list|all]"; exit 1 ;;
  esac
fi
