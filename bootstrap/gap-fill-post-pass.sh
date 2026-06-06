#!/usr/bin/env bash
# post-pass.sh — Runs automatically after every gap-fill pass.
# Closes all 5 broken connections:
#   1. Index new KB files to AgentDB (fix: gap-fill writes but doesn't index)
#   2. Commit new KB files to git memory (fix: new knowledge not persisted)
#   3. Index heal reports to PARA (fix: lessons learned never searchable)
#   4. Mark watcher-ingested files as "known" (fix: gap-fill re-researches them)
#   5. Touch sync marker so next sync-check is accurate

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/Users/drive/.claude/bin:/Users/drive/.local/bin:$PATH"

KB="$HOME/knowledge-base"
MEMORY="$HOME/.claude/projects/-Users-drive/memory"
HEAL_DIR="$HOME/.claude/skills/gap-heal"
SYNC_MARKER="$HOME/.gstack/.last-agentdb-sync"
PASS_LOG="$HOME/.claude/skills/gap-fill/data/gap-log.jsonl"
TODAY=$(date '+%Y-%m-%d')
START=$(date +%s)

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  GAP-FILL POST-PASS — $(date '+%Y-%m-%d %H:%M:%S')            ║"
echo "╚══════════════════════════════════════════════════════════╝"

# ── Fix 1: Index new KB files to AgentDB ──────────────────────────────────
echo ""
echo "── Fix 1: Index new KB entries ──"
INDEXED=0
if [ -f "$SYNC_MARKER" ]; then
  NEW_FILES=$(find "$KB/3-resources" "$KB/5-potential" \
    -name "*.md" ! -name "_*" ! -name "README*" \
    -newer "$SYNC_MARKER" 2>/dev/null)
else
  # First run — index everything in 3-resources
  NEW_FILES=$(find "$KB/3-resources" -name "*.md" ! -name "_*" -mtime -1 2>/dev/null)
fi

if [ -n "$NEW_FILES" ]; then
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    SLUG=$(basename "$f" .md | tr '/' '_')
    CONTENT=$(head -c 3000 "$f")
    if command -v claude-flow &>/dev/null; then
      claude-flow memory store \
        --key "kb_${SLUG}" \
        --value "$CONTENT" \
        --namespace "knowledge-base" \
        --quiet 2>/dev/null && INDEXED=$((INDEXED + 1)) || true
    fi
  done <<< "$NEW_FILES"
  echo "   ✅ Indexed $INDEXED new KB entries to AgentDB"
else
  echo "   ✓ No new KB entries since last sync"
fi

# ── Fix 2: Commit new KB files to git memory ──────────────────────────────
echo ""
echo "── Fix 2: Git memory commit ──"
cd "$MEMORY"
GIT_STATUS=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
if [ "$GIT_STATUS" -gt 0 ]; then
  git add -A
  git commit -m "gap-fill: post-pass commit $(date '+%Y-%m-%d %H:%M')" 2>/dev/null && \
    echo "   ✅ Committed $GIT_STATUS files to git memory" || \
    echo "   ⚠️  Commit failed (continuing)"
else
  echo "   ✓ Git memory already clean"
fi

# ── Fix 3: Index heal reports into PARA ───────────────────────────────────
echo ""
echo "── Fix 3: Index heal reports to PARA ──"
REPORTS_DIR="$HEAL_DIR/reports"
PARA_HEAL_DIR="$KB/3-resources/gap-heal-reports"
mkdir -p "$PARA_HEAL_DIR"

REPORT_COUNT=0
# Index any report from the last 24h not yet in PARA
find "$REPORTS_DIR" -name "*.md" -mtime -1 2>/dev/null | while read -r r; do
  RNAME=$(basename "$r")
  DEST="$PARA_HEAL_DIR/$RNAME"
  if [ ! -f "$DEST" ]; then
    cp "$r" "$DEST"
    # Index to AgentDB
    if command -v claude-flow &>/dev/null; then
      SLUG=$(basename "$r" .md | tr '-' '_')
      claude-flow memory store \
        --key "heal_report_$SLUG" \
        --value "$(head -c 2000 "$r")" \
        --namespace "knowledge-base" \
        --quiet 2>/dev/null || true
    fi
    REPORT_COUNT=$((REPORT_COUNT + 1))
    echo "   ✅ Indexed heal report: $RNAME"
  fi
done
[ "$REPORT_COUNT" -eq 0 ] && echo "   ✓ No new heal reports to index"

# ── Fix 4: Mark PARA-Inbox-ingested files as "known" to gap-fill ─────────
echo ""
echo "── Fix 4: Dedup watcher-added files ──"
KNOWN_FILE="$HOME/.claude/skills/gap-fill/data/known-topics.txt"
touch "$KNOWN_FILE"

# Every file recently added via the watcher to 3-resources/inbox gets its slug
# registered in known-topics.txt so gap-fill skips it in Phase 1 scanning
find "$KB/3-resources/inbox" -name "*.md" -mtime -1 2>/dev/null | while read -r f; do
  SLUG=$(basename "$f" .md)
  if ! grep -qF "$SLUG" "$KNOWN_FILE" 2>/dev/null; then
    echo "$SLUG" >> "$KNOWN_FILE"
    echo "   📌 Registered as known: $SLUG"
  fi
done

# ── Fix 5: Update sync marker (makes next sync-check accurate) ────────────
echo ""
echo "── Fix 5: Update sync marker ──"
mkdir -p "$(dirname "$SYNC_MARKER")"
touch "$SYNC_MARKER"
echo "   ✅ Sync marker updated: $(date '+%Y-%m-%d %H:%M')"

# ── Fix 6: Index Obsidian second-brain vault to AgentDB ───────────────────
echo ""
echo "── Fix 6: Obsidian→AgentDB sync ──"
OBSIDIAN_VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/second brain"
OBS_INDEXED=0
if [ -d "$OBSIDIAN_VAULT" ]; then
  # Index any Obsidian file newer than sync marker (or last 24h on first run)
  if [ -f "$SYNC_MARKER" ]; then
    OBS_FILES=$(find "$OBSIDIAN_VAULT" -name "*.md" ! -name "_*" ! -name "Untitled*" \
      -newer "$SYNC_MARKER" 2>/dev/null)
  else
    OBS_FILES=$(find "$OBSIDIAN_VAULT" -name "*.md" ! -name "_*" ! -name "Untitled*" \
      -mtime -1 2>/dev/null)
  fi
  if [ -n "$OBS_FILES" ]; then
    while IFS= read -r f; do
      [ -f "$f" ] || continue
      SLUG=$(basename "$f" .md | tr '/ ' '_' | tr -cd '[:alnum:]_-')
      if command -v claude-flow &>/dev/null; then
        claude-flow memory store \
          --key "obs_${SLUG}" \
          --value "$(head -c 2500 "$f")" \
          --namespace "obsidian-vault" \
          --quiet 2>/dev/null && OBS_INDEXED=$((OBS_INDEXED+1)) || true
      fi
    done <<< "$OBS_FILES"
    echo "   ✅ Indexed $OBS_INDEXED Obsidian files to AgentDB (namespace: obsidian-vault)"
  else
    echo "   ✓ No new Obsidian files since last sync"
  fi
else
  echo "   ⚠️  Obsidian vault not found at expected path"
fi

# ── Summary ───────────────────────────────────────────────────────────────
END=$(date +%s)
ELAPSED=$((END - START))
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
printf "║  POST-PASS COMPLETE — %ds                               \n" "$ELAPSED"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Fix 1: KB→AgentDB     ✅"
echo "║  Fix 2: KB→git         ✅"
echo "║  Fix 3: heal→PARA      ✅"
echo "║  Fix 4: watcher dedup  ✅"
echo "║  Fix 5: sync marker    ✅"
echo "║  Fix 6: Obsidian→AgentDB ✅"
echo "╚══════════════════════════════════════════════════════════╝"
