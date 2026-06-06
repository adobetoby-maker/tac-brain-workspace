# Toby's Claude Code Workspace — M1 Ultra
**Last updated:** 2026-05-07  
**Machine:** M1 Ultra (primary workstation)  
**User:** drive / adobetoby@gmail.com

---

## Bootstrap Chain

Every session loads in this order:

```
SessionStart → ~/.claude/bootstrap/session-start.sh
  ├── 1. MEMORY.md index (flat-file memory)
  ├── 2. RAG memory (claude-flow, namespace: claude-memories)
  ├── 3. Neural intelligence status (claude-flow neural)
  ├── 4. Memory sync status (.last-memory-sync marker)
  └── 5. Active hookify rules (auto-approve/block)

Stop (every turn) → ~/.claude/bootstrap/memory-writeback.sh
  └── memory-sync.sh → timestamps sync, logs file count

Cron (*/30 min) → memory-sync.sh
  └── Keeps sync log current between sessions
```

---

## Hooks Active

| Event | Script | Purpose |
|---|---|---|
| `SessionStart` | `bootstrap/session-start.sh` | Loads all context into every new session |
| `Stop` | `bootstrap/memory-writeback.sh` | Flushes memory state after every turn |

**Hookify auto-approve rules** (no prompts for these):
- Memory ops (read/write `~/.claude/projects/`)
- npm/bun builds
- git reads + commits
- Project file reads
- Supabase node operations

**Hookify blocks:**
- Force-push to main
- `.env` file commits

---

## Installed Plugins — 84 total

### Core Workflow
| Plugin | Version | Purpose |
|---|---|---|
| `superpowers` | v5.1.0 | Meta-skills: brainstorming, debugging, TDD, git worktrees, planning |
| `frontend-design` | unknown | Distinctive UI/component generation |
| `feature-dev` | unknown | Full feature architecture + implementation |
| `code-review` | unknown | Staff-engineer level code review |
| `code-simplifier` | v1.0.0 | Refactor for clarity without changing behavior |
| `pr-review-toolkit` | unknown | PR review, test analysis, type design, silent failure hunting |
| `commit-commands` | unknown | commit, push, PR automation |
| `hookify` | unknown | Auto-approve/block rule management |

### AI & Agent Development
| Plugin | Version | Purpose |
|---|---|---|
| `agent-sdk-dev` | unknown | Build + verify Claude Agent SDK apps (Python + TS) |
| `claude-code-setup` | v1.0.0 | Workspace automation recommendations |
| `claude-md-management` | v1.0.0 | CLAUDE.md creation + improvement |
| `skill-creator` | unknown | Build new Claude Code skills |
| `plugin-dev` | unknown | Build + publish Claude Code plugins |
| `mcp-server-dev` | unknown | Build MCP servers |
| `playground` | unknown | Rapid prototyping environment |

### Ruflo Suite (32 plugins — v0.1.0–v0.2.0, all installed 2026-05-05)
| Plugin | Purpose |
|---|---|
| `ruflo-rag-memory` | Vector memory: HNSW, hybrid search, Graph RAG |
| `ruflo-swarm` | Hierarchical multi-agent coordination (max 8 agents) |
| `ruflo-intelligence` | Neural pattern learning, trajectory tracking, model routing |
| `ruflo-agentdb` | AgentDB + RuVector memory operations |
| `ruflo-aidefence` | AI safety: threat detection, PII scanning |
| `ruflo-autopilot` | Autonomous task coordination via /loop |
| `ruflo-browser` | Browser automation: UI testing, scraping |
| `ruflo-core` | Project init, doctor, plugin discovery |
| `ruflo-cost-tracker` | Token usage + USD cost attribution |
| `ruflo-daa` | Dynamic Agentic Architecture: adaptive agents |
| `ruflo-ddd` | Domain-Driven Design: bounded contexts, aggregates |
| `ruflo-docs` | API + project documentation generation |
| `ruflo-federation` | Cross-installation agent federation |
| `ruflo-goals` | GOAP planning, horizon tracking, deep research |
| `ruflo-jujutsu` | Git workflow: diff analysis, PR management |
| `ruflo-knowledge-graph` | Entity extraction, graph traversal |
| `ruflo-loop-workers` | Background worker scheduling + cron |
| `ruflo-market-data` | OHLCV ingestion, candlestick pattern matching |
| `ruflo-migrations` | Sequential DB migrations with rollback |
| `ruflo-neural-trader` | LSTM/Transformer trading strategies, backtesting |
| `ruflo-observability` | Structured logging, distributed tracing |
| `ruflo-plugin-creator` | Plugin scaffolding + publishing |
| `ruflo-ruvector` | Vector ops: HNSW, FlashAttention-3, DiskANN |
| `ruflo-ruvllm` | Local inference, MicroLoRA fine-tuning |
| `ruflo-rvf` | Session persistence, state management |
| `ruflo-security-audit` | Security auditing + vulnerability remediation |
| `ruflo-sparc` | 5-phase SPARC methodology orchestration |
| `ruflo-testgen` | TDD London School test generation |
| `ruflo-wasm` | WASM sandbox for isolated agent environments |
| `ruflo-workflows` | Multi-step workflow automation |
| `ruflo-adr` | Architecture Decision Records lifecycle |
| `ruflo-iot-cognitum` | Cognitum Seed device fleet management |

### Platform Integrations
| Plugin | Version | Purpose |
|---|---|---|
| `vercel` | v0.40.1 | Deploy, env, marketplace, AI SDK, Next.js |
| `supabase` | v0.1.6 | DB, auth, RLS, Edge Functions, Realtime |
| `cloudflare` | v1.0.0 | Workers, Durable Objects, Agents SDK, MCP |
| `stripe` | v0.1.0 | Payments, test cards, upgrade guidance |
| `slack` | v1.0.0 | Messaging, search, standups, digests |
| `github` | unknown | PR management, issues |
| `gitlab` | unknown | CI/CD, MR management |
| `linear` | unknown | Issue tracking |
| `figma` | v2.1.30 | Design generation, implementation, code connect |
| `postman` | v1.0.0 | API testing, mocking, code generation |
| `sentry` | v1.0.0 | Error tracking, Seer AI debugging |
| `firecrawl` | v1.0.8 | Web scraping, skill generation |
| `playwright` | unknown | Browser automation |
| `chrome-devtools-mcp` | v0.22.0 | LCP debug, memory leaks, a11y |
| `serena` | unknown | Symbolic code navigation (LSP-powered) |

### Language Servers (LSP)
`typescript-lsp`, `pyright-lsp`, `gopls-lsp`, `rust-analyzer-lsp`, `swift-lsp`, `php-lsp`, `jdtls-lsp`

### Specialized
| Plugin | Purpose |
|---|---|
| `searchfit-seo` | Content strategy, keyword clustering, schema markup, audits |
| `huggingface-skills` | Local models, Gradio, vision trainer, datasets |
| `shopify-ai-toolkit` | Storefront, Admin, Polaris, Liquid, Functions |
| `coderabbit` | AI code review + autofix |
| `ralph-loop` | Loop management |
| `remember` | Persistent memory |
| `imessage` | iMessage access |
| `zapier` | Tool profiles, workflow setup |
| `spotify-ads-api` | Ad campaign management |
| `amazon-location-service` | Maps + location |
| `mintlify` | Documentation platform |
| `qodo-skills` | PR resolver, coding rules |
| `microsoft-docs` | Azure + Microsoft documentation access |
| `nimble` | Business intelligence research |
| `product-tracking-skills` | Analytics tracking plans |

---

## GStack Skills (Garry Tan's dev team — installed 2026-05-07)

Located at `~/.claude/skills/gstack/`

| Skill | Role |
|---|---|
| `/office-hours` | CEO strategic product thinking |
| `/plan-ceo-review` | Feature review from founder POV |
| `/plan-eng-review` | Architecture lockdown |
| `/plan-design-review` | Design direction pre-build |
| `/review` | Staff engineer code review |
| `/ship` | End-to-end PR + merge automation |
| `/qa` | Real browser QA against staging URL |
| `/qa-only` | QA without shipping |
| `/design-shotgun` | Multiple UI directions fast |
| `/design-html` | HTML/CSS design generation |
| `/design-consultation` | Design feedback + direction |
| `/design-review` | Review existing design for issues |
| `/investigate` | Deep-dive debugging agent |
| `/cso` | Security officer: OWASP + STRIDE audit |
| `/benchmark` | Performance benchmarking |
| `/canary` | Canary deploy + monitoring |
| `/retro` | Post-launch retrospective |
| `/autoplan` | Automatic planning before coding |
| `/document-release` | Release documentation |
| `/learn` | Learn from codebase patterns |
| `/browse` | Web browsing (preferred over MCP browser tools) |
| `/freeze` / `/unfreeze` | Lock/unlock code areas |
| `/guard` | Protect critical paths |
| `/gstack-upgrade` | Update gstack itself |

---

## Active Projects — Pick Up From Here

### 🔧 Jr.'s Auto Repair Website
**Path:** `/Users/drive/jrs-auto-repair`  
**Live:** `jrs.worker-bee.app`  
**Last active:** 2026-05-04  
**State:** Production-complete. Landing page, 21 blog articles, customer portal (Supabase auth), full admin backend (repair orders, customers, inventory, analytics), 4 city SEO pages (Twin Falls, Jerome, Kimberly, Buhl).  
**Resume:** `npm run dev` → localhost:3000. Admin login: adobetoby@gmail.com at `/admin/login`.  
**Next:** More articles, customer messaging (CRM), paid ads landing pages.

### 🌍 LinguaLens
**Path:** `/Users/drive/lingua-lens`  
**Live:** `language-lens-elite.lovable.app` (original), local rewrite active  
**Last active:** 2026-05-07 (TODAY — active session)  
**State:** Next.js rewrite. Landing (3D globe), 6 tabs: Reader, Speak & Learn, Writing Studio, Match (real-time matchmaking), Tutor, Dashboard. 9+ API routes. Supabase auth + vocabulary sync. Flashcard study mode. Real matchmaking with NPC fallback.  
**Resume:** `PORT=3001 npm run dev` → localhost:3001. Supabase project: `cadyxjryolayvxcynkeb`.  
**Pending:** Run `match_queue` SQL migration in Supabase dashboard. Vercel deploy.

### 🏢 Anderton & Associates
**Path:** `/Users/drive/anderton-associates` *(presumed)*  
**Live:** Deployed  
**Last active:** 2026-05-03  
**State:** Complete CRM/admin site. Supabase: `qnrkifdbkcbacgznoabs`. Admin pw in memory file.  
**Status:** Done — maintenance only.

### 🐝 Worker-Bee Management Platform
**Path:** `/Users/drive/manage-worker-bee`  
**Last active:** 2026-05-04  
**State:** Agency dashboard. Sites registry, credential vault, Claude configurator.  
**Resume:** Check `npm run dev` for port. Admin pw in memory file.

### ⛓ DEX Project (Uniswap V2 Fork)
**Path:** Unknown  
**Last active:** 2026-05-06  
**State:** Phase 2 frontend complete. Waiting on testnet deploy for Factory + Router addresses. Target: TSC production. SAV ~2026-05-19.  
**Resume:** Need testnet deploy before frontend can be fully wired.

### 🔧 Mountain Edge Plumbing (Claude Agent)
**Last active:** 2026-05-05  
**State:** Claude managed agent config saved. Template + Mountain Edge-specific build complete.

### 🐝 Worker-Bee Deploy System
**Script:** `~/deploy-client.sh <path> <clientname>`  
**Result:** `clientname.worker-bee.app` (Vercel + Cloudflare)  
**Last active:** 2026-05-03

---

## Memory System

**Flat-file:** `~/.claude/projects/-Users-drive/memory/` (14 files, all indexed)  
**RAG/Vector:** `claude-flow memory` — namespace `claude-memories`  
**Sync:** Stop hook fires after every turn → 30-min cron loop backs up  
**Cross-session lag:** ~1 message (Session B sees Session A's writes on next turn)

---

## Key Commands

```bash
# Dev servers
PORT=3001 npm run dev              # LinguaLens
npm run dev                        # jrs-auto-repair (port 3000)

# Memory
claude-flow memory store --namespace claude-memories -k "key" -v "value"
claude-flow memory search --namespace claude-memories -q "query"

# Deploy
~/deploy-client.sh /path/to/project clientname

# Agents
claude agent create --name "Name" --model claude-sonnet-4-6 ...

# GStack (from any project dir)
/review    /qa    /ship    /plan-ceo-review    /cso
```

---

## Laptop Bridge — See LAPTOP-BRIDGE.md
