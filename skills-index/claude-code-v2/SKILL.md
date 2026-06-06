---
name: claude-code-v2
description: "New Claude Code features from v2.1.144–2.1.153 (official anthropics/claude-code repo). Use when configuring hooks, skills, plugins, or workflow patterns. Covers: disallowed-tools, MessageDisplay hook, /code-review, feature-dev 3-phase pattern, ralph loop, confidence-based review, hookify rule engine."
risk: safe
source: "https://github.com/anthropics/claude-code"
date_added: "2026-05-28"
---

# Claude Code v2 — New Features & Patterns

Sourced from the official anthropics/claude-code repo (127k stars) CHANGELOG + plugins.
Reference: https://github.com/anthropics/claude-code

---

## New CLI Commands

### `/code-review` (replaces `/simplify`)
```bash
/code-review          # 4 parallel agents, confidence ≥80 filter, output to terminal
/code-review --fix    # applies findings directly to working tree
/code-review --comment  # posts review as inline GitHub PR comment
/code-review high     # set effort level
/code-review ultra    # multi-agent cloud review of current branch
/code-review ultra 42 # cloud review of GitHub PR #42
```
Architecture: 4 parallel agents — 2 for CLAUDE.md compliance, 1 for bugs, 1 for git blame context. Each scores 0–100 confidence. Only ≥80 surfaces.

### `/reload-skills`
Re-scans all skill directories without restarting the session. Use after installing a skill mid-session or when a SessionStart hook installs new skills.

### `/usage`
Now shows per-category breakdown of what's consuming limits: skills, subagents, plugins, per-MCP-server cost.

### `/model`
- Default behavior (2.1.152+): saves selection as default for new sessions
- Press `s` in picker = this session only (does not change default)
- Old `d` key is now `s` — update any keybindings.json references

### `/branch`
Fork current conversation into a new branch. Works in both interactive and background sessions.

### `claude agents --json`
List all live sessions as JSON for scripting:
```bash
claude agents --json | jq '.[] | select(.status=="running") | .id'
```
Useful for tmux-resurrect, status bars, session pickers.

---

## New Skill Frontmatter Keys

### `disallowed-tools:`
Remove tools from the model while a skill is active. Useful for read-only analysis skills or skills where you don't want file edits.
```yaml
---
name: my-analysis-skill
disallowed-tools:
  - Edit
  - Write
  - Bash
---
```

### `context: fork`
Forks the conversation context when the skill activates — skill runs in isolation, changes don't persist to main session. Bug-fixed in 2.1.144 (was re-invoking itself in a loop before).

### `effort:` frontmatter
Set thinking effort level for a skill:
```yaml
effort: high  # or low, medium, high
```

---

## New Hook Events & Fields

### `MessageDisplay` hook (2.1.152)
Fires as assistant message text is displayed. Can transform or hide output.
```json
{
  "event": "MessageDisplay",
  "message": "the assistant text about to render"
}
```
Return `{ "content": "modified text" }` to transform, or `{ "suppress": true }` to hide.

### Stop / SubagentStop hooks — new fields (2.1.145)
Hook input now includes:
```json
{
  "background_tasks": [...],
  "session_crons": [...]
}
```
Lets stop hooks check if background tasks are still running before allowing exit.

### `SessionStart` hook — new output fields (2.1.152)
```json
{
  "reloadSkills": true,        // re-scan skills dirs after hook runs
  "sessionTitle": "My Session" // sets the session name in claude agents view
}
```
`reloadSkills: true` is the key one — means a SessionStart hook can install a skill and then have it available in the same session without a restart.

---

## New Plugin Patterns

### feature-dev — 3-Phase Development Protocol
Source: `anthropics/claude-code` → `plugins/feature-dev`

**Phase 1: Discovery**
- Clarify requirements, edge cases, constraints
- Use TodoWrite to track all phases

**Phase 2: Codebase Exploration (parallel)**
Launch 2–3 `code-explorer` agents simultaneously, each with a different focus:
```
Agent 1: "Find features similar to [X], trace implementation comprehensively"
Agent 2: "Map architecture and abstractions for [area], trace code comprehensively"
Agent 3: "Analyze UI patterns, testing approaches, extension points for [feature]"
```
Each agent returns a list of 10 key files → **read all of them** before proceeding. Don't skip this step.

**Phase 3: Clarifying Questions → Architecture → Implementation**
Only after reading all agent-identified files. Ask specific questions, wait for answers, then design.

**Why this beats diving straight into code:** You surface patterns you'd miss, avoid duplicating existing abstractions, and ask the right questions before committing to architecture.

### ralph-wiggum — Self-Referential Iteration Loop
Source: `anthropics/claude-code` → `plugins/ralph-wiggum`

A Stop hook that intercepts Claude's exit attempts and re-feeds the same prompt. Creates autonomous iteration loops without external bash loops.

```bash
/ralph-loop "Your full task description here. Output <promise>DONE</promise> when complete." \
  --completion-promise "DONE" \
  --max-iterations 50
```

How it works:
1. You run `/ralph-loop` once
2. Claude works on the task
3. Claude tries to exit
4. Stop hook intercepts → re-injects the same prompt
5. Claude reads its own file history, git diff, test output from previous iteration
6. Iterates until it outputs the completion promise

Best for: long autonomous refactors, test-fix loops, code quality passes, research tasks.

### hookify — Python Rule Engine for Hooks
Source: `anthropics/claude-code` → `plugins/hookify`

Declarative hook rules in `.claude/hookify.*.local.md` files. Evaluated at PreToolUse, PostToolUse, UserPromptSubmit, Stop.

```markdown
<!-- hookify.my-rules.local.md -->
## Rule: No rm -rf
event: bash
pattern: rm\s+-rf
action: block
message: "Dangerous delete blocked. Use trash or rm -r without -f."

## Rule: No console.log in production files
event: file
pattern: console\.log\(
action: warn
message: "Remove console.log before shipping."
```

The Python rule engine (`~/.claude/plugins/hookify/core/`) loads these files, matches patterns against tool input, and returns block/warn/allow decisions.

Key: `CLAUDE_PLUGIN_ROOT` env var is always set in plugin hook scripts — use it to locate plugin files.

### code-review — 4 Parallel Agents + Confidence Scoring
Source: `anthropics/claude-code` → `plugins/code-review`

Architecture for production-quality code review:
```
PR diff
├── Agent 1: CLAUDE.md compliance (rules A–M)
├── Agent 2: CLAUDE.md compliance (rules N–Z)
├── Agent 3: Bug detection (changes only, not pre-existing)
└── Agent 4: Git blame context (history, intent, regressions)
     ↓
Each issue scored 0–100 confidence
Filter: drop < 80
Output: only high-confidence actionable findings
```

Confidence scoring prevents the false-positive problem that makes most automated reviews noise. Scoring criteria:
- 90–100: Definite bug, security issue, or explicit CLAUDE.md violation
- 80–89: Likely issue with clear reasoning
- < 80: Uncertain — dropped

---

## Key Behavioral Changes (Upgrade Notes)

| What changed | Old behavior | New behavior |
|---|---|---|
| `/simplify` | Cleanup + fix command | Renamed to `/code-review` — old name still works |
| `/model` picker | `d` = set default | `s` = this session only; saving default is now the default action |
| Skill listing at startup | Truncation shown as notification | Silently truncated; check `/doctor` for full list |
| `context: fork` skills | Could loop infinitely | Fixed — properly forks, doesn't re-invoke |
| Stop hooks | No background task info | Now receives `background_tasks` + `session_crons` |
| Auto mode | Required opt-in | No opt-in needed |
| `head`/`tail` | Did not satisfy read-before-edit | Now count as file reads for edit permission |

---

## Status Line Improvements

Status line scripts (in `statusline:` config) now receive:
```bash
COLUMNS=120   # terminal width
LINES=40      # terminal height
```
Use to size output dynamically:
```bash
if [ "$COLUMNS" -lt 80 ]; then echo "short"; else echo "full status line here"; fi
```

Also: `claude agents` tab title now shows awaiting-input count — you know when an agent needs attention without switching windows.

---

## Performance / Reliability Fixes Worth Knowing

- **Startup hang eliminated**: Was hanging up to 75s when `api.anthropic.com` unreachable. Now 15s max timeout.
- **Memory fix**: Resuming sessions by transcript path was using multiple GB. Fixed.
- **`find` fix**: Was exhausting macOS vnode table on large trees. Fixed — use with specific paths, not `/`.
- **MCP paginated tools**: Was only returning first page, silently dropping tools. Fixed in 2.1.144.
- **Skill reload loop**: Non-`.md` files in a skill directory were triggering infinite reload. Fixed.
- **`egrep`/`fgrep` exit 1**: "no matches" no longer reported as command failure — just empty results.

---

## When to Invoke This Skill
- Configuring hooks or writing new hook scripts
- Writing skill frontmatter (especially `disallowed-tools`, `effort`, `context: fork`)
- Planning a multi-phase feature build (use 3-phase feature-dev pattern)
- Running a long autonomous task (consider ralph loop)
- Setting up automated code review (confidence-scoring pattern)
- Upgrading from older Claude Code config (rename `/simplify` → `/code-review`, update `/model` keybindings)
