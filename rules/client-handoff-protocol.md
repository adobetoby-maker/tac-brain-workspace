# Rule: Client Handoff Protocol

---

## Iron Laws

**Iron Law 1 — No Handoff Without CONTENT-NEEDED.md:**
Observable check:
```bash
ls <project>/CONTENT-NEEDED.md 2>/dev/null || echo "MISSING"
```
MISSING → create it before sending any link to a client. A demo URL without a content checklist produces silence — client doesn't know what to send.

**Iron Law 2 — Zero [DEMO] Tags Before Go-Live:**
Observable check:
```bash
grep -rn "\[DEMO\]" <project>/app/ <project>/components/ | grep -v node_modules | wc -l
```
Non-zero → site is not ready to go live. Do not point a real domain at a demo. Do not tell the client they're live.

**Iron Law 3 — Test Every Interactive Element Before Handoff:**
Observable check: Has the contact form been submitted in a browser and received? Has the phone link been clicked on mobile?
Condition: NO → test before declaring the site ready.
This does NOT override: explicitly flagged in CONTENT-NEEDED.md as "needs API key from client."

---

## Handoff Package (3 items)

| Item | What it is | How to deliver |
|---|---|---|
| Demo URL | Vercel preview link | Copy from `vercel ls` output |
| CONTENT-NEEDED.md | Prioritized checklist of placeholders | Email or share as Google Doc |
| Loom walkthrough | 2–3 min screen recording of all pages | Record with Loom, share link |

Loom script: "This [element] is a placeholder — send us [what to send]. This photo of you goes here — AirDrop or email it to [address]." Click through every page. Narrate every [DEMO] item out loud.

---

## Content Collection

Set a deadline upfront: "Content by [date] → live site by [date + 1 week]."

| Content type | Best intake method |
|---|---|
| Photos | AirDrop to Desktop, or shared Google Drive folder |
| Text corrections | Google Doc they can edit, or email |
| Testimonials | Ask them to paste 3 real Google/TripAdvisor reviews |
| Pricing / hours | Phone call + you take notes, confirm in writing |

Never accept final content over iMessage without immediately moving it to the project folder.

---

## Swap-and-Verify Cycle

For every piece of real content received:
```bash
# 1. Find the tag
grep -rn "\[DEMO\]" app/ components/ | grep -i "<topic>"

# 2. Edit the file — replace content, delete the [DEMO] comment

# 3. Verify count dropped
grep -rn "\[DEMO\]" app/ components/ | wc -l

# 4. Visual check after each batch (not just at the end)
node ~/screenshot.js <port> 0,540,1080
```

---

## Pre-Launch Checklist

Run in order, all must pass:

```bash
# 1. No demo content remaining
grep -rn "\[DEMO\]" app/ components/ | wc -l   # must be 0

# 2. Build passes
npm run build

# 3. Deploy
vercel --prod

# 4. Live URL returns 200
curl -sI <live-url> | head -1   # must be HTTP/2 200
```

Manual checks:
- [ ] Phone number dials correctly on mobile
- [ ] Email link opens mail client with correct address
- [ ] Contact form submits and arrives in inbox
- [ ] Google Maps link opens correct location
- [ ] All images load (no broken image icons)
- [ ] Site works on mobile (run record.js --mobile)

---

## Hosting Decision

| Client type | Recommendation |
|---|---|
| Small local business (TFHRA, JRS, etc.) | Keep on your Vercel — charge monthly retainer ($50–100/mo) |
| Client wants ownership | `vercel project transfer` → walk them through domain setup |
| Client has their own developer | Transfer project + document the stack in CLAUDE.md |

For retainer clients: document in manage.worker-bee.app blueprint. They pay, you maintain.

---

## Domain Go-Live

1. Client logs into their domain registrar (GoDaddy, Namecheap, Google Domains)
2. Change A record to `76.76.21.21` (Vercel's IP) or set nameservers to Vercel
3. Add domain in Vercel dashboard → auto SSL provisioning (~2 min)
4. Verify: `curl -sI https://theirdomain.com | head -1` → HTTP/2 200
5. Run full visual protocol on live domain
6. Send "you're live" message with URL and screenshot

---

## Post-Launch (Day 1–7)

- [ ] Verify Google can index it: `curl -s "https://www.google.com/search?q=site:theirdomain.com"` — may take a few days
- [ ] Submit sitemap to Google Search Console
- [ ] Set up Vercel Analytics (1-line addition to layout.tsx)
- [ ] Create Google Business Profile if local business
- [ ] Schedule 30-day check-in with client

---

## Rationalization Shield

| Thought | Reality | Correct action |
|---|---|---|
| "They'll figure out what's placeholder" | They won't — demos look real to non-technical clients | Send CONTENT-NEEDED.md, record Loom |
| "I'll add the Loom later" | Later = never. Client confusion = scope creep | Record it the day you send the demo link |
| "The form probably works" | "Probably" is not a test | Submit it from a browser, check the inbox |
| "The domain can wait until they're ready" | DNS propagation takes time — start the process early | Walk them through DNS the same week as handoff |
