---
name: tac-hermes
version: 1.0.0
description: |
  Fire a task to Hermes from inside Claude Code. Starts the local Qwen3.6 server
  if needed, dispatches the task, and streams output directly into the Claude session.
  Supports three profiles: claude (API), local (Qwen3.6 Metal), sitemanager (API).
  Trigger phrases: "tac-hermes", "fire hermes", "send to hermes", "hermes run", "dispatch hermes".
allowed-tools:
  - Bash
  - AskUserQuestion
triggers:
  - tac-hermes
  - fire hermes
  - send to hermes
  - hermes run
  - dispatch hermes
---

# TAC-Hermes — Dispatch Hermes from Claude

## Step 1 — Get the task and profile

If the user typed `/tac-hermes <task>` with a task inline, use it directly.
If no task was provided, ask:

- **Task**: what should Hermes do?
- **Profile**: claude (API, general), local (Qwen3.6 Metal, free, vision), sitemanager (API, orthobiologic site)

Default profile: `claude`.

## Step 2 — Local profile: ensure server is running

If profile is `local`:

```bash
if curl -s http://localhost:8090/health 2>/dev/null | grep -q "ok"; then
  echo "✅ Hermes-Local server already running"
else
  echo "🚀 Starting Qwen3.6-27B server on port 8090..."
  nohup ~/.hermes/local/start-qwen3.sh > /tmp/llama-local.log 2>&1 &
  LLAMA_PID=$!
  echo "Server PID: $LLAMA_PID (log: /tmp/llama-local.log)"
  for i in $(seq 1 60); do
    sleep 2
    curl -s http://localhost:8090/health 2>/dev/null | grep -q "ok" && { echo "✅ Ready after $((i*2))s"; break; }
    echo "  loading... $((i*2))s"
  done
fi
```

## Step 3 — Run Hermes and stream output into session

```bash
hermes --profile <profile> -z "<task>"
```

The output streams directly into the Claude Code chat window. Claude can read, comment on, and continue from Hermes' work.

## Step 4 — Report result

After Hermes completes, summarize:
- What Hermes did
- Any files created or modified
- Any errors encountered
- Suggested next steps

## Profiles quick reference

| Profile | Model | Cost | Use when |
|---|---|---|---|
| `claude` | claude-sonnet-4-6 (API) | API tokens | General tasks, complex reasoning |
| `local` | Qwen3.6-27B Metal | Free | Vision tasks, long runs, no API budget |
| `sitemanager` | claude-sonnet-4-6 (API) | API tokens | Orthobiologic site, LBS Pro |

## One-liner aliases (already in ~/.zshrc)

```bash
! hc "task"   # → hermes --profile claude -z "task"
! hl "task"   # → hermes --profile local -z "task"
! hs "task"   # → hermes --profile sitemanager -z "task"
! jr "task"   # → HERMES_HOME=~/.hermes-jr hermes-jr --profile claude -z "task"
! jrs "task"  # → HERMES_HOME=~/.hermes-jr hermes-jr --profile sitemanager -z "task"
```

## Hermes Jr (Max OAuth) — output injection into TAC

`jr` auto-tees every run to `/tmp/jr-YYYYMMDD-HHMMSS.txt` as a safety net.
**But TAC can only read and act on jr output when the Bash call is synchronous.**

```
Synchronous Bash(timeout=600000)  →  jr output returned as tool result  →  TAC acts on it  ✅
Bash(run_in_background=True)      →  output never enters TAC context    →  TAC is blind     ❌
```

**Canonical pattern — TAC dispatches jr and acts on result:**
```bash
# Bash tool: timeout=600000, run_in_background=False (default)
jr "task description"
```
Output lands in the tool result. TAC reads it immediately and can take follow-up actions.

**Vision run pattern:**
```bash
jr "Start dev server at '<project-path>' on port 5174. Screenshot routes / /page1 /page2 with node ~/screenshot.js 5174 0,540,1080. Read each PNG section-by-section. Report visual findings. Kill server when done."
```

**Recovery (if a past run used run_in_background by mistake):**
```bash
cat $(ls -t /tmp/jr-*.txt | head -1)
```

**NEVER:** `Bash(run_in_background=True)` for jr tasks TAC must follow up on.
**NEVER:** `hermes-jr -z "..." &` directly — bypasses the `jr` wrapper entirely.
