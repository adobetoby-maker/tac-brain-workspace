---
name: gap-fill
version: 1.0.0
description: |
  Self-learning brain gap finder. Syncs AgentDB + git memory + PARA knowledge base,
  detects knowledge gaps across all three layers, researches them, and fills them back in.
  Finds 10 gaps per run, runs 3× daily via cron.
  Trigger: /gap-fill [domain?]
triggers:
  - /gap-fill
  - gap fill
  - find gaps
  - sync brain
  - brain sync
allowed-tools:
  - Bash
  - Read
  - Write
  - WebSearch
  - WebFetch
  - Agent
---

# /gap-fill — Self-Learning Brain Gap Finder

## Observable Trigger

```bash
# Check if this is a sync run or gap-fill run
ls ~/.claude/skills/gap-fill/data/gap-log.jsonl 2>/dev/null || echo "FIRST_RUN"
git -C ~/.claude/projects/-Users-drive/memory log --oneline -1 2>/dev/null
```

## Phase 0 — Sync Check (always runs first)

Find what hasn't been committed to memory from recent sessions:

```bash
# Check for uncommitted changes in memory repo
git -C ~/.claude/projects/-Users-drive/memory status --short

# Find sessions from today that aren't in git
git -C ~/.claude/projects/-Users-drive/memory log --since="24 hours ago" --oneline

# Check if knowledge-base has files newer than last AgentDB ingest
find ~/knowledge-base -name "*.md" -newer ~/.gstack/.last-agentdb-sync 2>/dev/null | head -20

# Find any memory files not yet in AgentDB
for f in ~/.claude/projects/-Users-drive/memory/*.md; do
  key=$(basename "$f" .md)
  result=$(mem-search "$key" 2>/dev/null | wc -l)
  [ "$result" -lt 3 ] && echo "MISSING: $key"
done
```

Write any unsaved session notes now. Then run:
```bash
cd ~/.claude/projects/-Users-drive/memory && git add -A && git commit -m "sync: gap-fill pass $(date +%Y-%m-%d-%H%M)" 2>/dev/null || echo "nothing to commit"
touch ~/.gstack/.last-agentdb-sync
```

## Phase 1 — Scan All Brain Layers

Run these extractions:

```bash
# 1a. Extract all referenced concepts (high mention count = important)
grep -rh --include="*.md" -oE '[A-Z][a-zA-Z]{4,}|/[a-zA-Z-]+/[a-zA-Z-]+' \
  ~/.claude/projects/-Users-drive/memory/ \
  ~/knowledge-base/ 2>/dev/null \
  | sort | uniq -c | sort -rn | head -80

# 1b. Find open loops (TODOs never resolved)
grep -rh "TODO\|PENDING\|BLOCKING\|not yet deployed\|need to\|will add\|pending:" \
  ~/.claude/projects/-Users-drive/memory/*.md \
  ~/knowledge-base/2-areas/**/*.md 2>/dev/null | head -30

# 1c. Find orphan resources (knowledge-base files with no cross-references)
for f in ~/knowledge-base/3-resources/**/*.md 2>/dev/null; do
  name=$(basename "$f" .md)
  refs=$(grep -rl "$name" ~/knowledge-base/2-areas/ 2>/dev/null | wc -l)
  [ "$refs" -eq 0 ] && echo "ORPHAN: $f"
done

# 1d. Check email senders for professional/research value
ls ~/.claude/projects/-Users-drive/memory/email_sender_*.md \
  | sed 's/.*email_sender_//' | sed 's/\.md//' \
  | grep -iE "jbjs|lippincott|medpage|ems-world|claude|anthropic|vercel|cloudflare|railway"
```

## Phase 2 — Score and Rank Gaps

For each candidate gap, compute score:

```
score = (mention_count × 2) + (cross_project_refs × 3) + (days_stale × 0.3) + (is_open_loop × 5)
```

Gap types and their base scores:
- REFERENCE: term mentioned 5+ times, no dedicated entry → score + 8
- STALENESS: entry > 30 days old in fast-moving domain → score + 4  
- ORPHAN: resource with zero area connections → score + 3
- OPEN_LOOP: TODO/PENDING never resolved → score + 10
- CONTRADICTION: two entries conflict → score + 6, flag for human review
- COVERAGE: domain used in 3+ projects, no resource doc → score + 7

**Print top 10 ranked gaps. Do not proceed without printing this list.**

Format:
```
GAP #1 [OPEN_LOOP] "Deploy DEX contracts to chain 7282" — score: 23
  Source: memory/now.md, memory/project_dex_phase2.md
  Last seen: 2026-06-02
  
GAP #2 [COVERAGE] "Supabase RLS patterns" — score: 19
  Referenced in: 6 projects
  No resource doc exists
...
```

## Phase 3 — Research Each Gap

For each gap in the top 10:

### Simple gaps (definition, quick fact):
```
WebSearch: "[gap topic] 2026 guide"
WebFetch: first relevant result
→ Write 1-page summary to ~/knowledge-base/3-resources/[domain]/[topic].md
```

### Complex gaps (architecture, current state, deep docs):
```
jr "research: [gap topic]
   Context: I'm a developer/physician building AI apps.
   Return:
   - 2-paragraph summary of current state
   - 5 key facts or best practices
   - 3 source URLs
   - How this connects to: [related topics in my memory]"
```

### Codebase gaps (what does X do / where is it):
```
Agent(subagent_type="Explore"):
  "Find all references to [term] across /Users/drive/
   What is it, where defined, what depends on it?
   Return file paths + 1-para explanation."
```

### Email-sourced gaps:
```
Read relevant email_sender_*.md files
Extract: what professional updates did I receive that I haven't acted on?
Cross-ref against knowledge-base: what's missing?
```

### Gap sources priority order:
1. Email senders: jbjs.md, lippincott-journals-etoc.md, medpage-today.md, ems-world.md (orthopedic surgery / medical)
2. Email senders: vercel.md, cloudflare.md, railway.md, linkedin.md (tech stack updates)
3. Web searches: "Toby Anderton orthopedic surgeon Twin Falls", "tobyandertonmd.com"
4. Web searches: "Claude Code new skills 2026", "Anthropic new features June 2026"
5. Karpathy resources: llm-wiki.md, writing-on-LLMs
6. Open loops from memory (TODOs, PENDING, BLOCKING items)


## KB Hygiene Guards

Applied automatically by immunization loop. See `~/.claude/skills/gap-heal/data/error-patterns.md` for full patterns.

**Before writing any new KB entry, verify all 7 guards:**

| Guard | Rule |
|---|---|
| G-01 | Include `last-verified: 2026-06-06` in every entry |
| G-02 | Include `trust-score: 0.70` in every entry |
| G-03 | `related:` uses bare slugs only — no path prefixes (`family/`, `medical/`, etc.) |
| G-04 | Source URL must return 200 — avoid Stryker product-specific pages (redirect frequently) |
| G-05 | Canonical zone ID: `72470c7d604a63c4322e4ed317db2d84` |
| G-06 | All 8 frontmatter fields required: topic, type, filled, source, confidence, related, trust-score, last-verified |
| G-07 | Never write KB frontmatter to `2-areas/clients/` brief files |

**Canonical entry template:** `~/.claude/skills/gap-heal/data/error-patterns.md#canonical-kb-entry-template`


## Phase 4 — Write Filled Entries

For each gap researched, write a structured file:

```markdown
---
topic: [name]
type: [reference|coverage|staleness|open_loop|orphan|contradiction]
filled: [YYYY-MM-DD]
source: [URL or "memory:file" or "email:sender"]
confidence: high|medium|low
related: [comma-separated topics]
---
# [Topic Name]

[2–3 paragraph summary of what this is and why it matters in this context]

## Key Facts
- [fact 1]
- [fact 2]
- [fact 3]

## Connection Points
- Connects to: [project or area] via [relationship]
- Referenced by: [memory files that mention this]
- Next action: [if open_loop — what to do]
```

Save to: `~/knowledge-base/3-resources/[domain]/[topic].md`

Then ingest:
```bash
para-ingest ~/knowledge-base/3-resources/[domain]/[topic].md
mem-store "gap:[topic]" "[1-line summary]" knowledge-base
```

## Phase 5 — Log and Report

```bash
echo "{\"date\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"run_type\":\"scheduled\",\"gaps_found\":10,\"gaps_filled\":[n],\"gaps_deferred\":[n]}" \
  >> ~/.claude/skills/gap-fill/data/gap-log.jsonl

# Update memory with what was learned
cat >> ~/.claude/projects/-Users-drive/memory/now.md << 'EOF'

## Gap Fill Run — $(date '+%H:%M')
[list filled gaps and 1-line summary of each]
EOF
```

Print summary:
```
╔══════════════════════════════════════════════════════╗
║  GAP FILL — $(date '+%Y-%m-%d %H:%M')               ║
╠══════════════════════════════════════════════════════╣
║  Synced: git + AgentDB + PARA                        ║
║  Gaps found: 10                                      ║
║  ✅ Filled: [n] gaps                                 ║
║  ⏳ Deferred: [n] (needs human / too large)          ║
║  ⚠️  Contradictions: [n] (flagged for review)        ║
╚══════════════════════════════════════════════════════╝

Filled:
  1. [topic] → ~/knowledge-base/3-resources/[path]
  2. ...

Deferred:
  - [topic]: [reason]
```

## Phase 6 — Heal Pass (always runs after Phase 5)

After logging, immediately run gap-heal to fix any errors introduced this pass:

```bash
bash ~/.claude/skills/gap-heal/bin/run-heal-pipeline.sh
```

This catches broken related: links, missing trust-scores, and dead source URLs introduced by the fill pass. Takes ~90s. The Kaizen loop: fill fast → heal immediately.

## Exit Criteria

Run is complete when:
1. `git -C ~/.claude/projects/-Users-drive/memory log --oneline -1` shows a new commit
2. `~/.claude/skills/gap-fill/data/gap-log.jsonl` has a new entry with today's date
3. At least 5 new files exist in `~/knowledge-base/3-resources/`
4. `mem-search "gap:[any filled topic]"` returns results

## Cron Schedule

Runs 3× daily:
- 8:00 AM — morning sync + 10 gaps (full run)
- 1:00 PM — midday pass (focus: email + tech updates)
- 7:00 PM — evening pass (focus: medical/surgery + open loops)
