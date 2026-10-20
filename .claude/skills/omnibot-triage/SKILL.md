---
name: omnibot-triage
description: Fetch a Sentry issue through the Sentry MCP, decide whether it is fixable by a code change, and find or create the matching Linear ticket.
---

# omnibot-triage

## Steps

1. Use the Sentry MCP to get the issue: title, culprit, exception type and message,
   full stack trace (in-app frames first), breadcrumbs, tags, release, environment,
   event count, first and last seen, and suspect commits if available.
2. Save the raw facts to `runs/<sentry-id>/sentry.md`.
3. Classify the issue:
   - `code-bug` — in-app frames point at our code and the cause is plausibly in it.
   - `not-code` — infrastructure, network, third-party outage, OOM, deploy timing,
     bad client input with correct handling, or a browser extension.
   - `unclear` — not enough data.
4. Linear (Linear MCP):
   - Search for an existing ticket that mentions the Sentry issue ID or URL.
   - If none exists, create one: title `[Sentry] <error title>`, description with
     the Sentry link, classification and top stack frames.
   - Record the ticket identifier (for example `ENG-123`). Every later stage uses it.

## Gate

Continue only if the classification is `code-bug`. Otherwise comment the
classification and reasoning on the Linear ticket and stop.
