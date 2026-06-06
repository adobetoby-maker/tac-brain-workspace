#!/usr/bin/env bash
# sync-memory-trigger.sh
# Called by: SessionStart, UserPromptSubmit, Stop hook, launchd 5-min
# Flow:
#   1. flat-file memory ← GitHub pull
#   2. flat-file memory → vault Memory/  (existing)
#   3. vault notes → AgentDB claude-memories namespace (NEW)
#   4. vault notes → PARA ~/knowledge-base folders (NEW)

LOCK=/tmp/claude-memory-sync.lock
VAULT="/Users/drive/Library/Mobile Documents/iCloud~md~obsidian/Documents/second brain"
MEMORY_SRC="$HOME/.claude/projects/-Users-drive/memory"
KB="$HOME/knowledge-base"
MARKER="$HOME/.claude/bootstrap/.last-obsidian-agentdb-sync"
export PATH="/usr/local/bin:/opt/homebrew/bin:/Users/drive/.local/bin:$PATH"

# Prevent concurrent syncs
if [ -f "$LOCK" ]; then
  LOCK_AGE=$(( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0) ))
  [ "$LOCK_AGE" -lt 30 ] && exit 0
fi
touch "$LOCK"
trap 'rm -f "$LOCK"' EXIT

# ── 1. Pull flat-file memory from GitHub ──────────────────────────────────────
cd "$MEMORY_SRC" 2>/dev/null && git pull origin main --quiet 2>/dev/null || true

# ── 2. Flat-file memory → vault Memory/ ───────────────────────────────────────
VAULT_MEMORY="$VAULT/Memory"
mkdir -p "$VAULT_MEMORY" 2>/dev/null || true
KEY_FILES=(
  "now.md" "recent.md" "core-memories.md" "MEMORY.md" "failures.md"
  "project_dex_phase2.md" "project_jrs_auto_repair.md"
  "project_manage_worker_bee.md" "project_language_lens.md"
  "project_wba_agent.md" "project_workspace_bootstrap.md"
)
for f in "${KEY_FILES[@]}"; do
  src="$MEMORY_SRC/$f"
  [ -f "$src" ] && cp "$src" "$VAULT_MEMORY/$f" 2>/dev/null || true
done

# ── 3 & 4. Vault folders → AgentDB (claude-memories) + PARA ──────────────────
[ -f "$MARKER" ] || touch -t 197001010000 "$MARKER"
indexed=0

# index_file <path> <key-prefix>
# Stores in claude-memories namespace (same one mem-search queries)
index_file() {
  local file="$1" prefix="$2"
  local content snippet key
  content=$(cat "$file" 2>/dev/null) || return
  [ ${#content} -lt 40 ] && return
  key="obsidian_${prefix}_$(basename "$file" .md | tr ' /' '__' | tr -cd '[:alnum:]_-')"
  snippet="${content:0:8000}"
  command -v claude-flow &>/dev/null && \
    claude-flow memory store --namespace "claude-memories" -k "$key" --value "$snippet" \
    2>/dev/null || true
  indexed=$((indexed+1))
}

# ── Daily notes ───────────────────────────────────────────────────────────────
while IFS= read -r -d '' f; do
  index_file "$f" "daily"
  cp "$f" "$MEMORY_SRC/$(basename "$f" | tr ' ' '-')" 2>/dev/null || true
done < <(find "$VAULT/Daily" -name "*.md" -newer "$MARKER" -print0 2>/dev/null)

# ── Memory notes ──────────────────────────────────────────────────────────────
while IFS= read -r -d '' f; do
  index_file "$f" "memory"
  cp "$f" "$MEMORY_SRC/$(basename "$f" | tr ' ' '-')" 2>/dev/null || true
done < <(find "$VAULT/Memory" -name "*.md" -newer "$MARKER" -print0 2>/dev/null)

# ── Client notes → 2-areas/clients/ ──────────────────────────────────────────
while IFS= read -r -d '' f; do
  index_file "$f" "client"
  CLIENT=$(basename "$f" .md | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  mkdir -p "$KB/2-areas/clients/$CLIENT" 2>/dev/null || true
  cp "$f" "$KB/2-areas/clients/$CLIENT/$(basename "$f")" 2>/dev/null || true
done < <(find "$VAULT/Clients" -name "*.md" -newer "$MARKER" -print0 2>/dev/null)

# ── Project notes → 1-projects/ ───────────────────────────────────────────────
while IFS= read -r -d '' f; do
  index_file "$f" "project"
  PROJ=$(basename "$f" .md | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  mkdir -p "$KB/1-projects/$PROJ" 2>/dev/null || true
  cp "$f" "$KB/1-projects/$PROJ/$(basename "$f")" 2>/dev/null || true
done < <(find "$VAULT/Projects" -name "*.md" -newer "$MARKER" -print0 2>/dev/null)

# ── Knowledge → 3-resources/ ──────────────────────────────────────────────────
while IFS= read -r -d '' f; do
  index_file "$f" "knowledge"
  mkdir -p "$KB/3-resources/obsidian-knowledge" 2>/dev/null || true
  cp "$f" "$KB/3-resources/obsidian-knowledge/$(basename "$f")" 2>/dev/null || true
done < <(find "$VAULT/Knowledge" -name "*.md" -newer "$MARKER" -print0 2>/dev/null)

# ── Dev Logs ──────────────────────────────────────────────────────────────────
DEVLOGS="$VAULT/Dev Logs"
while IFS= read -r -d '' f; do
  index_file "$f" "devlog"
  cp "$f" "$MEMORY_SRC/$(basename "$f" | tr ' ' '-')" 2>/dev/null || true
done < <(find "$DEVLOGS" -name "*.md" -newer "$MARKER" -print0 2>/dev/null)

# ── Agency & People ───────────────────────────────────────────────────────────
while IFS= read -r -d '' f; do
  index_file "$f" "agency"
done < <(find "$VAULT/Agency" -name "*.md" -newer "$MARKER" -print0 2>/dev/null)

while IFS= read -r -d '' f; do
  index_file "$f" "people"
done < <(find "$VAULT/People" -name "*.md" -newer "$MARKER" -print0 2>/dev/null)

# Update marker
touch "$MARKER"

# ── Mirror Projects/ + Clients/ → work/active/ (keeps session-start Tier 3 live) ──
ACTIVE="$VAULT/work/active"
mkdir -p "$ACTIVE" 2>/dev/null || true

# New/updated project notes
while IFS= read -r -d '' f; do
  SLUG=$(basename "$f" .md | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | tr '—' '-')
  cp "$f" "$ACTIVE/$SLUG.md" 2>/dev/null || true
done < <(find "$VAULT/Projects" -name "*.md" -newer "$MARKER" -print0 2>/dev/null)

# New/updated client notes
while IFS= read -r -d '' f; do
  SLUG=$(basename "$f" .md | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  cp "$f" "$ACTIVE/$SLUG.md" 2>/dev/null || true
done < <(find "$VAULT/Clients" -name "*.md" -newer "$MARKER" -print0 2>/dev/null)

# ── Log to vault ──────────────────────────────────────────────────────────────
LOG="$VAULT/Logs/$(date '+%Y-%m-%d').md"
TRIGGER="${1:-manual}"
[ -f "$LOG" ] && printf "\n**%s** — obsidian→AgentDB: %d indexed (%s)\n" \
  "$(date '+%H:%M')" "$indexed" "$TRIGGER" >> "$LOG" 2>/dev/null || true

exit 0
