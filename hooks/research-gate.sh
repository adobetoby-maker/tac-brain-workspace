#!/bin/bash
# PreToolUse hook — Write tool — Research Gate
# Fires before writing code files. If project has no scores.md and no commits → hard stop.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

# Only check source code files that indicate building a site
if ! echo "$FILE_PATH" | grep -qE '\.(tsx|ts|jsx|js|css|scss|html)$'; then
  exit 0
fi

# Skip if it's a rule/config/memory file
if echo "$FILE_PATH" | grep -qE '(\.claude|node_modules|\.git|hooks\.json|settings\.json|SKILL\.md|CLAUDE\.md)'; then
  exit 0
fi

# Walk up to find the project root (directory with package.json)
PROJECT_ROOT=""
DIR=$(dirname "$FILE_PATH")
DEPTH=0
while [ "$DIR" != "/" ] && [ -n "$DIR" ] && [ "$DEPTH" -lt 8 ]; do
  if [ -f "$DIR/package.json" ]; then
    PROJECT_ROOT="$DIR"
    break
  fi
  DIR=$(dirname "$DIR")
  DEPTH=$((DEPTH + 1))
done

if [ -z "$PROJECT_ROOT" ]; then
  exit 0
fi

# scores.md present → research done → proceed
if [ -f "$PROJECT_ROOT/scores.md" ]; then
  exit 0
fi

# scores.md missing — check if this is a new project (no commits)
HAS_COMMITS=$(cd "$PROJECT_ROOT" 2>/dev/null && git log --oneline -1 2>/dev/null | wc -l | tr -d ' ' || echo "0")

if [ "$HAS_COMMITS" = "0" ]; then
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║  RESEARCH GATE — HARD STOP — research-first.md Iron Law   ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo ""
  echo "Project: $PROJECT_ROOT"
  echo "scores.md: MISSING"
  echo "Git commits: NONE — this is a new project"
  echo ""
  echo "Iron Law: No code written until scores.md exists."
  echo ""
  echo "Run research protocol:"
  echo "  1. Identify category: local biz / SaaS / affiliate / portfolio"
  echo "  2. WebSearch: 'best [category] websites 2026' → find 3 references"
  echo "  3. Screenshot each: node ~/screenshot.js <port>"
  echo "  4. Score each on: hero, typography, CTA, mobile, trust, speed"
  echo "  5. Build gap table: reference scores vs our target"
  echo "  6. Write scores.md with mandate: 'Build better than X on Y'"
  echo ""
  echo "THEN write code. Not before."
  echo ""
  echo "Exception: targeted bug fix on known file. If that's this — state it explicitly."
  exit 0
fi

# Project has commits but no scores.md — warn but allow (could be continuing work)
PAGE_COUNT=$(find "$PROJECT_ROOT/app" "$PROJECT_ROOT/src" -name "page.tsx" -o -name "index.tsx" 2>/dev/null | wc -l | tr -d ' ')
if [ "$PAGE_COUNT" = "0" ]; then
  echo "╔════════════════════════════════════════════════════════╗"
  echo "║  RESEARCH WARNING — scores.md missing, no pages yet    ║"
  echo "╚════════════════════════════════════════════════════════╝"
  echo "Project $PROJECT_ROOT has commits but no pages and no scores.md."
  echo "If building new pages → run research protocol first."
  echo "If bug fixing → proceed (and state that explicitly)."
fi
