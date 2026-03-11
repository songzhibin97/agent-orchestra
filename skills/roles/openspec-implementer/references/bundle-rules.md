# Task Bundle Rules

Treat these as the minimum checks before accepting a worker run.

## Required Files

- `task.md`
- `run.sh`
- `run.bat`
- `logs/worker_startup.txt`

## Required Paths When Applicable

- `tests/` for GUI or non-trivial validation
- `inputs/` when validation consumes files
- `outputs/` when validation produces files
- `expected/` when golden comparison is used

## Run Folder Naming

Use:

`run-<RUN4>__task-<task-id>__ref-<ref-id>__<YYYYMMDDThhmmssZ>/`

## Evidence Rules

The final `EVIDENCE (RUN #n)` line should capture:

- `SCOPE`
- `VALIDATION_BUNDLE`
- `WORKER_STARTUP_LOG`
- CLI validation commands and exit code when applicable
- GUI validation source and screenshots when applicable
- `RESULT`
- PASS-only git commit metadata
