# Feature List Schema

Use a minimal durable structure. Keep the file easy to diff and easy to update.

## Expected Properties

- `ref`: stable ref id, for example `R1`
- `feature`: short end-to-end description of what the ref represents
- `passes`: boolean validation state, default `false`
- Optional pass-state metadata only if the workflow already uses it

## Example

```json
[
  {
    "ref": "R1",
    "feature": "Users can switch models automatically based on day or night rules.",
    "passes": false
  },
  {
    "ref": "R2",
    "feature": "The active rule is visible in settings and survives restart.",
    "passes": false
  }
]
```

## Mapping Rules

- A single task may mention one stable ref.
- Multiple tasks may contribute evidence toward the same ref if the workflow allows it.
- Keep the feature text stable so pass-state changes do not require rewriting the definition.
