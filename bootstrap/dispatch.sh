#!/usr/bin/env bash
# dispatch — Claude Code → Hermes handoff
# Usage: dispatch [--profile <name>] [--bg] "<task>"
#
# Writes a task to ~/.hermes/tasks/pending/ and optionally spawns Hermes in background.
# Claude Code calls this to hand off work without blocking the session.

set -euo pipefail

PROFILE="claude"
BG=false
PRIORITY="normal"
TASK=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile|-p) PROFILE="$2"; shift 2 ;;
    --bg|-b)      BG=true; shift ;;
    --urgent|-u)  PRIORITY="urgent"; shift ;;
    --*)          echo "Unknown flag: $1" >&2; exit 1 ;;
    *)            TASK="$1"; shift ;;
  esac
done

if [[ -z "$TASK" ]]; then
  echo "Usage: dispatch [--profile <name>] [--bg] \"<task description>\"" >&2
  exit 1
fi

# ── Memory injection — same classifier as jr() in .zshrc ──────────────────────
# Fires for project-specific tasks; skips mechanical shell commands.
_dispatch_needs_memory() {
  local task="$1"
  local word1
  word1=$(echo "$task" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
  local skip_verbs="git|npm|cp|mv|rm|curl|ffmpeg|resize|rename|rotate|crop|compress|download|upload|deploy|push|pull|commit|install|uninstall|kill|start|stop|restart|wrangler|python3|node|bash|sh"
  [[ "$word1" =~ ^($skip_verbs)$ ]] && return 1
  local wc
  wc=$(echo "$task" | wc -w | tr -d ' ')
  local project_nouns="salvorias|jrs|climb|silver-creek|language-lens|orthobiologic|tobyandertonmd|manage-worker-bee|tac|hermes|gap-fill|gap-heal|para|knowledge-base|maxwell|block-reign|dex|exam|lingua|andertongroup|tac-brain|scaffold"
  [[ "$wc" -lt 5 ]] && ! echo "$task" | grep -qiE "($project_nouns)" && return 1
  return 0
}

if _dispatch_needs_memory "$TASK"; then
  MEM_KEYWORDS=$(echo "$TASK" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '\n' | \
    grep -vE "^(the|a|an|is|it|in|of|to|for|on|at|by|with|from|this|that|and|or|but|not|i|we|you|me|my|our|your|can|will|would|should|please|just|also|still|even|than|then|when|how|what|why|who|which|where|get|set|use|run|add|fix|make|do|be|have|has|had|was|were|are|am|so|up|as|if|do|all|any|some|no|new|old|now|here|there|very|well)$" | \
    head -8 | tr '\n' '|' | sed 's/|$//')
  if [ -n "$MEM_KEYWORDS" ]; then
    MEM_CTX=$(grep -ril "$MEM_KEYWORDS" "$HOME/.claude/projects/-Users-drive/memory/" 2>/dev/null | \
      head -5 | xargs -I{} sh -c 'grep -h "" "$1" 2>/dev/null' _ {} | \
      grep -v "^$\|^#\|^\-\-\-" | head -25)
    if [ -n "$MEM_CTX" ]; then
      TASK="[MEMORY CONTEXT]
${MEM_CTX}
[END MEMORY]

${TASK}"
      echo "🧠 memory injected into dispatch task" >&2
    fi
  fi
fi

TASK_DIR="$HOME/.hermes/tasks/pending"
mkdir -p "$TASK_DIR"

TASK_ID="$(date +%Y%m%d-%H%M%S)-$(openssl rand -hex 3)"
TASK_FILE="$TASK_DIR/$TASK_ID.json"

cat > "$TASK_FILE" <<EOF
{
  "id": "$TASK_ID",
  "profile": "$PROFILE",
  "priority": "$PRIORITY",
  "prompt": $(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$TASK"),
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "origin": "claude-code-dispatch",
  "status": "pending"
}
EOF

echo "✓ Task queued: $TASK_ID"
echo "  Profile: $PROFILE"
echo "  Priority: $PRIORITY"

if [[ "$BG" == "true" ]]; then
  LOG="$HOME/.hermes/logs/dispatch-$TASK_ID.log"
  hermes --profile "$PROFILE" -z "$TASK" > "$LOG" 2>&1 &
  HERMES_PID=$!
  echo "  Spawned: PID $HERMES_PID → $LOG"
  # Update task file with PID
  python3 -c "
import json
with open('$TASK_FILE') as f:
    t = json.load(f)
t['pid'] = $HERMES_PID
t['log'] = '$LOG'
t['status'] = 'running'
with open('$TASK_FILE', 'w') as f:
    json.dump(t, f, indent=2)
"
else
  echo ""
  echo "  To run now:   hermes --profile $PROFILE -z \"\$(<$TASK_FILE python3 -c 'import json,sys; print(json.load(sys.stdin)[\"prompt\"])')\""
  echo "  To run in bg: dispatch --bg --profile $PROFILE \"$TASK\""
fi
