# Rule: How to Write a Top-1% CLAUDE.md

---

## Iron Laws — Observable Checks

**Iron Law 1 — Length:**
```bash
wc -l CLAUDE.md | awk '{print $1}'
```
Result > 300 → FAIL. Split: move category content to `~/.claude/categories/`, keep only project-unique content in the project file.
Result < 150 → FAIL. Missing coverage — add decision defaults, failure patterns, or architecture details.

**Iron Law 2 — Decision Defaults Table:**
```bash
grep -c "^| " CLAUDE.md
```
Result < 5 → FAIL. A CLAUDE.md without ≥5 decision routing rows generates constant round-trip questions.

**Iron Law 3 — File Path Specificity:**
```bash
grep -E '"We use|"Uses |"The project uses' CLAUDE.md | head -5
```
Any match → FAIL. Abstract "we use X" is not actionable. Every fact needs a file path.

**Iron Law 4 — 5-Minute Test:**
A fresh Claude reads the file and starts working in 5 minutes without asking a single question about: structure, conventions, auth, or env vars. If it would ask → the file is incomplete.

**Iron Law 5 — Frontmatter:**
```bash
head -8 CLAUDE.md | grep -c "project:\|lifecycle:\|last_verified:\|deploy:"
```
Result < 4 → FAIL. Frontmatter required on every project CLAUDE.md.

---

## Layered Context Model

CLAUDE.md is THREE layers. Never duplicate across layers — point at the higher layer:

| Layer | Path | Owns |
|---|---|---|
| Global | `~/.claude/CLAUDE.md` + `~/.claude/rules/*.md` | Formatting, autonomy, model routing |
| Category | `~/.claude/categories/{archetype}.md` | Patterns for that project type |
| Project | `<project>/CLAUDE.md` | ONLY what is unique to this codebase |

If a project breaks from the category pattern → document the exception loudly with a reason.

---

## Required Frontmatter

```markdown
---
project: jrs-auto-repair
category: nextjs-supabase-saas
deploy: cloudflare-workers
lifecycle: active
last_verified: 2026-05-22
deployment_url: https://jrsautorepair.worker-bee.app
---
```

`lifecycle`: exactly one of `active` | `maintenance` | `sunset` | `archived`
`last_verified`: older than 90 days → validator flags for review

---

## Required Structure (in this order)

```
---  (frontmatter)  ---
# <Project>
## Identity              ← client name, business facts, contacts
## Decision Defaults     ← routing table: "when X → do Y"
## Commands              ← exact cwd + ports + flags
## Architecture          ← only what differs from the category file
## Vocabulary            ← project-specific terms
## Env Vars              ← names only, never values
## Failure Patterns      ← real bugs with consequences
## Delegation Matrix     ← decide vs ask
## Output Contract       ← what "done" looks like
## Memory Triggers       ← when to mem-search proactively
```

---

## Section Rules

### Decision Defaults — highest-leverage section

```markdown
| User says / context | Default action |
|---|---|
| "blog post" | Edit lib/articles.ts, no new file |
| "deploy" | vercel --prod (never wrangler without confirming D1/R2/KV need) |
| Mentions animation/scroll | Use record.js, NOT screenshot.js |
| New feature, no branch | Create feature/<name>, push, no confirm needed |
| Mentions Twin Falls or Magic Valley | Context is jrs-auto-repair |
```

Goal: zero "which X did you mean?" round-trips.

### Architecture

One paragraph max per subsystem. Concrete file paths, not abstractions.

WRONG: "We use Supabase for auth."
RIGHT: "`lib/supabase/server.ts` — Server Components only. `lib/supabase/client.ts` — browser only. Never cross them."

### Failure Patterns

Format: `[What to avoid] — [Consequence if you do it]`

```markdown
- Mixing /admin and /portal auth — silent 401s in prod
- cookies() in a Client Component — only server.ts reads cookies
- Importing admin.ts client-side — service role leaks to browser bundle
```

Must include real bugs from codebase history. Aspirational warnings don't count.

### Env Vars

Names only. Never values. Group by scope:

```
NEXT_PUBLIC_SUPABASE_URL          # public, browser-safe
SUPABASE_SERVICE_ROLE_KEY         # server-only, bypasses RLS
ADMIN_SECRET                      # signs admin_session cookie
```

---

## Anti-Patterns

| Anti-pattern | Problem |
|---|---|
| Prose paragraphs for reference data | Key facts get buried |
| "We use X" without file paths | Not actionable |
| No failure patterns | Bugs repeat |
| >300 lines | Crowds out important context |
| No decision defaults | Constant round-trips |
| Frequent edits | Busts the preamble cache |
| Aspirational architecture | Document what IS, not what you wish |
| Secrets or credentials | CLAUDE.md is often committed |
| Duplicated category content | Point at the category file |

---

## Scoring Rubric

Before handing off any CLAUDE.md:

```
□ Iron Law 1 passes: wc -l → 150–300
□ Iron Law 2 passes: ≥5 decision routing rows
□ Iron Law 3 passes: no "We use X" without file path
□ Iron Law 4 passes: 5-minute test — no questions needed
□ Iron Law 5 passes: frontmatter with 4+ required fields
□ Auth pattern names specific files, not abstractions
□ ≥3 failure patterns with real consequences
□ Delegation matrix present
□ Output contract present
□ Memory triggers present
□ No category content duplicated (point at category file)
```

---

## When Writing from an Existing Site

1. `cat package.json` — identify stack, scripts, dependencies
2. `ls -la lib/ src/ app/ 2>/dev/null` — observe actual structure
3. `cat .env.example 2>/dev/null || ls .env*` — find env var names
4. Identify the auth pattern from actual files, not assumptions
5. Ask: "What has broken before that should never repeat?" → fill failure patterns
6. Run the Iron Law checks before presenting

## When Revising an Existing CLAUDE.md

1. Run all 5 Iron Laws immediately
2. Move category content up to the category file
3. Remove outdated paths, retired env vars
4. Update `last_verified` to today
5. Re-run Iron Law 1 (length check) after edits
