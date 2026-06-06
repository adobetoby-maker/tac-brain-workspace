---
name: testsite
version: 1.0.0
description: |
  Full site audit — clicks every link, checks every image, verifies all destinations,
  produces a P1/P2/P3 report, fixes all P1+P2 issues, then re-audits to confirm clean.
  Wraps the complete visual + link + deploy workflow in one command.
  
  Trigger phrases:
    - /testsite <url>
    - "audit all links on X"
    - "click review of X"
    - "find broken links on X"
    - "visual and click review"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Agent
  - mcp__plugin_playwright_playwright__browser_navigate
  - mcp__plugin_playwright_playwright__browser_snapshot
  - mcp__plugin_playwright_playwright__browser_take_screenshot
  - mcp__plugin_playwright_playwright__browser_evaluate
  - mcp__plugin_playwright_playwright__browser_click
  - mcp__plugin_playwright_playwright__browser_tabs
triggers:
  - /testsite
  - audit all links
  - click review
  - find broken links
  - visual and click review
---

# /testsite — Full Site Link & Visual Audit

Audits every link and image on a site, produces a prioritised issue report, fixes P1+P2,
and confirms with a visual before/after using Playwright. Creates the /testsite skill if it doesn't exist.

## When This Fires

Observable: `/testsite <url>` typed OR user asks to "audit links", "click through", "find broken links" on a site.
Argument: `<url>` — the site to audit (e.g. `https://worker-bee.app`)

---

## Step 1 — Entry Visual (/eyes equivalent for live sites)

```bash
# Parse URL from args
URL="$ARGS"
SLUG=$(echo "$URL" | sed 's|https://||' | sed 's|[./]|-|g')
```

Navigate to the site with Playwright and take the entry screenshot:

```
mcp__plugin_playwright_playwright__browser_navigate → $URL
mcp__plugin_playwright_playwright__browser_take_screenshot → filename: testsite-${SLUG}-entry.png, fullPage: true
```

Read the entry PNG. Describe what you see section by section. Note:
- Above-fold content
- Navigation bar visible?
- Any obvious visual breaks (white boxes, overlaps, blank sections, missing images)
- CTA buttons present and styled?

---

## Step 2 — Extract All Links

Run this JS via `browser_evaluate` to capture every internal and external link:

```javascript
() => {
  const links = Array.from(document.querySelectorAll('a[href]'))
    .map(a => ({
      text: a.innerText.trim().slice(0, 60) || a.getAttribute('aria-label') || '(no text)',
      href: a.getAttribute('href'),
      isInternal: !a.getAttribute('href')?.startsWith('http') || 
                  a.getAttribute('href')?.includes(window.location.hostname),
      isDead: a.getAttribute('href') === '#' || a.getAttribute('href') === ''
    }));
  
  const images = Array.from(document.querySelectorAll('img'))
    .map(img => ({
      src: img.getAttribute('src'),
      alt: img.getAttribute('alt') || '(no alt)',
      broken: !img.complete || img.naturalWidth === 0
    }));
  
  const deadLinks = links.filter(l => l.isDead).map(l => l.text);
  const internalLinks = [...new Set(links.filter(l => l.isInternal && !l.isDead).map(l => l.href))];
  const externalLinks = [...new Set(links.filter(l => !l.isInternal && !l.isDead).map(l => l.href))];
  const brokenImages = images.filter(i => i.broken);
  
  return JSON.stringify({ deadLinks, internalLinks, externalLinks, brokenImages, totalLinks: links.length }, null, 2);
}
```

---

## Step 3 — HTTP Status Check All Routes

Run a bash batch check on all unique internal routes and external URLs:

```bash
BASE="$URL"

echo "=== INTERNAL ROUTES ==="
for route in $INTERNAL_ROUTES; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 "$BASE$route")
  echo "$route → $STATUS"
done

echo "=== EXTERNAL LINKS ==="
for exturl in $EXTERNAL_URLS; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 8 "$exturl")
  FINAL=$(curl -s -o /dev/null -w "%{url_effective}" -L --max-time 8 "$exturl")
  echo "$exturl → $STATUS | final: $FINAL"
done
```

Flag any route/URL where status is NOT 200 (or 301/302 to 200).

---

## Step 4 — Navigate Each Internal Route

For each internal route, navigate with Playwright and run this eval:

```javascript
() => {
  const h1 = document.querySelector('h1')?.innerText || 'NO H1';
  const title = document.title;
  const bodyLen = document.body.innerText.trim().length;
  const hasContent = bodyLen > 100;
  return JSON.stringify({ title, h1, bodyLen, hasContent });
}
```

Flag any page where:
- `hasContent` is false (< 100 chars of body text = likely stub)
- Title is the generic default (same as homepage title)
- Page redirects to login without auth context

---

## Step 5 — Compile Issue Report

Categorise every finding:

### Priority 1 — Blocking (fix immediately)
- External link returns 000 or 404 (dead domain or broken URL)
- Internal route returns 404 or renders blank
- `href="#"` placeholder links (navigation dead ends)
- Missing images (src broken, 404)
- Form submit button with no action
- Typo in a URL (e.g. missing character in a domain)

### Priority 2 — Should work (fix before next release)
- Footer/nav links pointing to `#` instead of correct anchor
- Duplicate nav labels pointing to different URLs
- External link that redirects to wrong domain
- Link with no text content (accessible name missing)
- Image with no alt text

### Priority 3 — Enhancement (track, fix when convenient)
- Social links not wired (pointing to platform root, not the actual profile)
- Privacy Policy / Terms of Service not yet created
- Anchor links where section `id` doesn't exist on the page
- Low-contrast CTA

Format the report as:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SITE AUDIT — $URL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PRIORITY 1 — Blocking ($COUNT issues)
  ✗ [description] — [location] — [evidence]
  ...

PRIORITY 2 — Should Work ($COUNT issues)
  ⚠ [description] — [location] — [evidence]
  ...

PRIORITY 3 — Enhancement ($COUNT issues)
  ○ [description] — [location] — [suggested fix]
  ...

PASSING ✓
  ✓ [what's working]
  ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Present this report to the user before making any changes.

---

## Step 6 — Fix P1 and P2 Issues

**Find the project directory first:**
```bash
# Find by domain match in sitemap.ts, robots.ts, or layout.tsx
grep -r "$DOMAIN" /Users/drive/*/app/sitemap.ts /Users/drive/*/app/robots.ts 2>/dev/null | head -5
```

Then for each P1/P2 issue, edit the relevant file directly. Common fix patterns:

| Issue | Fix |
|---|---|
| `href="#"` dead links | Edit component, replace with real anchor (`/#section-id`) or real route |
| URL typo in domain | Fix the domain string in the data file (e.g. `lib/portfolio.ts`) |
| Dead external domain | Replace with working URL or remove card |
| Duplicate nav label | Rename one entry to be descriptive |
| Missing alt text | Add descriptive `alt` to each `<img>` |

After each file edit, run:
```bash
cd /Users/drive/<project> && npm run build 2>&1 | tail -5
```
Build must pass before proceeding.

---

## Step 7 — Commit and Deploy

```bash
cd /Users/drive/<project>
git add -A
git commit -m "fix: broken links, dead anchors, and URL errors from /testsite audit"
vercel --prod 2>&1 | tail -8
```

Verify live URL:
```bash
curl -sI $URL | head -2   # must be HTTP/2 200
```

---

## Step 8 — Re-check Dead Links on Live Site

Navigate to the live URL with Playwright and re-run the dead link detector:

```javascript
() => {
  const dead = Array.from(document.querySelectorAll('a[href="#"]'))
    .map(a => a.innerText.trim() || '(no text)');
  const portfolio = Array.from(document.querySelectorAll('a[href^="https://"]'))
    .map(a => ({ text: a.innerText.trim(), href: a.getAttribute('href') }));
  return JSON.stringify({ deadLinkCount: dead.length, dead, portfolio });
}
```

Expected: `deadLinkCount: 0`

---

## Step 9 — Exit Visual

```
mcp__plugin_playwright_playwright__browser_take_screenshot → filename: testsite-${SLUG}-exit.png, fullPage: true
```

Read the exit PNG. Compare against entry PNG:
- Are all sections still rendering?
- Did any visual regressions appear from the fixes?
- Footer correct layout?

---

## Step 10 — Final Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/testsite COMPLETE — $URL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FIXED ($COUNT):
  ✓ [what was fixed]
  ...

REMAINING P3 ($COUNT — not auto-fixed):
  ○ [description]
  ...

VISUAL: [entry description] → [exit description]
DEAD LINKS: $ENTRY_COUNT → $EXIT_COUNT
LIVE URL: $URL — HTTP 200 confirmed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Rationalization Shield

| Thought | Reality | Correct action |
|---|---|---|
| "HTTP 200 means the link works" | Next.js returns 200 for stub pages | Navigate with Playwright and check body content |
| "The link text is just a placeholder" | Placeholders ship to production | Flag as P1 if it's a navigation dead-end |
| "I'll fix the dead links after launch" | Users click footer links on day one | Fix before declaring done |
| "The counter shows 0 so the animation is broken" | Scroll-triggered animations start at 0 | Scroll to section and verify, or accept as expected |
| "The domain looks right" | One missing character breaks it silently | curl the exact URL and check for 000 |

---

## Exit Criteria

Observable: `document.querySelectorAll('a[href="#"]').length === 0` on the live URL AND all portfolio/external links return non-000 HTTP status.
