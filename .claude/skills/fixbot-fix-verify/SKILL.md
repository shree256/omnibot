---
name: fixbot-fix-verify
description: Make the minimal fix in the worktree, confirm the reproduction now passes, and run the full test suite.
---

# fixbot-fix-verify

## 1. Fix

- Edit only inside `worktrees/`.
- Fix the root cause, not the symptom. Swallowing the exception, adding a broad
  try/except or a bare null check that hides bad data is not a fix unless that
  really is the correct behaviour. Explain the choice in the summary.
- Follow the repo's own conventions, and any `CLAUDE.md`, `AGENTS.md` or
  `.claude/skills/` in that repo.
- Keep the reproduction test from `fixbot-reproduce` as a regression test.

## 2. Verify

1. Run the reproduction. Save output to `runs/<sentry-id>/repro-after.txt`.
   It must pass.
2. Run the repo's full `test` command. Save output to `runs/<sentry-id>/tests.txt`.
3. Run the repo's linter and type checker if it has them (see its CI config).
4. If tests fail, compare with the same tests on the untouched default branch
   (`repos/<repo>`). Failures that also happen there are pre-existing; list them
   in the summary but do not fix them.

Allow at most 3 fix attempts. After that, stop and report.

## 3. Show the change

Save `git -C worktrees/<dir> diff` to `runs/<sentry-id>/fix.diff`.

## Gate

The reproduction passes, and no test fails that passed on the default branch.
