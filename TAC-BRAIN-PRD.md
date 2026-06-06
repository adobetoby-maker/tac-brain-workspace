# TAC Brain — System Architecture & PRD
### Toby Anderton's AI Development Workspace

> **Version:** 2.0 — June 2026  
> **Author:** Toby Anderton (Drive)  
> **Machine:** M1 Ultra, macOS  
> **Purpose:** Complete reference for how the AI memory, skills, plugins, hooks, agents, and Obsidian vault work together as one system.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [The Agent Ecosystem](#2-the-agent-ecosystem)
3. [Memory Architecture (Five Layers)](#3-memory-architecture-five-layers)
4. [Obsidian Vault Integration](#4-obsidian-vault-integration)
5. [Skills System (1,560 skills)](#5-skills-system)
6. [Plugins & Marketplaces](#6-plugins--marketplaces)
7. [Hooks — Behavioural Enforcement](#7-hooks--behavioural-enforcement)
8. [Rules — Iron Laws](#8-rules--iron-laws)
9. [MCP Servers](#9-mcp-servers)
10. [Bootstrap Chain](#10-bootstrap-chain)
11. [Data Flow Diagrams](#11-data-flow-diagrams)
12. [PARA Knowledge Base](#12-para-knowledge-base)
13. [How It All Connects — A Session Walkthrough](#13-how-it-all-connects)
14. [File Map](#14-file-map)

---

## 1. System Overview

The TAC Brain is a **multi-agent AI workspace** built on top of Claude Code. It transforms a standard AI coding assistant into a persistent, context-aware, self-enforcing development OS.

### Core Design Principles

| Principle | Implementation |
|---|---|
| **Memory persists across sessions** | Five-layer memory (flat files, AgentDB, Obsidian, PARA, claude-mem) |
| **Behaviour enforced, not reminded** | Hooks fire on observable state, not on intent |
| **Skills selected automatically** | Skill-self-selection rule + Skill tool invocation before any response |
| **Agents routed by cost** | Haiku for mechanical work, Sonnet for architecture, Opus for strategy |
| **Vault is ground truth** | Obsidian vault (iCloud-synced) is the single source of human + AI knowledge |

### The System in One Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                       TOBY'S AI WORKSPACE                            │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                     SESSION LAYER                            │    │
│  │  Claude Code (TAC)   ←──── SOUL.md (identity + character)   │    │
│  │  /tac bootstrap      ←──── session-start.sh                 │    │
│  │  1,560 Skills        ←──── ~/.claude/skills/                │    │
│  │  13 Rules (Iron Laws)←──── ~/.claude/rules/                 │    │
│  │  10 Hooks            ←──── ~/.claude/hooks.json             │    │
│  └──────────────────┬──────────────────────────────────────────┘    │
│                     │ reads/writes                                    │
│  ┌──────────────────▼──────────────────────────────────────────┐    │
│  │                     MEMORY LAYER                             │    │
│  │  L1: Flat files   ~/.claude/projects/.../memory/*.md         │    │
│  │  L2: AgentDB      ~/.claude/memory/agentdb.rvf (HNSW)        │    │
│  │  L3: Obsidian     iCloud → second brain/ (vault)             │    │
│  │  L4: PARA KB      ~/knowledge-base/ (_index 1,530 files)     │    │
│  │  L5: claude-mem   ~/.claude-mem/*.db (SQLite FTS5)           │    │
│  └──────────────────┬──────────────────────────────────────────┘    │
│                     │ shared memory                                   │
│  ┌──────────────────▼──────────────────────────────────────────┐    │
│  │                    AGENT LAYER                               │    │
│  │  wba (worker-bee-agent)  — Max OAuth daemon, background      │    │
│  │  Hermes Jr               — full profile agent, cron          │    │
│  │  SiteManager             — orthobiologic site + LBS          │    │
│  └─────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 2. The Agent Ecosystem

### Agent 1 — Claude Code (TAC / Drive)

The primary session agent. Runs in the terminal or IDE. All other agents are orchestrated from here.

```
Identity:    ~/.claude/SOUL.md
Bootstrap:   /tac skill → session-start.sh
Model:       claude-sonnet-4-6 (default) | claude-opus-4-8 (strategy)
Memory:      ~/.claude/projects/-Users-drive/memory/ (git-backed)
Skills:      ~/.claude/skills/ (1,560 installed)
Rules:       ~/.claude/rules/ (13 Iron Law files)
```

**What TAC does:**
- Writes, edits, deploys code
- Orchestrates subagents via Agent tool
- Reads/writes memory to all 5 layers
- Routes work to Hermes Jr or wba when tasks should persist beyond the session

---

### Agent 2 — worker-bee-agent (wba)

A lightweight daemon that uses the `claude -p` CLI (Max OAuth) so it runs at zero API cost.

```
Binary:      wba
Daemon:      ~/.worker-bee/daemon.py
Model:       claude-sonnet-4-6 | claude-haiku-4-5 (forced with -m haiku)
Auth:        Max OAuth via Claude Code CLI (same Keychain token)
Queue:       ~/.worker-bee/tasks/
Logs:        ~/.worker-bee/logs/
Cron:        ~/.worker-bee/cron/jobs.json
```

| Command | What it does |
|---|---|
| `wba "task"` | Inline execution — runs now, blocks, prints result |
| `wba -b "task"` | Background dispatch to daemon |
| `wba -s skill-name "task"` | Load skill context before task |
| `wba -m haiku "task"` | Force Haiku model (cheap mechanical work) |
| `wba -n "task"` | Notify via iMessage when done |
| `wba start / stop / status` | Daemon lifecycle |

---

### Agent 3 — Hermes Jr

Full Hermes interface powered by `claude -p`. Supports profiles, SOULs, skills injection.

```
Binary:      hermes-jr (also aliased as jr)
Identity:    ~/.hermes-jr/SOUL.md
Profiles:    ~/.hermes-jr/profiles/
Repo:        ~/hermes-jr-agent/
Model:       claude-sonnet-4-6 via Max OAuth
```

| Command | What it does |
|---|---|
| `jr "task"` | One-shot synchronous — output injected into TAC session |
| `jr -p teacher "task"` | One-shot with personality profile |
| `hermes-jr --profile claude -z "task"` | Full Hermes interface |
| `hermes-jr --profile sitemanager -z "task"` | SiteManager persona |

> **Critical distinction:** Use `Bash(timeout=600000)` + `jr "task"` when TAC must act on the output. Use `Bash(run_in_background=True)` only for fire-and-forget. `run_in_background=True` means TAC never sees the result.

---

### Agent 4 — SiteManager

Specialised Hermes profile for the Orthobiologic Pathways site and LBS Pro inventory.

```
Profile:     hermes --profile sitemanager
Sites:       orthobiologicpathways.com + LBS Pro inventory
Trigger:     any mention of "sitemanager" or orthobiologic site
```

---

### Model Routing Decision Tree

```
Is the task mechanical? (rename, curl, cp, git commit, npm install)
  → YES → Haiku (claude-haiku-4-5) — ~1/10 the cost
  → NO  → Is it architecture / debugging / multi-file reasoning?
           → YES → Sonnet (claude-sonnet-4-6) — default
           → NO  → Is it high-stakes product/strategy decision?
                   → YES → Opus (claude-opus-4-8) — use sparingly
```

---

## 3. Memory Architecture (Five Layers)

The system uses five distinct memory layers, each with different scope, persistence, and retrieval method.

### Layer 1 — Flat-File Memory (Primary, Git-Backed)

```
Location:   ~/.claude/projects/-Users-drive/memory/
Format:     *.md files (one topic per file)
Sync:       GitHub (auto-push on session end via memory-writeback.sh)
Access:     Read tool | mem-search | mem-store | mem-get
```

The flat-file store is the simplest and most reliable layer. Every key fact gets a named `.md` file. The `memory-writeback.sh` hook auto-pushes after every session so it's available from any machine.

**Memory management commands:**
```bash
mem-search "your query"       # semantic search across all history
mem-store KEY "value" [ns]    # store a note
mem-get KEY [ns]              # retrieve by exact key
mem-list [ns]                 # list recent entries
```

---

### Layer 2 — AgentDB / RuVector (Semantic Search)

```
Location:   ~/.claude/memory/agentdb.rvf
Technology: HNSW (Hierarchical Navigable Small Worlds) vector index
Bridge:     ~/.claude/bootstrap/ruflo-bridge.sh
Sync:       ruflo sync command re-syncs from GitHub → AgentDB
Access:     claude-flow memory search | mem-search MCP tool
```

The ruflo-bridge script reads every `.md` in the flat-file store and upserts it into the AgentDB HNSW index. This enables semantic similarity search — you can find notes by meaning rather than exact key match.

**Sync flow:**
```
Flat files (*.md)
  → ruflo-bridge.sh
    → claude-flow memory store --namespace claude-memories
      → AgentDB HNSW index
        → mem-search returns semantically ranked results
```

---

### Layer 3 — Obsidian Vault (Human + AI Knowledge)

```
Location:   ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/second brain/
Sync:       iCloud (real-time, available on iPhone/iPad/Mac)
Access:     Direct Read tool | session-start.sh bridge
Format:     Markdown with YAML frontmatter, wikilinks [[like this]]
```

The vault is the only layer that humans write directly. It is also written by Claude during sessions. Every vault note follows the AI-first format from `_CLAUDE.md`:

- **Self-contained** — each note explains itself without surrounding context
- **"For future Claude" preamble** — 2–3 sentence summary at the top of every note
- **Rich frontmatter** — `type`, `date`, `tags`, `ai-first: true`
- **Wikilinks mandatory** — every person, project, concept uses `[[wikilinks]]`

**Key vault files:**
| File | Purpose |
|---|---|
| `_CLAUDE.md` | Claude operating manual — read this first every session |
| `index.md` | Master catalog of all notes (auto-updated by Claude) |
| `CRITICAL_FACTS.md` | Facts that must never be re-derived from scratch |
| `Daily/YYYY-MM-DD.md` | One note per day |
| `Projects/*.md` | One note per active project |
| `Clients/*.md` | One note per client |
| `Dev Logs/*.md` | Technical session logs |
| `Memory/` | Bridge folder — mirrors flat-file memory into vault |

**How the session-start.sh loads the vault:**
```bash
VAULT="/Users/drive/Library/Mobile Documents/iCloud~md~obsidian/Documents/second brain"
# 1. Read _CLAUDE.md for operating instructions
# 2. Read index.md for project catalog
# 3. Check CRITICAL_FACTS.md
# 4. Bridge new memory from ~/.remember/ → vault Memory folder
```

---

### Layer 4 — PARA Knowledge Base

```
Location:   ~/knowledge-base/
Structure:  PARA (Projects / Areas / Resources / Archives)
Index:      ~/knowledge-base/_index/ (~1,530 files across 14 folders)
Ingest:     para-ingest <file|url> [--area|--project|--resource]
```

The PARA KB is a model-agnostic knowledge system. It works with Claude Code, local models (Llama/DeepSeek/Qwen), or any RAG system.

**_index folder structure (14 categories, ~1,530 files):**

| Folder | Files | Purpose |
|---|---|---|
| `00-principles/` | ~80 | Universal rules — loaded every session |
| `01-skills/` | ~250 | When/how/why for each installed skill |
| `02-skills-disambig/` | ~100 | "Use X not Y when..." prevents wrong skill selection |
| `03-plugins/` | ~93 | One per plugin — what it provides, how to activate |
| `04-mcp-tools/` | ~180 | MCP tool params, response shapes, failure modes |
| `05-patterns/` | ~300 | Deep technical knowledge (Next.js, Supabase, CF, TS) |
| `06-failures/` | ~150 | Documented bugs → exact fixes |
| `07-projects/` | ~80 | Project-specific architecture |
| `08-agents/` | ~100 | Agent types, orchestration patterns |
| `09-seo-content/` | ~100 | SEO patterns, content rules |
| `10-review-qa/` | ~80 | Checklists, pre-deploy gates |
| `11-overnight-batch/` | ~80 | Autonomous session patterns |
| `12-local-model/` | ~60 | Local model constraints and tuning |
| `13-stack-bundles/` | ~47 | Pre-merged context for common task types |

**Ingest pipeline:**
```
Any file  ──markitdown──→ Markdown ──→ PARA folder ──→ AgentDB (HNSW) ──→ mem-search
PDF       ──MinerU──────→ Markdown ─┘
URL       ──markitdown──→ Markdown ─┘
```

---

### Layer 5 — claude-mem (SQLite FTS5)

```
Location:   ~/.claude-mem/*.db
Technology: SQLite with Full-Text Search (FTS5)
Backup:     ~/.claude/projects/.../memory/claude-mem-backup.sql (auto on Stop)
Access:     MCP tool mcp__plugin_claude-mem_mcp-search__*
```

Used for high-frequency semantic search and memory retrieval via the MCP tool interface. The Stop hook auto-dumps the SQLite database to SQL so it's included in the git-backed memory.

---

### Memory Write-Back (Automatic)

Every Claude session end triggers `memory-writeback.sh`:

```
1. Update ~/.remember/now.md from latest today-*.md session file
2. Run memory-sync.sh → timestamp + count files
3. Dump claude-mem SQLite → memory/claude-mem-backup.sql
4. git add + commit + push → GitHub memory repo
```

This means memory is always current on GitHub, readable from any machine or agent.

---

## 4. Obsidian Vault Integration

The vault is not just a notes app — it is the **human layer of the AI memory system**.

### Write Paths

| Writer | What they write | Where |
|---|---|---|
| **Toby (human)** | Daily notes, client notes, decisions | `Daily/`, `Clients/`, `Projects/` |
| **Claude (TAC)** | Dev logs, session notes, tech decisions | `Dev Logs/`, `Memory/` |
| **session-start.sh** | Loads vault into every session context | Reads only |

### Read Paths

| Reader | How they access | When |
|---|---|---|
| **TAC (Claude Code)** | Read tool on vault files | Any session |
| **session-start.sh** | Reads `_CLAUDE.md`, `index.md`, `CRITICAL_FACTS.md` | Every session start |
| **mem-search** | Queries AgentDB (which is seeded from vault via bridge) | Any time |
| **Hermes Jr** | Same Read tool on vault files | Background tasks |

### AI-First Note Format

Every note Claude writes follows this template:

```markdown
---
type: dev-log
date: 2026-06-06
tags: [project-name, technology, relevant-topic]
ai-first: true
project: salvorias-marketplace
---

## For future Claude
One paragraph explaining what this note is about, why it matters, and what questions it answers. Written so Claude can decide relevance in 10 seconds without reading the full note.

## Content

[full note body with wikilinks, sources, confidence markers]

## Related
- [[Project Name]]
- [[Client Name]]
- [[Decision Log]]
```

### iCloud Sync = Cross-Device Memory

The vault lives in iCloud. This means:
- Notes written on iPhone sync to Mac within seconds
- TAC reads the same vault on any Mac
- Hermes Jr reads the vault via the same path
- Human-written notes are immediately available to all agents

---

## 5. Skills System

### Scale

**1,560 skills** installed in `~/.claude/skills/`. Each skill is a directory with a `SKILL.md` file.

### How Skills Work

1. User types `/skill-name` OR the skill-self-selection rule fires automatically
2. The `Skill` tool loads the `SKILL.md` content into the session context
3. Claude follows the skill's instructions exactly for the duration of the task

```
User message → skill-invocation-order rule fires → check skill map
→ Skill tool invoked → SKILL.md loaded → task executed with skill guidance
```

### Skill Categories

| Category | Count | Examples |
|---|---|---|
| **Frontend / Next.js** | ~80 | `nextjs-best-practices`, `nextjs-app-router-patterns`, `nextjs-supabase-auth`, `react-best-practices` |
| **UI/Design** | ~120 | `ui-ux-pro-max`, `tailwind-patterns`, `tailwind-design-system`, `shadcn`, `landing-page-generator` |
| **SEO & Content** | ~200 | `seo-audit`, `seo-aeo-blog-writer`, `seo-keyword-strategist`, `content-strategy`, `copywriting` |
| **Platform** | ~60 | `supabase-automation`, `cloudflare-workers-expert`, `vercel-ai-sdk-expert`, `vercel-deployment` |
| **Agents & Orchestration** | ~40 | `multi-agent-patterns`, `parallel-agents`, `dispatching-parallel-agents`, `agent-memory-systems` |
| **Architecture** | ~30 | `brainstorming`, `writing-plans`, `autoplan`, `production-code-audit`, `investigate` |
| **3D / Animation** | ~20 | `threejs-skills`, `threejs-shaders`, `animejs-animation`, `3d-web-experience` |
| **Testing** | ~30 | `testing-patterns`, `e2e-testing-patterns`, `playwright-skill` |
| **Database** | ~20 | `database-design`, `postgresql-optimization`, `database-migrations-sql-migrations` |
| **Session Mgmt** | ~10 | `tac`, `tac-hermes`, `context-save`, `graphify` |
| **Domain-specific** | ~950 | Security, marketing, CRM, language learning, finance, medical, legal, etc. |

### Flagship Skills

**`/tac`** — Session bootstrap. Every session starts here:
- Syncs memory from GitHub
- Bridges flat files → AgentDB
- Shows active projects + model routing guide
- Displays skills menu
- Checks Hermes / Hermes Jr / local model status
- Loads project todos

**`/ui-ux-pro-max`** — Design intelligence system:
- Runs before ANY UI code is written
- Generates colour tokens, typography, layout patterns
- Scripts in `~/.claude/skills/ui-ux-pro-max/scripts/` (search.py, design_system.py)
- Queries 1,530-file knowledge base for design patterns by domain

**`/brainstorming`** — Pre-planning gate:
- Fires before entering plan mode
- Generates multiple approaches before committing
- Required before any new architecture decision

**`/graphify`** — Converts any input to a knowledge graph in Obsidian

**`/production-code-audit`** — Deep codebase scan for bugs, security issues, patterns

### Skill Selection is Mandatory

The `skill-invocation-order.md` rule enforces: **invoke matching skill BEFORE any response or action.**

```
Observable check: Am I about to type a response without invoking a skill first?
YES → STOP → check skill map → invoke skill → then respond
```

The "red flag" patterns that signal a skill is being skipped:
- "This is just a simple question"
- "I need more context first"
- "I know how to do this already"
- "The skill is overkill"

All of these are rationalizations. If a skill exists and the task matches, it fires.

---

## 6. Plugins & Marketplaces

### Installed Marketplaces

| Marketplace | Location | What it provides |
|---|---|---|
| **ruflo** | `~/.claude/plugins/marketplaces/ruflo/` | 30+ Ruflo AI agent plugins |
| **claude-plugins-official** | `~/.claude/plugins/marketplaces/claude-plugins-official/` | Official Claude Code plugins |
| **claude-design-skillstack** | `~/.claude/plugins/marketplaces/claude-design-skillstack/` | Design-focused skills |
| **comfyui-mcp** | `~/.claude/plugins/marketplaces/comfyui-mcp/` | ComfyUI MCP integration |
| **thedotmack** | `~/.claude/plugins/marketplaces/thedotmack/` | Third-party community plugins |

### Ruflo Plugins (30 plugins from NousResearch/ruflo)

The Ruflo plugin suite provides AI-native tools for enterprise-grade agent workflows:

| Plugin | Purpose |
|---|---|
| `ruflo-adr` | Architecture Decision Records — lifecycle, index, supersede |
| `ruflo-agentdb` | AgentDB/RuVector — HNSW indexing, semantic search, memory operations |
| `ruflo-aidefence` | AI safety — threat detection, PII scanning, adaptive defense |
| `ruflo-autopilot` | Autonomous task coordination using /loop and autopilot |
| `ruflo-browser` | Browser automation — UI testing, web scraping |
| `ruflo-core` | Core agents: coder, researcher, reviewer |
| `ruflo-cost-tracker` | Token usage, cost attribution, budget monitoring |
| `ruflo-daa` | Dynamic Agentic Architecture — adaptive agents, cognitive patterns |
| `ruflo-ddd` | Domain-Driven Design — bounded contexts, aggregate roots |
| `ruflo-docs` | Documentation generation and maintenance |
| `ruflo-federation` | Cross-installation agent federation with zero-trust security |
| `ruflo-goals` | GOAP A* planning, deep research, long-horizon tracking |
| `ruflo-intelligence` | Self-learning neural training, pattern discovery, routing optimization |
| `ruflo-knowledge-graph` | Entity/relation extraction, graph traversal, pathfinder scoring |
| `ruflo-migrations` | Sequential DB migrations with up/down pairs, rollback safety |
| `ruflo-neural-trader` | Backtesting, market analysis, risk assessment, trading strategies |
| `ruflo-observability` | Structured logging, distributed tracing, agent swarm correlation |
| `ruflo-plugin-creator` | Scaffolding, validating, and publishing Claude Code plugins |
| `ruflo-rag-memory` | SOTA RAG — hybrid search, Graph RAG, MMR reranking |
| `ruflo-ruvector` | Vector operations — HNSW, FlashAttention-3, Graph RAG, DiskANN |
| `ruflo-ruvllm` | Local inference, MicroLoRA fine-tuning, multi-provider routing |
| `ruflo-rvf` | Session persistence, state management, cross-conversation continuity |
| `ruflo-security-audit` | Security auditing and vulnerability remediation |
| `ruflo-sparc` | SPARC methodology — 5-phase development with quality gates |
| `ruflo-swarm` | Swarm coordination — agent lifecycle, task assignment, anti-drift |
| `ruflo-testgen` | TDD London School test generation |
| `ruflo-wasm` | WASM sandbox — isolated agent environments |
| `ruflo-workflows` | Workflow automation — multi-step process management |

### Official Claude Code Plugins (from Anthropic)

| Plugin | Purpose |
|---|---|
| `agent-sdk-dev` | Python/TypeScript Agent SDK development and verification |
| `code-review` | Staff engineer code review (4 parallel agents, ≥80% confidence filter) |
| `code-simplifier` | Simplify code for clarity while preserving functionality |
| `feature-dev` | 3-phase feature development (discover → explore → implement) |
| `frontend-design` | Frontend design patterns |
| `hookify` | Conversation analyzer — finds behaviours worth preventing with hooks |
| `pr-review-toolkit` | PR review suite (test coverage, type design, silent failures) |

---

## 7. Hooks — Behavioural Enforcement

Hooks are shell scripts that fire automatically at specific lifecycle events. They enforce rules without relying on Claude's memory.

### Active Hooks

```json
{
  "UserPromptSubmit": ["prompt-gate.sh"],
  "SessionStart": ["session-start.sh"],
  "Stop": ["memory-writeback.sh"],
  "PreToolUse(Bash)": ["deploy-gate.sh", "code-gate.sh", "visual-block.sh", "research-gate.sh"],
  "PostToolUse": ["visual-gate.sh", "visual-clear.sh", "commit-gate.sh"]
}
```

### Hook Details

**`prompt-gate.sh`** (UserPromptSubmit — fires on EVERY user message)
- Detects research/build/find/add intent in the prompt
- Injects: "check local files FIRST before external research"
- Forces order: ls ~/→ CLAUDE.md → mem-search → THEN WebSearch
- Prevents going straight to WebSearch when a local project already exists
- Grade: 10/10 — fires before any tool call, cannot be rationalized away

**`session-start.sh`** (SessionStart — fires once at session start)
- Loads memory from GitHub (`git pull`)
- Bridges flat files → AgentDB (ruflo-bridge.sh)
- Reads Obsidian vault: `_CLAUDE.md`, `index.md`, `CRITICAL_FACTS.md`
- Shows active projects, today's date
- Displays model routing guide
- Shows skills menu
- Checks Hermes / Hermes Jr / local model availability
- Loads project todos from `~/.claude/todos.json`

**`memory-writeback.sh`** (Stop — fires after every turn)
- Updates `~/.remember/now.md` from latest session file
- Runs memory-sync.sh
- Dumps claude-mem SQLite to SQL backup
- Pushes memory to GitHub

**`deploy-gate.sh`** (PreToolUse Bash — fires before any Bash call)
- Detects deploy commands: `vercel --prod`, `wrangler deploy`, etc.
- Runs platform decision gate:
  - Marketing/portfolio/landing page → Vercel
  - worker-bee.app subdomain with D1/R2/KV → Cloudflare Workers
- Prevents deploying to wrong platform

**`code-gate.sh`** (PreToolUse Bash)
- Runs `npx tsc --noEmit` before any deploy
- Blocks deploy if TypeScript errors exist

**`research-gate.sh`** (PreToolUse Write)
- Fires before writing new code files (`.tsx`, `.ts`, `.jsx`, `.css`)
- Checks if `scores.md` exists and project has commits
- If MISSING → hard stop → force research protocol first
- Prevents building new sites without competitive research

**`visual-gate.sh`** (PostToolUse — fires after any Write/Edit)
- Detects if visual files changed (`.tsx`, `.css`, `.svg`, `.png`)
- If yes → injects screenshot + video protocol
- Forces: `node ~/screenshot.js <port>` + `node ~/record.js <port>`

**`visual-block.sh`** (PreToolUse Bash)
- Blocks deploy if visual files changed without screenshot verification

**`commit-gate.sh`** (PostToolUse)
- Auto-runs `git status` after commits
- Verifies commit succeeded

### Hookify Auto-Approve Rules

These rules bypass the permission prompt for common safe operations:

```
hookify.auto-approve-builds.local.md     — npm/bun/pnpm builds
hookify.auto-approve-git.local.md        — git reads + commits (not force push to main)
hookify.auto-approve-memory.local.md     — read/write ~/.claude/projects/
hookify.auto-approve-project-reads.local.md — reading source files
hookify.auto-approve-supabase.local.md  — Supabase MCP operations
hookify.block-force-push.local.md       — BLOCKS git push --force to main
hookify.warn-env-files.local.md         — warns before reading .env files
```

---

## 8. Rules — Iron Laws

Rules are markdown files in `~/.claude/rules/` that encode enforced behaviour. Each rule file uses **observable state triggers** (bash commands) rather than intent-based triggers.

### Enforcement Model

```
Level 1: Pre-action hook (9–10/10) — fires automatically, cannot be skipped
Level 2: Observable state (7–8/10) — bash exits non-zero → action required
Level 3: Skill invocation (7–8/10) — Skill tool fires before reasoning
Level 4: Reasoning-time (4–6/10) — weakest, relies on memory
```

### Active Rules

| Rule File | Purpose | Key Iron Law |
|---|---|---|
| `autonomous-operations.md` | Try 3–5 methods before reporting to user | Iron Law 0: Win Before Asking |
| `quality-gate.md` | Definition of Done — 7 gates | Iron Law 1: run tsc + lint + build before "done" |
| `visual-review-non-negotiable.md` | Screenshot + video after every UI change | Fires on: `git diff --name-only \| grep -qE '\.(tsx\|css)'` |
| `skill-invocation-order.md` | Invoke skill BEFORE any response | Observable: Am I about to type without invoking? |
| `skill-self-selection.md` | Task → Tool routing matrix | Full table of which skill fires for which task |
| `research-first.md` | No code before scores.md exists | Observable: `ls scores.md \|\| echo MISSING` |
| `md-architecture.md` | How to write rule/skill/CLAUDE.md files | Grade rubric, observable trigger patterns |
| `api-wall-checklist.md` | 10-method checklist before asking user for auth | Observable: any 401/403/expired error |
| `claude-md-rubric.md` | CLAUDE.md quality standard | 5 Iron Laws with wc -l, grep -c checks |
| `client-handoff-protocol.md` | Demo → CONTENT-NEEDED.md → live | Observable: `grep "\[DEMO\]"` must return 0 |
| `demo-to-live-protocol.md` | Tag every invented content item | Observable: `grep -rn "\[DEMO\]"` |
| `image-sourcing-protocol.md` | Never stop for missing images | Decision flow: 6 options before asking |
| `no-asterisks-in-urls-or-paths.md` | URLs/paths never get asterisk decoration | Output-time scan before every message |
| `kaizen-7-steps.md` | 7-step improvement process | Applied to every bug, every improvement |

### The Canonical Failures

Two real failures that every rule references as cautionary examples:

**iter-16 (Block Reign):** Shader lifted to fullpage. Code scored +0.25. Website regressed on every section. Score came from code intent, not pixels. Screenshot was never opened. Time lost: full iteration wasted. **Fix: screenshot BEFORE any score.**

**iter-19 (Block Reign):** Element collisions near footer. Harness scroll stopped short (`body.scrollHeight` instead of `documentElement.scrollHeight - window.innerHeight`). Single-viewport blindness (1440px only). Bugs at 2560px were invisible. **Fix: explicit scroll to bottom + all 4 viewports.**

---

## 9. MCP Servers

MCP (Model Context Protocol) servers expose external tools directly to Claude.

### Local MCP Servers (always active)

```json
{
  "imessage": "Read iMessages, reply via bluebubbles gateway",
  "oauth-gateway": "OAuth 2.1 PKCE server (Node.js) — localhost:8080",
  "oauth-gateway-py": "OAuth gateway Python mirror — fallback",
  "playwright": "Browser automation — Chromium via Playwright"
}
```

### Remote MCP Servers (claude.ai integrated)

| Category | Servers |
|---|---|
| **Deploy / Hosting** | Vercel, Railway |
| **Database** | Supabase |
| **Code** | GitHub, GitLab |
| **Communication** | Slack, Gmail, iMessage |
| **AI / Creative** | Higgsfield (video generation) |
| **Search / Research** | Context7 (library docs), WebSearch, WebFetch |
| **Productivity** | Google Drive, Zapier, Supermetrics |
| **Monitoring** | Sentry |
| **Project Management** | Linear |
| **Design** | Figma |
| **Meetings** | Circleback |
| **Browser** | Chrome DevTools, Playwright (remote) |
| **Local Models** | ComfyUI |

### MCP Access Pattern

```bash
# Example: deploy to Vercel via MCP instead of CLI
mcp__claude_ai_Vercel__deploy_to_vercel

# Example: search Supabase tables
mcp__plugin_supabase_supabase__list_tables

# Example: create GitHub PR
mcp__plugin_github_github__create_pull_request
```

---

## 10. Bootstrap Chain

Every session follows this exact sequence:

```
User opens Claude Code
    │
    ▼
SessionStart hook fires
    │
    ▼
session-start.sh runs
    ├── 1. git pull ~/.claude/projects/.../memory/  (sync memory from GitHub)
    ├── 2. ruflo-bridge.sh (bridge flat files → AgentDB HNSW)
    ├── 3. Read Obsidian vault: _CLAUDE.md, index.md, CRITICAL_FACTS.md
    ├── 4. Load ~/.remember/: now.md + recent.md
    ├── 5. Check Hermes + Hermes Jr availability (test with -z "ok")
    ├── 6. Check local model status (llama-server :8090, LM Studio :1234)
    ├── 7. Load ~/.claude/api-keys.env (FAL_KEY, etc.)
    └── 8. Display: date, projects, model routing guide, skills menu, todos
    │
    ▼
User types /tac [optional topic]
    ├── If topic given: mem-search("<topic>") immediately
    └── If no topic: "What do you want to work on today?"
    │
    ▼
User messages → UserPromptSubmit hook fires (every message)
    └── prompt-gate.sh → inject "check local files first" if research/build intent
    │
    ▼
Task execution
    ├── PreToolUse hooks: deploy-gate, code-gate, research-gate, visual-block
    └── PostToolUse hooks: visual-gate, visual-clear, commit-gate
    │
    ▼
Session ends → Stop hook fires
    └── memory-writeback.sh → update now.md → sync → push to GitHub
```

---

## 11. Data Flow Diagrams

### Memory Read Flow

```
Claude needs context for a task
    │
    ├── 1. Check this session's conversation (in-context)
    ├── 2. mem-search "query" → AgentDB HNSW → ranked results
    ├── 3. Read ~/.claude/projects/.../memory/<key>.md directly
    ├── 4. Read Obsidian vault notes via Read tool
    └── 5. para-search "query" → ~/knowledge-base/ PARA structure
```

### Memory Write Flow

```
Claude learns something new
    │
    ├── In-session: stored in conversation context
    ├── Important fact: Write ~/.claude/projects/.../memory/<key>.md
    ├── Technical decision: Write ~/knowledge-base/2-areas/ note
    ├── Dev log: Write Obsidian vault Dev Logs/YYYY-MM-DD-<project>.md
    └── On session end: memory-writeback.sh pushes all to GitHub
```

### Skill Invocation Flow

```
User message arrives
    │
    ▼
prompt-gate.sh checks for intent (UserPromptSubmit hook)
    │
    ▼
Claude processes message
    │
    ▼
skill-invocation-order rule: check skill map
    │
    ├── Match found? → Skill tool → load SKILL.md → follow it
    └── No match? → reason from general knowledge + rules
```

### Deploy Flow

```
User says "deploy" / "ship"
    │
    ▼
PreToolUse(Bash) → deploy-gate.sh fires
    ├── Check: does project have D1/R2/KV bindings?
    │   ├── YES → Cloudflare Workers (wrangler deploy)
    │   └── NO → Vercel (vercel --prod)
    │
    ▼
PreToolUse(Bash) → code-gate.sh fires
    └── npx tsc --noEmit → must exit 0
    │
    ▼
Deploy runs
    │
    ▼
curl -sI <live-url> | head -1 → must be HTTP/2 200
```

---

## 12. PARA Knowledge Base

The `~/knowledge-base/` directory is the structured long-term knowledge repository. Unlike the Obsidian vault (human notes + decisions), the PARA KB is pure reference material and patterns.

### What Goes Where

| Folder | Content | Lifespan |
|---|---|---|
| `1-projects/` | Active work with a deadline | Weeks–months |
| `2-areas/` | Ongoing responsibility (per client, per domain) | Indefinite while active |
| `3-resources/` | Reference material, docs, patterns, API specs | Indefinite |
| `4-archives/` | Completed projects, retired areas | Permanent |

### 2-Areas Structure (Current Active Areas)

```
2-areas/
  clients/         — One stub per active client (20+)
  architecture/    — Cross-project patterns and ADRs
  operations/      — Cron jobs, agents, monitoring
  open-loops/      — Things that need follow-up
  people/          — Extended people notes
  agent-chat/      — Agent conversation logs
```

### How it Integrates with Memory

```
New file/URL arrives
    │
    ▼
para-ingest <file|url> [--area|--project|--resource]
    │
    ├── markitdown/MinerU → converts to Markdown
    ├── Placed in correct PARA folder
    └── AgentDB indexed → available via mem-search
```

---

## 13. How It All Connects — A Session Walkthrough

**Scenario: Toby says "Work on the salvorias marketplace listings page"**

```
1. SESSION START
   └── session-start.sh ran at session open:
       memory synced from GitHub, vault loaded, todos checked

2. MESSAGE ARRIVES
   └── prompt-gate.sh fires (UserPromptSubmit):
       Detects "work on" + project name intent
       Injects: "check local files first"

3. CLAUDE CHECKS LOCAL FILES
   └── ls ~/salvorias-marketplace/  → project exists
   └── mem-search "salvorias marketplace listings" → finds prior session notes
   └── Read AGENTS.md → loads full project context

4. SKILL SELECTION
   └── skill-invocation-order.md fires:
       "listings page" → nextjs-best-practices skill
       "server component" → nextjs-app-router-patterns
   └── Skill tool invoked → SKILL.md loaded

5. WORK HAPPENS
   └── Read, Edit, Write tools (tracked in hooks)
   └── PostToolUse/Write → visual-gate.sh detects .tsx changed
       → injects screenshot + video requirement

6. VISUAL REVIEW
   └── node ~/screenshot.js 3000 0,540,1080
   └── node ~/record.js 3000
   └── Read tool opens PNGs → Claude describes what's visible

7. DEPLOY
   └── PreToolUse/Bash → deploy-gate.sh: Vercel (no D1/R2/KV)
   └── PreToolUse/Bash → code-gate.sh: tsc passes
   └── vercel --prod → HTTP/2 200 verified

8. QUALITY GATE
   └── quality-gate.md Iron Laws:
       Gate 1 ✓ (tsc + lint + build)
       Gate 2 ✓ (visual verified)
       Gate 5 ✓ (HTTP/2 200)

9. SESSION END
   └── memory-writeback.sh fires (Stop hook):
       - Writes session summary to ~/.remember/today-<date>.md
       - Pushes memory to GitHub
       - If architectural change: AGENTS.md updated
```

---

## 14. File Map

```
~/.claude/
├── SOUL.md                     — Claude's identity in this workspace
├── AGENTS.md                   — Full agent ecosystem map
├── CLAUDE.md                   — Global instructions (delegates to SOUL + AGENTS)
├── WORKSPACE.md                — Machine-specific config (M1 Ultra)
├── hooks.json                  — Hook configuration (events → scripts)
├── mcp.json                    — MCP server configuration
├── api-keys.env                — Persistent API keys (FAL_KEY, etc.)
├── vocabulary.md               — Project-specific terminology
├── todos.json                  — Cross-project todo list
│
├── skills/                     — 1,560 skill directories
│   ├── tac/SKILL.md            — Session bootstrap
│   ├── ui-ux-pro-max/          — Design intelligence (scripts + data)
│   ├── brainstorming/          — Pre-planning gate
│   ├── graphify/               — Knowledge graph builder
│   └── ... (1,556 more)
│
├── rules/                      — 13 Iron Law rule files
│   ├── autonomous-operations.md
│   ├── quality-gate.md
│   ├── visual-review-non-negotiable.md
│   ├── skill-invocation-order.md
│   ├── skill-self-selection.md
│   └── ...
│
├── hooks/                      — Shell scripts called by hooks.json
│   ├── prompt-gate.sh          — UserPromptSubmit: local-files-first
│   ├── deploy-gate.sh          — PreToolUse: platform decision
│   ├── code-gate.sh            — PreToolUse: tsc before deploy
│   ├── research-gate.sh        — PreToolUse: scores.md required
│   ├── visual-gate.sh          — PostToolUse: screenshot on UI change
│   ├── visual-block.sh         — PreToolUse: block deploy without screenshot
│   └── commit-gate.sh          — PostToolUse: verify commit
│
├── bootstrap/                  — Session lifecycle scripts
│   ├── session-start.sh        — SessionStart: full context load
│   ├── memory-writeback.sh     — Stop: flush + push memory
│   ├── memory-sync.sh          — Shared sync utility
│   └── ruflo-bridge.sh         — Flat files → AgentDB
│
├── plugins/                    — Plugin system
│   ├── installed_plugins.json  — Plugin manifest
│   └── marketplaces/           — 5 plugin marketplaces
│       ├── ruflo/              — 30 Ruflo plugins
│       ├── claude-plugins-official/ — Official plugins
│       └── ...
│
├── projects/-Users-drive/
│   └── memory/                 — Flat-file memory (git-backed)
│       ├── MEMORY.md           — Master index
│       └── *.md                — Individual memory files
│
├── memory/                     — AgentDB vector store
│   └── agentdb.rvf             — HNSW index
│
└── hookify.*.local.md          — Auto-approve/block rules

~/.remember/                    — Rolling session memory
├── now.md                      — Most recent session
├── today-YYYY-MM-DD.md         — Daily files
├── recent.md                   — 7-day summary
└── archive.md                  — Older history

~/knowledge-base/               — PARA knowledge system
├── _index/                     — 1,530 indexed docs (14 categories)
├── 1-projects/                 — Active sprint work
├── 2-areas/                    — Ongoing areas (clients, architecture, ops)
├── 3-resources/                — Reference material
└── 4-archives/                 — Completed work

~/Library/Mobile Documents/iCloud~md~obsidian/Documents/second brain/
├── _CLAUDE.md                  — Claude operating manual for vault
├── index.md                    — Master catalog (auto-updated)
├── CRITICAL_FACTS.md           — Never re-derive these
├── Daily/YYYY-MM-DD.md         — Daily notes
├── Projects/                   — One note per active project
├── Clients/                    — One note per client
├── Dev Logs/                   — Technical session logs
├── Memory/                     — Mirrors ~/.claude/memory
├── Knowledge/                  — Reference + permanent notes
└── Skills/                     — Skill notes + usage guides
```

---

## Appendix A — Quick Reference Commands

```bash
# Memory
mem-search "query"              # semantic search all memory
mem-store KEY "value"           # store a note
mem-get KEY                     # exact key retrieval
ruflo sync                      # re-sync GitHub → AgentDB

# Agents
jr "task"                       # Hermes Jr synchronous (TAC gets output)
jr -p teacher "task"            # Hermes Jr with personality
wba "task"                      # worker-bee-agent inline
wba -b "task"                   # worker-bee-agent background
wba -m haiku "task"             # force Haiku model

# Bootstrap
/tac                            # full session bootstrap
/tac salvorias                  # bootstrap + mem-search "salvorias"

# Skills
/skill-name                     # invoke any of 1,560 skills
/tac | /brainstorming | /graphify | /autoplan | /investigate

# Visual review
node ~/screenshot.js <port> 0,540,1080
node ~/record.js <port>
node ~/record.js <port> --mobile
ffmpeg -i review.webm -vf fps=2 frames/frame_%03d.png

# Knowledge base
para-ingest <file> [--area|--project|--resource]
para-search "query"
```

---

## Appendix B — System Grade

| Component | Grade | Forcing Function |
|---|---|---|
| `prompt-gate.sh` | 10/10 | UserPromptSubmit hook — fires before every message |
| `session-start.sh` | 9/10 | SessionStart hook — fires at every session open |
| `memory-writeback.sh` | 9/10 | Stop hook — fires after every turn |
| `deploy-gate.sh` | 9/10 | PreToolUse(Bash) — fires before every bash call |
| `visual-gate.sh` | 8/10 | PostToolUse — detects .tsx/.css changes |
| `research-gate.sh` | 8/10 | PreToolUse(Write) — detects new site builds |
| Skill self-selection | 8/10 | skill-invocation-order rule — output-time check |
| PARA KB ingestion | 7/10 | para-ingest command — manual trigger |
| Vault AI-first format | 8/10 | _CLAUDE.md operating manual |

**System average: 8.7/10**

The remaining 1.3 points come from: skill invocation being trained behaviour (not a pre-action hook), and PARA ingest requiring a manual trigger rather than auto-detecting new files.

---

*Built by Toby Anderton (Drive) · June 2026 · adobetoby@gmail.com*
