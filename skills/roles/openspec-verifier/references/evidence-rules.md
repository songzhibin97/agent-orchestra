# Evidence Rules

Defines what must appear in a formal EVIDENCE line and supporting artifacts.

## Required EVIDENCE Fields

Every EVIDENCE line must include:

| Field | Description |
|-------|-------------|
| `SCOPE` | `CLI`, `GUI`, or `MIXED` |
| `VALIDATION_BUNDLE` | Full path to the bundle directory |
| `WORKER_STARTUP_LOG` | Full path to `logs/worker_startup.txt` |
| `RESULT` | `PASS` or `FAIL` — no other values |

## CLI-Specific Fields

| Field | Description |
|-------|-------------|
| `VALIDATED_CLI` | Command executed, e.g., `bash run.sh` |
| `EXIT_CODE` | Numeric exit code from `run.sh` |

## GUI-Specific Fields

| Field | Description |
|-------|-------------|
| `VALIDATED_GUI` | Tool used, e.g., `MCP(playwright)` |
| `SCREENSHOTS` | Path(s) to screenshot evidence (optional but recommended) |

## Startup Log Requirements

`logs/worker_startup.txt` must contain:

- UTC timestamp
- Selected task id and ref tag
- Bundle path
- Concrete repository file(s) or code path(s) changed
- Short note describing how validation should run

## REVIEW GUIDANCE Format

On FAIL, append after the EVIDENCE line:

```
REVIEW GUIDANCE (RUN #n): <specific reason for failure> | SUGGESTED_FIX: <concrete next action>
```

Be precise. Vague guidance like "fix the bug" is not acceptable.

## Evidence Integrity Rules

- One EVIDENCE line per RUN number — never overwrite.
- EVIDENCE lines are append-only — never delete a prior EVIDENCE line.
- PASS-only git metadata may appear in the EVIDENCE line as a suffix.
- EVIDENCE must be written by the supervisor or verifier, never by the implementer.
