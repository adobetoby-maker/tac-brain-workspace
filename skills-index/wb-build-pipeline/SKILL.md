---
name: wb-build-pipeline
version: 1.0.0
description: |
  Complete web project pipeline: Research → Plan → Build → Review → Deploy → Social → Monitor.
  Integrates Claude Code skills with Hermes skills at each phase.
  Trigger phrases: "let's build", "build me a site", "new site for", "new project", "build this"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Agent
triggers:
  - "let's build"
  - "build me a site"
  - "new site for"
  - "new project"
  - "build this"
  - "start a new project"
---

# Worker Bee Build Pipeline

Unified pipeline for every web project — freehand ("let's build X") and tracked (manage.worker-bee.app).
Claude Code handles architecture, code, and deploy. Hermes handles planning, review, social, and monitoring.

---

## Entry Gate — Which Path?

```bash
# Determine project type
ls scores.md 2>/dev/null || echo "MISSING"
ls CLAUDE.md 2>/dev/null || echo "NO_CLAUDE_MD"
ls package.json 2>/dev/null || echo "NO_PACKAGE"
```

| State | Path |
|---|---|
| scores.md MISSING + no package.json | → Full pipeline from Phase 1 |
| scores.md exists + package.json exists | → Resume from Phase 3 (build) |
| Live site exists, user says "update" | → Maintenance path (Phase 3 only) |
| User says "just ship it" | → Skip to Phase 4 (review + deploy) |

---

## Phase 1 — RESEARCH (Claude Code)

**Iron Law:** `ls scores.md || echo MISSING` exits MISSING → this phase runs. No exceptions.

### 1A. Competitive landscape

```bash
# Identify the niche and find 3 reference sites
# WebSearch: "best [category] websites 2026"
# WebFetch or firecrawl each reference
# Screenshot each: node ~/screenshot.js <port>
```

Capture for each reference:
- Above-the-fold impact (0–10)
- Type hierarchy
- CTA prominence
- Mobile experience
- Trust signals
- Page load feel
- Category-specific dimensions (e.g. booking flow, product display, portfolio quality)

### 1B. Keyword research

Invoke: `/seo-keyword-strategist` skill
- Primary keyword + 5 supporting
- Search volume estimates
- Competitor keyword gaps

### 1C. Write scores.md

```markdown
# [Project] — Competitive Research
Date: YYYY-MM-DD

## References
| Site | Score | Strongest dimension |
|---|---|---|
| competitor-a.com | 7.2 | Hero impact |
| competitor-b.com | 6.8 | Trust signals |
| competitor-c.com | 8.1 | Mobile UX |

## Our Target
Beat competitor-c.com (8.1) on hero impact. Match on trust signals.
Primary keyword: [keyword], vol: [X]/mo

## Gap Table
| Dimension | Best ref | Our target |
|---|---|---|
| Hero | 8.5 | 9.0 |
| CTA | 7.0 | 8.0 |
| Mobile | 8.1 | 8.5 |
```

**Gate: scores.md written → Phase 2 unlocks.**

---

## Phase 2 — PLAN (Claude Code → Hermes writing-plans + plan skills)

### 2A. Architecture plan (Claude Code)

Define:
- Stack: Next.js 16 + Vercel (default) OR TanStack + CF Workers (if D1/R2/KV needed)
- Routes: list every page with purpose
- Data: static vs Supabase vs CF D1
- Auth: needed? `/admin` cookie or `/portal` Supabase JWT?
- Image strategy: Pexels/Unsplash for demo, real photos via CONTENT-NEEDED.md
- Env vars needed — always include:
  - Next.js: `NEXT_PUBLIC_GA_ID` (measurement tag) + `GA_PROPERTY_ID` (Data API numeric ID)
  - Vite: `VITE_GA_ID` + `GA_PROPERTY_ID`

### 2B. Design direction (UUPM)

Run before writing a single line of UI code. Takes 60 seconds and prevents hours of rework.

```bash
# Step 1: Full design system recommendation
python3 ~/.claude/skills/ui-ux-pro-max/scripts/design_system.py "<describe the business in one sentence>"

# Step 2: Targeted follow-up searches (use for any domain that needs detail)
SKILL=~/.claude/skills/ui-ux-pro-max/scripts/search.py
python3 $SKILL "<business type>"  --domain product     # style priority + landing pattern
python3 $SKILL "<style name>"     --domain style       # CSS keywords + AI prompt
python3 $SKILL "<palette mood>"   --domain color       # hex palette for this industry
python3 $SKILL "<mood>"           --domain typography  # font pair + Google Fonts import URL
python3 $SKILL "<layout need>"    --domain landing     # section order + CTA placement
python3 $SKILL "<concern>"        --domain ux          # a11y + interaction rules
python3 $SKILL "<feature>"        --stack nextjs       # Next.js do/don't + code example
```

Append to `scores.md` before Phase 3:
```markdown
## Design System
Style: [name] | CSS keywords: [from output]
Palette: primary=[hex] secondary=[hex] cta=[hex] bg=[hex] text=[hex]
Fonts: [pair] | Import: [Google Fonts URL from output]
Landing pattern: [section order from output]
Anti-patterns: [what NOT to do for this industry]
```

### 2C. Implementation plan (Hermes writing-plans skill)

Dispatch to Hermes:
```bash
dispatch --bg "Use writing-plans skill to create a bite-sized implementation plan for [project].
Stack: [stack]. Routes: [list]. Save plan to ~/.hermes/plans/$(date +%Y-%m-%d)-[project].md.
Each task must be 2-5 minutes. Include: file to edit, exact code, test command, git commit message."
```

Hermes writes `~/.hermes/plans/YYYY-MM-DD-[project].md` with:
- Task list (each = one file change + verification step + commit message)
- File paths
- Test commands
- Risks and open questions

### 2D. Content plan

Invoke: `/seo-aeo-blog-writer` or `/landing-page-generator` skill for copy structure
- Hero headline + subhead
- CTA text
- 3 key sections
- FAQ (if applicable)
- All marked `{/* [DEMO] */}` until real content arrives

**Gate: plan file exists + content outline ready → Phase 3 unlocks.**

---

## Phase 3 — BUILD (Claude Code primary + Hermes subagent-driven-development)

### 3A. Scaffold

```bash
# Next.js (default)
npx create-next-app@latest [project] --typescript --tailwind --app --no-src-dir
cd [project]
npm run dev -H 0.0.0.0 -p [port] &

# Write project CLAUDE.md immediately
# See: ~/.claude/rules/claude-md-rubric.md
```

### 3B. Build loop — Claude Code executes

For each task in the Hermes plan:
1. Read the task from `~/.hermes/plans/YYYY-MM-DD-[project].md`
2. Implement it (one file, one concern)
3. Capture after every component:
   ```bash
   # Static components:
   git diff HEAD --name-only | grep -qE '\.(tsx|css)' && node ~/screenshot.js [port] 0,540,1080
   # Animated/scroll components (any Framer Motion, parallax, shader, transition):
   node ~/record.js [port] && mkdir -p /tmp/frames-qa && ffmpeg -i ~/review.webm -vf fps=2 /tmp/frames-qa/frame_%03d.png -y
   ```
4. **Invoke `/visual-qa-dispatch` skill** — assembles the build-aligned jr prompt and dispatches synchronously.
   See: `~/.claude/skills/visual-qa-dispatch/SKILL.md`
   Supply: `[project]`, `[port]`, `[component]`, `[reference]` from `scores.md`, `[threshold]`, `[animated yes/no]`
   jr's verdict arrives as a tool result. TAC reads it and acts on it — no self-assessment substitutes for this.
5. If REVISE: fix the exact issues jr listed, re-capture (step 3), re-invoke skill (step 4). Repeat until PASS.
6. Log every PASS score to `scores.md` before moving to the next task.

### 3C. Parallel fan-out for independent sections (Hermes subagent-driven-development)

When 3+ independent sections need building simultaneously:
```bash
dispatch --bg "Use subagent-driven-development skill to implement tasks 4-7 from
~/.hermes/plans/YYYY-MM-DD-[project].md. Run 2-stage review after each task.
Working dir: /Users/drive/[project]. Report completion to ~/.hermes/tasks/done/[project]-tasks.md"
```

Claude Code continues on tasks 1-3 while Hermes handles 4-7 in parallel.

### 3D. Demo content compliance

```bash
# All invented content must be tagged
grep -rn "\[DEMO\]" app/ components/ | wc -l
# Must be > 0 if any content is invented
# Create CONTENT-NEEDED.md
```

### 3E. Analytics wiring (every site, no exceptions)

```bash
# Next.js sites
grep -q "NEXT_PUBLIC_GA_ID\|next/script" app/layout.tsx || echo "GA MISSING"

# Vite sites
grep -q "VITE_GA_ID\|GoogleAnalytics" src/App.tsx || echo "GA MISSING"
```

**If GA MISSING → add before Phase 4:**

Next.js (`app/layout.tsx`):
```ts
import Script from 'next/script'
const GA_ID = process.env.NEXT_PUBLIC_GA_ID
// In <body>:
{GA_ID && (<><Script src={`https://www.googletagmanager.com/gtag/js?id=${GA_ID}`} strategy="afterInteractive" /><Script id="ga4-init" strategy="afterInteractive">{`window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}gtag('js',new Date());gtag('config','${GA_ID}',{anonymize_ip:true});`}</Script></>)}
```

Vite SPA (`src/components/GoogleAnalytics.tsx` + mount in `App.tsx`):
- `import.meta.env.VITE_GA_ID` — baked at build time
- Use `useLocation` from react-router-dom to fire `page_view` on route change
- Guard all calls: `if (!GA_ID || !window.gtag) return`

After wiring, add to manage.worker-bee Config panel for this site:
- `NEXT_PUBLIC_GA_ID` or `VITE_GA_ID` = the G-XXXXXXXX measurement ID
- `GA_PROPERTY_ID` = the numeric property ID (from analytics.google.com → Admin → Property Settings)

### 3F. UUPM pre-delivery checklist (run before Phase 4)

```bash
# Every checkbox must pass before requesting code review
echo "UUPM Pre-Delivery:"
echo "[ ] No emojis as icons — SVG only (Heroicons / Lucide)"
echo "[ ] cursor-pointer on every clickable element"
echo "[ ] Hover states: transition 150–300ms"
echo "[ ] Text contrast ≥ 4.5:1 (check in browser DevTools)"
echo "[ ] Focus states visible for keyboard nav"
echo "[ ] prefers-reduced-motion respected"
echo "[ ] Responsive: 375px / 768px / 1024px / 1440px — screenshotted"
echo "[ ] Touch targets ≥ 44×44px with ≥ 8px gap"
# Verify no emoji icons crept in:
grep -rn "emoji\|role=\"img\"" app/ components/ 2>/dev/null | grep -v "\.test\." | head -5
# Verify cursor-pointer on buttons:
grep -rn "onClick\|href" app/ components/ 2>/dev/null | grep -v "cursor-pointer\|\.test\." | wc -l
```

**Gate: `npm run build` passes + all viewports screenshotted + scores.md updated + GA wired + UUPM checklist clean → Phase 4 unlocks.**

---

## Phase 4 — REVIEW (Hermes requesting-code-review + systematic-debugging)

### 4A. Pre-deploy code review (Hermes)

```bash
dispatch --bg "Use requesting-code-review skill on /Users/drive/[project].
Run: cd /Users/drive/[project] && git diff HEAD.
Check: security scan (no exposed keys, no SQL injection), quality gates (tsc, lint, build),
independent reviewer subagent, auto-fix loop. Report to ~/.hermes/tasks/done/[project]-review.md"
```

Hermes runs:
1. `git diff HEAD` — gets full diff
2. Static security scan — looks for exposed secrets, injection vectors, OWASP top 10
3. Independent reviewer subagent (fresh context) — spec compliance check
4. Auto-fix loop — fixes issues found, re-runs until clean
5. Writes review report

### 4B. Quality gates (Claude Code)

```bash
npx tsc --noEmit 2>&1 | tail -5        # must be clean
npm run lint 2>&1 | grep -c "error"    # must be 0
npm run build 2>&1 | tail -3           # must succeed
```

### 4C. Debugging any failures (Hermes systematic-debugging)

If build or lint fails:
```bash
dispatch --bg "Use systematic-debugging skill to diagnose build failure in /Users/drive/[project].
Error: [paste error]. Phase 1: understand the bug. Phase 2: find root cause.
Phase 3: fix. Phase 4: verify fix. Do NOT fix symptoms — find root cause first."
```

**Gate: all quality gates pass + Hermes review report clean → Phase 5 unlocks.**

---

## Phase 5 — DEPLOY (Claude Code + Vercel)

### 5A. Deploy decision

```bash
# Does this project need D1/R2/KV/cron bindings?
cat wrangler.jsonc 2>/dev/null | grep -E "d1_databases|r2_buckets|kv_namespaces" | wc -l
# 0 → Vercel
# >0 → Cloudflare Workers
```

### 5B. Vercel deploy

```bash
vercel --prod 2>&1
curl -sI https://[project-url] | head -1   # must be HTTP/2 200
```

### 5C. PR workflow (Hermes github-pr-workflow)

```bash
dispatch "Use github-pr-workflow skill to create a PR for [project].
Branch: feature/[name]. Title: '[short title]'. Body: phases completed, gates passed.
Merge to main after CI passes."
```

Hermes handles: branch check, commit message quality, PR body, CI status watch, merge.

### 5D. GA4 deploy verification

```bash
# Confirm env var is set in the deployment platform
vercel env ls | grep -i GA_ID || echo "GA_ID not in Vercel env — add it"
# After deploy:
curl -s https://[url] | grep -o "googletagmanager\|G-[A-Z0-9]*" | head -3
```

If measurement ID appears in the page source → GA4 active. If not → env var missing from platform.

### 5E. Blueprint update (if tracked project)

```bash
curl -s -X POST https://manage.worker-bee.app/api/blueprints/update \
  -H "x-api-key: 9fd6a40a79137d7fdb4ea7dc97d7c40478af2fae339dc8b25cc4595bd8dd1747" \
  -H "content-type: application/json" \
  -d '{"siteId": "[UUID]", "summary": "Phase 5 complete — live at [url]"}'
```

**Gate: HTTP 200 on live URL + GA4 in page source + blueprint updated → Phase 6 unlocks.**

---

## Phase 6 — SOCIAL + NOTIFY (Hermes xurl + iMessage)

### 6A. Draft social posts

```bash
dispatch --bg "Draft launch social posts for [project name]:
1. LinkedIn post (150-200 words, professional, value-focused)
2. X/Twitter thread (3 tweets, hook + detail + CTA)
3. Instagram caption (50-80 words + 8 hashtags)
All posts: [describe the site/business]. Live URL: [url].
Save drafts to ~/.hermes/tasks/done/[project]-social-$(date +%Y%m%d).md
Then send iMessage to Toby with the drafts for approval."
```

### 6B. Post on approval

When you reply APPROVE via iMessage:
```bash
# Hermes monitors ~/.hermes/tasks/done/[project]-social-*.md for APPROVED flag
# On approval: use xurl skill to post to X
# LinkedIn + Instagram: copy text to clipboard + open browser
dispatch "Use xurl skill to post the approved X thread from
~/.hermes/tasks/done/[project]-social-$(date +%Y%m%d).md"
```

### 6C. Client handoff (if client project)

```bash
ls CONTENT-NEEDED.md || echo "MISSING — create before client handoff"
# Send: demo URL + CONTENT-NEEDED.md + Loom walkthrough
# See: ~/.claude/rules/client-handoff-protocol.md
```

**Gate: social drafts sent to Toby + client notified (if applicable) → Phase 7 unlocks.**

---

## Phase 7 — MONITOR + MAINTAIN (Hermes cron)

### 7A. Add to site-monitor cron

Add the new site to Hermes's site-monitor job:
```bash
# Edit ~/.hermes/cron/jobs.json
# Add URL to site-monitor's check list
# Hermes runs every 30m and texts Toby if site goes down
```

### 7B. Weekly maintenance cron (add once per project)

```json
{
  "name": "[project]-weekly-maintenance",
  "prompt": "Weekly check for [project] at [url]: 1) curl -sI [url] | head -1 (must be 200). 2) Check for broken links on homepage. 3) Check Google Search Console for crawl errors if configured. 4) Report to ~/.hermes/tasks/done/[project]-weekly-$(date +%Y%m%d).md. If anything needs attention, iMessage Toby.",
  "schedule": { "kind": "cron", "expr": "0 9 * * 1", "display": "Mondays 9am" },
  "model": "claude-haiku-4-5-20251001",
  "provider": "anthropic"
}
```

### 7C. Monthly SEO check (add once per project)

```bash
dispatch "Monthly SEO audit for [url]:
1. curl -s [url] | grep -E '<title>|description|canonical|og:' — check meta tags
2. curl -I [url]/sitemap.xml — must be 200
3. curl -I [url]/robots.txt — must be 200
4. Check Core Web Vitals if Vercel Analytics is on
5. Suggest 1 content update based on current keyword performance
Report to ~/.hermes/tasks/done/[project]-seo-$(date +%Y%m%d).md and iMessage Toby."
```

---

## Maintenance Path (existing site update)

When user says "update [project]" or "fix X on [project]":

```
1. cd /Users/drive/[project]
2. Read CLAUDE.md — understand current state
3. mem-search "[project]" — surface prior context
4. Make the change (skip research if incremental)
5. Visual gate: screenshot if .tsx/.css changed
6. Hermes requesting-code-review before commit
7. vercel --prod
8. curl -sI [url] | head -1 — must be 200
9. Done
```

**Skip phases 1-2 for maintenance. Never skip phases 4-5.**

---

## Quick Reference Card

```
TRIGGER        "let's build X"
PHASE 1        Claude Code → research → scores.md
PHASE 2        UUPM design_system.py → scores.md design block + Hermes writing-plans
PHASE 3        Claude Code builds + Hermes parallel subagents + UUPM checklist gate
PHASE 4        Hermes requesting-code-review + systematic-debugging
PHASE 5        vercel --prod + Hermes github-pr-workflow
PHASE 6        Hermes xurl/social drafts → iMessage approval → post
PHASE 7        Hermes cron: 30m monitor + weekly check + monthly SEO

UUPM CMD       python3 ~/.claude/skills/ui-ux-pro-max/scripts/design_system.py "<desc>"
UUPM SEARCH    python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<q>" --domain product|style|color|typography|landing|ux

MAINTENANCE    Read CLAUDE.md → fix → visual gate → Hermes review → deploy

GATE RULE      Each phase has a hard gate. Cannot proceed without it passing.
MODEL RULE     Claude Code + Hermes claude = sonnet. Cron jobs = haiku.
DISPATCH RULE  Independent work → dispatch --bg. Sequential work → inline.
```
