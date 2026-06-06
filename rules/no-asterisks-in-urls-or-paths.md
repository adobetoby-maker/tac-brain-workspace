# Rule: Never Put Asterisks Around URLs or File Paths

---

## Iron Law — Observable Check Before Every Output

Before outputting any text that contains `http`, `/Users/`, or a shell command:

Scan your draft for these patterns:
- `**http` — bold URL → STOP → remove the asterisks
- `**\`` — bold code span → STOP → remove outer asterisks
- `**/` — bold path → STOP → use plain text or backtick
- `*http` — italic URL → STOP → same fix

If any match found → rewrite before outputting.

This check fires even when you want to emphasize something. Emphasis is achieved with words, not with asterisks on the URL.

---

## The Rule

| What | Correct | Broken |
|---|---|---|
| URL | `https://example.com` | `**https://example.com**` |
| File path | `/Users/drive/project` or `` `/Users/drive/project` `` | `**/Users/drive/project**` |
| Shell command | `` `npm run dev` `` | `` `**npm run dev**` `` |
| Package name | `` `@opennextjs/cloudflare` `` | `**@opennextjs/cloudflare**` |

---

## Why This Breaks Things

Asterisks travel with the string when copied. A user pasting `**https://climb-france.vercel.app**` into a browser gets a navigation failure. No error shown. Silent. Same for file paths pasted into a terminal.

The formatting adds zero value and actively causes failures.

---

## What to Do Instead

Emphasize context with words:

WRONG: "Deploy at **https://velocitymade.vercel.app**"
RIGHT: "Live at https://velocitymade.vercel.app"

WRONG: "Edit **`/Users/drive/project/app/page.tsx`**"
RIGHT: "Edit `/Users/drive/project/app/page.tsx`"

The destination is clear without decoration. Don't decorate it.
