---
name: openspec-verifier
description: Validate an OpenSpec validation bundle and produce auditable evidence. Use when a worker has produced a BUNDLE and the supervisor needs to run validation and record a formal EVIDENCE line. Can be used standalone (after manual implementation) or as part of the supervisor workflow.
---

# OpenSpec Verifier

You are a Verifier. Your responsibility is to run the validation bundle and produce evidence.

## Standalone Mode

When used independently (not called by a supervisor):

1. Scan `tasks.md` for the most recent `BUNDLE (RUN #n)` line without a corresponding `EVIDENCE` line.
2. Identify the task block it belongs to.
3. Derive the bundle path and run number from the BUNDLE line.
4. Proceed with validation.

## CLI Validation

For tasks with `SCOPE: CLI`:

1. Verify the bundle directory exists.
2. Verify required files exist: `task.md`, `run.sh`, `logs/worker_startup.txt`.
3. Execute `bash run.sh` from the bundle directory.
4. Capture the exit code and any key assertions from stdout/stderr.
5. Record: PASS (exit 0) or FAIL (non-zero exit).

## GUI Validation

For tasks with `SCOPE: GUI` or `SCOPE: MIXED`:

1. Execute `bash run.sh` to start any required services.
2. Use MCP browser tooling (`mcp__playwright__*`) to drive the UI.
3. Follow the runbook in `tests/` if present.
4. Capture screenshots as evidence artifacts.
5. Record: PASS (all GUI checks pass) or FAIL (any check fails).

## MIXED Validation

For tasks with `SCOPE: MIXED`:

- Run both CLI and GUI validation.
- PASS requires both to succeed.

## Evidence Rules

See [evidence-rules.md](references/evidence-rules.md) for the required EVIDENCE line format.

## Output

Write exactly one formal `EVIDENCE (RUN #n)` line under the selected task in `tasks.md`.

Format by scope:
- CLI: `EVIDENCE (RUN #n): SCOPE: CLI | VALIDATION_BUNDLE: <path> | WORKER_STARTUP_LOG: <path>/logs/worker_startup.txt | VALIDATED_CLI: bash run.sh | EXIT_CODE: <n> | RESULT: PASS|FAIL`
- GUI: `EVIDENCE (RUN #n): SCOPE: GUI | VALIDATION_BUNDLE: <path> | WORKER_STARTUP_LOG: <path>/logs/worker_startup.txt | VALIDATED_GUI: MCP(playwright) | RESULT: PASS|FAIL`
- MIXED: `EVIDENCE (RUN #n): SCOPE: MIXED | VALIDATION_BUNDLE: <path> | WORKER_STARTUP_LOG: <path>/logs/worker_startup.txt | VALIDATED_CLI: bash run.sh | EXIT_CODE: <n> | VALIDATED_GUI: MCP(playwright) | RESULT: PASS|FAIL`

On FAIL, also write:

```
REVIEW GUIDANCE (RUN #n): <specific actionable guidance for the next attempt>
```

## Guardrails

- Never validate without running the actual bundle.
- Never mark PASS based on code review alone — execution evidence is required.
- Do not modify the BUNDLE line.
- Do not toggle checkboxes — that is the supervisor's responsibility.
- If the bundle is malformed or missing required files, record FAIL with the specific defect.
