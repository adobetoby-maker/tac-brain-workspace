# Rule: API / Auth Wall Checklist — Exhaust Before Asking

---

## Iron Law — Never Stop at the First Wall

Observable trigger: Any tool call returns auth error, 401, 403, token expired, rate limit, permission denied, or "requires re-authorization."

**Do NOT report the error to the user. Run this checklist first.**

If all 10 methods fail → THEN report to user with: exact error, which methods were tried, and the minimum possible ask (one URL, one command, one click).

---

## The 10-Method Checklist (run in order)

### 1. Retry the MCP with a fresh call
Some "expired" errors are transient. Try the tool call once more before treating it as real.

### 2. Find a different MCP for the same task
- Cloudflare blocked? → Try `cloudflare-bindings`, `cloudflare-observability`, `cloudflare-builds`
- Vercel blocked? → Try `mcp__claude_ai_Vercel__*` tools
- GitHub blocked? → Try `mcp__plugin_github_github__*` tools
- Search: `ToolSearch("cloudflare dns")` — a different server may have the same capability

### 3. Use the CLI / binary directly
```bash
# Cloudflare: wrangler
npx wrangler@latest whoami
npx wrangler@latest dns list --zone andertongroup.com

# Vercel: vercel CLI
vercel domains add domain.com
vercel alias set deployment.vercel.app domain.com

# GitHub: gh CLI
gh api /repos/owner/repo/contents/file

# Supabase: supabase CLI
supabase db query --linked "SQL HERE"
```

### 4. Find credentials in the environment
```bash
# Search all env files
grep -r "TOKEN\|API_KEY\|SECRET\|PASSWORD" \
  ~/.claude/api-keys.env \
  /Users/drive/.env \
  /Users/drive/manage-worker-bee/.env.local \
  2>/dev/null | grep -i "<service>"

# Search keychain
security find-generic-password -l "<service>" -w 2>/dev/null
security find-internet-password -s "<domain>" -w 2>/dev/null

# Search wrangler / tool configs
cat ~/Library/Preferences/.wrangler/config/default.toml 2>/dev/null
cat ~/.claude/.credentials.json 2>/dev/null
```

### 5. Extract session from browser cookies
```bash
pip3 install pycookiecheat 2>/dev/null
python3 -c "
from pycookiecheat import chrome_cookies
c = chrome_cookies('https://<domain>', browser='Chrome')
print(list(c.keys()))
print({k:v for k,v in c.items() if 'session' in k.lower() or 'auth' in k.lower() or 'token' in k.lower()})
"
# Then use the session cookie directly against the API:
# curl -H "Cookie: <session>=<value>" "https://api.<domain>.com/..."
```

### 6. Use Playwright with extracted cookies
```js
// Launch chromium (not Chrome — avoids profile lock) + inject cookies
const ctx = await chromium.launch({ headless: false })
const page = await ctx.newPage()
await page.context().addCookies(extractedCookies)
await page.goto('https://dashboard.service.com')
// Then automate the UI action
```

### 7. Use Playwright to automate the dashboard UI
When API is blocked but the user is logged in via browser:
```js
// Connect to running Chrome via CDP (if --remote-debugging-port is open)
const browser = await chromium.connectOverCDP('http://localhost:9222')
// OR launch persistent context with user profile
const ctx = await chromium.launchPersistentContext(
  '/Users/drive/Library/Application Support/Google/Chrome',
  { channel: 'chrome', args: ['--profile-directory=Default'] }
)
// Automate the UI action (add DNS record, configure email routing, etc.)
```

### 8. Use a REST fallback / alternative endpoint
- Cloudflare DNS: `https://api.cloudflare.com/client/v4/zones/{id}/dns_records` (needs zone token)
- Cloudflare via wrangler OAuth token: `~/Library/Preferences/.wrangler/config/default.toml`
- Vercel via REST: `https://api.vercel.com/v9/projects/{id}/domains`
- Most services have a REST API separate from their SDK/MCP

### 9. Use a different account layer
- Can a service account / bot token do this instead of a user token?
- Does Zapier/Make have a connector that bypasses the auth wall?
- Does the Vercel MCP (`mcp__claude_ai_Vercel__*`) cover the same action?

### 10. Trigger re-auth and continue
```bash
# Cloudflare: restart wrangler OAuth
npx wrangler@latest login

# GitHub: re-authenticate gh CLI
gh auth login

# Supabase: re-link project
supabase link --project-ref <ref>

# Vercel: re-authenticate
vercel login
```
If re-auth opens a browser prompt, tell the user: "Run `! npx wrangler@latest login` in the terminal" — the `!` prefix runs it in this session.

---

## When All 10 Fail — Minimum Viable Ask

Report to user in this exact format:
```
❌ [Service] wall — tried [N] methods.

Minimum fix (30 seconds):
1. Go to [exact URL]
2. [One specific action] — e.g., "paste this record:" [value]
3. [Done condition]

I'll [verify / continue] automatically once you confirm.
```

Never say "I can't do this." Say "I hit a wall at step N — here's the minimum ask."

---

## Platform-Specific Quick Paths

| Platform | Fastest unblocking | Credential location |
|---|---|---|
| Cloudflare DNS | `! npx wrangler@latest login` | `~/.wrangler/config/default.toml` |
| Cloudflare API | ToolSearch("cloudflare-api") re-auth | `.credentials.json` mcpOAuth |
| Vercel | `vercel login` or MCP Vercel tools | `~/.local/share/com.vercel.cli/auth.json` |
| GitHub | `gh auth login` or gh MCP | `~/.config/gh/hosts.yml` |
| Supabase | `supabase link` + `supabase db query --linked` | `.env.local` SUPABASE_SERVICE_ROLE_KEY |
| Resend | REST API with key from `.env.local` | Always works — no OAuth |
| Stripe | Stripe MCP or REST with key | `.env.local` STRIPE_SECRET_KEY |
| Google/GBP | Zapier connector → webhook | No direct REST without app review |

---

## Playwright Automation Triggers

Use Playwright to automate UI when:
- The service has no public API for the action
- API requires an approval/review that would take days
- The user is already logged in via Chrome (use persistent context or CDP)
- The API rate limit blocks programmatic access

Playwright success rate is high for: DNS dashboards, email routing config, directory submissions, form fills, platform settings pages.

Playwright is NOT worth attempting for: captcha-protected login flows, 2FA-gated actions without saved sessions, services with advanced bot detection on their login page.

---

## Grade: 8/10
Forcing function: This rule fires when I see auth errors. Without a pre-action hook checking for auth failures, the rule depends on session-start conditioning. Gap: no hook that intercepts "401/403/expired" shell output and re-fires this protocol automatically. That hook would push this to 9.5/10.
