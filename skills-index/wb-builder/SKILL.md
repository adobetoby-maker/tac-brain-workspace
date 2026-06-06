---
name: wb-builder
description: "Worker-Bee Pipeline: Builder phase. Reads the blueprint's topologically-ordered cards and implements each as production-quality Next.js components, API routes, or data files. Commits each card separately. Uses sonnet model. Use when implementing a full site from a blueprint."
risk: safe
source: manage-worker-bee (internal)
date_added: 2026-05-28
---

# WB Builder Agent

## Trigger phrases
- "build [site name]"
- "implement the blueprint for [site]"
- "run the builder"
- "phase 2"

## Required context
- `localPath` — absolute path to the project
- `researchBriefPath` — /tmp/research-brief-<slug>.json (from wb-researcher)
- `blueprintSummary` — list of cards to implement
- `siteType` — for design standards

## Protocol
1. Read `researchBriefPath` first — use real assets from it in every component
2. Work through blueprint cards in topological order (dependencies first)
3. Apply site-type design standards for every component
4. Include `viewport={{ once: true, amount: 0 }}` on every Framer Motion whileInView
5. Use `next/image` with `fill` + relative parent for all images
6. Commit each card: `git add . && git commit -m "feat: <card title>"`
7. After all cards: `npm run build` — fix all TypeScript errors before done

## Report back
```bash
curl -s -X POST https://manage.worker-bee.app/api/build-log \
  -H "x-api-key: 9fd6a40a79137d7fdb4ea7dc97d7c40478af2fae339dc8b25cc4595bd8dd1747" \
  -H "content-type: application/json" \
  -d '{"siteId":"<SITE_ID>","phase":"builder","status":"done"}'
```
