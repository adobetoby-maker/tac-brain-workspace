---
name: wb-researcher
description: "Worker-Bee Pipeline: Research phase. Searches the web for the subject's real headshot, bio, credentials, reviews, phone, address, and hours. Screenshots reference sites for visual benchmarking. Saves results to /tmp/research-brief-<slug>.json. Use when starting a new site build or refreshing assets for an existing site."
risk: safe
source: manage-worker-bee (internal)
date_added: 2026-05-28
---

# WB Researcher Agent

## Trigger phrases
- "research [site name]"
- "find assets for [client]"
- "run the researcher"
- "phase 0"

## Required context (ask if missing)

- `subjectName` — the person/business to research (e.g. "Dr. John Smith", "JRS Auto Repair")
- `siteType` — medical / legal / local-service / restaurant / saas / ecommerce / agency / real-estate / general
- `slug` — URL-safe site identifier (e.g. "jrs-auto-repair")
- `referenceUrls` — list of competitor sites to screenshot and benchmark against (can be empty)

## Research sources by site type

| Type | Primary Sources |
|------|----------------|
| medical | healthgrades.com, usnews.com/doctors, vitals.com, hospital website |
| legal | avvo.com, martindale.com, justia.com, state bar profile |
| local-service | Google Business Profile, Yelp, existing website, Facebook |
| restaurant | Google Business Profile, Yelp, OpenTable, TripAdvisor |
| saas | ProductHunt, their site, Crunchbase, G2, LinkedIn |
| real-estate | Zillow, Realtor.com, their brokerage |
| general | Google search, LinkedIn, social profiles, existing website |

## Steps

1. Use `browser_navigate` + `browser_evaluate` to search each source for `subjectName`
2. Extract: headshot URL, bio text, credentials[], reviews[], phone, address, hours
3. For each referenceUrl: `browser_navigate` → `browser_take_screenshot` → save as `/tmp/ref-<slug>-<i>.png`
4. Write the research brief:

```json
{
  "photoUrl": "<real headshot URL or null>",
  "heroImageUrl": "<real facility/setting photo URL or null>",
  "bio": "<real bio text>",
  "credentials": ["credential 1", "credential 2"],
  "reviews": [{"text": "...", "author": "...", "rating": 5, "source": "Google"}],
  "phone": "",
  "address": "",
  "hours": "",
  "referenceScreenshots": ["/tmp/ref-<slug>-0.png"]
}
```

Save to: `/tmp/research-brief-<slug>.json`

## Rules

- Real asset → use it. Unsplash is only a fallback.
- Never use a generic stock person as a portrait.
- Zero results after 3 searches → write null for that field and document why.
- Always save the file even if most fields are null — the builder depends on it.

## Report back
```bash
curl -s -X POST https://manage.worker-bee.app/api/build-log \
  -H "x-api-key: 9fd6a40a79137d7fdb4ea7dc97d7c40478af2fae339dc8b25cc4595bd8dd1747" \
  -H "content-type: application/json" \
  -d '{"siteId":"<SITE_ID>","phase":"researcher","status":"done","artifacts":["/tmp/research-brief-<slug>.json"]}'
```

## Output artifacts

- `/tmp/research-brief-<slug>.json` — primary output consumed by wb-builder
- `/tmp/ref-<slug>-*.png` — reference site screenshots (visual benchmark)
