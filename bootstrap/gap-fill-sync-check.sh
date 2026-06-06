#!/usr/bin/env bash
# sync-check.sh — Phase 0 of gap-fill: sync git memory + AgentDB + PARA
set -euo pipefail

MEMORY_DIR="$HOME/.claude/projects/-Users-drive/memory"
KB_DIR="$HOME/knowledge-base"
SYNC_MARKER="$HOME/.gstack/.last-agentdb-sync"
LOG="$HOME/.claude/skills/gap-fill/data/sync-log.jsonl"

echo "╔══════════════════════════════════════════════╗"
echo "║  BRAIN SYNC CHECK — $(date '+%Y-%m-%d %H:%M')          ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# 1. Git memory repo status
echo "── Git Memory ──"
cd "$MEMORY_DIR"
UNCOMMITTED=$(git status --short | wc -l | tr -d ' ')
if [ "$UNCOMMITTED" -gt 0 ]; then
  echo "⚠️  $UNCOMMITTED uncommitted files:"
  git status --short
  echo ""
  git add -A
  git commit -m "sync: gap-fill auto-commit $(date '+%Y-%m-%d-%H%M')" 2>/dev/null && \
    echo "✅ Committed to git memory" || echo "✗ Commit failed"
else
  echo "✅ Git memory clean (last commit: $(git log --oneline -1))"
fi
echo ""

# 2. Find and INDEX knowledge-base files not yet synced
echo "── PARA Knowledge Base ──"
UNSYNCED_FILES=""
if [ -f "$SYNC_MARKER" ]; then
  UNSYNCED_FILES=$(find "$KB_DIR" -name "*.md" ! -name "_*" ! -name "README*" \
    -newer "$SYNC_MARKER" 2>/dev/null)
  UNSYNCED=$(echo "$UNSYNCED_FILES" | grep -c . 2>/dev/null || echo 0)
  echo "${UNSYNCED} files newer than last AgentDB sync"
else
  echo "⚠️  No sync marker — indexing files from last 48h"
  UNSYNCED_FILES=$(find "$KB_DIR" -name "*.md" ! -name "_*" -mtime -2 2>/dev/null)
  UNSYNCED=$(echo "$UNSYNCED_FILES" | grep -c . 2>/dev/null || echo 0)
fi

# Act on unsynced files — index each to AgentDB
if [ "$UNSYNCED" -gt 0 ]; then
  INDEXED=0
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    echo "  📥 Indexing: ${f#$KB_DIR/}"
    SLUG=$(basename "$f" .md | tr '/ -' '_')
    if command -v para-ingest &>/dev/null; then
      para-ingest "$f" --quiet 2>/dev/null && INDEXED=$((INDEXED+1)) || true
    elif command -v claude-flow &>/dev/null; then
      claude-flow memory store \
        --key "kb_$SLUG" --value "$(head -c 3000 "$f")" \
        --namespace "knowledge-base" --quiet 2>/dev/null && INDEXED=$((INDEXED+1)) || true
    fi
  done <<< "$UNSYNCED_FILES"
  echo "✅ Indexed $INDEXED/$UNSYNCED unsynced files to AgentDB"
else
  echo "✅ All PARA files are indexed"
fi
echo ""

# 3. Update sync marker
touch "$SYNC_MARKER"

# 4. Log the sync
mkdir -p "$(dirname "$LOG")"
echo "{\"date\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"sync\",\"uncommitted\":$UNCOMMITTED}" >> "$LOG"

echo "── Memory Files Summary ──"
echo "Sessions in memory:"
ls "$MEMORY_DIR"/2026-*.md 2>/dev/null | wc -l | xargs echo "  Session notes:"
ls "$MEMORY_DIR"/email_sender_*.md 2>/dev/null | wc -l | xargs echo "  Email senders:"
ls "$MEMORY_DIR"/project_*.md 2>/dev/null | wc -l | xargs echo "  Project files:"
ls "$KB_DIR/3-resources" 2>/dev/null | wc -l | xargs echo "  Resource folders:"
ls "$KB_DIR/2-areas" 2>/dev/null | wc -l | xargs echo "  Area folders:"
echo ""
echo "✅ Sync check complete"
