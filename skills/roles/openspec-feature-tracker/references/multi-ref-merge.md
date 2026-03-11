# Multi-Ref Merge Rules

Defines how to handle `feature_list.json` when multiple tasks reference the same ref tag.

## Core Rule

One ref → one feature entry, always. Never create duplicate entries for the same ref.

## When Multiple Tasks Share a Ref

Example: tasks 1.2, 1.3, and 2.1 all reference `[#R1]`.

### Generation

Create exactly one entry for `R1`. The feature description should capture the full user-observable outcome, not a single task's scope.

```json
{
  "ref": "R1",
  "feature": "Users can export data in CSV format with all fields included.",
  "passes": false,
  "tasks": ["1.2", "1.3", "2.1"]
}
```

The `tasks` array is optional but recommended for traceability.

### Pass Condition

`passes: true` requires **all** associated tasks to have PASS evidence.

- If task 1.2 passes but 1.3 fails → `passes: false`, add `"partial": "1/3 tasks passed"`.
- Only when all tasks pass → `passes: true`, remove `partial`.

### Partial Pass Format

```json
{
  "ref": "R1",
  "feature": "Users can export data in CSV format with all fields included.",
  "passes": false,
  "partial": "1/3 tasks passed",
  "tasks": ["1.2", "1.3", "2.1"]
}
```

## Repair Scenarios

### Tasks Added to an Existing Ref

If a new task is added that references an existing ref:

- Update the `tasks` array.
- If `passes` was true, reset to `false` and add `"partial"` — new evidence is required.
- Update the feature description only if the new task changes the user-observable outcome.

### Tasks Removed from an Existing Ref

If a task is removed that referenced a ref:

- Update the `tasks` array.
- Keep `passes` state based on remaining tasks.
- If the removed task was the only failing one, and all remaining tasks have PASS → set `passes: true`.

### Ref Removed Entirely

If all tasks for a ref are removed from `tasks.md`:

- Remove the feature entry from `feature_list.json`.
- Confirm the removal by checking that the ref tag no longer appears anywhere in `tasks.md`.

## Summary Recomputation

After any change, recompute the top-level summary:

```json
{
  "summary": {
    "total": <n>,
    "passed": <n>,
    "failed": <n>,
    "partial": <n>
  }
}
```
