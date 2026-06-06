#!/usr/bin/env bash
# kb-ingest.sh — Index ~/knowledge-base/ files into AgentDB (claude-flow memory)
# Run once after setup, or re-run to pick up new files.
# Usage: bash ~/.claude/bootstrap/kb-ingest.sh [--quiet]

KB_DIR="${KB_DIR:-$HOME/knowledge-base}"
NAMESPACE="knowledge-base"
QUIET="${1:-}"
count=0
skipped=0
failed=0

[ -d "$KB_DIR" ] || { echo "❌ Knowledge base not found at $KB_DIR"; exit 1; }

cd "$HOME/.claude/memory" 2>/dev/null || cd "$HOME"

[ -z "$QUIET" ] && echo "📚 Indexing $KB_DIR → AgentDB (namespace: $NAMESPACE)..."
[ -z "$QUIET" ] && total=$(find "$KB_DIR" -name "*.md" | wc -l | tr -d ' ') && echo "   Found $total files"

find "$KB_DIR" -name "*.md" | sort | while read -r f; do
  # Build a compact key from relative path: 05-patterns/patterns--foo.md → 05-patterns/patterns--foo
  rel="${f#$KB_DIR/}"
  key="${rel%.md}"

  # Read file — skip tiny files
  raw=$(cat "$f")
  [ ${#raw} -lt 80 ] && continue

  # Store in AgentDB
  result=$(claude-flow memory store --namespace "$NAMESPACE" -k "$key" --value " $raw" 2>&1)

  if echo "$result" | grep -q "Data stored\|OK"; then
    [ -z "$QUIET" ] && echo "  ✓ $key"
    count=$((count+1))
  elif echo "$result" | grep -q "UNIQUE constraint"; then
    skipped=$((skipped+1))
  else
    [ -z "$QUIET" ] && echo "  ✗ $key: $result"
    failed=$((failed+1))
  fi
done

echo ""
echo "✅ KB ingestion complete: $count stored, $skipped already existed, $failed failed"
echo "   Search: claude-flow memory search --namespace $NAMESPACE -q \"your query\""
