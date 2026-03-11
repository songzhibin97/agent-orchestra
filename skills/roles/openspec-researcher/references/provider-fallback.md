# Provider Fallback

Use this when the preferred research providers are missing, disabled, or returning errors.

## Fallback Rules

1. Always start with local repo evidence.
2. If a configured provider is unavailable, skip it and note that it was unavailable.
3. Continue to the next provider instead of failing the whole research pass.
4. Distinguish:
   - verified by repo or primary source
   - likely based on secondary source
   - hypothesis that still needs confirmation

## Minimum Output When External Providers Fail

Return:

```md
Blocker:
Likely cause:
Evidence:
- local repo file or exact error text
Next steps:
1. local action that can be tried immediately
2. external verification still needed once providers are restored
If still failing:
```

## Notes

- Do not fabricate citations for unavailable providers.
- Do not present skipped-provider guesses as verified fact.
- If the blocker cannot be resolved without external verification, say that directly.
