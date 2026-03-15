---
name: openspec-supervisor
description: Supervise one OpenSpec task at a time through any configured dispatcher while preserving strict role boundaries and auditable evidence. Use when a change is tracked in an OpenSpec tasks.md and a worker must implement exactly one eligible task, produce a validation bundle, and leave final validation and bookkeeping to the supervisor.
---

# OpenSpec Supervisor

Run the workflow as a strict supervisor, not as a coder.

## Core Responsibilities

1. Select the first eligible unchecked task in `tasks.md`.
2. Dispatch exactly one worker run **via the user-specified dispatcher skill**.
3. Verify the worker produced only implementation plus bundle assets.
4. Run validation yourself (or delegate to verifier skill).
5. Write evidence and bookkeeping only after verified results.

## Task Selection

Pick the first unchecked task that is:

- not marked `NOT_EXECUTABLE` or `SKIP`
- not already `MAXED`
- not blocked by earlier unmet prerequisites unless independence is explicit

## Dispatch Protocol

1. Confirm the dispatcher the user specified (e.g., `dispatch-codex`, `dispatch-subagent`, etc.).
2. Read the corresponding dispatcher skill's `SKILL.md`.
3. Build the `TASK_PROMPT`:
   a. Base: task description + implementer skill's worker-contract + bundle-rules.
   b. If retry: append prior `REVIEW GUIDANCE` and `UNBLOCK GUIDANCE` content.
   c. If researcher output exists: append `Next steps` from `unblock-note.md`.
4. Follow the dispatcher skill's **Dispatch Steps** to invoke the worker.
5. Check worker output: does `tasks.md` have a new `BUNDLE (RUN #n)` line?
   - No BUNDLE → treat as `SILENT_FAILURE` (see [timeout-recovery.md](references/timeout-recovery.md)).

## Validation

Read `validation.dispatcher` from `.orchestra/config.json`.

### Local validation (default — `validation.dispatcher` is null)

- For CLI scope: run the bundle entrypoint and capture exit code and key assertions.
- For GUI or MIXED scope: use MCP browser tooling for evidence collection.
- Mark done only after the evidence line contains the required bundle path, startup log, validation commands, result, and PASS-only git anchors.

### Dispatched validation (`validation.dispatcher` is set)

When `validation.dispatcher` names a dispatcher (e.g., `"codex"`, `"subagent"`, `"cli"`, `"mcp"`, `"manual"`):

1. Read the corresponding dispatcher skill's `SKILL.md`.
2. Build the `VALIDATION_PROMPT`:
   a. Role instructions: reference `openspec-verifier` skill rules.
   b. Bundle path: the `VALIDATION_BUNDLE` from the most recent `BUNDLE (RUN #n)` line.
   c. ACCEPT criteria and TEST steps from the task block in `tasks.md`.
   d. SCOPE (CLI / GUI / MIXED) from the task's TEST block.
   e. Worker startup log path.
   f. Expected output: the agent must return a structured result containing SCOPE, VALIDATION_BUNDLE, WORKER_STARTUP_LOG, VALIDATED_CLI and EXIT_CODE (if CLI scope), VALIDATED_GUI and SCREENSHOTS (if GUI scope), RESULT (PASS or FAIL), and REVIEW GUIDANCE (if FAIL).
   g. If retry: append prior `REVIEW GUIDANCE`.
3. Follow the dispatcher skill's **Dispatch Steps** to invoke the validation agent.
4. Read the validation agent's result.
5. The **supervisor** writes the `EVIDENCE (RUN #n)` line in `tasks.md` based on the returned result — the validation agent does not write to `tasks.md` directly.

If the validation agent does not return a parseable result, treat as FAIL with REVIEW GUIDANCE noting the validation dispatch failure.

### Common

Use [monitor-checklist.md](references/monitor-checklist.md) during runs.
Use the `openspec-verifier` skill for detailed validation rules.

## MAXED Policy

See [maxed-policy.md](references/maxed-policy.md) for when to mark a task MAXED and how to recover.

## Completion Policy

See [completion-policy.md](references/completion-policy.md) for when a change is considered complete.

## Timeout and Recovery

See [timeout-recovery.md](references/timeout-recovery.md) for TIMEOUT, CRASH, and SILENT_FAILURE handling.

## Worker Contract

The worker (implementer) may:

- implement product code
- create validation bundle assets
- add exactly one `BUNDLE (RUN #n): ...` line

The worker may not:

- toggle any checkbox
- write `EVIDENCE`, `PASS`, `FAIL`, or `RESULT`
- edit `feature_list.json`
- create git commits

## Supervisor Contract

The supervisor owns:

- checkbox changes in `tasks.md`
- `EVIDENCE (RUN #n)` lines
- `progress.txt`
- PASS-only updates to feature pass-state
- PASS-only checkpoint commits and git history notes

## Guardrails

- One task per run.
- One fresh run folder per attempt.
- Record only verified facts.
- If validation fails, leave the checkbox unchecked and write review guidance for the next attempt.
- Never validate your own implementation — dispatch to a worker first.
