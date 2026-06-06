# Cross-Project Vocabulary

Terms that appear in conversation without context. When you hear any of these, look here first before asking for clarification.

---

## manage-worker-bee (manage.worker-bee.app)

| Term | What it means |
|---|---|
| **worker-bee** | The internal dashboard project at `manage.worker-bee.app` — manages all client sites, credentials, and blueprints |
| **blueprint** | The visual canvas system (`@xyflow/react`) in worker-bee where client site architectures are designed as flowcharts. Stored as `{nodes, edges}` JSON in Supabase Storage `blueprints` bucket. Route: `/sites/[id]` |
| **vault** | AES-256-GCM encrypted credential manager in worker-bee. Stores API keys, logins, SSH creds per client site. Route: `/vault/`. Master password in `vault_session` cookie. |
| **configurator** | Worker-bee tool that generates `CLAUDE.md` + `settings.json` for new client projects. Route: `/configurator/` |
| **submissions** | Incoming client blueprint submissions (public-facing form at `/plan`). Internal view at `/submissions/` |
| **pipeline** | The 5-phase automated build pipeline: Research → Architecture → Build → SEO/QA → Deploy. Triggered via worker-bee dispatch |
| **blueprint-wizard** | AI-powered blueprint generation endpoint (`/api/blueprint-wizard`) — refines raw requirements into structured nodes/edges |
| **onboard** | The `POST /api/sites/[id]/onboard` route that kicks off the full site-build pipeline for a new client site |
| **image-gen** | ComfyUI proxy at `/api/image-gen` — takes a prompt, returns base64 PNG |
| **TETRAD** | Internal security/intelligence module name (war room) — referenced in manage-worker-bee security context |
| **Ares** | Security audit module within manage-worker-bee — runs 5-check audit on site configurations |
| **blueprint canvas** | Synonym for "blueprint" — the `@xyflow/react` visual canvas at the site detail page |
| **sitemap** (worker-bee context) | The list of managed client sites at `/(dashboard)/sites/` — NOT an XML sitemap |

---

## LinguaLens / language-lens-elite

| Term | What it means |
|---|---|
| **LinguaLens** | The language learning app at `language-lens-elite.worker-bee.app`. TanStack Start + Vite + Cloudflare Workers. |
| **XP tier** | Learner progression: Beginner🌱 → Apprentice📖 → Scholar🎓 → Linguist🗣️ → Maestro✦. Computed from XP in `app-state.tsx`. Persisted to Supabase `profiles`. |
| **rank tier** | Multiplayer matchmaking rank: Bronze → Silver → Gold → Platinum → Diamond → Champion → Unreal. In `match-state.tsx`. SEPARATE from XP tier. |
| **KanaPad** | Romaji ↔ Hiragana ↔ Katakana ↔ Kanji converter. TabKey: `"kana"`. |
| **parallel reader** | Dual-pane text reader with furigana/romaja toggle. `ParallelReader.tsx`. |
| **tab system** | Feature panels registered in `tab-registry.ts`. Adding a tab = dual update required (ADR-0011). |
| **server function** | TanStack Start server-side function (NOT a Next.js API route). Lives in `src/routes/api.*.ts`. |

---

## Jr.'s Auto Repair (jrs-auto-repair)

| Term | What it means |
|---|---|
| **admin** (jrs context) | Pablo's internal area at `/admin`. Cookie auth (`admin_session`). Users in `data/admins.json`. |
| **portal** (jrs context) | Customer-facing invoice/account area at `/portal`. Supabase JWT auth. |
| **shopInfo** | `lib/shopInfo.ts` — single source of truth for ALL business info (name, phone, hours, address, services). Never hardcode elsewhere. |
| **articles** | Blog posts in `lib/articles.ts` (TypeScript array). Never markdown files. Route: `/blog/[slug]`. |
| **Pablo** | Client — Pablo Zaldivar, owner. (208) 595-2101. Mon-Sat 9AM–5PM. |

---

## Silver Creek Logistics (silver-creek-logistics)

| Term | What it means |
|---|---|
| **dispatch** | Automated driver notification system. Two separate systems: Vercel cron (daily) + Cloudflare Worker (30-min). |
| **CF Worker** (silvercreek context) | `cloudflare-worker/silvercreek-dispatch` — deployed separately from Vercel. Handles real-time dispatch. |
| **CRON_SECRET** | Shared secret between Vercel and CF Worker. Must match in BOTH platforms or dispatch fails silently. |
| **admin** (silvercreek context) | Internal ops area at `/admin`. Cookie auth. Routes: `/admin/crm`, `/admin/dispatch`, etc. |
| **portal** (silvercreek context) | Customer invoices at `/portal`. Supabase JWT auth. |
| **calculator** | Freight quote calculator at `/(site)/calculator`. Public. |
| **QuickBooks** | OAuth invoice sync integration. `QB_CLIENT_ID`, `QB_REDIRECT_URI` must match OAuth app settings exactly. |

---

## Orthobiologic Pathways (orthobiologic-pathways)

| Term | What it means |
|---|---|
| **shop gate** | `/shop-gate` — access control page. No real e-commerce. |
| **consultation flow** | `/consultation-flow` — multi-step form. No backend persistence. |
| **patient dashboard** | `/patient-dashboard` — static/demo, no real auth. |

---

## Toby Anderton MD (tobyandertonmd)

| Term | What it means |
|---|---|
| **the site** | tobyandertonmd.vercel.app — minimal marketing site, single page, 8 components. |

---

## Climbing Sites (climb-brasil, climb-utah, climb-spain, climb-kalymnos, climb-france)

| Term | What it means |
|---|---|
| **images block** | `images: { hero, approach, crux, summit }` field in each route in `routes.ts`. Must be unique per site (ADR-0013). |
| **gallery** | Additional photos array in routes. Also subject to uniqueness rule. |
| **route slug** | URL-safe route identifier used in `[slug]` dynamic routes. |
| **affiliate** | Boolean on `guideOperator` and `lodging` — drives affiliate tracking. |
| **base city** | The town used as the base for a climbing area. Referenced in `BaseCityContent.tsx`. |

---

## Global / Cross-Project

| Term | What it means |
|---|---|
| **record.js** | `~/record.js` — video screen recorder for visual review of animations. Required for R3F, Framer Motion, scroll-driven UI. NEVER use screenshot.js for these. |
| **screenshot.js** | `~/screenshot.js` — static screenshot tool. Only for non-animated content (forms, typography, grids). |
| **devtools** | `/Users/drive/devtools/` — split terminal + preview server at localhost:3333 / 100.117.143.57:3333. |
| **Tailscale** | VPN that bridges local dev to mobile. Start dev servers with `-H 0.0.0.0` (ADR-0007). URL: `http://100.117.143.57:<port>`. |
| **failures.md** | `~/.claude/failures.md` — rolling failure log. Append whenever something breaks or wastes 30+ min. |
| **ADR** | Architecture Decision Record. Lives in `~/.claude/decisions/`. Action-triggering format with TRIGGER→ACTION→WHY→PREDICTED FAILURE→VERIFY. |
| **manage.worker-bee.app** | The internal dashboard (synonym for "worker-bee"). |
| **worker-bee.app** | Domain suffix for client deployments (e.g., `jrsautorepair.worker-bee.app`). |
| **missionary module** | TBD — not yet documented. Ask Toby for context if encountered. |
| **service role key** | `SUPABASE_SERVICE_ROLE_KEY` — bypasses RLS. Only use in `lib/supabase/admin.ts`, never client-side. |
| **claude-mem** | Memory MCP plugin. Use `mcp__plugin_claude-mem_mcp-search__memory_search` for semantic search. |
| **tac** | `/tac` skill — workspace bootstrap. Loads session context, memory, skills menu. |
