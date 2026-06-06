---
name: wb-visual-qa
description: "Worker-Bee Pipeline: Visual QA phase. Screenshots the built site at 375px mobile + 1440px desktop, scrolls full page, checks for invisible content, broken images, overlap collisions, and white text on white. Fixes layout bugs in-place. Saves QA screenshots to /tmp. Use after the builder agent completes."
risk: safe
source: manage-worker-bee (internal)
date_added: 2026-05-28
---

# WB Visual QA Agent

## Trigger phrases
- "visual qa [site]"
- "screenshot check [site]"
- "run visual qa"
- "phase 2.5"

## Required context (ask if missing)

- `slug` — URL-safe site identifier
- `localPath` — absolute path on build machine (e.g. `/Users/drive/jrs-auto-repair`)
- `port` — dev server port (start it if not running)

## Steps

### 1. Start dev server (if not running)

```bash
lsof -ti :<port> > /dev/null 2>&1 || (cd <localPath> && npm run dev -H 0.0.0.0 -p <port> &)
sleep 4
```

### 2. Desktop screenshot — full scroll

```bash
node ~/screenshot.js <port> 0,540,1080,1620,2160
cp ~/screenshot-*.png /tmp/wb-qa-desktop-<slug>.png
```

Open each PNG with the Read tool. Describe every section — hero, services, testimonials, contact, footer.

### 3. Mobile screenshot — 375px viewport

```bash
node ~/record.js <port> --mobile
ffmpeg -i ~/review.webm -vf fps=2 /tmp/wb-qa-mobile-frames/frame_%03d.png
cp ~/review.webm /tmp/wb-qa-mobile-<slug>.webm
```

Open the first and last frame. Confirm the footer appears in the last frame.

### 4. Scroll video — desktop

```bash
node ~/record.js <port>
ffmpeg -i ~/review.webm -vf fps=2 /tmp/wb-qa-desktop-frames/frame_%03d.png
cp ~/review.webm /tmp/wb-qa-desktop-<slug>.webm
```

Open 6 frames spread across the timeline. Describe what each shows.

### 5. Checklist — score each item PASS / WARN / FAIL

```
□ Hero image loads (not broken image icon)
□ All text visible — no white-on-white, no invisible text
□ No element overlap collisions at desktop
□ No element overlap collisions at mobile
□ CTA buttons visible and labeled
□ Contact section has phone + address
□ Footer visible at full scroll
□ No console errors (check via Playwright evaluate if available)
□ Images have descriptive alt text (check source)
□ Mobile nav menu opens correctly
□ Fonts loaded (not system fallback)
```

### 6. Fix layout bugs in-place

For each FAIL item: edit the file, fix the issue, re-screenshot the affected section.

Common fixes:
- Overlap → add `z-index` or `position: relative`
- White text on white → check tailwind class conflict
- Broken image → verify `public/images/<name>` exists and next.config.js includes the domain
- Missing footer → check scroll harness uses `document.documentElement.scrollHeight - window.innerHeight`

### 7. Final build check

```bash
cd <localPath> && npm run build 2>&1 | tail -5
```

Must complete without errors before reporting done.

## Output artifacts

- `/tmp/wb-qa-desktop-<slug>.png` — desktop screenshot
- `/tmp/wb-qa-mobile-<slug>.webm` — mobile scroll video
- `/tmp/wb-qa-desktop-<slug>.webm` — desktop scroll video

## Report back

```bash
curl -s -X POST https://manage.worker-bee.app/api/build-log \
  -H "x-api-key: 9fd6a40a79137d7fdb4ea7dc97d7c40478af2fae339dc8b25cc4595bd8dd1747" \
  -H "content-type: application/json" \
  -d '{"siteId":"<SITE_ID>","phase":"visual-qa","status":"done","artifacts":["/tmp/wb-qa-desktop-<slug>.png","/tmp/wb-qa-mobile-<slug>.webm"]}'
```

## Rules

- Never declare done without opening at least one PNG with the Read tool and describing it
- Footer missing from final frame = harness broken — fix the scroll before scoring
- Overlap at any viewport = FAIL, not WARN
- Score from pixels only — not from code intent
