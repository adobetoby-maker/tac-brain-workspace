---
name: btw
version: 1.0.0
description: |
  Capture a cross-project thought without breaking current context.
  Usage: /btw <project> <note or task>
  Examples:
    /btw climb-brasil add a Portuguese CTA to the hero
    /btw nexus fee should be 0.25% not 0.30%
    /btw jrs Pablo wants a Spanish language toggle
  Stores the note to AgentDB and optionally dispatches a Haiku agent
  to do the work in the background. Single-line ack — does not disrupt flow.
allowed-tools:
  - Bash
  - Agent
triggers:
  - btw
---

# /btw — By The Way

Parse the input to extract: **project** (first word) and **note** (everything after).

## Step 1: Store the thought

```bash
PROJECT="<first word of input>"
NOTE="<rest of input>"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
KEY="btw-${PROJECT}-${TIMESTAMP}"
(cd "$HOME/.claude/memory" && claude-flow memory store --namespace btw -k "$KEY" --value " [BTW] $PROJECT: $NOTE")
```

## Step 2: Always spawn a background Haiku agent to evaluate and act

**Always** dispatch a Haiku agent in the background — every BTW note gets one.
The agent decides whether to act, and acts if appropriate.

```
Agent(
  model="haiku",
  run_in_background=True,
  description="BTW evaluator: [project] — [first 6 words of note]",
  prompt="""
You are a BTW evaluator. A user left a quick note while working on something else.

PROJECT: <project>
NOTE: <note>
PROJECT PATH: <path from map below>

Project path map:
  climb-brasil     → /Users/drive/climb-brasil
  climb-spain      → /Users/drive/climb-spain
  climb-utah       → /Users/drive/climb-utah
  climb-kalymnos   → /Users/drive/climb-kalymnos
  jrs / jrs-auto-repair → /Users/drive/jrs-auto-repair
  manage / manage-worker-bee → /Users/drive/manage-worker-bee
  language-lens    → /Users/drive/language-lens-elite
  nexus / dex      → /Users/drive/dex-project/.worktrees/phase2-frontend/dex-frontend
  worker-bee       → /Users/drive/worker-bee

EVALUATE the note:

IF it is a concrete actionable task (add, build, fix, update, create, write, change, remove, deploy, wire, rename):
  → Determine which files need to change
  → Make the change (edit files, run npm run build to verify)
  → Confirm success with: ✓ BTW done: [project] — [what was done]

IF it is a thought, idea, question, or reminder (no concrete file changes needed):
  → Do nothing — it was already stored in memory
  → Confirm capture with: ✓ BTW noted: [project] — [summary]

RULES:
- Never push to main or delete files
- Never apply database migrations without confirmation
- If the task is ambiguous or risky, log to NEEDS_HUMAN.md in the project root
- Keep work scoped: only touch files directly related to the note
"""
)
```

## Step 3: Respond in ONE line

Always:
`✓ [project] "[note]" — evaluator agent running in background`

Then **immediately return to whatever was happening before**. Do not elaborate. Do not switch context.

## How stored thoughts surface

When the user runs `/tac <project>`, the `mem-search` step uses the project name as the query.
BTW notes stored in the `btw` namespace are included in search results.
All accumulated `/btw` thoughts for that project appear as prior context before starting work.
