---
name: push-to-worker-bee
version: 1.0.0
description: |
  Full Worker Bee pipeline for any site. Registers the site, builds the blueprint cork board,
  runs SEO + CSO + monetization audits, finds affiliate matches, populates vault, and records
  the run in manage-worker-bee. Use when the user says "push to worker bee", "wb push", 
  "run worker bee", or "process this site through WB".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - WebFetch
  - WebSearch
  - Agent
triggers:
  - "push to worker bee"
  - "wb push"
  - "run worker bee on"
  - "push [project] to WB"
  - "process through worker bee"
---

# Push to Worker Bee

Executes the full Worker Bee pipeline for the current project.

## Constants

```
WB_API=https://manage.worker-bee.app
WB_KEY=9fd6a40a79137d7fdb4ea7dc97d7c40478af2fae339dc8b25cc4595bd8dd1747
```

---

## Step 0 — Identify the project

```bash
# From current working directory
PROJECT_DIR=$(pwd)
PROJECT_SLUG=$(basename "$PROJECT_DIR")
PROJECT_URL=$(grep -r "deployment_url\|vercel.*app\|worker-bee.app" CLAUDE.md 2>/dev/null | head -1 | grep -oE 'https?://[^ ]+' | head -1)
echo "Project: $PROJECT_SLUG at $PROJECT_URL"
```

If no URL found, check `vercel ls 2>/dev/null | head -5` or ask the user.

---

## Step 1 — Register / upsert site in manage-worker-bee

```bash
# Check if site already exists by name
SITE_LIST=$(curl -sf -X GET "$WB_API/api/sites" -H "x-api-key: $WB_KEY" 2>/dev/null || echo '{"sites":[]}')
SITE_ID=$(echo "$SITE_LIST" | python3 -c "
import json,sys
d=json.load(sys.stdin)
sites=d.get('data',d.get('sites',[]))
match=[s for s in sites if '$PROJECT_SLUG' in s.get('name','').lower() or '$PROJECT_SLUG' in s.get('url','').lower()]
print(match[0]['id'] if match else '')
" 2>/dev/null)

if [[ -z "$SITE_ID" ]]; then
  STACK=$(grep -q "wordpress\|wp-" CLAUDE.md 2>/dev/null && echo "wordpress" || echo "nextjs")
  GITHUB=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com\///' | sed 's/\.git//' || echo "")
  NEW=$(curl -sf -X POST "$WB_API/api/sites" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $WB_KEY" \
    -d "{\"name\":\"$PROJECT_SLUG\",\"url\":\"$PROJECT_URL\",\"stack\":\"$STACK\",\"github_repo\":\"$GITHUB\"}" 2>/dev/null)
  SITE_ID=$(echo "$NEW" | python3 -c "import json,sys; print(json.load(sys.stdin).get('data',{}).get('id',''))" 2>/dev/null)
fi
echo "Site ID: $SITE_ID"
```

---

## Step 2 — SEO Audit

Call the site-audit API and extract scores.

```bash
SEO_RESULT=$(curl -sf -X POST "$WB_API/api/site-audit" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"$PROJECT_URL\",\"siteId\":\"$SITE_ID\"}" 2>/dev/null || echo '{}')
SEO_SCORE=$(echo "$SEO_RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('scores',{}).get('total',d.get('total',0)))" 2>/dev/null || echo "0")
echo "SEO score: $SEO_SCORE/100"
```

Capture failing checks as recommendations:
```bash
SEO_RECS=$(echo "$SEO_RESULT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
checks=d.get('checks',[])
fails=[c['label']+': '+c.get('detail','') for c in checks if c.get('status') in ('fail','warn')]
print('\n'.join(fails[:10]))
" 2>/dev/null)
```

---

## Step 3 — CSO (Security) Audit

Use the same site-audit endpoint which includes a security section, or run the `/cso` skill:

```bash
CSO_SCORE=$(echo "$SEO_RESULT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('scores',{}).get('security',d.get('security_score',0)))
" 2>/dev/null || echo "0")
```

For a deep CSO audit, invoke the `/cso` skill separately and pull its score.

---

## Step 4 — Monetization & Affiliate Analysis

Call the monetization analysis using Claude — analyze the site type and match affiliate programs:

```bash
SITE_TYPE=$(python3 -c "
import sys
url='$PROJECT_URL'.lower()
slug='$PROJECT_SLUG'.lower()
if 'climb' in url or 'climb' in slug: print('climbing-guide')
elif 'auto' in slug or 'repair' in slug: print('auto-repair')
elif 'medical' in slug or 'spanish' in slug: print('medical-education')
elif 'language' in slug or 'lingua' in slug: print('language-saas')
elif 'logistics' in slug or 'trucking' in slug: print('logistics')
else: print('marketing')
" 2>/dev/null || echo "marketing")
```

Then use `jr` to do affiliate research:
```bash
AFFILIATE_RESULT=$(jr "For a $SITE_TYPE website at $PROJECT_URL, identify the top 5 affiliate programs that would be relevant. For each: name, category, estimated commission %, signup URL, and why it fits this site. Return JSON array." 2>/dev/null || echo '[]')
```

---

## Step 5 — Build Blueprint Cork Board

Analyze the project codebase to generate blueprint nodes. Each page → one node, each major section → one node, APIs → nodes.

```bash
# Generate page list from project structure
PAGES=$(find app src -name "page.tsx" -o -name "*.page.tsx" 2>/dev/null | \
  grep -v node_modules | grep -v ".next" | \
  sed 's|app/||;s|/page\.tsx||;s|src/pages/||;s|\.tsx||' | sort)

COMPONENTS=$(find components src/components -name "*.tsx" 2>/dev/null | \
  grep -v node_modules | head -20 | \
  xargs -I{} basename {} .tsx)
```

Build blueprint nodes array and push to manage-worker-bee:
```bash
BLUEPRINT_NODES=$(python3 << 'PYEOF'
import json, os

pages = """$PAGES""".strip().split('\n') if """$PAGES""".strip() else []
components = """$COMPONENTS""".strip().split('\n') if """$COMPONENTS""".strip() else []

nodes = []
x, y = 100, 100

# Home always first
nodes.append({'id':'home','type':'default','position':{'x':x,'y':y},'data':{'label':'Home','sublabel':'app/page.tsx','type':'page'}})
y += 120

for i, p in enumerate(pages[:20]):
    if not p or p in ('','home','(dashboard)'):
        continue
    nodes.append({
        'id': f'page-{i}',
        'type': 'default',
        'position': {'x': x + (i % 3) * 280, 'y': y + (i // 3) * 120},
        'data': {'label': p.split('/')[-1].title(), 'sublabel': f'app/{p}/page.tsx', 'type': 'page'}
    })

y += (len(pages) // 3 + 1) * 120 + 60

for i, c in enumerate(components[:12]):
    if not c:
        continue
    nodes.append({
        'id': f'comp-{i}',
        'type': 'default',
        'position': {'x': x + (i % 4) * 220, 'y': y + (i // 4) * 100},
        'data': {'label': c, 'sublabel': f'components/{c}.tsx', 'type': 'component'}
    })

print(json.dumps(nodes))
PYEOF
)

curl -sf -X POST "$WB_API/api/blueprints/update" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $WB_KEY" \
  -d "{\"siteId\":\"$SITE_ID\",\"nodes\":$BLUEPRINT_NODES,\"edges\":[],\"summary\":\"$PROJECT_SLUG — WB push $(date +%Y-%m-%d). SEO: $SEO_SCORE/100\"}" \
  && echo "Blueprint pushed ✓"
```

---

## Step 6 — Vault Population

Store all API keys and important URLs from this project's environment:

```bash
# Collect env vars from .env.local or CLAUDE.md
ENV_KEYS=$(grep -E "^[A-Z_]+=|NEXT_PUBLIC_|SUPABASE|STRIPE|RESEND|ANTHROPIC" .env.local 2>/dev/null | \
  grep -v "^#" | cut -d= -f1 | sort -u)

# For each key, POST to credentials vault
for KEY in $ENV_KEYS; do
  VALUE=$(grep "^$KEY=" .env.local 2>/dev/null | cut -d= -f2-)
  if [[ -n "$VALUE" ]]; then
    curl -sf -X POST "$WB_API/api/credentials" \
      -H "Content-Type: application/json" \
      -H "x-api-key: $WB_KEY" \
      -d "{\"title\":\"$PROJECT_SLUG — $KEY\",\"category\":\"env\",\"site\":\"$PROJECT_SLUG\",\"project\":\"$PROJECT_SLUG\",\"apiKey\":\"$VALUE\",\"tags\":[\"$PROJECT_SLUG\",\"env\"]}" \
      > /dev/null 2>&1
  fi
done
echo "Vault entries written ✓"
```

---

## Step 7 — Record the run

Write everything back to the WB run log:

```bash
CHANGES_JSON=$(python3 -c "
import json
changes = [
    'SEO audit completed — score $SEO_SCORE/100',
    'Blueprint cork board generated with nodes',
    'Vault populated with env vars',
    'Affiliate program analysis complete',
    'Site registered/updated in manage-worker-bee',
]
print(json.dumps(changes))
")

RECS_JSON=$(python3 -c "
import json,sys
recs = [r.strip() for r in '''$SEO_RECS'''.split('\n') if r.strip()][:8]
print(json.dumps(recs))
")

curl -sf -X POST "$WB_API/api/wb-run" \
  -H "Content-Type: application/json" \
  -d "{
    \"site_id\": \"$SITE_ID\",
    \"triggered_by\": \"claude\",
    \"phases\": {\"seo\":true,\"cso\":true,\"monetization\":true,\"blueprint\":true,\"vault\":true,\"affiliate\":true},
    \"seo_score\": $SEO_SCORE,
    \"cso_score\": $CSO_SCORE,
    \"changes\": $CHANGES_JSON,
    \"recommendations\": $RECS_JSON,
    \"affiliate_matches\": $AFFILIATE_RESULT,
    \"summary\": \"$PROJECT_SLUG WB push complete. SEO $SEO_SCORE, CSO $CSO_SCORE.\",
    \"status\": \"complete\"
  }" && echo "Run logged ✓"
```

---

## Step 8 — Pipeline readiness check

After running, check if the site needs to go through the full wb-pipeline for visual revisions:

```bash
if [[ "$SEO_SCORE" -lt 70 || "$CSO_SCORE" -lt 70 ]]; then
  echo ""
  echo "⚠️  Score below 70 — recommend running full WB pipeline:"
  echo "   Phase 01: Research → Phase 02: Scaffold → Phase 03: Visual Loop → Phase 04: Deploy"
  echo "   Trigger: POST $WB_API/api/build-trigger with siteId: $SITE_ID"
fi
```

---

## Exit Criteria

Run is complete when all of these have a value:
- `SITE_ID` — non-empty UUID
- `SEO_SCORE` — integer 0–100
- Blueprint pushed — `200 OK` from `/api/blueprints/update`
- Run logged — `201 Created` from `/api/wb-run`

Report back:
```
✅ [project-slug] pushed to Worker Bee
   Site ID:    [uuid]
   SEO:        [score]/100
   CSO:        [score]/100
   Blueprint:  [N] nodes
   Vault:      [N] entries written
   Affiliates: [N] matches found
   Run logged: [run_id]
   Dashboard:  https://manage.worker-bee.app/sites/[site_id]
```
