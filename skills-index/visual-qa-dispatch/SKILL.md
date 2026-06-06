---
name: visual-qa-dispatch
version: 1.0.0
description: |
  Mid-build visual QA gate. TAC invokes after each component or section is built.
  Assembles a context-aware jr prompt from build parameters, dispatches synchronously,
  and returns a structured PASS/REVISE verdict TAC must act on before proceeding.
  Trigger phrases: "visual qa", "image review", "check visuals", "screenshot gate", "visual gate"
allowed-tools:
  - Bash
  - Read
triggers:
  - visual qa
  - image review
  - check the build visually
  - screenshot gate
  - visual gate
  - check visuals
---

# Visual QA Dispatch — Build-Aligned Image Review

## The Problem This Solves

TAC builds a component. TAC self-assesses visually. TAC rationalizes "looks fine from the code."
The product ships with layout bugs TAC would have caught if it had actually looked.

This skill breaks that loop: jr reads the pixels with no stake in the outcome and returns a
verdict TAC cannot rationalize away. The verdict is a tool result — it physically arrives in
TAC's context and demands a response.

---

## Step 1 — Gather Build Context

TAC must supply these before dispatching. If any are missing, derive from context:

| Parameter | Where to find it | Example |
|---|---|---|
| `[project]` | Current working directory | `language-threshold` |
| `[port]` | Running dev server | `5173` |
| `[component]` | What was just built | `hero`, `pricing`, `nav`, `features-grid` |
| `[reference]` | From `scores.md` or memory | `Palantir.com hero: 8.5/10` |
| `[threshold]` | From `scores.md` target | `9.0` (must beat reference) |
| `[animated]` | Does this section have motion? | `yes` (Framer Motion/3D) or `no` |
| `[iteration]` | Current build iteration | `iter-03` |

---

## Step 2 — Select Dimensions for This Component Type

Map `[component]` to the dimensions jr will score. Use the table below.
Embed the selected dimensions in the jr prompt (Step 3).

| Component type | Dimensions to score |
|---|---|
| `hero` | Above-fold clarity, headline impact, CTA visibility, mobile viewport, type hierarchy |
| `nav` | Overflow/wrap at all viewports, color legibility, CTA button, mobile hamburger |
| `pricing` | Pricing clarity, plan differentiation, CTA prominence, trust signals |
| `features / grid` | Alignment, card consistency, spacing, mobile stack order |
| `cta-section` | Button size (mobile ≥44px tap), contrast ratio, copy urgency |
| `footer` | Present in final scroll frame, contact info legible, link color contrast |
| `animation / 3D` | Motion presence, depth/layering, element overlap, mobile degradation |
| `full-page` | All of the above + page weight feel, scroll continuity |

---

## Step 3 — Run Capture

```bash
# Static component:
node ~/screenshot.js [port] 0,540,1080

# Animated component (Framer Motion, parallax, shader, 3D, any scroll effect):
node ~/record.js [port]
mkdir -p /tmp/frames-qa
ffmpeg -i ~/review.webm -vf fps=2 /tmp/frames-qa/frame_%03d.png -y
# Also run mobile:
node ~/record.js [port] --mobile
```

---

## Step 4 — Dispatch jr Synchronously

**This is a synchronous Bash call — timeout=300000, NOT run_in_background.**
jr's output returns as a tool result. TAC reads it and acts on it.

Assemble the jr prompt using the parameters from Steps 1–2:

```bash
jr "Visual QA — [project] [component] [iteration]:

CONTEXT
  Component just built: [component]
  Reference baseline: [reference] on [dimension list for this component type]
  Acceptance threshold: every scored dimension must reach [threshold]/10
  Animated: [yes/no]

STEP 1 — Read all viewport screenshots (describe pixels — not code intent, not assumptions):
  Read ~/screenshot-desktop.png — describe every visible section top to bottom
  Read ~/screenshot-mobile.png — describe every section
  Read ~/screenshot-4k.png — describe every section

STEP 2 — [Only if animated=yes] Read video frames:
  Read /tmp/frames-qa/frame_001.png (first frame — initial state)
  Read the middle frame (animation midpoint)
  Read /tmp/frames-qa/ final 3 frames — confirm footer is visible in the last one
  If footer is NOT in the last frame: flag 'HARNESS BROKEN — scroll did not reach bottom'

STEP 3 — Score vs reference [reference]:
  [PASTE DIMENSION LIST FROM STEP 2 HERE, one per line]
  Format each: [dimension]: [X]/10 (reference: [Y]/10) — [one-line observation from pixel]

STEP 4 — Flag issues (regardless of score):
  - Any two elements visibly overlapping (not intentional layering)
  - Text contrast below 4.5:1 on body copy, below 3:1 on large text or icons
  - Content cut off or overflowing at any viewport
  - Mobile tap targets below 44px
  - Alignment breaks between desktop and mobile
  - Missing or illegible footer content

STEP 5 — Return structured verdict:

  SCORES:
    [dimension]: [X]/10 (ref [Y]/10)
    [repeat for each]

  ISSUES:
    [list each issue with specific location — or 'none']

  VERDICT: PASS or REVISE

  If REVISE — for each issue, one specific fix:
    Issue: [what]
    Fix: [exactly what to change — file, class, value]"
```

---

## Step 5 — TAC Acts on the Verdict

jr's verdict arrives as the tool result. TAC reads it immediately.

| Verdict | TAC action |
|---|---|
| `PASS` | Proceed to next build task. Log score in `scores.md`. |
| `REVISE` | Fix the exact issues jr listed. Re-run Step 3 (capture). Re-dispatch Step 4. Repeat until PASS. |
| `HARNESS BROKEN` | Fix scroll formula: `document.documentElement.scrollHeight - window.innerHeight`. Re-capture. |

**Never:**
- Proceed to the next task on a REVISE verdict
- Substitute TAC self-assessment for this gate ("it looks fine" = REVISE not acted on)
- Skip this gate because the component "seems simple"

---

## Step 6 — Log the Score

After every PASS, update `scores.md`:

```markdown
## [date] — [project] [component] [iteration]
Scores: [dimension list with values]
Reference: [reference]
Issues fixed: [list or 'none']
Status: PASS
```

---

## Rationalization Shield

| Thought | Reality | Correct action |
|---|---|---|
| "The component is small, no need for QA" | Small components cascade — nav wrapping broke the entire header | Run the gate |
| "I'll check visuals at the end" | End-of-build review misses component-level issues | Gate fires after every component |
| "jr takes time" | A missed overlap costs more to fix post-deploy than jr takes | Dispatch jr, wait for PASS |
| "The code produces what I designed" | iter-16: code was correct, pixels were wrong | Code intent ≠ pixel truth |
| "Mobile probably looks fine" | Mobile carries equal weight — single-viewport blindness is a canonical failure | Always capture mobile |

---

## Example Call (TAC fills this in at build time)

```bash
# After building the hero section of language-threshold on port 5173, iteration 2:
node ~/screenshot.js 5173 0,540,1080
node ~/record.js 5173

jr "Visual QA — language-threshold hero iter-02:

CONTEXT
  Component just built: hero
  Reference baseline: Duolingo.com hero 8.2/10 on above-fold clarity, headline impact, CTA visibility
  Acceptance threshold: 8.5/10 on every dimension
  Animated: yes (Framer Motion entrance)

STEP 1 — Read screenshots:
  Read ~/screenshot-desktop.png — describe every visible section top to bottom
  Read ~/screenshot-mobile.png — describe every section
  Read ~/screenshot-4k.png — describe every section

STEP 2 — Read video frames:
  Read /tmp/frames-qa/frame_001.png
  Read the middle frame
  Read the last 3 frames — confirm footer visible in final frame

STEP 3 — Score vs Duolingo.com hero 8.2/10:
  Above-fold clarity: X/10 (ref 8.2/10) — [pixel observation]
  Headline impact: X/10 (ref 8.2/10) — [pixel observation]
  CTA visibility: X/10 (ref 8.2/10) — [pixel observation]
  Mobile viewport: X/10 (ref 8.2/10) — [pixel observation]
  Motion presence: X/10 (ref 8.2/10) — [video frame observation]

STEP 4 — Flag: overlaps, contrast failures, overflow, mobile tap targets, alignment breaks

STEP 5 — SCORES + ISSUES + VERDICT (PASS or REVISE with specific fixes)"
```

---

## Integration Points

- Invoked by: `wb-build-pipeline` Phase 3B after every component
- Informed by: `scores.md` (reference + threshold), project CLAUDE.md (port, stack)
- Feeds back to: `scores.md` (logged scores per iteration), TAC decision (proceed vs fix)
- Anti-avoidance: jr verdict arrives as tool result — TAC cannot skip what it has already received
