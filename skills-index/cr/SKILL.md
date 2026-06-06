---
name: cr
version: 1.0.0
description: |
  Alias for /context-restore. Restores saved working context so you can
  resume exactly where you left off.
    /cr               → restore most recent save for current branch
    /cr nexus         → restore most recent save matching "nexus"
    /cr list          → list all saved contexts
allowed-tools:
  - Bash
  - Read
triggers:
  - cr
---

# /cr — Context Restore (alias)

Invoke the `context-restore` skill immediately, passing any arguments through.

Use the Skill tool: `skill("context-restore", args)` where args is whatever the user typed after `/cr`.

Do not add commentary. Run context-restore and report its output.
