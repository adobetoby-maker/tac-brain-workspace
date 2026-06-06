---
name: owen
version: 1.0.0
description: |
  Owen — local AI session bootstrap. Sets ANTHROPIC_BASE_URL to LiteLLM proxy
  routing to qwen2.5vl:72b (Owen) running on Ollama. Mirrors /tac but runs
  entirely locally at zero API cost. Shows Owen status, overnight queue, and
  project context. Use for overnight builds, large tasks, and cost-free sessions.
  Trigger phrases: "owen", "local ai", "start owen", "overnight", "boot owen".
allowed-tools:
  - Bash
  - Read
triggers:
  - owen
  - local ai
  - start owen
  - overnight
  - boot owen
---

# Owen — Local AI Session Bootstrap

Owen is qwen2.5vl:72b running on Ollama via LiteLLM proxy.
Vision + reasoning + tool calling. 128k context. 100% local. Zero API cost.

Execute each step below in order.

## Step 1: Set Environment

```bash
export ANTHROPIC_BASE_URL="http://localhost:4000"
export ANTHROPIC_API_KEY="local-overnight-key"
echo "🦉 Owen session — routing to local qwen2.5vl:72b"
echo "   ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"
```

## Step 2: Check Owen Stack

```bash
echo ""
if pgrep -x ollama > /dev/null; then
  echo "✅ Ollama running"
else
  echo "⚠️  Ollama not running — starting..."
  nohup ollama serve > ~/.claude/logs/ollama.log 2>&1 &
  sleep 3 && echo "✅ Ollama started"
fi

if lsof -ti :4000 > /dev/null 2>&1; then
  echo "✅ LiteLLM proxy on :4000"
else
  echo "⚠️  LiteLLM not running — starting..."
  nohup litellm --config ~/.claude/litellm-config.yaml --port 4000 \
    > ~/.claude/logs/litellm.log 2>&1 &
  sleep 5 && echo "✅ LiteLLM started"
fi

echo ""
echo "🦉 Owen model status:"
ollama ps 2>/dev/null | grep -E "NAME|owen|qwen" || echo "   Owen not loaded yet — will load on first request (~30s cold start, then stays warm)"
echo ""
echo "   Model:    qwen2.5vl:72b  (vision + reasoning + tool calling)"
echo "   Context:  128k tokens    (64k KV cache, 100% GPU on M1 Ultra)"
echo "   Speed:    ~8-10 tok/s    (warm — stays loaded between tasks)"
echo "   Cost:     \$0.00          (fully local, Metal-accelerated)"
```

## Autonomy Mode

Owen sessions run in **autonomous mode**. Act without asking for permission on
anything reversible. Only pause before: rm/delete/drop, force-push main, production
data deletion. When in doubt: branch and build, never delete.

## Step 3: Session Context

```bash
echo ""
echo "📅 $(date '+%A, %B %-d %Y')"
echo ""
echo "📁 Active projects:"
echo "   climb-france      → climb-france.vercel.app    (building — Owen overnight)"
echo "   climb-kalymnos    → climb-kalymnos.vercel.app  (Next.js, 4-lang EN/DE/IT/GR)"
echo "   climb-brasil      → climbbrasil.com             (Next.js + Cloudflare Workers)"
echo "   climb-utah        → climb-utah.vercel.app       (Next.js)"
echo "   climb-spain       → climb-spain.vercel.app      (Next.js)"
echo "   jrs-auto-repair   → jrsautorepair.com           (Next.js + Supabase)"
echo "   manage-worker-bee → manage.worker-bee.app       (Blueprint canvas + Vault)"
echo "   language-lens     → language-lens-elite (TanStack Start + CF Workers)"
echo ""
echo "   Dev ports: kalymnos:3001  france:3002  manage:3000"
echo "   Screenshots: node ~/screenshot.js <port> <scroll1,scroll2,...>"
echo "   Video:       node ~/record.js <port> [--mobile|--fast|--slow]"
```

## Step 4: Overnight Queue Status

```bash
echo ""
echo "📋 Overnight queue:"
echo ""
QUEUE=~/.claude/overnight-queue.md
pending=$(grep -c "^- \[ \]" "$QUEUE" 2>/dev/null || echo 0)
done=$(grep -c "^- \[x\]" "$QUEUE" 2>/dev/null || echo 0)
echo "   Pending: $pending tasks"
echo "   Done:    $done tasks"
echo ""
echo "   Next up:"
grep "^- \[ \]" "$QUEUE" 2>/dev/null | head -3 | sed 's/^/   /'
echo ""
echo "   Run queue:    overnight-build"
echo "   Dry run:      overnight-dry"
echo "   Watch log:    tail -f ~/.claude/logs/overnight-$(date '+%Y-%m-%d').log"
```

## Step 5: Owen vs Sonnet — When To Use Each

```bash
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║              OWEN vs SONNET — pick the right tool                ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║  OWEN (local qwen2.5vl:72b)           \$0.00/task                 ║"
echo "║    ✓ Overnight builds — all 10-iter France tasks                 ║"
echo "║    ✓ Clone cleanup — grep/replace across files                  ║"
echo "║    ✓ Content writing — sectors, copy, MD files                  ║"
echo "║    ✓ Vision review — screenshot + fix layout issues             ║"
echo "║    ✓ SEO — JSON-LD, meta tags, robots.txt, sitemaps             ║"
echo "║    ✓ Mechanical tasks — anything 'just do X to Y files'         ║"
echo "║    ✗ Novel architecture decisions → use Sonnet                  ║"
echo "║    ✗ Complex multi-file debugging → use Sonnet                  ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║  SONNET 4.6 (Anthropic API)           ~\$0.05–0.50/task           ║"
echo "║    ✓ TypeScript architecture + new component design             ║"
echo "║    ✓ Complex debugging across many files                        ║"
echo "║    ✓ Strategic product decisions                                ║"
echo "║    ✓ Tasks that failed on Owen and need stronger reasoning      ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Owen ready. Zero cost. Full vision. Build overnight."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
```

## Step 6: Topic Focus

Check if an argument was passed to `/owen`:

- **If an argument provided** (e.g. `/owen france`): use it as the topic directly.
  Say: "Focusing on **<argument>** with Owen — here's the queue status and what I know:"
  Then show relevant tasks from the overnight queue for that project.
- **If no argument**: ask "What should Owen work on?" and route accordingly —
  mechanical/content tasks go straight to Owen, architecture tasks get flagged for Sonnet.
