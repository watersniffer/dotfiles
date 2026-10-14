# quickshell-music-player2

Media player widget for the waybar `mpris` module, replacing the old eww music
widget.

- `MediaPlayer.qml` is vendored verbatim from
  <https://github.com/GTGalaxi/qsMediaPlayer> (MIT). Re-fetch it with:
  ```sh
  curl -fsSL https://raw.githubusercontent.com/GTGalaxi/qsMediaPlayer/main/MediaPlayer.qml \
       -o config/quickshell-music-player2/MediaPlayer.qml
  ```
- `shell.qml` is ours. It wraps the component in a `PanelWindow` and adds the
  three things the raw component doesn't do: centring, open/close animation,
  and a file-watched visibility toggle.

## Toggling

Started once at login by `config/hypr/hyprland.lua` and left running.
`~/.local/bin/music-widget-toggle` flips a one-byte file in `$XDG_RUNTIME_DIR`,
which `shell.qml` polls — opening the widget is instant (~25 ms).

Do **not** switch this back to start/stop-the-process: Quickshell needs ~15 s to
bring this widget up, so the widget appeared slowly and with no animation.
