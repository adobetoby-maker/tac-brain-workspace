# Rule: Demo-to-Live Protocol

---

## Iron Laws

**Iron Law 1 — Full Demo First:**
Observable check: Does the project have no client content yet (no stats, no real photos, no verified copy)?
Condition: YES → build a complete, believable demo with realistic invented content. Never leave sections empty or skeletal.
This does NOT override: client has provided real content — use real content directly.

**Iron Law 2 — Tag Everything Invented:**
Observable check after writing any piece of content:
```bash
grep -rn "\[DEMO\]" <project>/app/ <project>/components/ <project>/lib/ 2>/dev/null | wc -l
```
Every invented stat, name, price, phone, email, testimonial, or photo MUST have a `{/* [DEMO] */}` comment or appear in CONTENT-NEEDED.md.
No invented content ships without a tag. No exceptions.

**Iron Law 3 — CONTENT-NEEDED.md on Every New Site:**
Observable check:
```bash
ls <project>/CONTENT-NEEDED.md 2>/dev/null || echo "MISSING"
```
MISSING → create it before declaring the demo done. It is the conversion checklist for the client.

---

## What Gets Tagged

| Content type | Demo version | Tag format |
|---|---|---|
| Phone number | (xxx) 555-xxxx | `{/* [DEMO] replace with real number */}` |
| Email | anything@domain.com | `{/* [DEMO] replace with real email */}` |
| Stats / numbers | plausible round numbers | `{/* [DEMO] verify: 13+, 8,000+, etc */}` |
| Testimonials | invented names + quotes | `{/* [DEMO] replace with real Google/TripAdvisor reviews */}` |
| Pricing | market-researched estimates | `{/* [DEMO] confirm pricing with client */}` |
| Hours | standard business hours | `{/* [DEMO] verify operating hours */}` |
| Hero photo | Pexels stock | `{/* [DEMO] replace with real location photo */}` |
| People photos | Pexels stock | `{/* [DEMO] replace with real photo from client */}` |
| Business name/tagline | invented unless provided | `{/* [DEMO] confirm with client */}` |
| Service descriptions | inferred from business type | `{/* [DEMO] verify details with client */}` |

---

## CONTENT-NEEDED.md Template

```markdown
# Content Needed — [Project Name]
Generated: [date]
Status: Demo live at [URL]

## Priority 1 — Replace Before Launch

- [ ] **Phone number** — current: (xxx) 555-xxxx → replace with real number
- [ ] **Email** — current: contact@domain.com → replace with real email
- [ ] **Hero photo** — current: stock photo → provide real location photo
- [ ] **Team/owner photo** — current: stock placeholder → AirDrop or email real photo
- [ ] **Testimonials** — current: invented → paste 3 real Google/TripAdvisor reviews

## Priority 2 — Verify Before Launch

- [ ] **Stats** — verify: X years, X customers, X rating
- [ ] **Pricing** — verify all prices are correct
- [ ] **Operating hours** — verify days and times
- [ ] **Address** — verify exact address and Google Maps link
- [ ] **Service descriptions** — verify ride names, durations, difficulty levels

## Priority 3 — Nice to Have

- [ ] **Real horse photos** — current: stock → photos of actual horses
- [ ] **Trail/location photos** — current: stock → photos of actual trails
- [ ] **Logo** — current: text logo → provide logo file if available

## How to Send Content

Email to: [developer email]
Or: AirDrop photos to [Mac name]
Photos should be: JPG, at least 1200px wide
```

---

## Decision Flow

```
New client site request
  ↓
1. Do we have real content from the client? (copy, photos, stats)
   YES → use it directly, skip demo phase
   NO  → build full demo

2. Build demo:
   → Research market: pricing, competitors, standard services
   → Invent realistic content: names, stats, testimonials, hours
   → Source stock photos: Pexels/Unsplash matching the location/subject
   → Tag EVERY invented item with [DEMO] comment

3. Create CONTENT-NEEDED.md in project root

4. Deploy demo to Vercel preview URL

5. Share URL + CONTENT-NEEDED.md with client

6. When client sends real content:
   → grep -rn "\[DEMO\]" to find every swap point
   → Replace each one, remove the tag
   → Verify grep returns 0 matches before launch
   → Re-run visual protocol after each swap batch
```

---

## Conversion Verification

Before marking a site as "live-ready":
```bash
# Must return 0 — no [DEMO] tags remaining
grep -rn "\[DEMO\]" <project>/app/ <project>/components/ <project>/lib/ | grep -v "node_modules" | wc -l
```
Non-zero output = demo content still present. Do not launch.

---

## Rationalization Shield

| Thought | Reality | Correct action |
|---|---|---|
| "The client can figure out what's placeholder" | They can't — demos look real | Tag every item, create CONTENT-NEEDED.md |
| "I'll add tags later" | Tags get missed when added retroactively | Tag as you write, not after |
| "The design is more important than placeholder content" | Both matter — a broken phone number on launch is a client disaster | Tag now, swap later |
| "The stats are close enough" | "Close enough" is not the client's real business | Tag, confirm, then remove the tag |
