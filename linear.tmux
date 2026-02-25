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
  "#($CURRENT_DIR/scripts/linear_issue.sh full #{pane_current_path})"
  "#($CURRENT_DIR/scripts/linear_issue.sh id #{pane_current_path})"
  "#($CURRENT_DIR/scripts/linear_issue.sh title #{pane_current_path})"
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

update_tmux_status_format_options() {
  local line
  local option

  while IFS= read -r line; do
    option="${line%% *}"
    if [[ "$option" == status-format\[*\] ]]; then
      update_tmux_option "$option"
    fi
  done < <(tmux show-options -g status-format 2>/dev/null)
}

main() {
  update_tmux_option "status-right"
  update_tmux_option "status-left"
  update_tmux_status_format_options
}

main
