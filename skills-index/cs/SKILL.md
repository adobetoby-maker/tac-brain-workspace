---
name: cs
version: 1.0.0
description: |
  Alias for /context-save. Saves working context so any future session
  can resume without losing a beat. Accepts optional title:
    /cs               → save with inferred title
    /cs nexus swap UI → save with title "nexus swap UI"
allowed-tools:
  - Bash
  - Read
  - Write
triggers:
  - cs
---

# /cs — Context Save (alias)

Invoke the `context-save` skill immediately, passing any arguments as the title.

Use the Skill tool: `skill("context-save", args)` where args is whatever the user typed after `/cs`.

Do not add commentary. Run context-save and report its output.
