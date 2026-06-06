---
name: tac
version: 2.1.0
description: |
  TAC — Toby Anderton's Claude Code. Personal session bootstrap for Drive's
  multi-agent neural network. Syncs memory, shows Hermes agent status, displays
  active projects, model routing, skills menu, and agent ecosystem quick ref.
  Invoke when starting a new session or switching projects.
  Trigger phrases: "bootstrap", "tac", "start session", "get ready", "boot up".
allowed-tools:
  - Bash
  - Read
triggers:
  - bootstrap
  - start session
  - get ready
  - tac
  - boot up
---

# TAC — Toby Anderton's Claude Code

You are running the personal workspace bootstrap for Drive (Toby Anderton).
Execute each step below in order, showing output as you go.

## Step 1: Memory Sync

Pull latest memory from GitHub and bridge to AgentDB for semantic search:

```bash
echo "📥 Syncing memory from GitHub..."
(cd "$HOME/.claude/projects/-Users-drive/memory" && git pull origin main --quiet 2>/dev/null) && echo "✅ Memory up to date" || echo "⚠️  Offline — using local cache"
echo ""
echo "🧠 Bridging to AgentDB (HNSW vector search)..."
(cd "$HOME/.claude/memory" && bash "$HOME/.claude/bootstrap/ruflo-bridge.sh" --quiet)
```

## Autonomy Mode

This session runs in **autonomous mode**. Act without asking for permission on anything reversible — file edits, branch pushes, builds, service setup (Vercel/Supabase/CF/MCPs/APIs), installs, research. Only pause to confirm before: `rm`/delete/drop operations, force-pushing main, or removing production data. When in doubt, branch and build — never delete.

## Step 2: Session Context

Show active projects and today's date:

```bash
echo ""
echo "📅 $(date '+%A, %B %-d %Y')"
echo ""
echo "📁 Active projects:"
echo "   climb-brasil            → climbbrasil.com                 (Next.js + CF Workers)"
echo "   climb-france            → climb-france.vercel.app         (Next.js + Vercel)"
echo "   climb-spain             → climb-spain.worker-bee.app"
echo "   climb-utah              → climb-utah.worker-bee.app"
echo "   climb-kalymnos          → climb-kalymnos.worker-bee.app"
echo "   jrs-auto-repair         → jrsautorepair.worker-bee.app    (Supabase + Vitest)"
echo "   manage-worker-bee       → manage.worker-bee.app           (Blueprint canvas + Vault)"
echo "   language-lens-elite     → language-lens-elite.worker-bee.app (TanStack Start + CF Workers)"
echo "   silver-creek-logistics  → silvercreeklogistics.worker-bee.app"
echo "   orthobiologic-pathways  → orthobiologicpathways.com       (R3F + Framer Motion)"
echo "   tobyandertonmd          → tobyandertonmd.vercel.app       (marketing only)"
echo ""
echo "🔑 Stack: Next.js 16 + @opennextjs/cloudflare | Supabase | TanStack Start | Vercel"
echo "📖 Read node_modules/next/dist/docs/ before writing Next.js code (breaking changes)"
```

## Step 3: Model Routing — Cost Efficiency Guide

Show the routing guide so Sonnet is not wasted on mechanical work:

```bash
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       MODEL ROUTING — read before spawning agents              ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  HAIKU 4.5    claude-haiku-4-5          ~1/10 the cost         ║"
echo "║    ✓ curl / sips / cp / mv / rename                           ║"
echo "║    ✓ String replacements across files                         ║"
echo "║    ✓ Image download, resize, format convert                   ║"
echo "║    ✓ git add / commit / push                                  ║"
echo "║    ✓ npm install, lint, build checks                          ║"
echo "║    ✓ Anything: 'just do X to Y files'                         ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  SONNET 4.6   claude-sonnet-4-6         default model          ║"
echo "║    ✓ TypeScript architecture + new components                 ║"
echo "║    ✓ Multi-file debugging and reasoning                       ║"
echo "║    ✓ Blog/route content writing                               ║"
echo "║    ✓ Agent orchestration decisions                            ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  OPUS 4.7     claude-opus-4-7           10x Sonnet — use sparingly ║"
echo "║    ✓ High-stakes strategic/product decisions only             ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  RULE: 'Do X' tasks → Haiku. 'Design X' tasks → Sonnet.      ║"
echo "║  Agent tool: add  model:\"haiku\"  to spawn at lower cost.      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
```

## Step 4: Skills Menu

Display all available skills numbered for this session:

```bash
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           SKILLS — type /skill-name in chat                  ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  ANTIGRAVITY — NEXT.JS / REACT / FRONTEND                    ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║   1  /nextjs-best-practices        App Router, RSC, caching  ║"
echo "║   2  /nextjs-app-router-patterns   Streaming, PPR, layouts   ║"
echo "║   3  /nextjs-supabase-auth         Supabase Auth + Next.js   ║"
echo "║   4  /react-best-practices         React 19 perf patterns    ║"
echo "║   5  /shadcn                       shadcn/ui component mgmt  ║"
echo "║   6  /tailwind-design-system       Production design systems ║"
echo "║   7  /tailwind-patterns            Tailwind v4 CSS-first     ║"
echo "║   8  /landing-page-generator       High-converting pages     ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  ANTIGRAVITY — PLATFORM                                       ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║   9  /supabase-automation          DB, tables, admin         ║"
echo "║  10  /cloudflare-workers-expert    Workers, D1, R2, KV       ║"
echo "║  11  /vercel-ai-sdk-expert         AI SDK streaming/tools    ║"
echo "║  12  /vercel-deployment            Vercel + Next.js deploy   ║"
echo "║  13  /vercel-automation            CI/CD, env, project mgmt  ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  ANTIGRAVITY — SEO (1460 total — use /skill-name directly)   ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  14  /seo-aeo-blog-writer          Long-form SEO posts       ║"
echo "║  15  /seo-audit                    Crawl/index diagnostics   ║"
echo "║  16  /seo-technical                Technical SEO audit       ║"
echo "║  17  /seo-content-writer           Keyword-optimized copy    ║"
echo "║  18  /seo-keyword-strategist       Density & analysis        ║"
echo "║  19  /content-strategy             Topic clusters + roadmap  ║"
echo "║  20  /copywriting                  Conversion-focused copy   ║"
echo "║  21  /keyword-extractor            Keyword mining            ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  ANTIGRAVITY — ARCHITECTURE / AGENTS                         ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  22  /multi-agent-patterns         Multi-agent system design ║"
echo "║  23  /parallel-agents              Orchestration patterns    ║"
echo "║  24  /production-code-audit        Deep codebase scan        ║"
echo "║  25  /prompt-engineering           Prompt design patterns    ║"
echo "║  26  /github-actions-templates     CI/CD workflow templates  ║"
echo "║  27  /api-design-principles        REST/GraphQL design       ║"
echo "║  28  /testing-patterns             Jest + factory patterns   ║"
echo "║  29  /e2e-testing-patterns         E2E test suite design     ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  RUFLO (invoke: /plugin:ruflo-X:skill-name)                  ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  30  /ruflo-rag-memory:ruflo-memory   Vector store/search    ║"
echo "║  31  /ruflo-cost-tracker:ruflo-cost   Token cost tracking    ║"
echo "║  32  /ruflo-sparc:ruflo-sparc         SPARC methodology      ║"
echo "║  33  ruflo-swarm:coordinator          Swarm orchestration    ║"
echo "║  34  ruflo-core:coder                 Code implementation    ║"
echo "║  35  ruflo-goals:goal-planner         GOAP A* planning       ║"
echo "║  36  ruflo-security-audit:security-auditor  Vuln scan        ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  GSTACK (invoke: /skill-name)                                ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  37  /review          Staff engineer code review             ║"
echo "║  38  /ship            PR + merge automation                  ║"
echo "║  39  /qa              Browser QA against staging URL         ║"
echo "║  40  /cso             Security OWASP+STRIDE audit            ║"
echo "║  41  /investigate     Deep-dive debugging                    ║"
echo "║  42  /autoplan        Auto-plan before coding                ║"
echo "║  43  /office-hours    CEO product thinking                   ║"
echo "║  44  /plan-eng-review Architecture lockdown                  ║"
echo "║  45  /design-shotgun  Multiple UI directions                 ║"
echo "║  46  /context-save / /context-restore  Session state         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  + 1,460 antigravity skills installed — /skill-name to invoke any"
```

## Step 5: Hermes Agent Status

Check if the neural network's background agent is available:

```bash
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              NEURAL NETWORK — AGENT STATUS                   ║"
echo "╠══════════════════════════════════════════════════════════════╣"
# Test hermes claude profile
HERMES_TEST=$(hermes --profile claude -z "ok" 2>&1 | tail -1)
if echo "$HERMES_TEST" | grep -qi "ok\|yes\|sure\|hello\|ready"; then
  echo "║  🟢 Hermes          claude-sonnet-4-6  API key      ONLINE   ║"
else
  echo "║  🔴 Hermes          claude-sonnet-4-6               OFFLINE  ║"
fi
# Test hermes-jr (Max OAuth via claude -p)
JR_TEST=$(HERMES_HOME="$HOME/.hermes-jr" hermes-jr --profile claude -z "ok" 2>&1 | tail -1)
if echo "$JR_TEST" | grep -qi "ok\|yes\|sure\|hello\|ready"; then
  echo "║  🟢 Hermes Jr       claude-sonnet-4-6  Max OAuth    ONLINE   ║"
else
  echo "║  🔴 Hermes Jr       claude-sonnet-4-6               OFFLINE  ║"
fi
# Check Qwen 3.6 27B (llama-server port 8090)
if curl -s --max-time 2 http://localhost:8090/v1/models > /dev/null 2>&1; then
  echo "║  🟢 Qwen 3.6-27B    llama-server :8090  M1 Ultra    ONLINE   ║"
else
  echo "║  🟡 Qwen 3.6-27B    llama-server :8090               OFFLINE ║"
fi
# Check LM Studio (port 1234 — embedding model)
if curl -s --max-time 2 http://localhost:1234/v1/models > /dev/null 2>&1; then
  echo "║  🟢 LM Studio       local models  :1234              ONLINE   ║"
else
  echo "║  🟡 LM Studio       local models  :1234              OFFLINE  ║"
fi
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  QUICK COMMANDS                                              ║"
echo "║  jr \"task\"                         Hermes Jr oneshot (sync)  ║"
echo "║  jrs \"task\"                        Hermes Jr sitemanager     ║"
echo "║  jr -p teacher \"task\"              Hermes Jr + personality   ║"
echo "║  wba \"task\"                        wba inline                ║"
echo "║  wba -b \"task\"                     wba background queue      ║"
echo "║  herm                              full agent command list   ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  JR → TAC injection: synchronous Bash only                  ║"
echo "║  Bash(timeout=600000) + jr \"task\"  output returned to TAC   ║"
echo "║  Bash(run_in_background=True)      TAC blind — fire&forget  ║"
echo "║  ls -t /tmp/jr-*.txt | head -1     recover missed output    ║"
echo "║  NEVER: hermes-jr -z '...' &       bypasses jr wrapper       ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  DISPATCH — Claude Code → Hermes handoff                    ║"
echo "║  dispatch --bg \"task\"              fire-and-forget (sonnet)  ║"
echo "║  dispatch --bg --profile haiku \"…\" run task at haiku cost    ║"
echo "║  dispatch --urgent \"task\"          priority queue            ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  ACTIVE CRON JOBS                                            ║"
echo "║  site-monitor          every 30m    site health → iMessage   ║"
echo "║  md-vault-graph-refresh every 4h    /api/graph health check  ║"
echo "║  willie-elam-social    Mon 8am      social draft → iMessage  ║"
echo "║  memory-daily-sync     7am daily    git pull + AgentDB sync  ║"
echo "║  lbs-daily-sync        6am daily    LBS inventory → Supabase ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  IDENTITY FILES                                              ║"
echo "║  ~/.claude/SOUL.md          Claude Code identity             ║"
echo "║  ~/.claude/AGENTS.md        Full agent ecosystem map         ║"
echo "║  ~/.hermes/SOUL.md          Hermes original identity         ║"
echo "║  ~/.hermes-jr/SOUL.md       Hermes Jr identity               ║"
echo "║  ~/.hermes-jr/profiles/*/   Hermes Jr profile SOULs          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
```

## Step 6: Memory CRUD Quick Reference

```bash
echo ""
echo "  Memory commands (global AgentDB — always semantic-searchable):"
echo "  mem-search \"your query\"        — semantic search across all history"
echo "  mem-store KEY \"value\" [ns]     — store a note"
echo "  mem-get KEY [ns]               — retrieve by exact key"
echo "  mem-list [ns]                  — list recent entries"
echo "  ruflo sync                     — re-sync from GitHub → AgentDB"
echo "  hermes memory search \"query\"   — search Hermes SQLite memory"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TAC v2 ready. Neural network active. Build fast, ship clean."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
```

## Step 7: Dev Split View + Build Studio

Start the devtools server (port 3333) if not running, then open Build Studio:

```bash
if lsof -ti :3333 > /dev/null 2>&1; then
  echo "✅ Devtools server already running (port 3333)"
else
  echo "🖥️  Starting devtools server..."
  node /Users/drive/devtools/server.mjs > /tmp/devtools.log 2>&1 &
  sleep 2
  if lsof -ti :3333 > /dev/null 2>&1; then
    echo "✅ Devtools server ready (port 3333)"
  else
    echo "⚠️  Devtools server failed — check /tmp/devtools.log"
  fi
fi

# Open Build Studio in browser
open "https://manage.worker-bee.app/build-studio" 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  BUILD STUDIO                                                ║"
echo "║  https://manage.worker-bee.app/build-studio                  ║"
echo "║  Terminal → wss://devtools.tobyandertonmd.com (CF tunnel)    ║"
echo "║  Screenshot: node ~/screenshot.js <port> [scrolls]           ║"
echo "║  Video:      node ~/record.js <port> [--mobile|--fast|--slow]║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
```

To start a project dev server and load it in the Build Studio preview pane:
```bash
# cd /Users/drive/<project> && npx next dev -H 0.0.0.0 -p <port>
# Then paste http://100.117.143.57:<port> into the Build Studio preview URL bar
```

## Step 8: Project Todos

Display pending tasks from the todo list (last thing before asking what to work on):

```bash
TODOS="$HOME/.claude/todos.json"
if [ -f "$TODOS" ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║                    PROJECT TODOS                             ║"
  echo "╠══════════════════════════════════════════════════════════════╣"
  node -e "
    const todos = JSON.parse(require('fs').readFileSync(process.env.HOME + '/.claude/todos.json','utf8'));
    const W = 60;
    todos.forEach(proj => {
      const done  = proj.tasks.filter(t=>t.done).length;
      const total = proj.tasks.length;
      if (done === total) return; // skip fully-done projects
      const header = '  ■ ' + proj.project + '  (' + done + '/' + total + ')';
      console.log('║' + header.padEnd(W) + '║');
      proj.tasks.filter(t=>!t.done).forEach(task => {
        const prefix = '    ○ ';
        const maxLen = W - prefix.length - 1;
        const text = task.text.length > maxLen ? task.text.slice(0,maxLen-1)+'…' : task.text;
        console.log('║' + (prefix + text).padEnd(W) + '║');
      });
      console.log('║' + ''.padEnd(W) + '║');
    });
  " 2>/dev/null || echo "║  (run: cat ~/.claude/todos.json to check)                  ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "  Dashboard: https://100.117.143.57:8094 → Todos tab"
  echo ""
fi
```

## Step 9: Topic Focus

Check if a topic was passed as an argument to `/tac`:

- **If an argument was provided** (e.g. `/tac nexus`): skip asking — use the argument as the topic directly.
  Run `mem-search "<argument>"` immediately and say: "Focusing on **<argument>** — here's what I remember:"
- **If no argument**: ask "What do you want to work on today?" then run `mem-search` using keywords from their answer.

Either way, surface prior context before starting work.
