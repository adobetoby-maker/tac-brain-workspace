# Rule: Skill and Tool Self-Selection

Claude selects and invokes the right skill, MCP, plugin, or API for every task automatically.
Do not wait to be asked. If a task matches a category below, invoke the corresponding tool first.

---

## The Prime Directive

A skill is a curated, proven pattern. Reasoning from general knowledge when a skill exists wastes the skill investment and produces worse results. The skill fires first, every time.

---

## Task → Tool Matrix

### Building / Designing

| Task | Invoke First | Supporting Tools |
|---|---|---|
| New website or app | `brainstorming` skill → `website-build-protocol` category → UUPM design_system.py | See website build protocol |
| New landing page | UUPM `design_system.py` → `landing-page-generator` skill | `tailwind-patterns`, `shadcn` |
| UI component | `ui-ux-pro-max` skill + UUPM `search.py --domain ux` | `shadcn`, `react-best-practices` |
| Design direction / style / palette | `python3 ~/.claude/skills/ui-ux-pro-max/scripts/design_system.py "<desc>"` | `search.py --domain style/color/typography` |
| Color palette choice | `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<mood>" --domain color` | `search.py --domain product` |
| Font pairing / typography | `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<mood>" --domain typography` | Google Fonts URL in output |
| Landing page layout / section order | `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<type>" --domain landing` | `seo-aeo-landing-page-writer` |
| Accessibility / a11y check | `python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "accessibility" --domain ux` | `accessibility-compliance-accessibility-audit` |
| Next.js feature | `nextjs-best-practices` skill + `search.py "<concern>" --stack nextjs` | `nextjs-app-router-patterns` |
| Supabase work | `supabase-automation` skill | Supabase MCP if available |
| Auth flow | `auth-implementation-patterns` skill | `nextjs-supabase-auth` |
| Animation / scroll | `animejs-animation` or `threejs-skills` | `visual-loop` skill after |
| 3D / shader | `threejs-shaders` skill | `threejs-fundamentals` |
| Dark/premium UI | `industrial-brutalist-ui` or `frontend-ui-dark-ts` + UUPM `--domain style` | `tailwind-design-system` |
| Design system | UUPM `design_system.py` → `tailwind-design-system` skill | `shadcn`, `ui-tokens` |
| Mobile UI | `mobile-design` skill + UUPM `--stack react-native` or `--stack swiftui` | `hig-platforms` |

### Research & Analysis

| Task | Invoke First | Supporting Tools |
|---|---|---|
| Competitor research | `competitor-profiling` skill | `firecrawl:firecrawl-scrape`, WebSearch |
| Market analysis | `startup-business-analyst-market-opportunity` | `deep-research` skill |
| Marketing plan / evaluation / report | `content-strategy` skill | `copywriting`, `seo-keyword-strategist` |
| Content plan / content strategy / topic clusters | `content-strategy` skill | `seo-aeo-keyword-research` |
| Site audit | `seo-audit` skill | `mcp__claude_ai_Vercel__get_runtime_logs` |
| Keyword research | `seo-keyword-strategist` skill | `seo-aeo-keyword-research` |
| Codebase exploration | Agent(subagent_type=Explore) | Glob, Grep |
| Photo sourcing / add photos / real images | Follow image-sourcing protocol (see below) | Never substitute stock silently |

### SEO & Content

| Task | Invoke First | Supporting Tools |
|---|---|---|
| SEO audit | `seo-audit` skill | `seo-technical` |
| Write blog post | `seo-aeo-blog-writer` skill | `copywriting` |
| Write landing copy | `seo-aeo-landing-page-writer` skill | `copywriting` |
| Meta descriptions | `seo-aeo-meta-description-generator` skill | — |
| Schema markup | `seo-aeo-schema-generator` skill | `schema-markup` |
| Internal linking | `seo-aeo-internal-linking` skill | — |
| Keyword map | `seo-aeo-keyword-research` skill | `keyword-extractor` |
| Technical SEO | `seo-technical` skill | `indexing-issue-auditor` |
| SEO images | `seo-images` skill | `seo-image-gen` |
| Local SEO | `local-legal-seo-audit` or `seo-geo` | — |

### Visual Verification (always after any UI change)

| Task | Tool | Notes |
|---|---|---|
| Static content check | `node ~/screenshot.js <port> 0,540,1080` | Forms, grids, typography only |
| Animated / scroll UI | `node ~/record.js <port>` | REQUIRED — never skip |
| Mobile check | `node ~/record.js <port> --mobile` | Equal weight to desktop |
| Frame extraction | `ffmpeg -i review.webm -vf fps=2 frame%03d.png` | Then Read each frame |
| Score iteration | `visual-loop` skill | Compare vs reference + prior iter |

### Debugging

| Task | Invoke First | Supporting Tools |
|---|---|---|
| Unknown bug | `systematic-debugging` skill | `bug-hunter` |
| Error trace | `error-debugging-error-trace` skill | — |
| Performance | `performance-optimizer` skill | `web-performance-optimization` |
| Security issue | `security-audit` skill | `cso` skill |
| Build failure | `error-diagnostics-smart-debug` skill | Bash build output |

### Deployment

**Decision before any deploy command:**
- Marketing / affiliate / portfolio / landing page → **Vercel** (`vercel --prod`)
- worker-bee.app subdomain with D1/R2/KV/cron → **Cloudflare Workers** (wrangler)
- When in doubt → **Vercel**. Image optimization, persistent CLI auth, GitHub auto-deploy.

**If any deploy step fails (exit non-zero) → Iron Law 2:**
```bash
vercel whoami                           # 1. Vercel CLI cached?
env | grep -iE "cloudflare|vercel"      # 2. Token in env?
gh repo view --json homepageUrl         # 3. GitHub auto-deploy wired?
# 4. mcp__claude_ai_Vercel__deploy_to_vercel
# 5. .github/workflows/deploy.yml with VERCEL_TOKEN secret
```
Report what worked. Never report what failed without running all five first.

| Task | Tool |
|---|---|
| Vercel deploy (standard) | `vercel --prod` |
| Vercel deploy (MCP) | `mcp__claude_ai_Vercel__deploy_to_vercel` |
| Cloudflare Workers (bindings project) | `cloudflare-workers-expert` skill — confirm D1/R2/KV first |
| CI/CD setup | `github-actions-templates` skill |
| DNS / domain | `mcp__claude_ai_Vercel__check_domain_availability_and_price` |
| Deploy failed | Run Iron Law 2 check sequence — do not report failure first |

### Database & Storage

| Task | Invoke First | Supporting Tools |
|---|---|---|
| Supabase schema | `supabase-automation` skill | Supabase MCP |
| DB design | `database-design` skill | `postgresql` |
| DB migration | `database-migrations-sql-migrations` skill | — |
| Query optimization | `postgresql-optimization` skill | `database-optimizer` |

### Testing

| Task | Invoke First | Supporting Tools |
|---|---|---|
| E2E tests | `playwright-skill` skill | Playwright MCP |
| Unit tests | `testing-patterns` skill | `tdd-workflows-tdd-cycle` |
| API tests | `api-testing-observability-api-mock` skill | — |
| Accessibility | `accessibility-compliance-accessibility-audit` | `ui-a11y` skill |

### Agents & Orchestration

| Task | Invoke First | Supporting Tools |
|---|---|---|
| Multi-step complex build | `dispatching-parallel-agents` skill | Multiple Agent calls |
| Background fan-out | `parallel-agents` skill | Agent(run_in_background=True) |
| Plan before coding | `writing-plans` skill or `autoplan` | `brainstorming` first |
| Memory search | `mem-search` MCP or `claude-mem:mem-search` | — |

---

## MCP Quick-Select

| Need | MCP Tool |
|---|---|
| Deploy to Vercel | `mcp__claude_ai_Vercel__deploy_to_vercel` |
| Get Vercel logs | `mcp__claude_ai_Vercel__get_runtime_logs` |
| Vercel project info | `mcp__claude_ai_Vercel__get_project` |
| Supabase DB | `mcp__plugin_supabase_supabase__*` (authenticate first) |
| Scrape a URL | `firecrawl:firecrawl-scrape` |
| Search the web (structured) | `firecrawl:firecrawl-search` |
| GitHub issue | `github-automation` skill or `github-issue-creator` |
| Slack message | `slack:draft-announcement` or `slack:standup` |
| Memory search | `claude-mem:mem-search` skill |
| Code review | `coderabbit:code-review` or `pr-review-toolkit:review-pr` |

---

## Plugin Quick-Select

| Need | Plugin |
|---|---|
| ComfyUI image gen | `comfy:gen` skill |
| Playwright browser | `playwright:playwright` MCP |
| Chrome DevTools | `chrome-devtools-mcp:chrome-devtools` |
| Figma design | `figma:figma-use` |
| Sentry errors | `sentry:seer` |
| Linear issues | `linear-automation` skill |

---

## Auto-Invoke Rules (Observable State, Not User Intent)

These fire on what IS TRUE, not on what the user said.

| Observable state | Action |
|---|---|
| `scores.md` missing in project root | Research required — run `research-first` protocol before any code |
| Project has no commits (`git log` fails) | Research required — new project, run research-first protocol |
| UI component added or changed | `record.js` immediately after — not screenshot.js |
| New public page created | Check SEO metadata: title, description, canonical, OG, JSON-LD |
| Any deploy command exits non-zero | Iron Law 2 — run 5-option check, report what worked not what failed |
| Deploy succeeds | Verify live URL: `curl -I <url>` → must return 200 |
| Architecture changed (new route, dep, env var) | Update project CLAUDE.md before declaring done |
| Project name mentioned, not worked on this session | `mem-search` before answering |
| "like we did with X" or "remember when" | `mem-search` for X before guessing |
| Session ends (Stop hook) | Push to manage.worker-bee.app blueprint API if tracked project |
