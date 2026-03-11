# Completion Policy

Defines when a change is considered complete and what actions to take.

## Completion Condition

A change is complete when every task in `tasks.md` is in one of these terminal states:

| State | Marker |
|-------|--------|
| Passed | `[x]` checkbox |
| MAXED | `MAXED (after n attempts)` line |
| Skipped | `SKIP` annotation |
| Not executable | `NOT_EXECUTABLE` annotation |

All tasks must be in a terminal state — no unchecked `[ ]` tasks without a terminal marker.

## Verification Steps Before Completion

1. Count tasks: passed + maxed + skipped + not_executable = total tasks.
2. Verify `feature_list.json` consistency:
   - Every ref tag in `tasks.md` has an entry in `feature_list.json`.
   - `passes` values match the task outcomes (PASS → true, anything else → false).
   - Recompute summary counts.
3. Write a completion summary to `progress.txt`:
   ```
   [<ISO UTC>] [CHANGE_COMPLETE] <change-id> | passed=<n> maxed=<n> skipped=<n> total=<n>
   ```

## Clean Completion

All tasks passed. No MAXED or SKIP.

Mark as: `CHANGE_COMPLETE`

Optional: create a final checkpoint commit:
```
git commit -m "orchestra: CHANGE_COMPLETE <change-id>"
```

## Partial Completion

One or more tasks are MAXED or SKIPPED.

Mark as: `COMPLETE_WITH_GAPS`

Add a `NEEDS_ATTENTION` list to `progress.txt`:
```
[<ISO UTC>] [COMPLETE_WITH_GAPS] <change-id>
NEEDS_ATTENTION:
- task-1.2: MAXED after 3 attempts — needs human intervention
- task-2.1: SKIP — out of scope for this change
```

## feature_list.json Consistency

After completion:
- `passes: true` — only for refs where ALL associated tasks passed.
- `passes: false` — for refs where any task is MAXED, SKIP, or NOT_EXECUTABLE.
- Add `"partial": "<n>/<total> tasks passed"` if a ref has mixed results.

## Guardrails

- Do not mark complete if any task is unchecked without a terminal marker.
- Do not set `passes: true` for a ref unless all its tasks have PASS evidence.
- Do not suppress the NEEDS_ATTENTION list — it is required for human follow-up.
