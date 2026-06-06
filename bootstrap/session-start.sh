#!/usr/bin/env bash
# Auto-bootstrap: vault-first tiered loading + flat-file fallback
# Runs on every Claude Code SessionStart — outputs additionalContext JSON
# Single source of truth: Obsidian vault (iCloud-synced, written by human + TAC)

set -euo pipefail

USERNAME=$(whoami)
VAULT="/Users/drive/Library/Mobile Documents/iCloud~md~obsidian/Documents/second brain"
MEMORY_DIR="$HOME/.claude/projects/-Users-$USERNAME/memory"
REMEMBER_DIR="$HOME/.remember"

# Load persistent API keys (FAL_KEY, etc.) — never ask user for these
[ -f "$HOME/.claude/api-keys.env" ] && set -a && source "$HOME/.claude/api-keys.env" && set +a

# Helper: strip ONLY the first frontmatter block (--- ... ---) from a file
# Uses Python so body --- horizontal rules are never treated as delimiters
strip_frontmatter() {
  python3 - "$1" << 'PYEOF'
import sys, re
try:
    content = open(sys.argv[1]).read()
    # Remove only the leading frontmatter block (first --- ... --- pair)
    content = re.sub(r'^---\n.*?\n---\n?', '', content, count=1, flags=re.DOTALL)
    sys.stdout.write(content)
except Exception:
    pass
PYEOF
}

# Helper: extract the first line of ## For future Claude section from a vault file
extract_preamble() {
  python3 - "$1" << 'PYEOF'
import sys, re
try:
    content = open(sys.argv[1]).read()
    # Find ## For future Claude section, get first non-empty line after it
    m = re.search(r'## For future Claude\s*\n(.*?)(?=\n##|\Z)', content, re.DOTALL)
    if m:
        for line in m.group(1).splitlines():
            line = line.strip()
            if line and not line.startswith('---'):
                print(line[:140])
                break
except Exception:
    pass
PYEOF
}

# ── TIER 1: Critical Facts (always loaded, ~120 tokens) ───────────────────
CRITICAL_FACTS=""
if [ -f "$VAULT/CRITICAL_FACTS.md" ]; then
  CRITICAL_FACTS=$(strip_frontmatter "$VAULT/CRITICAL_FACTS.md" 2>/dev/null | head -40 || echo "")
fi

# ── TIER 2: North Star excerpt (first 35 lines after frontmatter) ─────────
NORTH_STAR=""
if [ -f "$VAULT/brain/North Star.md" ]; then
  NORTH_STAR=$(strip_frontmatter "$VAULT/brain/North Star.md" 2>/dev/null | head -50 || echo "")
fi

# ── TIER 3: Active project index + one-liner preamble ─────────────────────
ACTIVE_PROJECTS=""
if [ -d "$VAULT/work/active" ]; then
  PROJECT_LINES=""
  for f in "$VAULT/work/active/"*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .md)
    preamble=$(extract_preamble "$f" 2>/dev/null || echo "")
    if [ -n "$preamble" ]; then
      PROJECT_LINES="${PROJECT_LINES}  - ${name}: ${preamble}\n"
    else
      PROJECT_LINES="${PROJECT_LINES}  - ${name}\n"
    fi
  done
  ACTIVE_PROJECTS=$(printf '%b' "$PROJECT_LINES")
fi

# ── TIER 4: Recent session state ─────────────────────────────────────────
RECENT_STATE=""
# Try ~/.remember/now.md first (obsidian-second-brain pattern)
if [ -f "$REMEMBER_DIR/now.md" ] && [ -s "$REMEMBER_DIR/now.md" ]; then
  RECENT_STATE=$(head -30 "$REMEMBER_DIR/now.md" 2>/dev/null || echo "")
fi
# Supplement with today's daily file if it exists and has content
TODAY_FILE="$REMEMBER_DIR/today-$(date +%Y-%m-%d).md"
if [ -f "$TODAY_FILE" ] && [ -s "$TODAY_FILE" ]; then
  TODAY_CONTENT=$(head -20 "$TODAY_FILE" 2>/dev/null || echo "")
  if [ -n "$TODAY_CONTENT" ]; then
    RECENT_STATE="${RECENT_STATE}

### Today's session ($(date +%Y-%m-%d)):
$TODAY_CONTENT"
  fi
fi
# Final fallback: flat-file MEMORY.md (full file, not head -40)
if [ -z "$RECENT_STATE" ] && [ -f "$MEMORY_DIR/MEMORY.md" ]; then
  RECENT_STATE=$(cat "$MEMORY_DIR/MEMORY.md" 2>/dev/null | head -120 || echo "")
fi

# ── TIER 5: Memory sync status ────────────────────────────────────────────
SYNC_STATUS=""
SYNC_MARKER="$HOME/.claude/bootstrap/.last-memory-sync"
if [ -f "$SYNC_MARKER" ]; then
  LAST_SYNC=$(cat "$SYNC_MARKER" 2>/dev/null || echo "unknown")
  VAULT_COUNT=$(find "$VAULT/work/active" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  SYNC_STATUS="Vault: $VAULT_COUNT active projects | Last sync: $LAST_SYNC"
else
  VAULT_COUNT=$(find "$VAULT/work/active" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  SYNC_STATUS="Vault: $VAULT_COUNT active projects | Sync marker missing"
fi

# ── TIER 6: Active hookify rules ─────────────────────────────────────────
HOOK_RULES=""
HOOK_FILES=$(ls "$HOME/.claude/hookify.".*.local.md 2>/dev/null || true)
if [ -n "$HOOK_FILES" ]; then
  HOOK_RULES=$(for f in $HOOK_FILES; do
    name=$(grep "^name:" "$f" | head -1 | sed 's/name: //')
    action=$(grep "^action:" "$f" | head -1 | sed 's/action: //')
    echo "  - $name ($action)"
  done)
fi

# ── TIER 7: Gap-fill cron status ─────────────────────────────────────────
GAP_FILL_STATUS=""
GAP_LOG="$HOME/.claude/skills/gap-fill/data/gap-log.jsonl"
if [ -f "$GAP_LOG" ]; then
  LAST_RUN=$(tail -1 "$GAP_LOG" | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('date','unknown'))" 2>/dev/null || echo "unknown")
  TOTAL_FILES=$(wc -l < "$GAP_LOG" | tr -d ' ')
  KB_COUNT=$(find "$HOME/knowledge-base/3-resources" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  GAP_FILL_STATUS="Last run: $LAST_RUN | Log entries: $TOTAL_FILES | KB entries: $KB_COUNT files"
else
  GAP_FILL_STATUS="Never run — invoke /gap-fill to start"
fi

# ── Build additionalContext ───────────────────────────────────────────────
CONTEXT="# Session Bootstrap — Vault-First

## Critical Facts
$CRITICAL_FACTS

## North Star
$NORTH_STAR

## Active Projects (vault/work/active/) — with one-liner context
$ACTIVE_PROJECTS
Full files: Read $VAULT/work/active/<project>.md when working on that project.

## Recent Session State
$RECENT_STATE

## Vault Status
$SYNC_STATUS
Vault: $VAULT
Flat memory (fallback): $MEMORY_DIR

## Gap-Fill Brain System
$GAP_FILL_STATUS
ACTION REQUIRED: At session start, re-register gap-fill crons by invoking the /gap-fill skill OR calling CronCreate 3 times:
  - cron [47 7 x x x]  morning pass (medical + email + open loops)
  - cron [13 13 x x x] midday pass (tech stack + Claude Code updates)
  - cron [23 19 x x x] evening pass (LLM research + connection expansion)
Knowledge base: ~/knowledge-base/3-resources/ | Log: ~/.claude/skills/gap-fill/data/gap-log.jsonl

## Active Hookify Rules
$HOOK_RULES

## Vault Navigation
- Full project context: $VAULT/work/active/<name>.md
- Credentials & secrets (where to find any key/token): $VAULT/brain/credential-map.md
- Climb sites (all 6, deploy methods, lang keys): $VAULT/brain/climb-sites.md
- wba daemon reference: $VAULT/brain/wba.md
- Managed agents API: $VAULT/brain/claude-agents-api.md
- Decisions: $VAULT/brain/Key Decisions.md
- Patterns: $VAULT/brain/Patterns.md
- Agent dispatch: $VAULT/org/agent-ecosystem.md
- Droid format: $VAULT/brain/how-to-build-droids.md
- Failures: $VAULT/00-workspace/failures.md
"

# Escape for JSON
CONTEXT_JSON=$(printf '%s' "$CONTEXT" | python3 -c "
import sys, json
print(json.dumps(sys.stdin.read()))
")

cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $CONTEXT_JSON
  }
}
EOF
