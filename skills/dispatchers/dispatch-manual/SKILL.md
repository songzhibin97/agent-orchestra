---
name: dispatch-manual
description: Hand off a task to a human for manual implementation. Use when no automated dispatcher is available, the task requires human judgment, or the supervisor wants explicit human confirmation before proceeding.
---

# Manual Dispatcher

## Applicable Scenarios

Use when:
- No automated dispatcher (Codex, subagent, CLI, MCP) is available.
- The task requires domain expertise, physical access, or human judgment.
- The supervisor is running in an environment without code execution capability.
- Explicit human sign-off is required before implementation.

## Dispatch Steps

1. Derive a unique run ID: `<change-id>-run-<n>-<YYYYMMDDThhmmssZ>`.
2. Create the handoff directory:
   ```
   .orchestra/handoff/<run-id>/
   ```
3. Write `task-instruction.md` to the handoff directory (see format below).
4. Write `expected-output.md` to the handoff directory (see format below).
5. Output the following message to the user:

   ```
   ── Manual Task Handoff ──────────────────────────────────────
   Task is ready for human implementation.

   Instructions: .orchestra/handoff/<run-id>/task-instruction.md
   Expected output: .orchestra/handoff/<run-id>/expected-output.md

   When complete, create the file:
     .orchestra/handoff/<run-id>/DONE

   File contents: exit_code=0 (for success) or exit_code=1 (for failure)
   ─────────────────────────────────────────────────────────────
   ```

6. Wait for `.orchestra/handoff/<run-id>/DONE` to appear.
7. Read `exit_code` from the DONE file.
8. Return the exit code to the supervisor.

## task-instruction.md Format

```markdown
# Task Instruction

## Change ID
<change-id>

## Task ID
<task-id>

## Ref Tag
[#<ref-id>]

## Run Number
#<n>

## Task Description
<full task text from tasks.md>

## Acceptance Criteria
<ACCEPT: block from tasks.md>

## Test Plan
<TEST: block from tasks.md>

## Bundle Requirements

Create the validation bundle at:
  auto_test_orchestra/<change-id>/run-<RUNC>__task-<TASKID>__ref-<REF>__<timestamp>/

Required files:
- task.md
- run.sh (exits 0 on pass, non-zero on fail)
- run.bat
- logs/worker_startup.txt

## BUNDLE Line

After creating the bundle, write exactly one line under the task in tasks.md:
  BUNDLE (RUN #<n>): MODEL=human | SCOPE: <CLI|GUI|MIXED> | VALIDATION_BUNDLE: <path> | HOW_TO_RUN: run.sh/run.bat

## Notes from Previous Attempts
<REVIEW GUIDANCE and UNBLOCK GUIDANCE if this is a retry>
```

## expected-output.md Format

```markdown
# Expected Output

## In tasks.md
One new line under task <task-id>:
  BUNDLE (RUN #<n>): MODEL=human | SCOPE: ... | VALIDATION_BUNDLE: <path> | ...

## Bundle Directory
All required files present at: <bundle-path>

## DONE File
After completing the above:
  .orchestra/handoff/<run-id>/DONE
  Contents: exit_code=0
```

## Notes

- There is no timeout for manual dispatch — wait indefinitely.
- The human may leave notes in `.orchestra/handoff/<run-id>/notes.md`.
- The human must still satisfy the bundle-rules (see `openspec-implementer` references).
- If the human cannot complete the task, they should create DONE with `exit_code=1` and explain in notes.md.
