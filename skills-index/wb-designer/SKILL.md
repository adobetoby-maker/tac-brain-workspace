---
name: wb-designer
description: "Worker-Bee Pipeline: Design Elevation phase. Elevates the built site above the production floor: runs UUPM design system, applies typography hierarchy, adds micro-animations (Framer Motion), improves spacing/rhythm, upgrades hero impact, polishes CTAs. Commits the elevation pass. Use after Visual QA passes."
risk: safe
source: manage-worker-bee (internal)
date_added: 2026-05-28
---

# WB Designer Agent

## Trigger phrases
- "elevate design [site]"
- "design pass [site]"
- "run the designer"
- "phase 3"

## Required context (ask if missing)

- `slug` — URL-safe site identifier
- `localPath` — absolute path on build machine
- `siteType` — medical / legal / local-service / restaurant / saas / ecommerce / agency / real-estate / general
- `port` — dev server port

## Steps

### 1. Load UUPM design system

```bash
cd <localPath>
python3 ~/.claude/skills/ui-ux-pro-max/scripts/design_system.py "<siteType> professional trustworthy" --persist -p "<slug>"
```

Read `design-system/<slug>/MASTER.md`. This sets:
- Primary + accent color tokens
- Typography scale (hero size, h2, body, caption)
- Spacing rhythm (section padding, component gap)
- Effect tokens (shadows, border-radius, glass morphism if applicable)

### 2. Audit current site against production floor

Score each dimension before touching the code:

| Dimension | Score (0–10) | Notes |
|---|---|---|
| Hero impact | ? | First screen, CTA prominence |
| Typography hierarchy | ? | H1 > H2 > body contrast |
| Spacing rhythm | ? | Consistent section padding |
| Color system | ? | Primary used consistently |
| Micro-animations | ? | Entrance, hover, scroll |
| Mobile polish | ? | 375px specific UX |
| Trust signals | ? | Reviews, credentials, photos |

Target: every dimension ≥ 7 before reporting done.

### 3. Apply design elevation (work through lowest-scoring dimensions first)

**Typography:**
- H1: `text-5xl md:text-7xl font-extrabold tracking-tighter`
- H2: `text-3xl md:text-4xl font-bold`
- Body: `text-lg leading-relaxed`
- Use UUPM font pairing from MASTER.md

**Spacing:**
- Section padding: `py-20 md:py-28`
- Component gap: `gap-8 md:gap-12`
- Container: `max-w-6xl mx-auto px-6`

**Color:**
- Apply UUPM primary color as CSS var `--color-primary`
- CTA button: `bg-[var(--color-primary)] hover:opacity-90 transition-opacity`

**Micro-animations (Framer Motion):**

```tsx
// Section entrance
<motion.section
  initial={{ opacity: 0, y: 24 }}
  whileInView={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.5, ease: 'easeOut' }}
  viewport={{ once: true }}
>

// Stagger children
<motion.div
  variants={{ hidden: {}, show: { transition: { staggerChildren: 0.1 } } }}
  initial="hidden"
  whileInView="show"
  viewport={{ once: true }}
>
  {items.map(item => (
    <motion.div
      key={item.id}
      variants={{ hidden: { opacity: 0, y: 16 }, show: { opacity: 1, y: 0 } }}
    >

// Button hover
<motion.button whileHover={{ scale: 1.03 }} whileTap={{ scale: 0.97 }}>
```

**Hero impact:**
- Full-viewport hero: `min-h-screen flex items-center`
- Gradient overlay on image: `bg-gradient-to-r from-black/70 to-transparent`
- Headline: 2-line max, primary keyword first
- CTA: 2 buttons — primary (filled) + secondary (outlined)

### 4. Re-score after elevation

Repeat the audit table from step 2. Every dimension must show improvement.

### 5. Visual verification

```bash
node ~/record.js <port>
node ~/record.js <port> --mobile
ffmpeg -i ~/review.webm -vf fps=2 /tmp/wb-designer-frames/frame_%03d.png
```

Open 6 frames. Describe what changed vs the Visual QA baseline.

### 6. Build + commit

```bash
cd <localPath>
npm run build 2>&1 | tail -5
git add -A
git commit -m "design elevation: UUPM tokens, typography hierarchy, Framer Motion entrances"
git push
```

## Rules

- Never apply animations without `viewport={{ once: true }}` — repeat-fire is annoying
- Never use `whileInView` on hero elements — they're visible on load, use `animate` instead
- `prefers-reduced-motion` must be respected — Framer Motion handles this automatically with `useReducedMotion`
- Score from pixels (Read tool on PNG), not from code intent
- Every section must have a recorded entrance animation before declaring done

## Report back

```bash
curl -s -X POST https://manage.worker-bee.app/api/build-log \
  -H "x-api-key: 9fd6a40a79137d7fdb4ea7dc97d7c40478af2fae339dc8b25cc4595bd8dd1747" \
  -H "content-type: application/json" \
  -d '{"siteId":"<SITE_ID>","phase":"designer","status":"done","artifacts":[]}'
```
