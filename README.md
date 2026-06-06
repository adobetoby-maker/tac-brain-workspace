# TAC Brain — AI Development Workspace

> Toby Anderton's (Drive's) complete Claude Code workspace — memory architecture, 1,560 skills, plugin system, Iron Law rules, hooks, and Obsidian vault integration.

## What This Is

This repo documents and backs up the **TAC Brain** — the multi-layer AI operating system built on top of Claude Code. It turns a standard AI coding assistant into a persistent, context-aware, self-enforcing development environment.

## Start Here

**[TAC-BRAIN-PRD.md](./TAC-BRAIN-PRD.md)** — The full architecture document. 14 sections covering every component.

## Repo Structure

```
├── TAC-BRAIN-PRD.md         — Full system PRD (start here)
├── SOUL.md                  — Claude's identity in this workspace
├── AGENTS.md                — Full agent ecosystem map
├── WORKSPACE.md             — Machine config (M1 Ultra)
├── vocabulary.md            — Project-specific terminology
├── hooks.json               — Hook event configuration
├── mcp-servers.json         — MCP server list (tokens redacted)
│
├── rules/                   — 13 Iron Law rule files
│   ├── autonomous-operations.md
│   ├── quality-gate.md
│   ├── visual-review-non-negotiable.md
│   ├── skill-self-selection.md
│   ├── skill-invocation-order.md
│   ├── research-first.md
│   └── ... (7 more)
│
├── hooks/                   — Shell scripts for lifecycle enforcement
│   ├── prompt-gate.sh       — Fires on every user message
│   ├── deploy-gate.sh       — Fires before every deploy
│   ├── code-gate.sh         — TypeScript check before deploy
│   ├── research-gate.sh     — Requires scores.md before new builds
│   ├── visual-gate.sh       — Requires screenshot after UI changes
│   └── ... (5 more)
│
├── bootstrap/               — Session lifecycle scripts
│   ├── session-start.sh     — Full context load at session start
│   ├── memory-writeback.sh  — Flush + push memory on session end
│   ├── memory-sync.sh       — Shared sync utility
│   └── ruflo-bridge.sh      — Sync flat files → AgentDB HNSW
│
├── plugins/
│   ├── ruflo-plugins.txt        — 30 Ruflo AI agent plugins
│   ├── official-plugins.txt     — Official Claude Code plugins
│   ├── marketplaces-list.txt    — All installed marketplaces
│   └── installed-plugins.json   — Plugin manifest
│
└── skills-index/
    ├── SKILLS-MASTER-LIST.txt   — All 1,560 skill names
    └── <skill-name>/SKILL.md    — One SKILL.md per installed skill
```

## The Five Memory Layers

| Layer | Technology | Location |
|---|---|---|
| Flat files | Git-backed Markdown | `~/.claude/projects/.../memory/` |
| AgentDB | HNSW vector index | `~/.claude/memory/agentdb.rvf` |
| Obsidian | iCloud-synced vault | `~/Library/Mobile.../second brain/` |
| PARA KB | 1,530 indexed docs | `~/knowledge-base/_index/` |
| claude-mem | SQLite FTS5 | `~/.claude-mem/*.db` |

## The Four Agents

| Agent | Role | Invoke |
|---|---|---|
| Claude Code (TAC) | Primary architect, session orchestrator | This terminal |
| worker-bee-agent (wba) | Max OAuth daemon, background tasks | `wba "task"` |
| Hermes Jr | Full profile agent, cron, iMessage | `jr "task"` |
| SiteManager | Orthobiologic site + LBS | `hermes --profile sitemanager` |

## The Ten Hooks

| Event | Script | What it enforces |
|---|---|---|
| UserPromptSubmit | prompt-gate.sh | Check local files before external research |
| SessionStart | session-start.sh | Load all memory + context |
| Stop | memory-writeback.sh | Push memory to GitHub |
| PreToolUse(Bash) | deploy-gate.sh | Platform decision (Vercel vs CF Workers) |
| PreToolUse(Bash) | code-gate.sh | TypeScript must pass before deploy |
| PreToolUse(Bash) | visual-block.sh | Block deploy without screenshot |
| PreToolUse(Bash) | research-gate.sh | Require scores.md before new builds |
| PostToolUse | visual-gate.sh | Screenshot + video after UI changes |
| PostToolUse | visual-clear.sh | Clear visual gate state |
| PostToolUse | commit-gate.sh | Verify commit succeeded |

## Quick Start (on a new machine)

```bash
# 1. Clone this repo to ~/.claude
git clone https://github.com/tobyandertonmd/tac-brain ~/.claude-brain

# 2. Copy rules, hooks, bootstrap to ~/.claude
cp -r ~/.claude-brain/rules ~/.claude/
cp -r ~/.claude-brain/hooks ~/.claude/
cp -r ~/.claude-brain/bootstrap ~/.claude/
cp ~/.claude-brain/hooks.json ~/.claude/
cp ~/.claude-brain/SOUL.md ~/.claude/
cp ~/.claude-brain/AGENTS.md ~/.claude/

# 3. Install skills (from marketplaces)
# Add ruflo: claude install plugin ruflo
# Add official: claude install plugin claude-plugins-official

# 4. Run /tac to bootstrap the session
```

---

*Built by Toby Anderton · adobetoby@gmail.com · June 2026*
