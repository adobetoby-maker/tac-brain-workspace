#!/bin/bash
# PreToolUse hook — Bash tool — Deploy Gate
# Fires before any Bash call. Checks for deploy commands and runs platform gate.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Only fire on deploy commands
if ! echo "$COMMAND" | grep -qE "(vercel --prod|vercel deploy --prod|wrangler deploy|npx wrangler deploy|opennextjs-cloudflare)"; then
  exit 0
fi

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  DEPLOY GATE — ADR-0014 / Iron Law 4                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"

# Platform decision: check for CF bindings
CWD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('cwd', ''))
except:
    print('')
" 2>/dev/null)

WRANGLER_FILE="${CWD}/wrangler.jsonc"
if [ ! -f "$WRANGLER_FILE" ]; then
  WRANGLER_FILE="${CWD}/wrangler.json"
fi

HAS_BINDINGS=""
if [ -f "$WRANGLER_FILE" ]; then
  HAS_BINDINGS=$(grep -E "d1_databases|r2_buckets|kv_namespaces" "$WRANGLER_FILE" 2>/dev/null | head -1)
fi

if [ -n "$HAS_BINDINGS" ]; then
  echo "Platform: Cloudflare Workers (D1/R2/KV bindings detected)"
  CFTOKEN=$(env | grep "^CLOUDFLARE_API_TOKEN=" | head -1)
  if [ -z "$CFTOKEN" ]; then
    echo "WARNING: CLOUDFLARE_API_TOKEN not in env — deploy will fail"
    echo "Run Iron Law 2 fallback: vercel --prod | GitHub auto-deploy | MCP deploy"
  else
    echo "CLOUDFLARE_API_TOKEN: present ✓"
  fi
else
  echo "Platform: No D1/R2/KV bindings → Marketing/SaaS site → Vercel"
  VERCEL_AUTH=$(vercel whoami 2>/dev/null | tr -d '\n')
  if [ -n "$VERCEL_AUTH" ]; then
    echo "Vercel auth: $VERCEL_AUTH ✓"
  else
    echo "Vercel auth: not cached — may need authentication"
  fi
fi

echo ""
echo "After deploy exits 0 → run: curl -sI <live-url> | head -1"
echo "Must return HTTP 200 before declaring done."
