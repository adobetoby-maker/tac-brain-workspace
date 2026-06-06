# AGENTS — Drive's Neural Network Ecosystem

The agents below form an interconnected network sharing OAuth credentials,
filesystem memory, and tool access. Each has a defined role and invocation pattern.

---

## Agent 1: Claude Code (TAC)
**Role:** Primary architect, coder, session orchestrator
**Identity:** `~/.claude/SOUL.md`
**Model:** claude-sonnet-4-6 (default) / claude-opus-4-7 (high-stakes)
**Auth:** macOS Keychain "Claude Code-credentials" → sk-ant-oat01-*
**Bootstrap:** `/tac` skill — syncs memory, shows projects, routes models
**Strengths:** Multi-file reasoning, architecture, tool orchestration, research
**Memory:** `~/.claude/projects/-Users-drive/memory/` (git-backed)

---

## Agent 2: worker-bee-agent / wba (Max OAuth Daemon)
**Role:** Lightweight autonomous daemon — runs tasks via `claude -p` (Max OAuth, zero API billing)
**Identity:** `~/.worker-bee/daemon.py`
**Model:** claude-sonnet-4-6 (default) | claude-haiku-4-5-20251001 (cron/mechanical)
**Auth:** Max OAuth via Claude Code CLI — same Keychain token, no direct API calls
**Invoke:** `wba "task"` (inline) | `wba -b "task"` (background) | `wba start` (daemon)
**Strengths:** Background tasks, cron, skill context injection, iMessage notify, queue
**Queue:** `~/.worker-bee/tasks/` | **Logs:** `~/.worker-bee/logs/` | **Cron:** `~/.worker-bee/cron/jobs.json`
**Key difference from Hermes:** uses `claude -p` as execution engine → Max OAuth works, no exhaustion

| Command | What it does |
|---|---|
| `wba "task"` | inline execution — runs now, blocks, prints result |
| `wba -b "task"` | background dispatch — queues to daemon |
| `wba -s skill-name "task"` | load skill context before task |
| `wba -m haiku "task"` | force model (haiku/sonnet/opus) |
| `wba -n "task"` | notify via iMessage when done |
| `wba start / stop / status` | daemon lifecycle |
| `wba cron` | list scheduled jobs |

---

## Agent 3: Hermes Jr (Max OAuth — Full Hermes Interface)
**Role:** Full Hermes interface powered by `claude -p` — profiles, SOUL, cron, gateway, skills
**Identity:** `~/.hermes-jr/SOUL.md` | profiles: `~/.hermes-jr/profiles/`
**Repo:** `~/hermes-jr-agent/` → branch `hermes-jr` (fork of NousResearch/hermes-agent)
**Model:** claude-sonnet-4-6 via Max OAuth (`claude -p`) — zero API billing
**Auth:** Max OAuth via Claude Code CLI — `user:sessions:claude_code` scope (works)
**Invoke:** `hermes-jr --profile claude -z "task"` | `hermes-jr --profile sitemanager -z "task"`
**Strengths:** Full Hermes CLI interface, profile personas, SOUL injection, memory search
**Data:** `~/.hermes-jr/` | **Skills:** `~/.claude/skills/` + `~/.hermes/skills/`
**Key difference from Hermes original:** execution engine is `claude -p` not `api.anthropic.com`

| Command | What it does |
|---|---|
| `hermes-jr --profile claude -z "task"` | one-shot with Claude persona |
| `hermes-jr --profile sitemanager -z "task"` | one-shot with SiteManager persona |
| `hermes-jr --profile claude` | interactive chat |
| `hermes-jr -z "task"` | one-shot, default profile |

**Side-by-side with Hermes original:**
| | Hermes | Hermes Jr |
|---|---|---|
| API call | `api.anthropic.com` direct | `claude -p` subprocess |
| Auth | Credential pool + API key | Max OAuth via CLI |
| Skills | Hermes skill registry | Flat SOUL+skill prompt injection |
| Memory | SQLite FTS5 | Git-backed flat files |
| Tools | Hermes tool registry | Claude Code MCP tools |

---

## Agent 4: Hermes (Gateway + Complex Long-running)
**Role:** Persistent autonomous agent, messaging gateway, cron jobs
**Identity:** `~/.hermes/SOUL.md`
**Model:** claude-sonnet-4-6 via OAuth (profile: claude) | local LM Studio fallback
**Auth:** Same Claude OAuth (reads from keychain via anthropic_adapter.py)
**Invoke:** `hermes --profile claude -z "task"` or `hermes chat`
**Strengths:** Long-running tasks, gateway (iMessage/Telegram/Discord/Slack), cron
**Memory:** `~/.hermes/memory_store.db` (SQLite FTS5) + `~/.hermes/team-memory/`
**Skills:** `~/.hermes/skills/` (software-dev, autonomous-ai-agents, etc.)

**Active profiles:**
| Profile | Model | Auth | Use case |
|---|---|---|---|
| `claude` | claude-sonnet-4-6 | Claude OAuth | General tasks, background ops, dispatch |
| `sitemanager` | claude-sonnet-4-6 | Claude OAuth | Orthobiologic site, LBS Pro, orders |

Archived local profiles (no LM Studio needed): `~/.hermes/profiles/_archived/` (gemma, granite, qwen, qwenvl)

---

## Agent 3: SiteManager
**Role:** Autonomous orthobiologic site manager — inventory, orders, monitoring
**Identity:** `~/.hermes/profiles/sitemanager/SOUL.md`
**Model:** claude-sonnet-4-6 via Claude OAuth (same keychain as Claude Code + Hermes)
**Delegation:** claude-haiku-4-5-20251001 for mechanical subtasks
**Sites:** orthobiologicpathways.com, ime-coach.com
**Supplier:** LBS Pro Advanced (lbsproadvanced.com)
**Invoke:** `hermes --profile sitemanager -z "sync inventory"`
**Cron:** Daily inventory sync, 30-min site monitoring
**Memory:** `~/.hermes/profiles/sitemanager/memories/`

---

## Credential Flow

```
macOS Keychain "Claude Code-credentials"
         │
         ├──▶ Claude Code (direct SDK)
         │
         └──▶ Hermes anthropic_adapter.py
                   ├──▶ profile: claude      → claude-sonnet-4-6
                   └──▶ profile: sitemanager → claude-sonnet-4-6
                             (both use same keychain read)
```

All three agents share ONE Claude OAuth token. No separate API keys. No LM Studio.
Token refresh handled by Hermes's `credential_pool` in `~/.hermes/auth.json`.

---

## Memory Sharing

| Memory type | Location | Readable by |
|---|---|---|
| Git-backed flat files | `~/.claude/projects/-Users-drive/memory/` | Claude Code (primary) |
| SQLite FTS5 sessions | `~/.hermes/memory_store.db` | Hermes (primary) |
| Shared team memory | `~/.hermes/team-memory/shared_memory.db` | Both (plugin: hermes-memory-store) |
| AgentDB (HNSW) | RAM / ruflo-agentdb | Both via ruflo bridge |

---

## Tool Routing

| Task | Agent | Command |
|---|---|---|
| Code architecture, feature dev | Claude Code | (this session) |
| Background long-running task | Hermes | `hermes --profile claude -z "..."` |
| iMessage to Toby | Hermes gateway | `hermes gateway` (bluebubbles) |
| Site inventory sync | SiteManager | `hermes --profile sitemanager` |
| Scheduled / cron task | Hermes cron | `hermes cron add ...` |
| Supabase DB work | Claude Code + MCP | supabase MCP plugin |
| Browser automation | Hermes | browser tool in hermes |
| Image generation | ComfyUI | comfy plugin / fal tools |

---

## Dispatch Patterns — How Claude Code and Hermes Work Together

### Pattern 1: Explicit Dispatch (you name the agent)
Use when you want a specific background agent to own a task.
```bash
# Syntax: dispatch [--bg] [--profile <name>] "<task>"
dispatch --bg "check all worker-bee sites and alert me if anything is down"
dispatch --bg --profile sitemanager "sync lbs inventory to supabase"
dispatch --urgent "send willie elam social post drafts for this week"
```
The `dispatch` script is at `~/.hermes/bin/dispatch` — queues to `~/.hermes/tasks/pending/`.

### Pattern 2: Internal Orchestration (let Claude Code decide)
Use when you're mid-session and the task is complex/long.
Say naturally: "run this in the background" or "have hermes handle that".
Claude Code will:
1. Write the task to `~/.hermes/tasks/pending/<id>.json`
2. Spawn `hermes --profile claude -z "..."` with `run_in_background=True`
3. Log to `~/.hermes/logs/dispatch-<id>.log`
4. Report what was dispatched and the log path

### Pattern 3: Cron / Scheduled (autonomous, recurring)
Hermes daemon handles these. Active cron jobs:
| Name | Schedule | Model | What it does |
|---|---|---|---|
| `site-monitor` | every 30m | local | Checks site-monitor.py, alerts via iMessage |
| `lbs-daily-sync` | 6am daily | local | LBS inventory → Supabase |
| `md-vault-graph-refresh` | every 4h | haiku | Pings /api/graph, confirms node count |
| `willie-elam-social-post` | Mondays 8am | sonnet | Drafts social posts, sends to Toby for approval |
| `memory-daily-sync` | 7am daily | haiku | Git pull memory, counts rules/personalities |

Edit cron: `~/.hermes/cron/jobs.json` (Hermes reads on daemon start/reload)

### Pattern 4: Gateway (iMessage → Hermes → action)
Send a text to your Mac and Hermes acts:
```
"hermes sync willie elam site"     → Hermes wakes, handles it, texts back
"hermes status"                    → Reports all active agents + last cron runs
"hermes dispatch <task>"           → Same as dispatch CLI but via iMessage
```
Gateway setup: `hermes gateway` — runs on bluebubbles/imessage integration.

---

## Willie Elam — Concrete Example

The workflow `"update willie elam site and post to social"` runs as:

```
Claude Code (you say it)
  → dispatch --bg "willie elam update: read latest content, draft social posts, iMessage Toby for approval"
  → ~/.hermes/tasks/pending/20260522-173000-abc123.json written
  → hermes --profile claude spawned in background
  → Hermes reads willie-elam site files
  → Drafts LinkedIn + Instagram posts
  → Saves to ~/.hermes/tasks/done/willie-social-20260522.md
  → iMessages Toby: "Here are this week's social drafts. Reply APPROVE to post."
  → You approve via iMessage → Hermes posts (if social API wired)
```

---

## Adding a New Agent

1. Create `~/.hermes/profiles/<name>/` directory
2. Copy config.yaml from nearest profile (sitemanager for local, claude for cloud)
3. Write `~/.hermes/profiles/<name>/SOUL.md` — identity + mission + rules
4. Add to this AGENTS.md with role, model, invoke pattern
5. Add to TAC skill Step 4 quick reference
6. Test: `hermes --profile <name> -z "introduce yourself"`

## Google Cloud / gcloud
- Installed at: /opt/homebrew/bin/gcloud
- Auth status: NOT logged in — run `gcloud auth login` once when at desktop
- Google OAuth client: <REDACTED_GOOGLE_CLIENT_ID>
- Client secret: <REDACTED_GOOGLE_CLIENT_SECRET>
- Note: Adding redirect URIs to OAuth clients requires Google Cloud Console — no public API
- Automation scripts: ~/.claude/bootstrap/setup-google-oauth.sh, create-supabase-user.sh
