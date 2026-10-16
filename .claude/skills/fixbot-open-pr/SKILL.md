---
name: fixbot-open-pr
description: After explicit human approval only, commit the fix in each worktree, push the branch, open a draft PR through the GitHub MCP, and link it to the Linear ticket.
disable-model-invocation: true
---

# fixbot-open-pr

Run this only when the human has explicitly approved opening the PR for this
issue in the current session. If you are not sure, ask.

For each worktree in `runs/<sentry-id>/summary.md`:

1. Show `git status` and `git diff --stat`. Commit only files that belong to the fix
   and its regression test:
   ```bash
   git -C worktrees/<dir> add <files>
   git -C worktrees/<dir> commit -m "<LINEAR-ID>: <short description>" \
     -m "Fixes Sentry issue <sentry-id>. <one-paragraph root cause>"
   ```
2. Push the branch: `git -C worktrees/<dir> push -u origin <branch>`.
3. Open a **draft** PR with the GitHub MCP `create_pull_request`:
   - base: the default branch; head: the fix branch
   - title: `<LINEAR-ID>: <short description>` (the Linear ID in the title and
     branch lets Linear's GitHub integration link the PR automatically)
   - body: the sections Root cause, Fix, Verification and Risk from
     `summary.md`, then the links:
     `Sentry: <url>` and `Linear: <url>`, and the line `Fixes <LINEAR-ID>`.
   - If the fix spans repos, list the other PRs in each body.
4. Linear MCP: add the PR URL to the ticket as an attachment or link, and post a
   short comment with the PR link(s).
5. Append the PR URLs to `runs/<sentry-id>/summary.md` and change its status to
   `PR OPENED`.

Never merge, and never mark a PR ready for review. The human does that.
