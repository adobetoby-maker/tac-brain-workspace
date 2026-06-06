---
name: wb-deployer
description: "Worker-Bee Pipeline: Deploy phase. Runs vercel --prod, sets domain alias to <slug>.worker-bee.app, seeds the master account, verifies the live URL returns 200, and reports back to manage.worker-bee.app. Use as the final pipeline step after QA Gate passes."
risk: safe
source: manage-worker-bee (internal)
date_added: 2026-05-28
---

# WB Deployer Agent

## Trigger phrases
- "deploy [site]"
- "ship [site]"
- "run the deployer"
- "phase 5"

## Required context (ask if missing)

- `slug` — URL-safe site identifier
- `localPath` — absolute path on build machine
- `githubRepo` — adobetoby-maker/<slug>
- `domain` — <slug>.worker-bee.app (or custom domain if provided)
- `siteId` — Supabase UUID for manage.worker-bee reporting

## Steps

### 1. Final build verification

```bash
cd <localPath>
npm run build 2>&1 | tail -5
```

Must contain "compiled successfully". If not → stop, report failure to build-log, do not deploy.

### 2. Deploy to Vercel

```bash
cd <localPath>
vercel --prod 2>&1
```

Capture the deployment URL from output. If deploy fails:
1. `vercel whoami` — confirm auth
2. Check for missing env vars: `vercel env ls`
3. Try MCP: `mcp__claude_ai_Vercel__deploy_to_vercel`
4. Check GitHub auto-deploy is wired: `gh repo view --json homepageUrl`

### 3. Set domain alias

```bash
vercel alias set <deployment-url> <domain>
```

If custom domain: also run:
```bash
vercel domains add <custom-domain>
```

### 4. Verify live URL

```bash
curl -sI https://<domain> | head -1
```

Must return `HTTP/2 200` or `HTTP/1.1 200`. Retry up to 3 times (DNS propagation).

If non-200:
- Check Vercel dashboard for deployment status
- Check for authentication protection blocking public access
- Verify domain alias was set correctly

### 5. Seed master account

For sites with auth (Supabase):

```bash
curl -s -X POST https://<domain>/api/seed \
  -H "content-type: application/json" \
  -d '{"email":"adobetoby@gmail.com","password":"workerbee.26","role":"admin"}'
```

If no seed endpoint: create admin account manually via Supabase dashboard or `supabaseAdmin.auth.admin.createUser()`.

### 6. Update blueprint in manage.worker-bee

```bash
curl -s -X POST https://manage.worker-bee.app/api/blueprints/update \
  -H "x-api-key: 9fd6a40a79137d7fdb4ea7dc97d7c40478af2fae339dc8b25cc4595bd8dd1747" \
  -H "content-type: application/json" \
  -d '{
    "siteId": "<siteId>",
    "summary": "Pipeline complete. Live at https://<domain>. All 7 phases done.",
    "liveUrl": "https://<domain>"
  }'
```

### 7. Report back

```bash
curl -s -X POST https://manage.worker-bee.app/api/build-log \
  -H "x-api-key: 9fd6a40a79137d7fdb4ea7dc97d7c40478af2fae339dc8b25cc4595bd8dd1747" \
  -H "content-type: application/json" \
  -d '{
    "siteId":"<siteId>",
    "phase":"deployer",
    "status":"done",
    "artifacts":["https://<domain>"],
    "notes":"Live. Seeded. Domain aliased."
  }'
```

## Output

Respond with:
```
✅ Pipeline Complete
Live URL: https://<domain>
Deploy time: <elapsed>
All 7 phases: researcher → provisioner → builder → visual-qa → designer → qa-gate → deployer
```

## Rules

- Never deploy if Pass 1 (build) failed in QA Gate — confirm build passes first
- Never skip the live URL curl check — a deploy that returns non-200 is not a successful deploy
- Never skip the master account seed — the client needs to be able to log in
- If Vercel auth fails: exhaust all 5 options (whoami, env, GitHub auto-deploy, MCP tool, GitHub Actions) before reporting failure
- Report failure to build-log even if deploy fails — always update the pipeline status
