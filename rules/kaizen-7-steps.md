# Rule: The 7-Step Kaizen Process

Apply this process whenever improving code quality, fixing recurring bugs, or eliminating workflow friction.

---

## The 7 Steps

### Step 1 — Identify a Problem or Opportunity

Spot a specific inefficiency, defect, or pain point — not a vague feeling.

Sources: employee/team feedback, support tickets, metrics trending wrong, recurring bugs, slow builds, repeated questions.

**Output:** One clearly stated problem with a measurable baseline.

### Step 2 — Map and Analyze the Current Process

Document the workflow as it actually works, not how it's supposed to.

- Draw every step, handoff, and wait time
- Identify the 7 wastes: overproduction, waiting, transport, over-processing, inventory, motion, defects
- Time each step — where does it stall?

**Output:** Visual or written map of current state with bottlenecks named.

### Step 3 — Determine the Root Cause

Don't treat symptoms. Find the actual cause using 5 Whys:

```
Problem: Build fails in CI unexpectedly
Why 1: Type error on deploy
Why 2: Dev and CI use different TypeScript versions
Why 3: No version pinned in package.json
Why 4: No policy requiring exact versions for devDependencies
Why 5: Team assumed "latest" was fine
Root cause: Missing version governance policy
```

**Output:** Documented root cause that, if fixed, eliminates the problem — not just the symptom.

### Step 4 — Develop an Optimal Solution

Brainstorm with the people closest to the problem.

- Generate 5+ ideas before evaluating any
- Prefer simple, reversible changes over complex ones
- Confirm: does this address the root cause, or a symptom?

**Output:** Chosen solution with rationale and expected improvement delta.

### Step 5 — Implement the Solution

Test small before rolling out broadly.

1. Pilot on one module, one environment, one sprint
2. Measure against baseline from Step 1
3. Confirm improvement → roll out fully

In code: branch the change, run CI, deploy to staging. Don't merge to main until pilot confirms the fix.

### Step 6 — Study the Results

Measure with data — not intuition.

- KPIs before vs. after (error rate, time, cost, satisfaction)
- Did the root cause from Step 3 actually get resolved?
- Any unintended side effects?

If the fix didn't move the metric: return to Step 3 with updated information. That is the method working, not failing.

**Output:** Written results with hard data, including what did and didn't improve.

### Step 7 — Standardize and Sustain

Lock in the gain so it doesn't regress.

- Formalize the new process (CLAUDE.md, SKILL.md, team wiki)
- Update onboarding so new team members start with the improvement already in place
- Set up a monitoring signal that catches regression early (alert, metric, periodic review)
- Celebrate the win — makes the next kaizen cycle easier to initiate

**Output:** Updated standard, trained team, regression monitor in place.

---

## Loop Back to Step 1

The 7-step process is a cycle. Every improvement reveals the next opportunity.

**In code context:**
- Step 1 = the failing test, the recurring bug, the slow deploy
- Step 3 = git blame + 5 Whys, not just fixing the symptom
- Step 5 = feature branch + staging, not direct commit to main
- Step 7 = CLAUDE.md failure pattern entry + CI check added
