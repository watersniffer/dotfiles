#!/usr/bin/env bash

status=$(playerctl status 2>/dev/null) || exit 0

case "$status" in
    Playing) icon="" ;;
    Paused)  icon="󰐊" ;;
    *)       exit 0 ;;
esac

# A title of "artist - title" would read badly doubled up.
meta=$(playerctl metadata --format '{{artist}}	{{title}}' 2>/dev/null) || exit 0
artist=${meta%%$'\t'*}
title=${meta#*$'\t'}

[[ -z $title ]] && exit 0
[[ $artist == "$title" ]] && artist=""

if [[ -n $artist ]]; then
    printf ' %s %s - %s ' "$icon" "$artist" "$title"
else
    printf ' %s %s ' "$icon" "$title"
fi
