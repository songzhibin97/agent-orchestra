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
| any | BUNDLE exists, but path/name/required files violate bundle rules | INVALID_BUNDLE |
| 0 | Validation passed, but worktree contains extra caches/build outputs/unrelated files | DIRTY_WORKTREE |

## Detection Steps

After the dispatcher returns:

1. Re-read `tasks.md` and locate the selected task block.
2. Check for a new `BUNDLE (RUN #n)` line matching the fresh run number.
3. If no BUNDLE line → classify based on exit code (see table above).
4. If BUNDLE line exists but path is missing → SILENT_FAILURE.
5. If BUNDLE line exists and path exists but required files are missing → INVALID_BUNDLE.
6. If the bundle directory name does not match `.orchestra/config.json.bundle.run_folder_pattern` → INVALID_BUNDLE.
7. After validation succeeds, run `git status --porcelain`. If extra caches, build outputs, local binaries, or unrelated source files remain → DIRTY_WORKTREE.

## Actions on Failure

For TIMEOUT, CRASH, SILENT_FAILURE, INVALID_BUNDLE, or DIRTY_WORKTREE:

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

## INVALID_BUNDLE Investigation

An INVALID_BUNDLE indicates the worker produced a bundle reference that cannot be accepted as evidence. Common causes:

- `VALIDATION_BUNDLE` points at the wrong directory
- the directory name does not match the configured run-folder pattern
- required files are missing or written under unexpected names

Record the exact defect in REVIEW GUIDANCE and require a fresh run folder on retry.

## DIRTY_WORKTREE Investigation

A DIRTY_WORKTREE indicates validation may have succeeded, but the task cannot be committed safely. Common causes:

- validation scripts wrote caches or build outputs into the repo
- unrelated source files were created outside the current task scope
- local binaries or temporary files were left in tracked directories

Record the offending paths in REVIEW GUIDANCE and require cleanup or task-scope correction before retry.

## Recovery

After researcher provides guidance:

1. The next dispatch will include the REVIEW GUIDANCE and researcher's Next steps in the TASK_PROMPT.
2. If the same task reaches `max_attempts` FAIL/TIMEOUT/CRASH → mark MAXED.
