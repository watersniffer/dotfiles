#!/usr/bin/env bash

set -uo pipefail

exec fastfetch --config "$HOME/.config/fastfetch/config.jsonc" "$@"
