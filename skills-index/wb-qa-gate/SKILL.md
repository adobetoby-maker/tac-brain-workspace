---
name: wb-qa-gate
description: "Worker-Bee Pipeline: QA Gate phase. Four-pass review: (1) code quality /review, (2) functional QA /qa browser run, (3) mobile 375px pass, (4) conversion audit. Fixes all blockers before reporting done. Use after Designer phase."
risk: safe
source: manage-worker-bee (internal)
date_added: 2026-05-28
---

# WB QA Gate Agent

## Trigger phrases
- "qa gate [site]"
- "run qa gate"
- "four-pass review [site]"
- "phase 4"

## Required context (ask if missing)

- `slug` — URL-safe site identifier
- `localPath` — absolute path on build machine
- `port` — dev server port
- `siteUrl` — live Vercel preview URL (if available)

## Four Passes — Run in Order

Each pass must PASS before moving to the next. Fix blockers before proceeding.

---

### Pass 1 — Code Quality

```bash
cd <localPath>
npx tsc --noEmit 2>&1 | head -20          # must be zero output
npm run lint 2>&1 | grep -c "error"       # must be 0
npm run build 2>&1 | tail -5              # must contain "compiled successfully"
```

Blockers: TypeScript errors, ESLint errors, build failures.

Also check:
```bash
grep -rn "console\.\(log\|warn\|error\)" app/ components/ --include="*.tsx" | grep -v "// ok"
grep -rn "TODO\|FIXME\|HACK" app/ components/ --include="*.tsx"
```

Fix any `console.*` calls and TODO comments. Warn on FIXME/HACK but don't block.

---

### Pass 2 — Functional QA (browser)

Navigate every page, test every interactive element:

```bash
# Capture current state before QA
node ~/screenshot.js <port> 0,540,1080
```

Checklist — test in browser:
```
□ All navigation links work (no 404)
□ Contact form submits (check network tab — POST returns 200 or queued)
□ Phone number is clickable (tel: link)
□ Email address is clickable (mailto: link)
□ Google Maps link opens to correct address
□ Any booking/scheduling link opens (external OK)
□ Images all load (no broken image icons anywhere)
□ No console errors in DevTools
□ No render-blocking blank sections
```

For each FAIL: locate file, fix, re-check.

---

### Pass 3 — Mobile 375px

```bash
node ~/record.js <port> --mobile
ffmpeg -i ~/review.webm -vf fps=2 /tmp/wb-qa-mobile-final-frames/frame_%03d.png
cp ~/review.webm /tmp/wb-qa-gate-mobile-<slug>.webm
```

Open first frame, last 3 frames. Describe each.

Mobile checklist:
```
□ Hero text not truncated or overflowing
□ Nav menu opens correctly (hamburger or visible links)
□ CTA buttons full-width or properly sized — not clipped
□ Phone number visible and tappable
□ Contact form inputs not too small to tap
□ Images fill width correctly — no portrait images cropped weirdly
□ Footer visible in final scroll frame
□ No horizontal scroll bar
```

---

### Pass 4 — Conversion Audit

Score each item (PASS / WARN / FAIL):

```
□ Value prop in hero — clear one-sentence statement of what the business does
□ Social proof visible above the fold or within first scroll
□ CTA button — contrasting color, imperative verb ("Book Now", "Call Today", "Get Quote")
□ Trust signals — license numbers, certifications, years in business, reviews count
□ Urgency element — "Available Today", "Same-Day Service", "Limited Slots"
□ Contact information — phone number visible in header or sticky bar
□ Google review stars or rating displayed
□ Mobile click-to-call — phone number is a tel: link
```

For each FAIL: prioritize fixes based on conversion impact. Fix the top 2.

---

## Final Gate Check

After all 4 passes pass:

```bash
cd <localPath>
npm run build 2>&1 | tail -3
```

Must contain "compiled successfully" or equivalent. Then:

```bash
git add -A
git commit -m "qa-gate: 4-pass review — code, functional, mobile, conversion fixes"
git push
```

## Output artifacts

- `/tmp/wb-qa-gate-mobile-<slug>.webm` — mobile QA video

## Report back

```bash
curl -s -X POST https://manage.worker-bee.app/api/build-log \
  -H "x-api-key: 9fd6a40a79137d7fdb4ea7dc97d7c40478af2fae339dc8b25cc4595bd8dd1747" \
  -H "content-type: application/json" \
  -d '{"siteId":"<SITE_ID>","phase":"qa-gate","status":"done","artifacts":["/tmp/wb-qa-gate-mobile-<slug>.webm"]}'
```

## Rules

- Never skip a pass — all four run every time
- FAIL on Pass 1 (TypeScript error) = stop, fix, restart all four passes
- FAIL on Pass 3 (mobile) = fix, re-run Pass 3 only — do not restart
- Never declare done if `grep -c error` returns non-zero
- Conversion audit FAIL items: fix top 2, document rest in CONTENT-NEEDED.md if they require client content
