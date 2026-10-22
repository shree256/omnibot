---
name: omnibot-reproduce
description: Create a worktree per repo, set the repo up locally, and write a failing test or script that reproduces the Sentry error.
---

# omnibot-reproduce

## 1. Create worktrees

For each repo chosen by `omnibot-locate-repos`, with `<id>` = the Linear ID in lower case and `<slug>` = a
short kebab-case description:

```bash
git -C repos/<repo> worktree add ../../worktrees/<id>-<repo> \
  -b fix/<id>-<slug> origin/<branch>
```

The branch name follows `omnibot-pr-naming`. If the branch or worktree already
exists from an earlier run, reuse it.

## 2. Set up

- Use `setup` from `repos.yaml` if present.
- Otherwise work it out from the repo: README, CONTRIBUTING, Makefile,
  `docker-compose.yml`, `package.json`, `pyproject.toml`, `requirements*.txt`,
  `go.mod`, `Gemfile`, CI workflow files (they show the exact test commands).
- Prefer Docker Compose for databases and other services.
- Use example env files (`.env.example`, `.env.sample`). Never use real
  production credentials. If the repo needs secrets that are not available, note
  it and continue only with what can run without them.
- Write the working `setup`, `run`, `test` and `test_single` commands back to
  `repos.yaml` so the next run can reuse them.

## 3. Reproduce

Prefer the smallest reproduction:

1. A unit or integration test in the repo's own test framework, placed where
   the repo keeps similar tests, that triggers the same exception from the same
   code path.
2. If a test is impossible, a script in `runs/<sentry-id>/repro.*` that calls the
   running service the way the Sentry event's request or breadcrumbs show.

Run it and save the output to `runs/<sentry-id>/repro-before.txt`.

## Gate

The reproduction fails with the same exception type and the same in-app frame
as the Sentry event. A different failure does not count. If you cannot
reproduce after a reasonable effort, stop and report what you tried.
