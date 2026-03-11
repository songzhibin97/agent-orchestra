# Provider Ordering

Use the highest-authority source that can answer the blocker.

## Default Order

1. Local repo evidence
   - Existing code, tests, configs, issue notes, and task artifacts.
2. `context7`
   - Use for current official documentation and API behavior.
3. `github`
   - Use for upstream issues, regressions, release notes, and implementation examples.
4. Configured web search provider
   - Use for recent breakages or discussion when official sources are incomplete.
5. Configured web reader
   - Use to fetch and verify the candidate pages found above.

## Availability Handling

- If a provider is unavailable, skip it and continue in order.
- Record unavailable providers in the final unblock note when they materially limit confidence.
- Prefer a local-only answer over a fabricated external answer.

## Stop Conditions

- Stop when you have one credible cause and one concrete next step.
- Stop early if the blocker is clearly local and the repo already contains the answer.
- Do not keep browsing once additional sources only repeat the same conclusion.
