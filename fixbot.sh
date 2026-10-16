#!/bin/zsh
# fixbot — local Sentry → fix → PR pipeline driven by Claude Code.
#
#   ./fixbot.sh poll            check Sentry for new issues and run the pipeline (launchd calls this)
#   ./fixbot.sh run <issue-id>  run the pipeline for one Sentry issue now
#   ./fixbot.sh review <issue-id>  open the issue's session interactively to review and approve the PR
#   ./fixbot.sh status          list runs and their status
#   ./fixbot.sh sync            clone or update every repo listed in repos.yaml into repos/
set -euo pipefail

FB="${0:A:h}"
cd "$FB"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

source ./config.sh
: "${MAX_TURNS:=80}" "${MAX_ISSUES_PER_POLL:=2}" "${POLL_MODEL:=haiku}"
: "${SENTRY_QUERY:=is:unresolved is:unassigned environment:production}"

mkdir -p state runs repos worktrees
touch state/seen.txt

notify() { osascript -e "display notification \"${2//\"/}\" with title \"${1//\"/}\"" 2>/dev/null || true; }

# Print "name|repo|branch" for each entry in repos.yaml (format documented there).
list_repos() {
  awk '
    function val(s) { sub(/^[^:]*:[[:space:]]*/, "", s); sub(/[[:space:]]+#.*$/, "", s); gsub(/["\047]/, "", s); return s }
    function flush() { if (name != "") print name "|" repo "|" branch; name = repo = branch = "" }
    /^[[:space:]]*-[[:space:]]+name:/ { flush(); name = val($0); next }
    /^[[:space:]]+repo:/              { repo = val($0); next }
    /^[[:space:]]+branch:/            { branch = val($0); next }
    END { flush() }
  ' repos.yaml
}

# Clone missing repos and fast-forward existing ones. Returns non-zero if any repo failed.
sync_repos() {
  local name repo branch url failed=0 listed=0 count=0
  while IFS='|' read -r name repo branch; do
    (( listed++ )) || true
    if [[ -z "$repo" ]]; then echo "fixbot: '$name' has no repo: line" >&2; failed=1; continue; fi
    url="$repo"; [[ "$repo" == *://* || "$repo" == git@* ]] || url="git@github.com:$repo.git"
    if [[ -d "repos/$name/.git" ]]; then
      git -C "repos/$name" fetch --prune --quiet origin \
        && { git -C "repos/$name" pull --ff-only --quiet 2>/dev/null || echo "fixbot: $name fetched (working copy not fast-forwarded)"; } \
        || { echo "fixbot: fetch failed for $name" >&2; failed=1; continue; }
    else
      local -a opts=(--quiet); [[ -n "$branch" ]] && opts+=(--branch "$branch")
      git clone "${opts[@]}" "$url" "repos/$name" \
        || { echo "fixbot: clone failed for $name ($url)" >&2; failed=1; continue; }
    fi
    (( count++ )) || true
  done < <(list_repos)
  (( listed > 0 )) || { echo "fixbot: no repos listed in repos.yaml" >&2; return 1; }
  echo "fixbot: synced $count of $listed repo(s) into repos/"
  return $failed
}

# Ask Claude (cheap model, Sentry MCP only) for current issue IDs. Prints one ID per line.
poll_sentry() {
  claude -p "Use only the Sentry MCP. In Sentry organization \"$SENTRY_ORG\", list up to 25 issues matching the Sentry search \"$SENTRY_QUERY\" seen in the last 24 hours, newest first. Reply with only their numeric Sentry issue IDs, one per line, or the word NONE if there are none. No other text." \
    --model "$POLL_MODEL" \
    --settings .claude/headless.settings.json \
    --allowedTools "mcp__sentry" \
    --disallowedTools "Bash,Edit,Write,mcp__linear,mcp__github" \
    --max-turns 6 \
    --output-format json \
    > state/poll-last.json 2> state/poll-last.err || true

  if ! jq -e '.is_error == false' state/poll-last.json >/dev/null 2>&1; then
    echo "fixbot: Sentry poll failed (see state/poll-last.*)" >&2
    notify "fixbot: Sentry poll failed" "Check the Sentry MCP sign-in: claude, then /mcp"
    return 1
  fi
  jq -r '.result' state/poll-last.json | grep -oE '^[[:space:]]*[0-9]+[[:space:]]*$' | tr -d '[:space:]' | sed '/^$/d' || true
}

run_issue() {
  local id="$1" out="runs/$1"
  mkdir -p "$out"
  echo "fixbot: starting Sentry issue $id"
  claude -p "/fixbot-run $id" \
    --settings .claude/headless.settings.json \
    --permission-mode acceptEdits \
    --allowedTools "Read,Edit,Write,Grep,Glob,Bash,mcp__sentry,mcp__linear,mcp__github" \
    --max-turns "$MAX_TURNS" \
    --output-format json \
    > "$out/result.json" 2> "$out/stderr.log" || true

  local sid result
  sid=$(jq -r '.session_id // empty' "$out/result.json" 2>/dev/null || true)
  result=$(jq -r '.result // "no result (see stderr.log)"' "$out/result.json" 2>/dev/null || echo "run failed (see stderr.log)")
  [[ -n "$sid" ]] && echo "$sid" > "$out/session"

  if [[ "$result" == *"READY FOR REVIEW"* ]]; then
    notify "fixbot: ready for review" "Sentry $id — run: ./fixbot.sh review $id"
  else
    notify "fixbot: stopped" "Sentry $id — see runs/$id/summary.md"
  fi
  echo "fixbot: finished $id → $out"
}

case "${1:-}" in
  poll)
    # One poll at a time.
    mkdir state/lock 2>/dev/null || { echo "fixbot: poll already running"; exit 0; }
    trap 'rmdir state/lock' EXIT

    ids=$(poll_sentry) || exit 1

    started=0
    for id in ${(f)ids}; do
      grep -qx "$id" state/seen.txt && continue
      (( started >= MAX_ISSUES_PER_POLL )) && break
      (( started > 0 )) || sync_repos || echo "fixbot: some repos failed to sync; continuing" >&2
      echo "$id" >> state/seen.txt
      run_issue "$id"
      (( started++ )) || true
    done
    ;;

  run)
    [[ -n "${2:-}" ]] || { echo "usage: $0 run <sentry-issue-id>" >&2; exit 1; }
    grep -qx "$2" state/seen.txt || echo "$2" >> state/seen.txt
    sync_repos || echo "fixbot: some repos failed to sync; continuing" >&2
    run_issue "$2"
    ;;

  sync)
    sync_repos
    ;;

  review)
    [[ -f "runs/${2:-}/session" ]] || { echo "fixbot: no session for '${2:-}'" >&2; exit 1; }
    [[ -f "runs/$2/summary.md" ]] && cat "runs/$2/summary.md"
    exec claude --resume "$(cat "runs/$2/session")"
    ;;

  status)
    for d in runs/*(N/); do
      id="${d:t}"
      st=$(grep -m1 '^Status:' "$d/summary.md" 2>/dev/null | sed 's/^Status: *//' || true)
      printf '%-14s %s\n' "$id" "${st:-running or failed (see $d/stderr.log)}"
    done
    ;;

  *)
    sed -n '2,9p' "$0"; exit 1 ;;
esac
