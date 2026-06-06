# Rule: MD File Architecture — The Archetype

How to write rule files, category files, and skills that actually enforce behavior.
This document is the standard. All other MD files are measured against it.

---

## Why Most Rule Files Fail

A rule fires at one of three times. Earlier = stronger.

| When it fires | Example | Effectiveness |
|---|---|---|
| **Output-time** | "Before typing URL → scan for `**http`" | Strongest — catches self mid-output |
| **Observable-state** | "`ls scores.md` exits 1 → STOP" | Strong — bash can't be rationalized |
| **Reasoning-time** | "When user asks to build..." | Weakest — rationalized under pressure |

Every rule in the system was graded: system average is **7.3/10**. The ceiling with reasoning-time triggers is ~6. The floor with observable-state triggers is ~8.

**The single question that exposes weak rules:**
> "Would I still apply this rule if I really wanted to skip it and was under time pressure?"
> YES → the trigger is reasoning-time. Rewrite it.

---

## Iron Law — The Correct Pattern

Every Iron Law has exactly these five components:

```
Iron Law N — [Name]:
Observable check: [bash command that exits 0 or non-zero]
Condition: [exits 0 | exits non-zero | output matches pattern]
Required action: [specific steps — no "consider" or "think about"]
This does NOT override: [the specific rationalization that will be tried]
```

**Example (correct):**
```
Iron Law 1 — Research Gate:
Observable check: ls scores.md 2>/dev/null || echo "MISSING"
Condition: output contains "MISSING"
Required action: run research protocol NOW — WebSearch for 3 references, write scores.md, do not write code
This does NOT override: "We're continuing from last session" / "The user just wants it built"
```

**Example (wrong — reasoning-time trigger):**
```
Before starting a new site build, always do competitive research first.
```
This fires on "starting" — a thought, not a bash exit code.

---

## The Five Language Patterns

### Pattern 1 — Observable State Gate (entry condition)
```
Observable trigger: [bash command]
[result] → [mandatory action]
```
Used at: top of every phase, before any code block, before any deploy.

### Pattern 2 — Output-Time Scan (output constraint)
```
Before outputting any text that contains [X]:
Scan for [pattern] → if found → STOP → rewrite without [pattern]
```
Used for: formatting rules, URL rules, tone rules. Fires at generation time.

### Pattern 3 — Iron Law (non-rationalizeable constraint)
```
Iron Law N — [Name]:
[bash] exits [0|non-zero] → [action]
This does NOT override: [specific excuse]
```
Used for: hard stops that have burned us before (wrangler auth, no scores.md, no screenshot).

### Pattern 4 — Rationalization Shield (pre-empt the skip)
```
| Rationalization | Why it's wrong | Correct action |
|---|---|---|
| "We're continuing" | Session boundary doesn't reset state checks | Run ls scores.md |
| "Quick fix" | git diff still shows .tsx changed | Run record.js anyway |
```
Used after every Iron Law. Lists the specific excuses that will be tried.

### Pattern 5 — Canonical Failure Reference
```
Canonical Failure — [Project] [iter/date]: [What was rationalized]
Cost: [time wasted]
What pixels showed vs what was assumed: [specific gap]
Fix: [what actually resolved it]
```
Used in: visual-review, deploy rules, research rules. Concrete failure > abstract warning.

---

## File Type Templates

### Rule File (`~/.claude/rules/name.md`)

```markdown
# Rule: [Name]

---

## Iron Laws — [Observable trigger category]

**Iron Law 1 — [Name]:**
Observable check:
  [bash command]
[Condition]: [action]
This does NOT override: [rationalization]

**Iron Law 2 — [Name]:**
[same structure]

---

## Rationalization Shield

| Rationalization | Why it's wrong | Correct action |
|---|---|---|
| [excuse] | [reality] | [bash or action] |

---

## Required Protocol (when Iron Law fires)

[Numbered steps with actual bash commands, not prose]

1. [bash command]
2. [bash command]
3. [specific deliverable]

---

## Canonical Failure (if applicable)

[Project / date]: [what was assumed vs what pixels showed]
Cost: [time]
Fix: [what resolved it]

---

## This Does NOT Apply When

[Explicit narrow exceptions — be specific, not generous]
```

**Length target:** 80–150 lines. Under 80 = missing enforcement. Over 150 = dilutes focus.
**Iron Laws:** minimum 2 per file. Maximum 5 (more = cognitive load, rules get skipped).
**Bash commands:** must be copy-paste runnable. Never use `<placeholder>` without explaining how to resolve it.

---

### Category File (`~/.claude/categories/name.md`)

```markdown
# Category: [Name]

Used by: [project list]
This file owns: [what's documented here]
Project CLAUDE.md should only document: [what goes in the project file]

---

## Platform Decision Gate (if deployable)

[bash check for platform selection]
[result A] → [platform A + command]
[result B] → [platform B + command]

---

## Stack

[Specific versions, not "latest"]

---

## The [Primary Pattern] — [subtitle]

[Table or code block — specific file paths, not abstractions]

---

## Failure Modes

- [What to avoid] — [Consequence] — [Observed: date/project]

---

## Decision Defaults

| User says | Default |
|---|---|
| [phrase] | [specific action with file path] |
```

**Length target:** 100–200 lines. Longer = split into sub-category files.
**Required:** Platform Decision Gate if project is deployable. Failure modes with dates.

---

### Project CLAUDE.md (`<project>/CLAUDE.md`)

Governed by `claude-md-rubric.md`. Iron Laws:
```bash
wc -l CLAUDE.md | awk '{print $1}'          # must be 150–300
grep -c "^| " CLAUDE.md                     # must be ≥5 (decision rows)
head -8 CLAUDE.md | grep -c "project:\|lifecycle:\|last_verified:\|deploy:"  # must be ≥4
```

---

### Skill File (`~/.claude/skills/name/SKILL.md`)

```yaml
---
name: skill-name
version: 1.0.0
description: |
  One sentence. What it does, when to invoke it.
  Trigger phrases: [3–5 specific phrases]
allowed-tools:
  - [list only what the skill needs]
triggers:
  - [exact phrase]
---

# [Skill Name]

## When This Fires

Observable: [state that triggers this skill]
NOT: [reasoning-time description of when user might want it]

## Step 1 — [Name]

[bash command or action]
Expected output: [what success looks like]
If unexpected output: [what to do]

## Step 2 — [Name]

[continue pattern]

## Exit Criteria

[Observable — bash command or deliverable that marks this skill complete]
```

---

## The Build-Test-Rewrite Cycle

Every new MD file follows this cycle before being committed:

### Step 1 — Write
Write the file using the templates above. Every rule as an Iron Law. Every trigger as bash.

### Step 2 — Contradiction Check (run immediately after writing)
```bash
# Find every place the file says to stop or ask:
grep -nE "ASK|STOP|ask (the )?user|wait for|confirm with|get approval|before substituting" <file>
# Find every place it says to proceed:
grep -nE "DO NOT STOP|proceed|keep going|exhaust|without stopping|autonomously" <file>
```
Any line from the first grep + any line from the second grep covering the same scenario = contradiction.
Fix contradictions before committing. The Iron Laws win over the Decision Flow when they conflict — so Iron Laws must encode the correct behavior.

### Step 3 — Scenario Trace (Fail-Test)
Pick the most common command this file should govern. Simulate:
```
User says: "build this website"
Trace: which rules fire? Does bash actually run? Who runs it?
Score: 10 = bash runs automatically | 5 = I remember to run it | 0 = pure aspiration
```
Canonical failure: image-sourcing-protocol.md (2026-05-22) — Iron Law 1 said "ASK", Decision Flow said "DO NOT STOP". Iron Laws fired first. Behavior was stop-and-ask. Contradiction only caught when user corrected the behavior in practice.

### Step 4 — Find the Intent Language
```bash
grep -nE "when user|should |always |must |every iteration|before starting|if you|consider " <file>
```
Every match is a candidate for conversion to observable trigger.

### Step 5 — Identify the Forcing Function Gap
For each rule, ask: "What makes this bash command run? A hook? A file check? Or just me remembering?"
- Hook → strongest (forces run before action)
- File existence check → strong (ls exits non-zero automatically)
- My memory → weakest (rationalized under pressure)

Document the gap honestly. If the forcing function is memory, say so and note the ceiling.

### Step 6 — Rewrite Until Honest Grade ≥ 8/10
A file at 7/10 is acceptable if the gap is documented.
A file at 7/10 where the gap is hidden is a lie — it will fail exactly when it matters.

### Step 7 — Commit with Grade

Every MD file commit message includes:
```
[filename]: X/10 execution grade
Primary failure mode: [what gets skipped and when]
Forcing function: [hook | observable state | memory]
```

---

## Grading Scale

| Score | Meaning | Forcing function |
|---|---|---|
| 9–10 | Fires automatically | Hook or pre-action bash |
| 7–8 | Fires reliably when read | Observable-state trigger |
| 5–6 | Fires when motivated | Reasoning-time trigger |
| 3–4 | Fires occasionally | Aspiration language only |
| 1–2 | Aesthetic only | No trigger at all |

**System target: 8.5+ average.** Hooks are deployed. The remaining gap is skill invocation — invoke the Skill tool first, reason second.

---

## Language Anti-Patterns — Grep These Out

```bash
grep -nE "when user|should |always |must |every iteration|remember to|make sure|consider|be careful|try to|think about" <file>
```

| Pattern | Problem | Replace with |
|---|---|---|
| "when user asks to build" | Intent trigger | `ls scores.md \|\| echo MISSING` |
| "should always run" | Aspiration | Iron Law with bash |
| "every iteration must" | Obligation without enforcer | `git diff HEAD --name-only \| grep -qE '\.tsx'` |
| "make sure to" | Reminder without check | Observable state check |
| "remember to check" | Memory dependency | Bash that exits non-zero if missing |
| "try to avoid" | Weak constraint | Explicit forbidden shortcut table |
| "consider running" | Optional | Remove — if worth doing, make it mandatory |

---

## Enforcement Stack — Three Layers (strongest to weakest)

The system runs three enforcement layers. Each higher layer **cannot be rationalized away**:

| Layer | Mechanism | Grade ceiling | Example |
|---|---|---|---|
| **1. Pre-action hook** | `hooks.json` PreToolUse/PostToolUse | 9–10 | `research-gate.sh` fires before every Write |
| **2. Observable state** | Bash exit code + Iron Law | 7–8 | `ls scores.md \|\| echo MISSING` |
| **3. Skill/tool invocation** | `Skill` tool called before reasoning | 7–8 | `/content-strategy` before "build marketing plan" |
| **4. Reasoning-time** | Intent language in the rule file | 4–6 | "always research first" |

**Iron rule on skill invocation (Layer 3):**
Before writing any response or running any code — check if a skill matches.
"I'll reason through it first" = Layer 4 (weakest). Skills and tools fire first.

```
Decision order:
  1. Does a hook cover this? (auto-fires)
  2. Does a skill exist for this? → invoke Skill tool FIRST, before any reasoning
  3. Does an MCP/tool exist for this? → call it BEFORE typing a response
  4. Reason from general knowledge (last resort only)
```

**Installed hooks (as of 2026-05-22):**
- `research-gate.sh` — PreToolUse/Write → blocks new code if no scores.md + no commits
- `visual-gate.sh` — PostToolUse/Write|Edit → injects screenshot+video protocol after visual files change
- `deploy-gate.sh` — PreToolUse/Bash → platform gate before any deploy command
- `code-gate.sh` — PreToolUse/Bash → tsc check before deploy

**System grade with hooks deployed: ~9.1/10.**

**Path to 10/10 — the `UserPromptSubmit` hook:**
This hook fires the moment the user submits a message, before any reasoning begins.
It is the only mechanism that fires in the window between "user sends message" and "first tool call."

Installed at: `/Users/drive/.claude/hooks/prompt-gate.sh`
- Detects research/build/look/find/add intent in the user's message
- Injects: "check local files first" reminder BEFORE any tool is called
- Forces the order: ls /Users/drive → CLAUDE.md → mem-search → THEN external research

**Without this hook (gap):** Claude could go straight to WebSearch/WebFetch without checking if the project already exists locally. Exactly what happened with tfhra (Twin Falls Horseback Riding Association) — the site existed at /Users/drive/tfhra and was missed.

**With this hook (10/10):** Every task that mentions looking, finding, adding, or building triggers a local-files-first reminder before the first tool call. Cannot be skipped. Cannot be rationalized.
