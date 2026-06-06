---
name: md-builder
version: 1.0.0
description: |
  Build, test, and grade any MD rule file, category file, or skill using the
  archetype system from md-architecture.md. Follows the research → write →
  fail-test → rewrite → grade → commit cycle. Invoke when creating or fixing
  any instruction file in the ~/.claude/ system.
  Trigger phrases: "write a rule", "create a skill", "build a category file",
  "fix this md file", "grade this rule", "my rules aren't working".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
triggers:
  - write a rule
  - create a skill
  - build a category file
  - fix this md file
  - grade this rule
  - md-builder
  - rules aren't working
---

# MD Builder — Research → Write → Test → Rewrite → Grade

You are building or fixing an instruction file for the ~/.claude/ system.
Follow this cycle exactly. Do not skip steps.

---

## Step 0 — Identify the File Type

Observable check:
```bash
ls ~/.claude/rules/ ~/.claude/categories/ ~/.claude/skills/ 2>/dev/null
```

Ask (if not specified): is this a **rule**, **category**, or **skill**?

| Type | Path | Purpose | Length |
|---|---|---|---|
| Rule | `~/.claude/rules/name.md` | Behavior constraint — fires on observable state | 80–150 lines |
| Category | `~/.claude/categories/name.md` | Stack/archetype patterns for a project type | 100–200 lines |
| Skill | `~/.claude/skills/name/SKILL.md` | Invokable procedure with YAML frontmatter | 80–200 lines |
| Project CLAUDE.md | `<project>/CLAUDE.md` | Project-specific context only | 150–300 lines |

---

## Step 1 — Research (What Does This File Need to Do?)

Before writing a single line:

```bash
# What command or situation should this file govern?
# State it explicitly: "This file fires when user says X"
```

Find 3 analogous existing rules and read them:
```bash
ls ~/.claude/rules/ | head -20
cat ~/.claude/rules/research-first.md    # best observable-state example
cat ~/.claude/rules/autonomous-operations.md  # best Iron Law example
cat ~/.claude/rules/quality-gate.md      # best multi-gate example
```

From each reference, extract:
- What is the observable trigger?
- What bash command fires it?
- What is the forcing function (hook / state check / memory)?
- What rationalization does it pre-empt?

Gap table before writing:
| Dimension | Ref A | Ref B | Ref C | Our Target |
|---|---|---|---|---|
| Observable trigger | ? | ? | ? | must be bash |
| Rationalization shield | ? | ? | ? | ≥3 specific excuses |
| Forcing function | ? | ? | ? | state or output |
| Canonical failure | ? | ? | ? | required if existed |

---

## Step 2 — Write the First Draft

Use the exact template from `~/.claude/rules/md-architecture.md`.

**For a Rule file:**

```markdown
# Rule: [Name]
---
## Iron Laws — [Observable trigger category]
**Iron Law 1 — [Name]:**
Observable check: [bash]
[Condition]: [action — specific, no "consider"]
This does NOT override: [specific rationalization]
---
## Rationalization Shield
| Rationalization | Why it's wrong | Correct action |
|---|---|---|
---
## Required Protocol
[numbered steps with real bash]
---
## Canonical Failure (if applicable)
[project/date]: [what was assumed vs reality]
Cost: [time wasted]
```

**For a Skill file:**

```yaml
---
name: [name]
version: 1.0.0
description: |
  [one sentence + trigger phrases]
allowed-tools: [list]
triggers: [list]
---
```

Then numbered steps. Each step has:
- Observable entry condition
- Bash command with expected output
- "If unexpected output" branch

**Rules for first draft:**
- No `<placeholder>` in bash without resolving how to fill it
- No "consider", "make sure", "try to" language
- Every trigger must be a bash exit code or output pattern
- Every step must have an observable exit criterion

---

## Step 3 — Fail-Test the Draft

Pick the governing command. Run the simulation:

```
Scenario: [the exact user input this rule should govern]

Trace:
1. Does any bash automatically run before I start? [YES/NO]
2. What makes me read this file first? [hook / preamble / memory]
3. When I read the Iron Law, do I run the bash? [forced / optional]
4. Can I rationalize skipping it? [NO = good / YES = weak trigger]
5. What's the forcing function? [hook=9 / observable-state=7 / memory=5]
```

**The rationalization test:**
For each Iron Law, try to construct the excuse that would make you skip it under time pressure. If you can — the trigger is reasoning-time. Rewrite it.

Common excuses and their fixes:

| Excuse tried | Trigger type | Fix |
|---|---|---|
| "We're continuing from last session" | Reasoning-time | `ls scores.md \|\| echo MISSING` runs regardless |
| "This is just a quick fix" | Reasoning-time | `git diff HEAD --name-only \| grep` runs regardless |
| "I know this platform works" | Reasoning-time | `vercel whoami` runs before deploy, regardless |
| "The build probably passed" | Reasoning-time | `npx tsc --noEmit` runs before "done", regardless |

---

## Step 4 — Find and Replace Intent Language

```bash
# Run this on the draft:
grep -nE "when user|should |always |must |every iteration|remember to|make sure|consider|be careful|try to|think about|if you" <draft-file>
```

For every match:
1. What observable state corresponds to this intent?
2. What bash command checks that state?
3. Replace the intent sentence with the bash-triggered pattern.

**Replacement table:**

| Intent language | Observable replacement |
|---|---|
| "when user asks to build" | `ls scores.md \|\| echo MISSING` → MISSING fires rule |
| "always screenshot after changes" | `git diff HEAD --name-only \| grep -qE '\.tsx'` exits 0 → screenshot |
| "should deploy to Vercel" | `cat wrangler.jsonc \| grep -E "d1_databases\|r2_buckets"` → no output → Vercel |
| "before declaring done" | Iron Law: scan for "done\|complete\|shipped" in output draft |
| "every iteration must produce" | `git diff HEAD --name-only \| grep -qE '\.tsx'` exits 0 → STOP |

---

## Step 5 — Grade the Rewrite

Score each Iron Law independently, then average:

```
Iron Law 1: [N]/10 — [forcing function: hook|state|memory]
Iron Law 2: [N]/10 — [forcing function]
...
File average: [N]/10
Primary failure mode: [what gets skipped and when]
Honest ceiling: [what it would take to get to 9+]
```

**Grading scale:**
- 9–10: Fires automatically via hook or pre-action check
- 7–8: Fires reliably when rule is read (observable-state trigger)
- 5–6: Fires when motivated (reasoning-time trigger)
- 3–4: Fires occasionally (aspiration language)

If any Iron Law scores below 7 → identify the observable replacement and rewrite.
Iterate until all Iron Laws are ≥7 and the file average is ≥7.5.

---

## Step 6 — Check Length and Structure

```bash
wc -l <file>    # Rule: 80–150 | Category: 100–200 | CLAUDE.md: 150–300 | Skill: 80–200
grep -c "Iron Law" <file>    # Rules: 2–5 Iron Laws
grep -nE "^\| " <file> | wc -l   # Category/CLAUDE.md: ≥5 decision rows
```

If over length → move category-level content to the category file, not the project file.
If under length → missing enforcement: add rationalization shield or canonical failure.

---

## Step 7 — Commit with Grade

```bash
cd ~/.claude/projects/-Users-drive/memory

# Copy updated file
cp ~/.claude/rules/<name>.md rules/<name>.md
# OR
cp ~/.claude/categories/<name>.md categories/<name>.md

git add <files>
git commit -m "[filename]: X/10 execution grade
Primary failure mode: [what gets skipped]
Forcing function: [hook|observable-state|memory]
Rationalization pre-empted: [specific excuse]"

git push origin main
```

---

## Exit Criteria (This Skill Is Done When)

```bash
wc -l <file>             # within target range
grep -c "Iron Law" <file>   # ≥2 for rule files
grep -nE "when user|should |must |always " <file>  # zero matches = clean
git log --oneline -1     # commit exists with grade in message
```

Honest grade ≥7.5 AND grade is documented in commit message.

---

## Reference Files (Read Before Writing)

| File | Why |
|---|---|
| `~/.claude/rules/md-architecture.md` | Master archetype — templates and language patterns |
| `~/.claude/rules/research-first.md` | Best observable-state Iron Law example |
| `~/.claude/rules/autonomous-operations.md` | Best multi-Iron-Law structure |
| `~/.claude/rules/quality-gate.md` | Best multi-gate enforcement example |
| `~/.claude/rules/visual-review-non-negotiable.md` | Best canonical failure examples |
