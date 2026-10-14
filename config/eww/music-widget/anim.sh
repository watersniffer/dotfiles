#!/usr/bin/env bash

# Drives the music widget's fade-in.
#
# The eww side is:
#     (defpoll anim_opacity :initial "0" :interval "120ms" "…/anim.sh")
#     (box … :style "opacity: {anim_opacity}")
#
# GTK3 can only transition between two values it has actually seen, so this has
# to emit "0" at least once before it emits "1". It does that with a per-window
# marker file:
#
#   * first call after the widget opens  -> sleeps, then prints 0
#   * every call after that             -> prints 1 immediately
#
# The sleep happens BEFORE printing 0 so that :initial "0" and this 0 agree; the
# widget then flips to 1 on the following poll ~120ms later, and the CSS
# `transition: opacity 200ms` interpolates it.
#
# The marker lives in XDG_RUNTIME_DIR so it disappears on logout and cannot go
# stale across a re-login (a stale marker would make the widget appear instantly
# with no animation).

set -uo pipefail

marker="${XDG_RUNTIME_DIR:-/tmp}/eww-music-anim-started"

if [ -f "$marker" ]; then
    printf '1\n'
    exit 0
fi

# Short delay so GTK has realised the widget at opacity 0 first.
sleep 0.06
: > "$marker" 2>/dev/null || true
printf '0\n'
