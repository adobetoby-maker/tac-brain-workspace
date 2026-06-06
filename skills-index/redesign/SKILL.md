---
name: redesign
description: |
  Visual redesign skill for existing working UI. Takes screenshots first,
  generates a design system, applies targeted improvements, scores the result,
  and iterates until the UI looks intentional and premium — not AI-generated.
  Trigger phrases: "redesign this", "give this a real visual identity",
  "make it look beautiful", "rethink the look", "make it premium",
  "fix the design", "it looks like AI made it", "polish the UI",
  "make it look professional", "visual overhaul"
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
  - redesign this
  - give this a real visual identity
  - make it look beautiful
  - rethink the look
  - make it premium
  - fix the design
  - it looks like AI made it
  - polish the UI
  - make it look professional
  - visual overhaul
  - make it look good
  - it looks generic
---

# /redesign — Visual Redesign for Existing UI

## Iron Law — Screenshot Before One Line Changes

**This fires before anything else. No exceptions.**

```bash
# Find the dev server port
PORT=$(lsof -ti :3000 >/dev/null 2>&1 && echo 3000 || \
       lsof -ti :3001 >/dev/null 2>&1 && echo 3001 || echo "NONE")

# If server not running, start it
if [ "$PORT" = "NONE" ]; then
  npm run dev -- -H 0.0.0.0 -p 3000 &
  sleep 4
  PORT=3000
fi

# Capture BEFORE screenshots — all 4 viewports
node ~/screenshot.js $PORT 0,540,1080
node ~/record.js $PORT
node ~/record.js $PORT --mobile

# Extract frames
mkdir -p /tmp/preview/frames
ffmpeg -i /tmp/preview/review.webm -vf fps=2 /tmp/preview/frames/frame_%03d.png -y 2>/dev/null

# Read ALL screenshots with Read tool — describe what you see
# This is the baseline. Every before/after comparison starts here.
```

**Read every PNG before proceeding. No exceptions.**

Banned phrases before screenshots are Read:
- "The current design looks generic" — describe the actual pixels
- "I'll improve the typography" — first describe the current typography from the screenshot
- "Skipping — it's an internal tool" — no such exception

---

## Step 1 — Understand the Stack

```bash
# Detect styling system
cat package.json | python3 -c "
import sys, json
d = json.load(sys.stdin)
deps = {**d.get('dependencies',{}), **d.get('devDependencies',{})}
styling = []
if 'tailwindcss' in deps: styling.append(f'tailwind {deps[\"tailwindcss\"]}')
if 'styled-components' in deps: styling.append('styled-components')
if '@emotion/react' in deps: styling.append('emotion')
print('Stack:', d.get('name'), '| Styling:', ', '.join(styling) or 'vanilla CSS')
"

# Find the design tokens / CSS variables
grep -rn "css-variables\|:root\|--color\|--font\|theme" \
  --include="*.css" --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules | head -20

# Find the global stylesheet
find . -name "globals.css" -o -name "global.css" -o -name "theme.ts" \
  -o -name "tokens.ts" 2>/dev/null | grep -v node_modules | head -5

# Current font usage
grep -rn "font-family\|fontFamily\|@import.*fonts\|next/font" \
  --include="*.css" --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules | head -10
```

---

## Step 2 — Design System Generation (UUPM)

Before writing any CSS, generate a design system using UUPM. This takes 30 seconds and prevents all "it looks AI-generated" problems.

```bash
# Run UUPM — describe the project type, industry, and desired mood
# Examples:
#   python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py \
#     "agency dashboard internal tool dark" --design-system --persist -p "<project>"
#   python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py \
#     "saas product landing page clean" --design-system --persist -p "<project>"
#   python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py \
#     "medical professional site trustworthy" --design-system --persist -p "<project>"

PROJECT=$(basename $(pwd))
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py \
  "<describe project type, mood, industry>" --design-system --persist -p "$PROJECT"

# Read the generated design system
cat "design-system/$PROJECT/MASTER.md" 2>/dev/null | head -60
```

The design system gives you:
- **Color tokens** — exact hex values, not "use indigo"
- **Typography pairing** — specific fonts with weights and sizes
- **Spacing scale** — consistent rhythm
- **Effect patterns** — shadows, borders, gradients
- **Anti-patterns** — what this specific type of project should NOT do

**Do not choose colors or fonts without running UUPM first.**

---

## Step 3 — Design Audit (Score the Before State)

Rate the current UI across 8 dimensions. Be specific — cite what you saw in the screenshots.

| # | Dimension | Score | Finding from screenshot |
|---|---|---|---|
| 1 | Typography | /10 | Font, hierarchy, spacing |
| 2 | Color & Surface | /10 | Palette, contrast, depth |
| 3 | Layout & Spacing | /10 | Grid, breathing room, alignment |
| 4 | Interactivity | /10 | Hover states, transitions, feedback |
| 5 | Components | /10 | Generic vs intentional patterns |
| 6 | Content | /10 | Real vs placeholder, copy quality |
| 7 | Iconography | /10 | Consistency, metaphor quality |
| 8 | Mobile | /10 | Touch targets, horizontal scroll, tap areas |

**Total: /80**

The audit uses the full pattern list from `redesign-existing-projects`. Run through it before making changes.

### Top Problems to Check (from the audit)

**Typography:**
- Browser default fonts / Inter everywhere → swap to character font
- Headlines lack weight and presence → tighten tracking, increase size
- No font scale → only 1-2 sizes used throughout

**Color:**
- Pure #000 or #fff background → replace with off-black or warm white
- "AI gradient" (purple/blue default) → replace with neutral base + one accent
- Oversaturated accents → desaturate below 80%
- Mixing warm and cool grays → pick one family

**Layout:**
- Three equal card columns everywhere → replace with asymmetric grid
- No max-width container → add 1200-1440px constraint
- Missing whitespace → double the padding
- Everything centered symmetrically → break with offset margins

**States:**
- No hover feedback → add scale, translate, or background shift
- No skeleton loaders → replace spinners with layout-matched skeletons
- No empty states → design a composed "getting started" view
- No error states → inline validation, not window.alert()

**Components:**
- Lucide icons exclusively → try Phosphor or Heroicons for differentiation
- Generic card pattern (border + shadow + white) → remove border OR shadow, not both
- Same testimonial carousel → masonry, social embeds, or single rotating quote
- Footer link farm → simplify to essential links only

---

## Step 4 — Plan the Redesign

Before changing any file, write the plan:

```
REDESIGN PLAN — [Project Name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Before score: __/80

Font: [current] → [replacement from UUPM]
Primary color: [current] → [from UUPM tokens]
Background: [current] → [from UUPM tokens]
Accent: [current] → [from UUPM tokens]

Changes this iteration (pick 3-5 max):
1. [Specific change — file:component]
2. [Specific change — file:component]
3. [Specific change — file:component]
```

**Work in batches of 3-5 changes, screenshot after each batch.**
Never make 20 changes then screenshot. You won't know what broke what.

Fix priority order (highest visual impact, lowest risk):
1. Font swap — biggest instant improvement
2. Color palette cleanup — remove clashing colors
3. Hover and active states — makes it feel alive
4. Layout and spacing — proper grid, max-width, padding
5. Replace generic components — swap clichéd patterns
6. Add loading, empty, error states — makes it feel finished
7. Polish typography scale — premium final touch

---

## Step 5 — Apply Changes

Follow the stack rules:

**Tailwind v4 projects:**
- Use CSS custom properties in `globals.css`, not `tailwind.config.ts`
- New syntax: `@theme { --color-brand: #... }` not `theme.extend.colors`
- Utility classes stay the same, but extend through CSS variables

**Tailwind v3 projects:**
- Extend via `tailwind.config.ts → theme.extend`
- Font via `fontFamily`, colors via `colors`

**Vanilla CSS:**
- Define all design tokens as CSS variables in `:root`
- Use `calc()` for spacing scale

**Do not:**
- Migrate styling libraries
- Change routing, data fetching, or business logic
- Remove accessibility attributes (`aria-*`, `role`, `alt`)
- Break existing tests

---

## Step 6 — Screenshot After (Mandatory)

```bash
PORT=3000  # adjust if different

# After screenshots
node ~/screenshot.js $PORT 0,540,1080
node ~/record.js $PORT
node ~/record.js $PORT --mobile

ffmpeg -i /tmp/preview/review.webm -vf fps=2 /tmp/preview/frames/frame_%03d.png -y 2>/dev/null
```

**Read every after PNG with the Read tool.**
**Read the final 3 frames — footer must be visible.**

---

## Step 7 — Score the After State

Re-run the same 8-dimension audit. Fill in the after column:

| # | Dimension | Before | After | Delta |
|---|---|---|---|---|
| 1 | Typography | /10 | /10 | ± |
| 2 | Color & Surface | /10 | /10 | ± |
| 3 | Layout & Spacing | /10 | /10 | ± |
| 4 | Interactivity | /10 | /10 | ± |
| 5 | Components | /10 | /10 | ± |
| 6 | Content | /10 | /10 | ± |
| 7 | Iconography | /10 | /10 | ± |
| 8 | Mobile | /10 | /10 | ± |

**Total: Before __/80 → After __/80 (+__ points)**

**Rules:**
- Score from pixels only — not from what the code "should" produce
- Any dimension that regressed → fix it before proceeding
- Any viewport with a broken layout → fix it before declaring the iteration done

---

## Step 8 — Iterate or Ship

**If score improved AND no regressions → commit and ask to continue:**
```
Iter N complete: __/80 → __/80 (+__)
Continue for another pass? (y/n)
```

**If score dropped in any dimension → roll back that change:**
```bash
git diff HEAD --stat  # see what changed
git checkout HEAD -- [file that regressed]
```

**Ship when:**
- Total score ≥ 65/80 (80%+)
- No dimension dropped vs the before state
- Mobile and desktop both pass visual check
- Footer visible in final scroll frame

---

## Step 9 — Commit

```bash
git add -A
git commit -m "redesign: [brief description] — score __→__/80

Changes:
- Typography: [font swap + what changed]
- Color: [palette change]
- Layout: [what was fixed]
- States: [hover/empty/error states added]"
```

---

## Exit Criteria

This skill is complete when:
- Before AND after screenshots have been Read with the Read tool
- Score table shows improvement in every changed dimension
- No regressions at any viewport
- Changes committed with a score in the commit message
- If deployed: live URL verified with `curl -sI <url> | head -1`

---

## Reference: Anti-Patterns to Never Introduce

Running these checks prevents introducing the same problems you're fixing:

```bash
# After changes — verify you didn't add back generic patterns

# No Lorem Ipsum
grep -rn "lorem ipsum\|Lorem Ipsum" --include="*.tsx" --include="*.ts" | grep -v node_modules | wc -l
# → 0

# No AI copywriting clichés
grep -rni "elevate\|seamless\|unleash\|game.changer\|next.gen\|delve\|tapestry" \
  --include="*.tsx" | grep -v node_modules | wc -l
# → 0

# No inline styles added (use design tokens instead)
grep -rn 'style={{' --include="*.tsx" | grep -v node_modules | wc -l
# → same or fewer than before

# No hardcoded colors in components (should use tokens)
grep -rn '#[0-9a-fA-F]\{6\}' --include="*.tsx" | grep -v "globals\|tokens\|theme\|node_modules" | wc -l
# → 0 or minimal (only approved one-offs)
```

---

## Quick Reference: UUPM Domain Drills

After the main design system, run targeted searches for specific dimensions:

```bash
PROJECT=$(basename $(pwd))

# Color palette deep-dive
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<mood>" --domain color

# Typography pairing
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<mood>" --domain typography

# Landing page layout patterns
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<type>" --domain landing

# UX patterns for this product type
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<type>" --domain ux

# Dark/premium UI references
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<type>" --domain style
```
