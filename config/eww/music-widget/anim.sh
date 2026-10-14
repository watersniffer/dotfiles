#!/usr/bin/env bash

# Drives the music widget's entrance animation.
#
# Emits a whole CSS fragment for eww's :style attribute, so one variable drives
# every animated property:
#
#     (defpoll anim_style :initial "…" :interval "60ms" "…/anim.sh")
#     (box … :style "${anim_style}")
#
# eww expands ${var} but NOT {var} - a bare {var} stays literal, which is how an
# earlier attempt left the widget stuck at opacity 0 and invisible.
#
# WHY ONLY THESE PROPERTIES
# ------------------------
# GTK3's CSS supports `transition` but has no @keyframes and no transform, and
# it only reliably interpolates RENDERING properties. Both of these were tested
# on this machine and rejected:
#
#   margin-top   - it DOES move the widget (verified: -100px clipped the title
#                  and artist off the top), but the transition snaps instantly
#                  instead of animating, because margins are a LAYOUT property.
#   window :y    - eww refuses it outright: "Unknown variable anim_y".
#
# So the movement options are gone, and what remains is opacity plus colour -
# both pure rendering properties that GTK3 genuinely interpolates. The result is
# a soft materialise rather than a literal slide.
#
# This must emit the hidden state at least once so GTK has a real starting value
# to transition FROM. The marker lives in XDG_RUNTIME_DIR so it cannot go stale
# across a re-login (a stale marker would make the widget appear instantly).

set -uo pipefail

marker="${XDG_RUNTIME_DIR:-/tmp}/eww-music-anim-started"

# Resting state: fully opaque panel, matching the static CSS.
readonly SHOWN='opacity: 1; background-color: rgba(0, 0, 0, 0.92); border-color: rgba(255, 255, 255, 0.08);'
# Start state: invisible, and the panel/edge colour still near-absent.
readonly HIDDEN='opacity: 0; background-color: rgba(0, 0, 0, 0); border-color: rgba(255, 255, 255, 0);'

if [ -f "$marker" ]; then
    printf '%s' "$SHOWN"
    exit 0
fi

# Brief pause so GTK realises the widget before the values change, otherwise
# there is no "from" state and it simply appears.
sleep 0.04
: > "$marker" 2>/dev/null || true
printf '%s' "$HIDDEN"
