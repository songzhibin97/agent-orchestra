---
name: dispatch-codex
description: Dispatch a task to Codex CLI for execution. Use when the supervisor needs to delegate implementation to Codex running in full-auto mode. Codex will run in a sandboxed environment and apply file changes via patch.
---

# Codex Dispatcher

## Applicable Scenarios

Use when:
- The supervisor needs to delegate implementation work to Codex.
- Full automation is required (no human confirmation during execution).
- The target project has Codex CLI installed and accessible.

## Prerequisites

Verify Codex is available:
```bash
codex --version
```

If unavailable, use `dispatch-manual` or `dispatch-subagent` instead.

## Configuration

All settings are read from `.orchestra/config.json` → `dispatchers.codex`:

| Setting | Config Key | Default |
|---------|-----------|---------|
| Command | `dispatchers.codex.command` | `codex exec --full-auto --skip-git-repo-check` |
| Timeout | `dispatchers.codex.timeout_seconds` | `600` |
| Model | `dispatchers.codex.model` | not set |
| Reasoning effort | `dispatchers.codex.reasoning_effort` | not set |

## Dispatch Steps

1. Build the `TASK_PROMPT` as a single inline string (see supervisor's Dispatch Protocol).
2. Read `dispatchers.codex.command` from `.orchestra/config.json`.
3. Execute the configured command with the task prompt:
   ```bash
   <command> "<TASK_PROMPT>"
   ```
4. Append optional flags from config when set:
   - `dispatchers.codex.model` → `--model <value>`
   - `dispatchers.codex.reasoning_effort` → `--reasoning-effort <value>`
5. Capture the exit code:
   - `0` = completed normally
   - Non-zero = failed or interrupted

## Timeout Handling

- Read timeout from `dispatchers.codex.timeout_seconds` in `.orchestra/config.json`.
- Codex does not natively signal timeout — monitor wall clock time.
- If the process is killed (exit 137) or times out (exit 124), treat as TIMEOUT.
- Report to supervisor: no BUNDLE was produced.

## Notes

- Codex runs in a sandboxed environment. File changes are applied via patch after completion.
- The TASK_PROMPT must be a self-contained single string. Avoid shell special characters without proper escaping.
- Codex reads the repo at the start of the run. Ensure latest `tasks.md` is committed or unstaged changes are acceptable before dispatch.

## Error Codes Reference

| Exit Code | Meaning |
|-----------|---------|
| 0 | Normal completion |
| 1 | General error |
| 124 | Timeout |
| 137 | Killed (OOM or signal) |
