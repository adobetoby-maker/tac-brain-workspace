#!/usr/bin/env bash
# msg-counter-sync.sh — called on every UserPromptSubmit
# Counts messages per session; triggers memory sync every 30

SESSION_ID="${CLAUDE_SESSION_ID:-default}"
COUNT_FILE="/tmp/claude-msg-count-${SESSION_ID}"

# Increment counter
count=$(cat "$COUNT_FILE" 2>/dev/null || echo 0)
count=$((count + 1))
echo $count > "$COUNT_FILE"

# Sync every 30 messages
if [ $((count % 30)) -eq 0 ]; then
  bash "$HOME/.claude/hooks/sync-memory-trigger.sh" "30-msg" &
fi

exit 0
