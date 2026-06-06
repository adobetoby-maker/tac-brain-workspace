---
name: gap-heal
version: 2.0.0
description: |
  Zero-trust knowledge healing. Runs after every gap-fill pass.
  Detects structural errors, computes trust-scores, fixes broken links,
  detects contradictions, flags stale entries, and immunizes gap-fill
  against known error patterns. Full 5-phase pipeline, ~2.5 min.
  Trigger: /gap-heal
triggers:
  - /gap-heal
  - run gap-heal
  - heal the knowledge base
  - fix broken kb links
  - trust score check
  - contradiction check
  - kb staleness
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
---

# gap-heal — Knowledge Healing Skill

## When This Fires

After every gap-fill cron pass (called from gap-fill Phase 6). Also manually via `/gap-heal`.

## Full Pipeline (5 phases, ~2.5 min total)

### Phase 1 — Structural Lint (~30s)
```bash
bash ~/.claude/skills/gap-heal/bin/structural-lint.sh
# Output: /tmp/heal-lint-results.json
```
Detects: broken related links, missing fields, malformed dates, duplicate slugs, missing trust-score/last-verified.

### Phase 2 — Trust Scoring + Apply (~60s)
```bash
grep -rh "^topic:" ~/knowledge-base/3-resources/ ~/knowledge-base/2-areas/ \
  | sed 's/^topic: *//' | sort -u > /tmp/heal-slug-registry.txt

python3 ~/.claude/skills/gap-heal/bin/trust-scorer.py ~/knowledge-base
# Output: /tmp/heal-trust-scores.json

bash ~/.claude/skills/gap-heal/bin/heal-apply.sh
# Output: ~/.claude/skills/gap-heal/data/heal-log.jsonl
```
Scores every KB entry 0.0–1.0. Heals: path-prefix broken refs, malformed dates, missing trust-score + last-verified fields.

### Phase 3 — Source Verification (~30s, skipped if >15 new entries)
```bash
python3 ~/.claude/skills/gap-heal/bin/source-verifier.py ~/knowledge-base
# Output: /tmp/heal-source-results.json
```
Parallel HEAD checks (8 threads, 8s timeout). 403 = bot-blocked (counts as active). Applies -0.15 trust penalty for confirmed dead URLs (404/410).

### Phase 4a — Contradiction Detection (~10s)
```bash
python3 ~/.claude/skills/gap-heal/bin/contradiction-finder.py ~/knowledge-base
# Output: /tmp/heal-contradictions.json
#         ~/.claude/skills/gap-heal/reports/YYYY-MM-DD-contradictions.md
```
Extracts 22 regex-based structured facts (NPI, zone ID, parser count, prices, versions). Multi-value whitelist suppresses false positives for multi-valued attributes (Mako TKA+THA, Toby hip+knee+shoulder).

### Phase 4b — Staleness Cron (~10s)
```bash
python3 ~/.claude/skills/gap-heal/bin/staleness-cron.py ~/knowledge-base
# Output: /tmp/heal-staleness-report.json
#         ~/.claude/skills/gap-heal/data/staleness-gaps.json (gap-fill seed)
```
Domain-aware shelf lives: tech-stack 90d, medical 365d, research 270d, people 730d, etc. Applies scaled staleness penalties. Writes gap seeds for overdue entries so gap-fill picks them up next run.

### Phase 5 — Immunization Loop (~10s)
```bash
python3 ~/.claude/skills/gap-heal/bin/immunization-loop.py
# Output: ~/.claude/skills/gap-heal/data/error-patterns.md
#         ~/.claude/skills/gap-heal/data/immunization.json
#         (patches gap-fill SKILL.md with KB Hygiene Guards section)
```
Harvests recurring error patterns from all heal runs. Writes 7 guards into gap-fill's SKILL.md so new entries are written correctly from the start. Kaizen: detect → document → prevent.

## Quick Run (full pipeline)
```bash
bash ~/.claude/skills/gap-heal/bin/run-heal-pipeline.sh
```

## Outputs

| File | Purpose |
|---|---|
| `~/.claude/skills/gap-heal/data/heal-log.jsonl` | Audit trail — every run ever |
| `~/.claude/skills/gap-heal/reports/YYYY-MM-DD-heal-report.md` | Structural heal report |
| `~/.claude/skills/gap-heal/reports/YYYY-MM-DD-contradictions.md` | Contradiction report |
| `~/.claude/skills/gap-heal/reports/YYYY-MM-DD-staleness.md` | Staleness report |
| `~/.claude/skills/gap-heal/data/error-patterns.md` | Human-readable guard list |
| `~/.claude/skills/gap-heal/data/immunization.json` | Machine-readable pattern index |
| `~/.claude/skills/gap-heal/data/staleness-gaps.json` | Overdue entries → gap-fill seed |
| `~/.claude/skills/gap-heal/data/quarantine.md` | Entries below trust threshold |
| `/tmp/heal-lint-results.json` | Current lint results |
| `/tmp/heal-trust-scores.json` | Current trust scores |
| `/tmp/heal-contradictions.json` | Current contradiction scan |
| `/tmp/heal-staleness-report.json` | Current staleness scan |

## Trust Score Thresholds

| Score | Status | Action |
|---|---|---|
| 0.80+ | verified | Use as-is |
| 0.60–0.79 | accepted | Minor verification suggested |
| 0.40–0.59 | provisional | Re-research before acting on |
| < 0.40 | quarantined | Do not use; flag for human review |

## Multi-Value Whitelist (not contradictions)

| Entity | Allowed values | Reason |
|---|---|---|
| `stryker_mako` | tka, tha, smartrobotics | Mako platform covers both knee and hip |
| `toby_specialty` | hip, knee, shoulder | Toby practices all three joints |
| `toby_hospital` | North Canyon, NCMC, St. Luke's Magic Valley | Dual affiliation (primary + secondary) |
| `next_version` | any | Multiple projects at different Next.js versions |

## Shelf Lives by Domain

| Domain | Shelf | Rationale |
|---|---|---|
| tech-stack, api, cloudflare, vercel | 90d | Fast-moving APIs and platform changes |
| project, saas, product, pricing | 180d | Product pivots and pricing changes |
| research, literature, journal | 270d | Quarterly publication cycles |
| medical, orthopedic, clinical | 365d | Annual guideline updates |
| pattern, reference, general | 540d | Relatively stable |
| person, identity, physician | 730d | Stable biographical facts |

## Architecture

```
~/.claude/skills/gap-heal/
├── SKILL.md               ← this file (v2.0.0)
├── PRD.md
├── bin/
│   ├── run-heal-pipeline.sh     ← orchestrator (all 5 phases)
│   ├── structural-lint.sh       ← Phase 1
│   ├── trust-scorer.py          ← Phase 2a
│   ├── heal-apply.sh            ← Phase 2b
│   ├── source-verifier.py       ← Phase 3
│   ├── contradiction-finder.py  ← Phase 4a
│   ├── staleness-cron.py        ← Phase 4b
│   └── immunization-loop.py     ← Phase 5
├── data/
│   ├── heal-log.jsonl           ← audit trail
│   ├── quarantine.md            ← low-trust entries
│   ├── staleness-gaps.json      ← gap-fill seed for overdue entries
│   ├── error-patterns.md        ← guard documentation
│   └── immunization.json        ← machine-readable pattern index
└── reports/
    ├── YYYY-MM-DD-heal-report.md
    ├── YYYY-MM-DD-contradictions.md
    └── YYYY-MM-DD-staleness.md
```

## Kaizen Loop

```
gap-fill (Phase 1–5) → writes new KB entries
  ↓
gap-fill Phase 6 → calls run-heal-pipeline.sh
  ↓
Phase 1–2: structural + trust → fix immediately
Phase 3: source verify → penalize dead URLs
Phase 4a: contradiction → flag divergent facts
Phase 4b: staleness → penalize aging entries, seed overdue list
Phase 5: immunization → patch gap-fill guards
  ↓
next gap-fill run uses updated guards → fewer errors introduced
  ↓
(repeat — tightening loop)
```
