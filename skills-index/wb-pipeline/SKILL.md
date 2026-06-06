---
name: wb-pipeline
description: "Worker-Bee pipeline agent router. Invokes individual build phase agents: /wb-researcher, /wb-provisioner, /wb-builder, /wb-visual-qa, /wb-designer, /wb-qa-gate, /wb-deployer. Use when building a new client site or running a specific phase independently."
risk: safe
source: manage-worker-bee (internal)
date_added: 2026-05-28
---

# Worker-Bee Pipeline Agents

The WB build pipeline is broken into 7 individual agents. Each can run independently or chained automatically.

## Pipeline Stages

| # | Agent | Skill | Model | Time | Purpose |
|---|-------|-------|-------|------|---------|
| 1 | Researcher | `/wb-researcher` | sonnet | ~8m | Find real assets, headshots, bio, benchmarks |
| 2 | Provisioner | `/wb-provisioner` | haiku | ~5m | Create repo, scaffold, wire Vercel |
| 3 | Builder | `/wb-builder` | sonnet | ~25m | Implement all blueprint cards |
| 4 | Visual QA | `/wb-visual-qa` | sonnet | ~8m | Screenshot, scroll, fix layout bugs |
| 5 | Designer | `/wb-designer` | sonnet | ~15m | Elevate design above production floor |
| 6 | QA Gate | `/wb-qa-gate` | sonnet | ~20m | Four-pass review (code/functional/visual/mobile) |
| 7 | Deployer | `/wb-deployer` | haiku | ~5m | Deploy, seed accounts, report back |

## Full Pipeline Run

To run all phases in sequence for a site:
```bash
jr "Run the full WB pipeline for <site name>. Site type: <type>. Stack: nextjs. Local path: /Users/drive/<slug>. GitHub: adobetoby-maker/<slug>. Domain: <slug>.worker-bee.app. Start with the researcher and chain through all 7 agents."
```

## Visual Agent Graph

The pipeline is also available as a visual Dify-style graph in manage.worker-bee.app → Sites → [site] → Build → Agents tab. Each agent appears as an XyFlow node. Click "Dispatch" to generate and copy the agent prompt.

## Individual Agent Invocation

When you only need to re-run one phase:
```bash
# Re-research without rebuilding
/wb-researcher

# Re-deploy after a hotfix
/wb-deployer
```

## Context Variables (required for all agents)

- `siteName` — client's business name
- `siteType` — medical / legal / local-service / restaurant / saas / ecommerce / agency / real-estate / general
- `stack` — nextjs / vite / wordpress / general
- `localPath` — absolute path on build machine
- `githubRepo` — adobetoby-maker/slug
- `domain` — slug.worker-bee.app or custom domain
- `subjectName` — the person/business being featured (may differ from siteName)
- `referenceUrls` — comma-separated list of competitor/reference sites to benchmark against
- `buildMode` — new / iteration

## Output Artifacts per Agent

| Agent | Primary Output |
|-------|---------------|
| Researcher | `/tmp/research-brief-<slug>.json` |
| Provisioner | Git repo + Vercel project |
| Builder | All component files, committed |
| Visual QA | `/tmp/wb-qa-desktop.png`, `/tmp/wb-qa-mobile.png` |
| Designer | Design elevation commit |
| QA Gate | Fix commits (4 passes) |
| Deployer | Live URL + blueprint update |

## When to Use

- User says "build [site name]" — run full pipeline
- User says "re-run research for [site]" — `/wb-researcher` only
- User says "just deploy it" — `/wb-deployer` only
- User says "fix the visual issues" — `/wb-visual-qa` only
- User says "run the qa pass" — `/wb-qa-gate` only
