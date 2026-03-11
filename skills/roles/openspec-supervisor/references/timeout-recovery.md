# Timeout and Recovery Policy

Defines how to handle worker failures that do not produce a clean BUNDLE or FAIL result.

## Failure Classification

| Exit Code | Condition | Classification |
|-----------|-----------|----------------|
| 124 | Process timed out | TIMEOUT |
| 137 | Process killed (OOM or signal) | CRASH |
| >1 | Non-zero exit, no BUNDLE line | CRASH |
| 0 | Exit 0, but no BUNDLE line in tasks.md | SILENT_FAILURE |
| 0 | Exit 0, but BUNDLE path does not exist | SILENT_FAILURE |

## Detection Steps

After the dispatcher returns:

1. Re-read `tasks.md` and locate the selected task block.
2. Check for a new `BUNDLE (RUN #n)` line matching the fresh run number.
3. If no BUNDLE line → classify based on exit code (see table above).
4. If BUNDLE line exists but path is missing → SILENT_FAILURE.
5. If BUNDLE line exists and path exists but required files are missing → SILENT_FAILURE.

## Actions on Failure

For TIMEOUT, CRASH, or SILENT_FAILURE:

1. Do NOT write an `EVIDENCE` line.
2. Write a `REVIEW GUIDANCE` note under the task:
   ```
   REVIEW GUIDANCE (RUN #n): FAILURE_TYPE: <TIMEOUT|CRASH|SILENT_FAILURE> | EXIT_CODE: <n> | NOTE: <brief description>
   ```
3. Append to `progress.txt`:
   ```
   [<ISO UTC>] [<FAILURE_TYPE>] [<task-id>] RUN #<n> | No bundle produced | EXIT_CODE: <n>
   ```
4. Count this as one attempt toward MAXED (see [maxed-policy.md](maxed-policy.md)).
5. Trigger `openspec-researcher` skill to analyze the crash cause if available.

## SILENT_FAILURE Investigation

A SILENT_FAILURE (exit 0 but no bundle) indicates the worker did not follow the implementer contract. Common causes:

- Worker implemented code but forgot to write the `BUNDLE` line.
- Worker misread the bundle path and created it at the wrong location.
- Worker interpreted task completion differently than expected.

Include these hypotheses in the REVIEW GUIDANCE note.

## Recovery

After researcher provides guidance:

1. The next dispatch will include the REVIEW GUIDANCE and researcher's Next steps in the TASK_PROMPT.
2. If the same task reaches `max_attempts` FAIL/TIMEOUT/CRASH → mark MAXED.
