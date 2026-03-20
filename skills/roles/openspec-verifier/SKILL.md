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
2. Verify the bundle directory name matches `.orchestra/config.json.bundle.run_folder_pattern`.
3. Verify required files exist: `task.md`, `run.sh`, `run.bat`, `logs/worker_startup.txt`, plus any additional paths listed in `.orchestra/config.json.bundle.required_files`.
4. Execute `bash run.sh` from the bundle directory.
5. Capture the exit code and any key assertions from stdout/stderr.
6. Record: PASS only when the exit code is `0` and all bundle integrity checks succeeded.

## GUI Validation

For tasks with `SCOPE: GUI` or `SCOPE: MIXED`:

1. Execute `bash run.sh` to start any required services.
2. Use MCP browser tooling (`mcp__playwright__*`) to drive the UI.
3. Follow the runbook in `tests/` if present.
4. Capture screenshots as evidence artifacts.
5. PASS requires both GUI checks and bundle integrity checks to succeed.

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

## Dispatched Mode

When running as a dispatched validation agent (invoked via `validation.dispatcher`):

1. You receive a `VALIDATION_PROMPT` from the supervisor containing the bundle path, ACCEPT criteria, TEST steps, and SCOPE.
2. Follow the same validation rules as standalone mode (CLI / GUI / MIXED).
3. **Do not write to `tasks.md`** — the supervisor owns `tasks.md` writes in dispatched mode.
4. Instead, return a structured result to the supervisor containing:
   - `SCOPE`: CLI | GUI | MIXED
   - `VALIDATION_BUNDLE`: the bundle path you validated
   - `WORKER_STARTUP_LOG`: path to `logs/worker_startup.txt`
   - `BUNDLE_EXISTS`: `true|false`
   - `REQUIRED_FILES_OK`: `true|false`
   - `BUNDLE_PATH_CONFIRMED`: `true|false`
   - `BUNDLE_NAME_PATTERN_OK`: `true|false`
   - `VALIDATED_CLI` and `EXIT_CODE` (if CLI scope)
   - `VALIDATED_GUI` and `SCREENSHOTS` (if GUI scope)
   - `RESULT`: PASS or FAIL
   - `REVIEW_GUIDANCE`: specific actionable guidance (if FAIL)
5. All other verifier rules and guardrails still apply.

## Guardrails

- Never validate without running the actual bundle.
- Never mark PASS based on code review alone — execution evidence is required.
- Do not modify the BUNDLE line.
- Do not toggle checkboxes — that is the supervisor's responsibility.
- If the bundle path is wrong, the run folder name is malformed, or required files are missing, record FAIL with the specific defect.
- `EXIT_CODE: 0` does not override bundle integrity failures.
- In dispatched mode, do not write to `tasks.md` — return results to the supervisor.
