#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/scripts/helpers.sh"

# 플레이스홀더 → #(스크립트) 치환 매핑
linear_interpolation=(
  "\#{linear_issue}"
  "\#{linear_id}"
  "\#{linear_title}"
)

linear_commands=(
  "#($CURRENT_DIR/scripts/linear_issue.sh full)"
  "#($CURRENT_DIR/scripts/linear_issue.sh id)"
  "#($CURRENT_DIR/scripts/linear_issue.sh title)"
)

do_interpolation() {
  local result="$1"
  for ((i = 0; i < ${#linear_interpolation[@]}; i++)); do
    result="${result//${linear_interpolation[$i]}/${linear_commands[$i]}}"
  done
  echo "$result"
}

update_tmux_option() {
  local option="$1"
  local value
  value="$(get_tmux_option "$option")"
  local new_value
  new_value="$(do_interpolation "$value")"
  tmux set-option -gq "$option" "$new_value"
}

main() {
  update_tmux_option "status-right"
  update_tmux_option "status-left"
}

main
