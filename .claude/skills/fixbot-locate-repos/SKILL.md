---
name: fixbot-locate-repos
description: Pick which of the repos listed in repos.yaml an error involves. The repos are already pulled into repos/ by fixbot.sh sync; never clone or add repos.
---

# fixbot-locate-repos

`repos.yaml` is the human-maintained list of repos fixbot may work on.
`./fixbot.sh sync` has already cloned or updated each one into `repos/<name>/`.

## 1. Pick repos from the list

Consider only repos in `repos.yaml`. Use these sources in order and stop when
you have confident matches:

1. Sentry project slug against each entry's `sentry_projects`.
2. In-app stack-frame paths against `path_hints`.
3. Sentry code mappings and suspect commits (they name the repo).
4. Search the pulled code: `grep -rn` in `repos/*/` for distinctive symbols from the
   in-app frames (function, class and file names, the error message string).
   GitHub MCP `search_code` is a fallback, limited to the listed repos.
5. Cross-service errors (for example a 5xx from an internal API): also include the
   listed repo that serves the failing endpoint. Use `depends_on` to follow links.

Include a dependency repo only if a frame actually points into it.

## 2. Check the clone is present and current

- If `repos/<name>/` is missing, the sync failed. Stop and report it. Do not clone.
- You may run `git -C repos/<name> fetch --prune origin` if you need newer refs.
- Never edit files or switch branches in `repos/`.

## 3. Check the code matches the release

If Sentry reports a release that is a commit SHA or a tag, confirm the failing
code still exists on the default branch (`branch` in `repos.yaml`, or
`git -C repos/<name> symbolic-ref refs/remotes/origin/HEAD`). If it was already
fixed, comment that on the Linear ticket (with the fixing commit) and stop.

## 4. Record what you learned

In the matching `repos.yaml` entries you may add `sentry_projects` and
`path_hints` values you confirmed. Never add or remove entries, and never change
`name`, `repo` or `branch`.

## Gate

Continue only if the failing code was found in at least one listed repo.

If the stack trace points into a repo that is not listed, stop. Write in
`summary.md` and on the Linear ticket which repo (owner/name) should be added to
`repos.yaml`, and why.
