# Evidence Threshold

Defines when to stop searching and when to keep looking.

## Stop Conditions (any one is sufficient)

Stop searching and produce the unblock note when:

1. **Official documentation directly answers the question** — the exact API, config, or behavior is documented in the primary source.
2. **Two independent sources agree** — two sources at the same or different authority levels give the same concrete answer.
3. **Reproducible diagnosis** — you can point to an exact error string, file path, or version number that explains the failure, even without an external source.
4. **Local self-answer** — the repo itself (code, tests, configs, changelogs, task artifacts) contains the answer without needing external lookups.

## Continue Conditions (all must be resolved)

Keep searching while:

- No direct match has been found for the exact error string or behavior.
- Results from queried providers are contradictory (→ apply [conflict-resolution.md](conflict-resolution.md)).
- A higher-priority provider (from [provider-ordering.md](provider-ordering.md)) has not been checked yet.
- Fewer than 3 providers/sources have been consulted and confidence is LOW.

## Hard Limit

Maximum providers per research pass is read from `.orchestra/config.json` → `governance.max_research_sources` (default: **5**).

After reaching the limit:
- Return the best available answer, even if confidence is MEDIUM or LOW.
- Label low-confidence conclusions as HYPOTHESIS.
- Recommend specific local experiments the implementer can run to confirm.

## Confidence Levels

| Level | Criteria |
|-------|----------|
| HIGH | Direct official documentation or 2+ independent sources agree |
| MEDIUM | One credible secondary source, or local repo evidence suggests the fix |
| LOW | Plausible hypothesis, no direct confirmation available |

Always report the confidence level in the unblock note.
