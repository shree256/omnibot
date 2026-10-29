---
name: omnibot-pr-naming
description: Naming rules for every pull request, branch and commit message created in any repo under this folder (repos/ and worktrees/). Use before creating or renaming a PR, a branch or a commit, including from omnibot-open-pr. Covers the conventional-commit type (feat, fix, chore, ...), scope and Linear ticket ID.
---

# omnibot-pr-naming

Apply these rules every time you create or retitle a PR, create a branch, or
write a commit message in a repo under this folder. They do not grant approval:
the hard rules in `CLAUDE.md` about commit, push and PR approval still apply.

## PR title

```
<type>(<scope>): <summary> (<LINEAR-ID>)
```

Example: `fix(contacts): stop organization admin search crashing on FK field (HWC-912)`

- **type**: one of these, in lowercase:

  | type       | use for                                                     |
  |------------|-------------------------------------------------------------|
  | `feat`     | new behaviour or a new endpoint, model or task              |
  | `fix`      | a bug fix, including every Sentry fix from the pipeline     |
  | `chore`    | dependencies, build, config or tooling; no behaviour change |
  | `refactor` | a code change with no behaviour change                      |
  | `perf`     | a performance improvement                                   |
  | `test`     | tests only                                                  |
  | `docs`     | documentation only                                          |
  | `ci`       | GitHub Actions and other CI/CD changes                      |
  | `revert`   | reverting an earlier change                                 |

  There is no `bug` or `hotfix` type. A bug fix is always `fix`.
- **scope**: the main app, module or area changed, in lowercase. For emr_api
  this is the Django app (`patients`, `communication`, `claims`, ...) or an
  area such as `deps`, `deployment` or `sentry`. Omit `(<scope>)` only when
  the change has no single main area.
- **summary**: imperative mood ("add", "stop", "guard"), starts in lowercase,
  no full stop at the end. It says what the change does, not which ticket it is.
  Keep the whole title at 72 characters or fewer.
- **Linear ID**: the ticket ID in uppercase, in parentheses at the end. If the
  work has no Linear ticket, find or create one with the Linear MCP first. If
  the human says there is no ticket, leave the parentheses out.

## Branch name

```
<type>/<linear-id>-<short-slug>
```

Example: `fix/hwc-912-org-admin-search-fk`. All lowercase, words joined with
hyphens. If the branch already exists, keep its name; do not rename it.

## Commit messages

Use the PR title format for the subject line. Put the reason for the change
in the body. For a Sentry fix, write `Fixes Sentry issue <sentry-id>.` and the
root cause.

## PR body

End the body with these lines, in this order:

```
Sentry: <url>        # only for Sentry fixes
Linear: <url>
Fixes <LINEAR-ID>    # Linear closes the ticket on merge; use "Refs <LINEAR-ID>" if it must stay open
```

The Linear ID in the title, the branch name and the body lets Linear's GitHub
integration link the PR to the ticket.

## Check before you create

1. The title matches `^(feat|fix|chore|refactor|perf|test|docs|ci|revert)(\([a-z0-9_-]+\))?: [a-z].* \([A-Z]+-[0-9]+\)$`,
   or the same pattern without the Linear ID when the human said there is no ticket.
2. The type matches the diff: a bug fix is `fix`, not `feat`.
3. The Linear ID is the same in the title, the branch and the body.
