# omnibot helpers. Run `make` or `make help` to list targets.
SHELL := /bin/bash
.DEFAULT_GOAL := help
.PHONY: help repos worktrees

help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{ printf "  make %-10s %s\n", $$1, $$2 }'

repos: ## List repos from repos.yaml with branch, sync state, local changes and last commit
	@names=$$(awk '/^[[:space:]]*-[[:space:]]+name:/ { sub(/^[^:]*:[[:space:]]*/, ""); sub(/[[:space:]]+#.*$$/, ""); gsub(/["\047]/, ""); print }' repos.yaml); \
	[ -n "$$names" ] || { echo "no repos listed in repos.yaml"; exit 0; }; \
	printf '%-20s %-24s %-14s %-9s %s\n' REPO BRANCH VS-REMOTE CHANGES LAST-COMMIT; \
	for n in $$names; do \
	  d="repos/$$n"; \
	  if [ ! -d "$$d/.git" ]; then printf '%-20s %s\n' "$$n" "not cloned (run ./omnibot.sh sync)"; continue; fi; \
	  br=$$(git -C "$$d" rev-parse --abbrev-ref HEAD); \
	  ab=$$(git -C "$$d" rev-list --left-right --count "HEAD...@{u}" 2>/dev/null | awk '{ print ($$1||$$2) ? "+"$$1"/-"$$2 : "up to date" }'); \
	  ch=$$(git -C "$$d" status --porcelain | wc -l | tr -d ' '); \
	  printf '%-20s %-24s %-14s %-9s %s\n' "$$n" "$$br" "$${ab:-no upstream}" "$$ch" "$$(git -C "$$d" log -1 --format='%h %cr %s' | cut -c1-70)"; \
	done

worktrees: ## List fix worktrees under worktrees/ with branch, local changes and source repo
	@found=0; \
	for d in worktrees/*/; do \
	  [ -e "$$d/.git" ] || continue; \
	  [ $$found = 1 ] || printf '%-24s %-22s %-9s %s\n' WORKTREE REPO CHANGES BRANCH; found=1; \
	  src=$$(git -C "$$d" rev-parse --path-format=absolute --git-common-dir | sed -E 's#/\.git$$##; s#.*/repos/#repos/#'); \
	  printf '%-24s %-22s %-9s %s\n' "$$(basename "$$d")" "$$src" "$$(git -C "$$d" status --porcelain | wc -l | tr -d ' ')" "$$(git -C "$$d" rev-parse --abbrev-ref HEAD)"; \
	done; \
	[ $$found = 1 ] || echo "no worktrees in worktrees/"
