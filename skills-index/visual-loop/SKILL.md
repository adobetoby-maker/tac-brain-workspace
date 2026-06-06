---
name: visual-loop
version: 1.0.0
description: |
  Autonomous visual QA loop. Screenshots the running dev server, scores it
  brutally against Apple.com-level design quality, fixes the worst issue,
  re-screenshots, and repeats until the score hits the target or max iterations.
  
  Invoke when you want Claude to self-critique and iterate without being asked.
  Trigger phrases: "visual loop", "keep iterating", "don't stop until it's good",
  "redo until 90", "visual qa loop", "iterate to quality".
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
triggers:
  - visual loop
  - visual-loop
  - keep iterating
  - iterate to quality
  - redo until
  - don't stop until
---

# Visual Loop — Autonomous Design Iteration

You are running an autonomous visual QA loop. Your job is to screenshot the
running site, score it honestly, fix the worst problem, and repeat.

**You are not allowed to declare success until the score genuinely deserves it.**

---

## Configuration

Read these from the invocation or use defaults:

- `PORT` — dev server port (default: auto-detect from `~/.next/dev/logs/`)
- `TARGET` — minimum acceptable score (default: 88)
- `MAX_ITERATIONS` — hard stop (default: 6)
- `SCROLLS` — scroll positions to capture (default: `0,540,810,1350`)

Example: `/visual-loop port=3007 target=90`

---

## The Loop

Repeat until score >= TARGET or iteration >= MAX_ITERATIONS:

### Step A — Screenshot

```bash
node ~/screenshot.js <PORT> <SCROLLS>
```

Read every image in `/tmp/preview/` using the Read tool.

### Step B — Score (be brutal)

Score each dimension out of 20. **Do not round up. Do not give credit for intent.**
Only score what is actually visible on screen right now.

| Dimension | Max | What to look for |
|---|---|---|
| **Typography** | 20 | Scale contrast, line-height, tracking, font weight discipline |
| **Whitespace & layout** | 20 | Breathing room, alignment grid, nothing cramped |
| **Color & contrast** | 20 | Palette discipline, text legibility, hierarchy through color |
| **Motion & polish** | 20 | Animations purposeful, not jarring; transitions smooth |
| **Mobile / responsiveness** | 20 | No overflow, tap targets adequate, readable at 375px |

**Total: /100**

Print the score table. Then write one sentence: what is the single worst thing
holding this page back from looking like an Apple.com product page?

### Step C — Decide

- If score >= TARGET: print "✓ Target reached. Score: X/100." and **stop**.
- If iterations >= MAX_ITERATIONS: print "⚠ Max iterations reached. Score: X/100. Remaining issues:" and list them, then **stop**.
- Otherwise: continue to Step D.

### Step D — Fix the worst issue

Fix ONLY the single highest-impact problem identified in Step B.

Rules:
- One problem per iteration. Do not refactor unrelated code.
- Be specific: name the file, the CSS class, the value you're changing and why.
- After editing, wait ~1s for hot reload before re-screenshotting.
- If the fix requires a new image or asset you cannot generate, skip it and fix
  the next highest-impact problem instead.

### Step E — Log

Print a one-line summary:
```
[Iteration N] Score: X → Y | Fixed: <what you changed>
```

Then go back to Step A.

---

## What "Apple-level" means

You are comparing to apple.com product pages, not average websites. The bar is:

- **Typography**: Display type is massive and commanding. Body is small and airy.
  Never more than 2 font weights on one screen. Letter-spacing on headings is tight.
- **Whitespace**: Sections have room to breathe. Nothing feels packed. Generous
  padding even on mobile.
- **Color**: Near-monochrome with one accent. No gradients that look "web 2.0".
  Backgrounds are true black or true white, not grays.
- **Motion**: Elements enter once, cleanly. No bouncing, no infinite loops unless
  they are subtle (like a pulse). Scroll-linked animations are silky.
- **Mobile**: The page looks designed for mobile first. Hero text is large enough
  to read without pinching. CTAs are thumb-sized.

If any of these are violated, that's your fix target.

---

## After the loop ends

Report:
1. Final score and what changed across all iterations
2. Any issues that remain above the threshold (honest backlog)
3. Whether to deploy: `node ~/screenshot.js` one final time and show the result
