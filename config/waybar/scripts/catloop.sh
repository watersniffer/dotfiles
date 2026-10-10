#!/usr/bin/env bash
set -euo pipefail

SLEEP_AFTER=4

AWAKE_FRAMES=(A B C D E)
SLEEP_FRAMES=(G H I J K L M N)

COUNT=0

sample() {
    local mode="${1-}"
    awk -v mode="$mode" -v prev_active="$prev_active" -v prev_total="$prev_total" '
        /^cpu /{
            active = $2 + $3 + $4
            total   = active + $5
            if (mode == "init") {
                printf "0 0.22\n"
                exit
            }
            da = active - prev_active
            dt = total - prev_total
            if (dt <= 0 || da < 0) {
                util = 0
            } else {
                util = da / dt
            }
            # Faster frames as the machine gets busier, floor of 0.05s.
            speed = 0.22 - (util * 0.10)
            if (speed < 0.05) {
                speed = 0.05
            }
            printf "%d %.4f\n", (util < 0.02 ? 1 : 0), speed
            exit
        }
    ' /proc/stat
}

SLEEP_FIFO=$(mktemp -u "${XDG_RUNTIME_DIR:-/tmp}/catloop.XXXXXX")
mkfifo "$SLEEP_FIFO"
trap 'rm -f "$SLEEP_FIFO"' EXIT
exec 9<>"$SLEEP_FIFO"

# The baseline, so the first real sample has something to difference against.
prev_active=0
prev_total=0
read -r _ _ < <(sample init)

while true; do
    read -r now_idle speed < <(sample)

    if [ "$now_idle" = "1" ]; then
        COUNT=$((COUNT + 1))
    else
        COUNT=0
    fi

    if [ "$COUNT" -ge "$SLEEP_AFTER" ]; then
        frames=("${SLEEP_FRAMES[@]}")
    else
        frames=("${AWAKE_FRAMES[@]}")
    fi

    for frame in "${frames[@]}"; do
        echo "$frame"
        read -t "$speed" -u 9 _ || true
    done
done
