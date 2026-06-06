#!/usr/bin/env bash
# ruflo-bridge: sync flat-file memory → claude-flow AgentDB (claude-memories namespace)
# Run from ~/.claude/memory to use the initialized global AgentDB.
# Usage: bash ~/.claude/bootstrap/ruflo-bridge.sh [--quiet]

MEMORY_DIR="$HOME/.claude/projects/-Users-drive/memory"
QUIET="${1:-}"
count=0
failed=0

cd "$HOME/.claude/memory" || { echo "❌ Run: cd ~/.claude/memory && claude-flow memory init first"; exit 1; }

[ -z "$QUIET" ] && echo "🔄 Bridging flat-file memory → AgentDB..."

for f in "$MEMORY_DIR"/*.md; do
  [ -f "$f" ] || continue
  key=$(basename "$f" .md)
  raw=$(cat "$f")
  [ ${#raw} -lt 50 ] && continue

  # Prefix with space to prevent YAML-parsing --- frontmatter as boolean
  value=" $raw"

  result=$(claude-flow memory store --namespace claude-memories -k "$key" --value "$value" 2>&1)
  if echo "$result" | grep -q "Data stored\|OK"; then
    [ -z "$QUIET" ] && echo "  ✓ $key"
    count=$((count+1))
  elif echo "$result" | grep -q "UNIQUE constraint"; then
    # Already exists — counts as synced
    [ -z "$QUIET" ] && echo "  = $key (already synced)"
    count=$((count+1))
  else
    failed=$((failed+1))
    [ -z "$QUIET" ] && echo "  ✗ $key: $(echo "$result" | grep ERROR | head -1 | sed 's/\[ERROR\] //')"
  fi
done

echo "✅ $count synced, $failed failed (namespace: claude-memories)"
