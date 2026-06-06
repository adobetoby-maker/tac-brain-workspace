# Rule: Image Sourcing Protocol

---

## Iron Laws

**Iron Law 1 — Ownership Signal:**
Observable check: Does the user's message contain "my photos", "our photos", "photos of mine", "pictures I took", or name a specific person/animal/place they own?
Condition: YES → search exhaustively (local Photos, ~/Pictures, ~/Desktop, ~/Downloads, AirDrop) → if not found → DO NOT STOP → exhaust all 6 options in Decision Flow → tell user what was used.
This does NOT override: "just use placeholders" said explicitly by the user.

**Iron Law 2 — Search Before Sourcing:**
Observable check before downloading any stock photo:
```bash
ls <project>/public/images/           # already in project?
find ~/Pictures -type f \( -iname "*.jpg" -o -iname "*.heic" \) | wc -l   # on this Mac?
```
If local images exist and subject matches → use them.
If not found locally → proceed to step 3 of Decision Flow without stopping.

**Iron Law 3 — Never Silent Substitution:**
Observable check: Am I about to curl/download a stock image for a subject the user claimed to own?
Condition: YES → tell user in conversation what was searched and what is being used → proceed.
This does NOT override: user explicitly says "use stock" or "use placeholders".

---

## Decision Flow

```
User asks to add photos
  ↓
1. Did user say "my photos" / "our photos" / name a specific subject?
   YES → search ~/Pictures, project public/, AirDrop folder, ~/Desktop, ~/Downloads
       → found? → use them
       → not found? → DO NOT STOP → proceed through options 2-5 below
         → tell user "I searched and didn't find them, so I'm using X as placeholder"
         → place placeholder, leave clear swap path in code
   NO  → proceed to step 2

2. Does the project already have images?
   ls <project>/public/images/ → check what's there
   → relevant images exist? → use them first
   → missing? → proceed to step 3

3. Is this a real-world location / specific business / specific people?
   YES → look for official sources first (government tourism sites, official venue photos)
       → then free stock (Pexels, Unsplash) — curl download directly into public/images/
       → download, note source, proceed
   NO  → free stock (Pexels/Unsplash) directly → curl download → proceed

4. If stock photos don't match well enough → AI generation (ComfyUI skill / DALL-E)

5. If client needs real professional photos → find local photographer:
   WebSearch: "horse photographer [city] Idaho" or "[sport] photographer [location]"
   Include 2-3 options with contact info in a note to user

6. After sourcing: add comment in code: "// TODO: replace with real photo from [source]"
   Keep going — don't stop for approval

IRON LAW: Never stop mid-task because a photo is missing. Exhaust all 6 options.
Always end with a working page — even if it uses a placeholder.
```

---

## For Climbing Sites Specifically

Climbing site photos should follow this order:
1. Check `<project>/public/images/` — any real route/crag photos already there?
2. Check official climbing area websites (Mountain Project, UKC, local climbing federations)
3. Official tourism board photos (Pexels/Unsplash for the region — search location name)
4. Never use random stock "climbing" photos that don't match the actual location

Each climbing site needs:
- Hero: the actual climbing area / crag / landscape — NOT generic "person climbing"
- Route photos: specific named routes if possible
- Location/area shots: canyon, coast, mountain backdrop

---

## Rationalization Shield

| Thought | Reality | Correct action |
|---|---|---|
| "I couldn't find them so I'll just use Pexels" | Silent substitution without telling the user hides the problem | Tell user what was searched, what is being used, proceed |
| "Stock photos look fine" | They do. But they're not the client's actual business | Use them as placeholder, say so, keep going |
| "The user wants me to be autonomous" | Correct — autonomous means exhaust all 6 options, then report what was used | Do not stop. Do not ask. Tell and proceed. |
| "I'll add a TODO comment" | A comment in the code doesn't tell the user their photos weren't used | Say it in the conversation |

---

## When Real Photos Arrive (AirDrop / shared folder)

When user says "I've AirDropped the photos":
```bash
ls ~/Desktop/          # AirDrop lands on Desktop
ls ~/Downloads/        # Or Downloads
ls ~/AirDrop/ 2>/dev/null  # Sometimes
```
Copy matching photos to `<project>/public/images/` with correct names.
Run build to confirm no errors.
Take screenshot to confirm image appears correctly.
