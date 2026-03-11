# Worker Contract

Defines the permission boundary for any agent acting as an Implementer.

## Allowed Actions

### Code Changes
- Write, modify, or delete product code files.
- Add new dependencies if required by the task.
- Create or update configuration files relevant to the task.
- Write test files if required by the bundle structure.

### Bundle Creation
- Create the validation bundle directory at the path provided in the task prompt.
- Write `task.md`, `run.sh`, `run.bat`, `logs/worker_startup.txt`.
- Write optional paths: `tests/`, `inputs/`, `outputs/`, `expected/`.

### tasks.md
- Add exactly one `BUNDLE (RUN #n):` line under the selected task.
- Read any section of `tasks.md` for context.

## Forbidden Actions

### tasks.md Mutations
- Changing `[ ]` to `[x]` or `[x]` to `[ ]`.
- Writing any `EVIDENCE (RUN #n):` line.
- Writing any `PASS`, `FAIL`, `RESULT`, `REVIEW GUIDANCE`, or `UNBLOCK GUIDANCE`.
- Adding, removing, or reordering tasks.

### Ledger Mutations
- Editing `feature_list.json` in any way.
- Writing or appending to `progress.txt`.
- Writing to `unblock-note.md`.

### Version Control
- Creating git commits.
- Staging files with `git add`.
- Modifying `.gitignore` in a way that hides artifacts.

### Scope Creep
- Implementing more than one task per run.
- Implementing tasks not explicitly assigned in the task prompt.

## Enforcement

The supervisor validates compliance before accepting the worker output. Violations result in a `SILENT_FAILURE` or rejection — not a PASS.
