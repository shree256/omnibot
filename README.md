# omnibot

Local, portable pipeline: Sentry error → Claude picks the affected repos from your list →
reproduces → fixes → runs tests → **you review** → draft PR linked to Linear.

Everything lives in this folder. Copy it anywhere.

## Setup on a new machine

No secrets live in this folder. Sentry and Linear sign in through MCP, GitHub
uses your `gh` login, and git uses your SSH key.

1. Install `claude`, `git`, `jq`, `gh` (plus Docker if your repos need it).
2. Make sure `ssh -T git@github.com` greets you (git clones and pushes over SSH).
3. GitHub: run `gh auth login`. The GitHub MCP comes from the
   `github@claude-plugins-official` plugin (enabled in `.claude/settings.json`),
   which reads `GITHUB_PERSONAL_ACCESS_TOKEN`. Add this to `~/.zshrc`:
   `export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token)"`.
   `omnibot.sh` sets it from `gh` on its own, so launchd runs work without it.
4. Sign in to the other MCP servers once: open a new terminal, run `claude` in
   this folder, then `/mcp`, authenticate `sentry` and `linear`, and check that
   `github` shows as connected.
5. Edit `config.sh` (Sentry org, search, poll interval).
6. List your repos in `repos.yaml`, then `./omnibot.sh sync` to pull them into `repos/`.
7. Try one issue by hand: `./omnibot.sh run <sentry-issue-id>`
8. Turn on polling: `./install.sh` (remove with `./install.sh --uninstall`).

## How polling works

Every `POLL_INTERVAL` seconds, launchd runs `./omnibot.sh poll`. It asks Claude
(`POLL_MODEL`, Sentry MCP only) for issues matching `SENTRY_QUERY`, skips IDs in
`state/seen.txt`, syncs the repos, and runs the pipeline for up to
`MAX_ISSUES_PER_POLL` new issues. If the Sentry sign-in expires, you get a
notification; run `claude` here and `/mcp` to sign in again.

## Daily use

| Command | What it does |
|---|---|
| `./omnibot.sh status` | List runs and where each one stopped |
| `./omnibot.sh review <id>` | Show the summary and resume that Claude session. Look at the diff in `worktrees/`, ask for changes, then type `/omnibot-open-pr` to approve. Claude still asks before each commit, push and PR. |
| `./omnibot.sh run <id>` | Sync repos, then run one issue now |
| `./omnibot.sh sync` | Clone or update every repo in `repos.yaml` into `repos/` (also runs automatically before each pipeline run) |

## How it decides what is allowed

- Unattended runs use `.claude/headless.settings.json`: commit, push and PR
  creation are blocked.
- Your review session uses `.claude/settings.json`: those actions ask you first.
- Merge and file deletion through the GitHub MCP are always blocked.

## Adding skills

Add `.claude/skills/<name>/SKILL.md`, then mention the skill in `CLAUDE.md` or in
the stage skill that should use it. Skills inside a target repo's own
`.claude/skills/` also apply when Claude works in that repo's worktree.

## Folders

- `repos/` clones of the repos listed in `repos.yaml` · `worktrees/` one per fix
- `runs/<sentry-id>/` summary, logs, diff, test output · `state/` seen IDs, poll logs
- `config.sh` settings (no secrets)
- `repos.yaml` your list of repos; Claude only fills in optional fields

Clean up a merged fix: `git -C repos/<repo> worktree remove ../../worktrees/<dir>`.
