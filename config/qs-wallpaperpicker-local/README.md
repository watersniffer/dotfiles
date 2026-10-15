# qs-wallpaperpicker (local notes)

Installed from <https://github.com/dhrruvsharma/qs-wallpaperpicker> (GPL-3.0) into
`~/.config/qs-wallpaperpicker`, with its CLI at `~/.local/bin/qs-wallpaperpicker`.

The upstream project is a git checkout, so it is **not** vendored here - reinstall
with:

```sh
git clone --depth 1 https://github.com/dhrruvsharma/qs-wallpaperpicker \
     ~/.config/qs-wallpaperpicker
install -Dm755 ~/.config/qs-wallpaperpicker/bin/qs-wallpaperpicker \
     ~/.local/bin/qs-wallpaperpicker
```

## Local changes

**`services/Wallhaven.qml`** — see `Wallhaven.qml.patched` for the exact content.
Wallhaven withholds results from a bare `topRange` (top list) query unless an API
key is supplied: HTTP 200, a valid `meta` block, and an empty `data` array. This
project defaults `wallhavenSorting` to `toplist` and only sends a seed when the
sort is `random` and `page > 1`, so a fresh keyless install opens the Wallhaven tab
to nothing. A seed is generated when there is neither a query nor a seed, which
makes the API return results anonymously. Entering a free key in the picker's own
settings is the better fix and makes this unnecessary.

**`settings.json`** — `wallpaperDir` changed from the default
`~/Pictures/wallpapers` to `~/Pictures/Wallpapers`, which is what this machine
actually has. The capital W matters.

## Notes

It draws the wallpaper itself in Quickshell (from
`~/.cache/current_wallpaper_source`), so awww and swaybg are no longer started -
having all three running meant three wallpaper layers stacked.
