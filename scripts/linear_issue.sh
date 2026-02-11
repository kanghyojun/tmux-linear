#!/usr/bin/env bash
#
# git branch에서 Linear 이슈 ID를 추출하고 API로 제목을 가져온다.
# 인자: "full" (ID: 제목) | "id" (ID만) | "title" (제목만)
#
set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

# --- 설정 ---
API_KEY="$(get_tmux_option "@linear_api_key" "${LINEAR_API_KEY:-}")"
CACHE_TTL="$(get_tmux_option "@linear_cache_ttl" "300")"
MAX_TITLE_LEN="$(get_tmux_option "@linear_max_title_len" "40")"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-linear"

MODE="${1:-full}"

# --- API 키 확인 ---
if [[ -z "$API_KEY" ]]; then
  exit 0
fi

# --- tmux 현재 pane의 디렉토리에서 git branch 가져오기 ---
pane_path="$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)" || exit 0
branch="$(git -C "$pane_path" rev-parse --abbrev-ref HEAD 2>/dev/null)" || exit 0

# --- branch 이름에서 Linear 이슈 ID 추출 (대소문자 모두 허용) ---
if [[ "$branch" =~ ([A-Za-z]+-[0-9]+) ]]; then
  issue_id="${BASH_REMATCH[1]^^}"
else
  exit 0
fi

# --- ID만 필요한 경우 API 호출 불필요 ---
if [[ "$MODE" == "id" ]]; then
  echo -n "$issue_id"
  exit 0
fi

# --- 캐시 확인 ---
mkdir -p "$CACHE_DIR"
cache_file="$CACHE_DIR/$issue_id"

if [[ -f "$cache_file" ]]; then
  cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null) ))
  if (( cache_age < CACHE_TTL )); then
    title="$(cat "$cache_file")"
    case "$MODE" in
      title) echo -n "$title" ;;
      *)     echo -n "$issue_id: $title" ;;
    esac
    exit 0
  fi
fi

# --- Linear API 호출 ---
team_key="${issue_id%%-*}"
issue_num="${issue_id##*-}"

response=$(curl -s --max-time 5 -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: $API_KEY" \
  -d "{\"query\": \"{ issueSearch(filter: { number: { eq: $issue_num }, team: { key: { eq: \\\"$team_key\\\" } } }, first: 1) { nodes { identifier title } } }\"}" \
  "https://api.linear.app/graphql" 2>/dev/null) || exit 0

title=$(echo "$response" | jq -r '.data.issueSearch.nodes[0].title // empty' 2>/dev/null) || exit 0

if [[ -z "$title" ]]; then
  exit 0
fi

# --- 캐시 저장 (원본 제목) ---
echo -n "$title" > "$cache_file"

# --- 제목 자르기 ---
if (( ${#title} > MAX_TITLE_LEN )); then
  title="${title:0:$MAX_TITLE_LEN}…"
fi

case "$MODE" in
  title) echo -n "$title" ;;
  *)     echo -n "$issue_id: $title" ;;
esac
