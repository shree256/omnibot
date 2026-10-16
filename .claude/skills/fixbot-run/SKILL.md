---
name: fixbot-run
description: Entry point. Takes a Sentry issue ID and runs the full fixbot pipeline (triage, locate and pull repos, reproduce, fix and verify), then stops for human approval. Use when given a Sentry issue to fix.
---

# fixbot-run

Argument: a Sentry issue ID or short ID (for example `4521337` or `PAYMENTS-1A2`).

1. Create `runs/<sentry-id>/` and append a timestamped line to `runs/<sentry-id>/log.md`
   at the start and end of each stage.
2. Run these skills in order. Pass along what each one found.
   - `fixbot-triage`
   - `fixbot-locate-repos`
   - `fixbot-reproduce`
   - `fixbot-fix-verify`
3. If any gate fails: write `runs/<sentry-id>/summary.md` with status `STOPPED at <stage>`,
   what you found, and what a human should look at. Comment the summary on the
   Linear ticket. Stop.
4. If all gates pass: write `runs/<sentry-id>/summary.md` using the template below,
   comment it on the Linear ticket, and stop. Do not commit, push or open a PR.
   End your final message with exactly:
   `READY FOR REVIEW: <linear-id> — worktrees: <paths>`

## summary.md template

```markdown
# <linear-id>: <one-line title>

Status: READY FOR REVIEW | STOPPED at <stage>
Sentry: <issue url>   Linear: <ticket url>
Events: <count> in <period>, first seen <date>, release <release>

## Root cause
<what is wrong and why, with file:line references>

## Fix
<what changed, per repo; why this is the minimal fix>

## Verification
- Reproduction: <test or script path> — failed before, passes after
- Test suite: `<command>` — <pass/fail counts>

## Risk
<what else this could affect; anything the reviewer should check>

## Worktrees
- <repo>: worktrees/<dir> on branch <branch>
```
