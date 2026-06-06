#!/bin/bash
# UserPromptSubmit hook — fires before Claude processes every user message
# Purpose: force "check own files first" before external research
# This closes the 0.9 gap — fires in the window between user message and first tool call

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('prompt', '').lower())
except:
    print('')
" 2>/dev/null)

# Fire on any research/build/look/find/show/what/add intent
if echo "$PROMPT" | grep -qE "(research|look at|show me|what (do|does|is)|find|check|add|build|create|fix|update|debug|can you see|do you see|what.*site|what.*project)"; then

  # Check for existing project match by scanning for project-like words in prompt
  PROJECTS=$(ls /Users/drive/ 2>/dev/null | grep -vE "^(Applications|Desktop|Documents|Downloads|Library|Movies|Music|Pictures|Public|Parallels)" | grep -v "\." | head -40 | tr '\n' '|' | sed 's/|$//')

  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║  PROMPT GATE — check own files BEFORE external research  ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""
  echo "Step 1: ls /Users/drive/ — does a project directory exist?"
  echo "Step 2: Check CLAUDE.md project table"
  echo "Step 3: Check ~/.claude/projects/-Users-drive/memory/"
  echo "Step 4: mem-search for relevant prior work"
  echo "Step 5: ONLY THEN use WebSearch / WebFetch for external data"
  echo ""
  echo "Skill check — does this task match?"
  echo "  'look at / show me / what does' → check local files first"
  echo "  'add photos / real images'      → seo-images skill, then check project at ls /Users/drive/"
  echo "  'marketing plan / eval'         → content-strategy skill"
  echo "  'build / create site'           → ls scores.md || echo MISSING"
  echo "  'fix / debug'                   → systematic-debugging skill"
  echo ""

  # ── AGENT/SKILL CLASSIFIER ─────────────────────────────────────────────
  # Classify task type → surface optimal agent/skill
  AGENT_HINT=""
  SKILL_HINT=""

  # Research / knowledge queries
  if echo "$PROMPT" | grep -qiE "(research|what is|who is|find out|explain|summarise|summarize|look up|investigate|competitive|market|seo audit)"; then
    AGENT_HINT="Scholar"
    SKILL_HINT="scholar \"$( echo "$PROMPT" | head -c 60 )\""
  fi

  # Browser / visual site checks
  if echo "$PROMPT" | grep -qiE "(browse|check (the |this )?(site|page|url)|screenshot|visual qa|look at.*site|verify.*live|test.*live|open.*browser)"; then
    AGENT_HINT="Scout"
    SKILL_HINT="scout \"$( echo "$PROMPT" | head -c 60 )\""
  fi

  # Computer / terminal / app tasks (Maxwell's Wizard)
  if echo "$PROMPT" | grep -qiE "(computer|open (app|application)|click|type into|fill (in|out)|automate|wizard|display|screen|local app|run (a )?script on)"; then
    AGENT_HINT="Wizard"
    SKILL_HINT="wizard \"$( echo "$PROMPT" | head -c 60 )\""
  fi

  # Build / feature / new project
  if echo "$PROMPT" | grep -qiE "^(build|add (a |the )?feature|create (a |the )?new|scaffold|implement|add support for)"; then
    AGENT_HINT="writing-plans → subagent-driven"
    SKILL_HINT="Invoke: writing-plans skill first, then subagent-driven-development"
  fi

  # Debug / fix / error
  if echo "$PROMPT" | grep -qiE "^(fix|debug|error|broken|failing|crash|exception|not working|why (is|does|isn't))"; then
    AGENT_HINT="systematic-debugging"
    SKILL_HINT="Invoke: systematic-debugging skill before writing any code"
  fi

  # Visual / animation / scroll
  if echo "$PROMPT" | grep -qiE "(animation|scroll|transition|motion|framer|threejs|r3f|parallax|hover effect)"; then
    AGENT_HINT="record.js + visual-loop"
    SKILL_HINT="node ~/record.js <port>  →  visual-loop skill"
  fi

  # Deploy / ship intent
  if echo "$PROMPT" | grep -qiE "^(ship|deploy|push (to )?prod|go live|launch|release)"; then
    AGENT_HINT="/10xit first"
    SKILL_HINT="Run /10xit to score before shipping — gates: tsc + lint + visual + SEO + live URL"
  fi

  # Output classifier hint if matched
  if [ -n "$AGENT_HINT" ]; then
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  NEURAL ROUTER                                              │"
    printf "│  Task type detected: %-40s│\n" "$AGENT_HINT"
    printf "│  → %-57s│\n" "$SKILL_HINT"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
  fi
fi
