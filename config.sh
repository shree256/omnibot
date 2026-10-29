# omnibot settings. No secrets here: Sentry and Linear are signed in through
# /mcp, GitHub uses your gh login, and git uses your SSH key. This file travels with the folder.

# Sentry organization slug and the search for issues worth fixing
# (Sentry search syntax).
SENTRY_ORG="houseworksinc"
SENTRY_QUERY="is:unresolved is:unassigned environment:production"

# Model for the cheap "anything new?" check. The fixing runs use your default model.
POLL_MODEL="haiku"

# Poll interval in seconds (applied by install.sh; re-run it after changing).
POLL_INTERVAL=600

# Max new issues started per poll, and max agent turns per issue.
MAX_ISSUES_PER_POLL=2
MAX_TURNS=80
