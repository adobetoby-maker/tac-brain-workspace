#!/usr/bin/env bash
# Stop hook — runs after every Claude turn
# Flushes memory state so other sessions (and laptop) see it on next message

REMEMBER_DIR="$HOME/.remember"
MEMORY_DIR="$HOME/.claude/projects/-Users-$(whoami)/memory"

# ── Update now.md from most recent today-*.md ────────────────────────────
# now.md = always reflects the most recent session's daily file
LATEST_TODAY=$(ls -t "$REMEMBER_DIR/today-"*.md 2>/dev/null | grep -v '\.done\.md' | head -1 || true)
if [ -n "$LATEST_TODAY" ] && [ -s "$LATEST_TODAY" ]; then
  # Prepend the date so now.md shows which session this came from
  DATE_LABEL=$(basename "$LATEST_TODAY" .md | sed 's/today-//')
  {
    echo "# Recent Session — $DATE_LABEL"
    echo ""
    cat "$LATEST_TODAY"
  } > "$REMEMBER_DIR/now.md"
fi

# ── Run the shared sync ───────────────────────────────────────────────────
bash "$HOME/.claude/bootstrap/memory-sync.sh" >> /tmp/claude-memory-writeback.log 2>&1 || true

# ── Dump claude-mem SQLite to git repo (if it exists) ────────────────────
CLAUDE_MEM_DB=$(find "$HOME/.claude-mem" -name "*.db" -o -name "*.sqlite" 2>/dev/null | head -1)
if [ -n "$CLAUDE_MEM_DB" ]; then
  sqlite3 "$CLAUDE_MEM_DB" .dump > "$MEMORY_DIR/claude-mem-backup.sql" 2>/dev/null || true
fi

# ── Auto-push memory to GitHub if anything changed ───────────────────────
if [ -d "$MEMORY_DIR/.git" ]; then
  cd "$MEMORY_DIR"
  if git status --porcelain 2>/dev/null | grep -q .; then
    git add -A
    git commit -m "sync: $(date -u +%Y-%m-%dT%H:%M:%SZ) [$(hostname -s)]" --quiet 2>/dev/null || true
    git push origin main --quiet 2>/dev/null || true
  fi
fi

exit 0
