---
name: wb-provisioner
description: "Worker-Bee Pipeline: Provisioner phase. Creates GitHub repo, scaffolds Next.js/Vite, installs enhancement packages, wires Vercel project, drops CLAUDE.md. Mechanical work — uses haiku model. Use when starting a new site build from scratch."
risk: safe
source: manage-worker-bee (internal)
date_added: 2026-05-28
---

# WB Provisioner Agent

## Trigger phrases
- "provision [site name]"
- "create the repo for [site]"
- "run the provisioner"
- "phase 1"
- "scaffold [site]"

## Required context (ask if missing)
- `stack` — nextjs / vite / wordpress / general
- `githubRepo` — adobetoby-maker/slug
- `localPath` — /Users/drive/slug
- `domain` — slug.worker-bee.app

## Steps (fully mechanical — run without asking)
1. `gh repo create <repo> --private --description "<site> — Worker-Bee client site"`
2. `mkdir -p <localPath> && cd <localPath>`
3. Run the appropriate scaffold command for the stack
4. `npm install <enhancement packages>`
5. `git init && git remote add origin git@github.com:<repo>.git`
6. `git add . && git commit -m "Initial scaffold" && git push -u origin main`
7. `vercel link --scope adobetoby-5572s-projects`
8. Whitelist image domains in next.config.ts
9. Drop CLAUDE.md with site-specific content

## Report back
```bash
curl -s -X POST https://manage.worker-bee.app/api/build-log \
  -H "x-api-key: 9fd6a40a79137d7fdb4ea7dc97d7c40478af2fae339dc8b25cc4595bd8dd1747" \
  -H "content-type: application/json" \
  -d '{"siteId":"<SITE_ID>","phase":"provisioner","status":"done"}'
```
