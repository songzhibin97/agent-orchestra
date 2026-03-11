# MAXED Policy

Defines when a task is considered exhausted and how to handle it.

## Definition

A task is MAXED when it has accumulated consecutive FAIL evidence lines with no PASS between them, reaching the configured limit.

- Read from `.orchestra/config.json` → `governance.max_attempts`.
- Default: **3** (if config is missing or key is absent).

## Detection

Count FAIL evidence lines under the task block:

```
EVIDENCE (RUN #1): ... RESULT: FAIL
EVIDENCE (RUN #2): ... RESULT: FAIL
EVIDENCE (RUN #3): ... RESULT: FAIL
```

If the count of consecutive FAILs equals or exceeds `max_attempts` with no intervening PASS, the task is MAXED.

## Marking

Append the following line directly after the last EVIDENCE line in the task block:

```
MAXED (after 3 attempts)
```

Replace `3` with the actual attempt count.

## Behavior After MAXED

1. Skip the task — do not dispatch another worker run.
2. Record in `progress.txt`:
   ```
   [<ISO UTC>] [MAXED] [<task-id>] Skipped after <n> failed attempts
   ```
3. Trigger `openspec-researcher` skill if available, to analyze why the task keeps failing.
4. Continue with the next eligible task.

## Recovery

Human recovery procedure:

1. Add an `UNBLOCK GUIDANCE` note under the task with actionable next steps.
2. Delete the `MAXED (after n attempts)` line from `tasks.md`.
3. Optionally reset the FAIL evidence lines or leave them for audit.
4. Restart the supervisor — the task will be eligible again.

## Completion Impact

A MAXED task counts toward completion (the change can be marked `COMPLETE_WITH_GAPS`).
See [completion-policy.md](completion-policy.md) for details.
