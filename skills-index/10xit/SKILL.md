---
name: 10xit
description: |
  10xit (ten-exit) — audit any project across 10 dimensions, score it 0–100,
  find everything missing, and fix it until the project is 10x-ready to ship.
  Trigger phrases: "10xit", "10x this", "what's missing", "make it production ready",
  "audit this project", "ship-ready check", "what am I missing"
version: 1.0.0
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Agent
triggers:
  - 10xit
  - 10x this
  - 10x it
  - what's missing
  - make it production ready
  - audit this project
  - ship-ready check
  - what am i missing
---

# 10xit — Ship Nothing Until It Scores 10/10

## IRON LAW — Visual Review Is Non-Negotiable

**This fires before Step 1. No exceptions. No deferrals.**

```bash
# Start dev server if not running
lsof -ti :3000 >/dev/null 2>&1 || (cd /Users/drive/$(basename $(pwd)) && npm run dev -H 0.0.0.0 &)
sleep 2

# Take screenshots — ALL 4 viewports
node ~/screenshot.js 3000 0,540,1080

# Record scroll video — desktop + mobile
node ~/record.js 3000
node ~/record.js 3000 --mobile

# Extract frames
ffmpeg -i /tmp/preview/review.webm -vf fps=2 /tmp/preview/frames/frame_%03d.png -y 2>/dev/null

# Read EVERY PNG with the Read tool. Describe what is visible.
# Read final 3 frames to confirm footer reached.
```

**Banned phrases until screenshots are Read:**
- "Visual looks good" — not a substitute for Read tool on PNG
- "UI appears correct" — describe pixels, not assumptions
- "Skipping visuals — internal tool" — no such exception
- "Deferring D4" — D4 is never deferred

**If auth wall blocks the screenshot:** screenshot the login page + note which routes are auth-gated. That IS a finding (D4 -2pts per blocked route that can't be verified). Note it explicitly, do not silently skip.

Humans interact with computers through their eyes. You have screenshot tools. Use them every single time. The fastest path to catching real bugs is looking at the actual rendered output, not reading code.

---

## What This Is

A project exits development only when it scores 10/10 across 10 dimensions.
Each dimension has an observable bash check — no guessing, no intent, only state.

**Score:** Each dimension is 0–10. Total: 0–100. Ship at 90+. Fix blockers first.

---

## The 10 Dimensions

| # | Dimension | Weight | Exit Condition |
|---|---|---|---|
| 1 | **Code Quality** | 10 | Zero TS errors, zero lint errors, build passes |
| 2 | **Security** | 10 | No exposed secrets, no XSS vectors, auth on protected routes |
| 3 | **Completeness** | 10 | Zero TODOs, zero [DEMO] tags, all routes reachable |
| 4 | **Visual / UX** | 10 | All 4 viewports pass, no broken layouts, error/empty states exist |
| 5 | **Performance** | 10 | LCP <2.5s, no blocking resources, images optimized |
| 6 | **SEO** | 10 | Title, description, OG, canonical, sitemap, robots.txt |
| 7 | **Tests** | 10 | Build passes, key paths have at least smoke tests |
| 8 | **Documentation** | 10 | CLAUDE.md current, env vars documented, deploy command known |
| 9 | **Deployment** | 10 | Live URL returns 200, HTTPS, no auth wall blocking public pages |
| 10 | **Memory** | 10 | Project in manage.worker-bee, memory updated, blueprint pushed |

---

## Step 1 — Identify Project

Ask if not clear from context:
```
Which project? (path or name)
```

Then read:
```bash
cat CLAUDE.md 2>/dev/null | head -40
ls -la
cat package.json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('name'), d.get('version'))"
```

---

## Step 2 — Run All 10 Checks

Run these bash checks. Record pass/fail/score for each.

### D1 — Code Quality (0–10)

```bash
# TypeScript
npx tsc --noEmit 2>&1 | tail -5
# → Zero output = 10. Each error = -1. More than 5 errors = 0.

# Lint
npm run lint 2>&1 | grep -c "error" || echo "0"
# → 0 errors = 10. 1-3 errors = 7. 4+ = 0.

# Build
npm run build 2>&1 | tail -3
# → "compiled successfully" or "build complete" = 10. Failure = 0.
```

**Score:** tsc_score × 0.4 + lint_score × 0.3 + build_score × 0.3

---

### D2 — Security (0–10)

```bash
# No hardcoded secrets
grep -rn "sk_live\|api_key\s*=\s*['\"][^'\"]\|password\s*=\s*['\"][^'\"]" \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude-dir=node_modules --exclude-dir=.next | grep -v ".env" | wc -l
# → 0 = 10. Any hits = investigate.

# No .env committed
git log --all --oneline -- '*.env' | head -3

# Auth check — protected routes need middleware/auth
grep -rn "supabaseAdmin\|service_role" app/ --include="*.tsx" | grep -v "api/" | wc -l
# → Client Components importing service role = critical fail.

# XSS — dangerouslySetInnerHTML without sanitization
grep -rn "dangerouslySetInnerHTML" --include="*.tsx" --include="*.jsx" \
  --exclude-dir=node_modules | grep -v "sanitize\|DOMPurify" | wc -l
# → 0 = 10.
```

**Score:** No secrets (4) + No .env in git (3) + No service role in client (3)

---

### D3 — Completeness (0–10)

```bash
# TODOs in code
grep -rn "TODO\|FIXME\|HACK\|XXX\|@ts-ignore\|@ts-expect-error" \
  --include="*.ts" --include="*.tsx" --include="*.js" \
  --exclude-dir=node_modules | wc -l
# → 0 = 10. Each TODO = -0.5 (min 0).

# [DEMO] placeholder tags (client handoff protocol)
grep -rn "\[DEMO\]" app/ components/ lib/ 2>/dev/null | wc -l
# → 0 = 10. Any = fail.

# console.error / console.warn in production code
grep -rn "console\.error\|console\.warn" \
  --include="*.ts" --include="*.tsx" --exclude-dir=node_modules | \
  grep -v "// " | wc -l
# → 0 = 10.

# Missing pages (check for common 404s)
# If site has nav links, grep hrefs and verify routes exist
grep -rh 'href="/' --include="*.tsx" | grep -oE 'href="[^"]*"' | \
  sort -u | head -20
```

**Score:** No TODOs (3) + No DEMO (4) + No console errors (3)

---

### D4 — Visual / UX (0–10) — MANDATORY, NEVER SKIP

```bash
# Ensure server is running — start it if not
lsof -ti :3000 >/dev/null 2>&1 || (npm run dev -- -H 0.0.0.0 -p 3000 & sleep 4)
PORT=3000

# Screenshots — desktop, mid-scroll, bottom
node ~/screenshot.js $PORT 0,540,1080

# Scroll video — must reach footer in final frame
node ~/record.js $PORT

# Mobile video
node ~/record.js $PORT --mobile

# Extract frames
ffmpeg -i /tmp/preview/review.webm -vf fps=2 /tmp/preview/frames/frame_%03d.png -y 2>/dev/null
```

**Read EVERY PNG file using the Read tool. No exceptions.**
**Read the final 3 video frames. Footer must be visible. If not → harness broken → fix it.**

**Score per viewport:**
- Desktop 1440 (3pts): No broken layouts, text readable, CTAs visible
- Mobile 375 (3pts): No horizontal scroll, touch targets ≥44px, no overlap
- 4K 2560 (2pts): No stretched elements
- Scroll/video (2pts): No animation jank, footer reachable

Empty state check:
```bash
grep -rn "length === 0\|\.length == 0\|isEmpty" --include="*.tsx" | wc -l
# → Some empty states exist = good. Zero = possible gap.
```

---

### D5 — Performance (0–10)

```bash
# Bundle size
ls -lh .next/static/chunks/ 2>/dev/null | sort -k5 -rh | head -10
# → No chunk > 500kB uncompressed = 10.

# Images — next/image usage
grep -rn "<img " --include="*.tsx" | grep -v "node_modules" | wc -l
# → 0 raw <img> tags = 10. Each = -1.

# 'use client' overuse
grep -rn "'use client'" --include="*.tsx" | grep -v node_modules | wc -l
# → < 30% of components = fine.

# Priority on hero images
grep -rn "priority\|fetchPriority" --include="*.tsx" | grep -i "hero\|above\|banner" | wc -l

# HTML page weight
# curl -s https://live-url | wc -c  (run after deploy verified)
```

**Score:** Bundle size (3) + No raw imgs (3) + use client lean (2) + priority images (2)

---

### D6 — SEO (0–10)

```bash
# Meta tags check (run against dev server or live URL)
URL=${LIVE_URL:-"http://localhost:3000"}
curl -s "$URL" | grep -E '<title>|<meta name="description"|<link rel="canonical"' | head -5
curl -s "$URL" | grep -E 'og:title|og:description|og:image|twitter:card' | head -5

# Sitemap
curl -sI "${URL}/sitemap.xml" | head -1
# → 200 = pass.

# Robots.txt
curl -sI "${URL}/robots.txt" | head -1
# → 200 = pass.

# H1 count
curl -s "$URL" | grep -c "<h1"
# → Exactly 1 = 10. 0 = -3. 2+ = -2.

# JSON-LD
curl -s "$URL" | grep -c "application/ld+json"
# → 1+ = pass.

# lang attribute
curl -s "$URL" | grep 'lang='
```

**Score:** title+desc (2) + OG tags (2) + sitemap+robots (2) + H1 (1) + JSON-LD (1) + canonical (1) + lang (1)

---

### D7 — Tests (0–10)

```bash
# Test files exist
find . -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" \
  -o -name "*.test.js" | grep -v node_modules | wc -l
# → 0 = 0. 1-5 = 5. 6+ = 8. With passing = 10.

# Run tests
npm test 2>&1 | tail -5
# → All pass = 10. Any fail = 0.

# If no tests, check at minimum: build passes (D1) + routes reachable (D3)
```

**Score:** Tests exist (5) + Tests pass (5). No tests = 3 if build+lint pass cleanly.

---

### D8 — Documentation (0–10)

```bash
# CLAUDE.md exists and is current
ls CLAUDE.md 2>/dev/null && wc -l CLAUDE.md
# → Exists + 150-300 lines = 10.

# Env vars documented
grep -c "^[A-Z_]*=" .env.example 2>/dev/null || grep -c "^[A-Z_]" CLAUDE.md | head -1
# → All vars have names in CLAUDE.md or .env.example = 10.

# Deploy command documented
grep -n "vercel\|wrangler\|deploy" CLAUDE.md | head -5

# README exists
ls README.md 2>/dev/null

# No placeholder secrets in committed env files
grep -rn "\[YOUR-PASSWORD\]\|<your-key>\|REPLACE_ME\|your_secret" \
  --include="*.env*" --include="*.toml" --include="*.json" \
  --exclude-dir=node_modules | grep -v ".example" | wc -l
# → 0 = pass.
```

**Score:** CLAUDE.md exists (3) + env vars documented (3) + deploy command known (2) + no placeholders (2)

---

### D9 — Deployment (0–10)

```bash
LIVE_URL="$(grep -oE 'https://[a-z0-9.-]+\.(app|com|io|dev|net)' CLAUDE.md | head -1)"

# Live URL returns 200
curl -sI "$LIVE_URL" | head -1
# → HTTP/2 200 = 10. Anything else = 0.

# HTTPS only
curl -sI "http://$(echo $LIVE_URL | sed 's|https://||')" | grep -i location
# → Redirects to https = good.

# No Vercel auth wall on public pages
curl -s "$LIVE_URL" | grep -c "You need to be authenticated"
# → 0 = pass.

# Check for error pages
curl -sI "${LIVE_URL}/nonexistent-route-xyz" | head -1
# → 404 = correct. 200 = check if it's a real 404 or catch-all.
```

**Score:** 200 live (5) + HTTPS (2) + No auth wall (2) + 404 works (1)

---

### D10 — Memory & Tracking (0–10)

```bash
# In manage.worker-bee
SITE_EXISTS=$(curl -s "https://manage.worker-bee.app/api/sites" \
  -H "x-api-key: 9fd6a40a79137d7fdb4ea7dc97d7c40478af2fae339dc8b25cc4595bd8dd1747" | \
  python3 -c "
import sys, json
sites = json.load(sys.stdin)
name = '$(basename $(pwd))'
match = [s for s in sites if name.lower() in s.get('name','').lower()]
print('FOUND' if match else 'MISSING')
" 2>/dev/null)
echo "manage.worker-bee: $SITE_EXISTS"

# Memory file exists
ls ~/.claude/projects/-Users-drive/memory/project_*.md | \
  xargs grep -l "$(basename $(pwd))" 2>/dev/null | wc -l

# Blueprint pushed (check blueprint API)
SITE_ID=$(curl -s "https://manage.worker-bee.app/api/sites" \
  -H "x-api-key: 9fd6a40a79137d7fdb4ea7dc97d7c40478af2fae339dc8b25cc4595bd8dd1747" | \
  python3 -c "
import sys, json
sites = json.load(sys.stdin)
name = '$(basename $(pwd))'
match = [s for s in sites if name.lower() in s.get('name','').lower()]
print(match[0]['id'] if match else '')
" 2>/dev/null)
echo "Site ID: $SITE_ID"
```

**Score:** In manage.worker-bee (4) + Memory file exists (3) + Blueprint has nodes (3)

---

## Step 3 — Build Scorecard

Present results as a table:

```
╔════════════════════════════════════════════════════════╗
║  10xit SCORECARD — [Project Name]                      ║
╠════╦══════════════════╦═══════╦═══════════════════════╣
║  # ║ Dimension        ║ Score ║ Key Finding           ║
╠════╬══════════════════╬═══════╬═══════════════════════╣
║  1 ║ Code Quality     ║  8/10 ║ 2 TS errors remain    ║
║  2 ║ Security         ║ 10/10 ║ ✓ Clean               ║
║  3 ║ Completeness     ║  6/10 ║ 4 TODOs, 0 DEMO tags  ║
║  4 ║ Visual / UX      ║  9/10 ║ Mobile CTA overlap    ║
║  5 ║ Performance      ║  7/10 ║ 2 raw <img> tags       ║
║  6 ║ SEO              ║  8/10 ║ Missing JSON-LD        ║
║  7 ║ Tests            ║  5/10 ║ No tests exist         ║
║  8 ║ Documentation    ║ 10/10 ║ ✓ CLAUDE.md current   ║
║  9 ║ Deployment       ║ 10/10 ║ ✓ Live + 200           ║
║ 10 ║ Memory           ║  8/10 ║ Blueprint empty        ║
╠════╬══════════════════╬═══════╬═══════════════════════╣
║    ║ TOTAL            ║ 81/100║ 🟡 Nearly ship-ready  ║
╚════╩══════════════════╩═══════╩═══════════════════════╝

Status: 🟡 Fix 3 blockers → ship
```

Status thresholds:
- 90–100 = 🟢 Ship it
- 75–89  = 🟡 Fix priority items first
- 50–74  = 🟠 Significant gaps — fix before client sees it
- 0–49   = 🔴 Not ready — rebuild first

---

## Step 4 — Priority Fix List

Rank findings by impact × effort:

```
PRIORITY FIXES (impact/effort):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 P1 — BLOCKERS (fix now, 0 effort)
   • [D3] 4 TODOs in checkout flow — grep output above
   • [D5] 2 raw <img> → convert to next/image

🟡 P2 — HIGH IMPACT (fix before handoff)
   • [D6] Add JSON-LD Organization schema to layout.tsx
   • [D4] Fix mobile CTA overlap at 375px

🟢 P3 — NICE TO HAVE (after ship)
   • [D7] Add smoke tests for /api/checkout route
   • [D10] Push blueprint nodes to manage.worker-bee
```

---

## Step 5 — Fix Mode

After showing the scorecard, ask:

> **Fix all P1+P2 items now? (y / show list / specific dimension)**

- `y` → Fix all P1 and P2 items automatically, re-run affected checks, update scorecard
- `show list` → Show full issue list with file:line references
- `d3` or `security` → Fix that dimension only
- `skip` → Ship the scorecard as-is

**When fixing:**
1. Fix one dimension at a time
2. Re-run that dimension's bash checks after fixing
3. Update the score
4. Show delta: "D3: 6→9 (+3). Total: 81→84."
5. Proceed to next

---

## Step 6 — Re-Score & Exit

After fixes, re-run all affected checks and show final scorecard.

If score ≥ 90:
```
✅ 10xit PASSED — 92/100
Project is ship-ready. Pushing memory update...
```

Then automatically:
1. Push blueprint to manage.worker-bee.app
2. Update `~/.claude/projects/-Users-drive/memory/now.md`
3. Commit any fixes: `git add -A && git commit -m "10xit: raise quality score 81→92"`

If score < 90:
```
🟡 10xit score: 84/100
Remaining gaps:
  • [D7] Tests — 3pts available (add smoke tests for key routes)
  • [D10] Blueprint — 2pts (push nodes to manage.worker-bee)
Continue fixing? (y/n)
```

---

## Scoring Quick Reference

| Score | Meaning | Action |
|---|---|---|
| 90–100 | 10x ready | Ship |
| 80–89 | Nearly there | Fix P1 blockers |
| 70–79 | Solid foundation | Fix P1+P2 |
| 60–69 | Functional prototype | Major gaps |
| < 60 | Needs work | Don't show client |

---

## Exit Criteria for This Skill

This skill is complete when:
- All 10 dimensions have been checked with actual bash output
- Scorecard has been presented with specific findings (not vague)
- All P1 blockers have been fixed or explicitly deferred
- Final score has been stated
- Memory has been updated if score changed significantly
