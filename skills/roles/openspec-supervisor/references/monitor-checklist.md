# Monitor Checklist

## Before Dispatch

- Read `tasks.md`, `progress.txt`, and `feature_list.json`.
- Derive the next global run number.
- Identify the first eligible unchecked task.
- Determine the per-task attempt number.

## Dispatch Rules

- Spawn one worker for one task only.
- Require the worker to use Codex CLI for implementation.
- Reject manual editing performed outside the worker contract.

## After Worker Returns

- Confirm there is exactly one matching `BUNDLE (RUN #n)` line.
- Confirm the referenced run folder exists.
- Confirm required files exist before validation.

## After Validation

- Write one `EVIDENCE (RUN #n)` line under the task.
- If PASS, toggle the checkbox, update durable bookkeeping, and create one checkpoint commit.
- If FAIL, write review guidance and preserve the unchecked state.
