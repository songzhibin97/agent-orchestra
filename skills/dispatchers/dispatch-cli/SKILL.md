---
name: dispatch-cli
description: Dispatch a task via any generic CLI tool such as aider, cursor CLI, or other AI coding assistants. Use when the supervisor needs to delegate implementation to a non-Codex, non-Claude CLI tool.
---

# CLI Dispatcher

## Applicable Scenarios

Use when:
- A third-party AI CLI tool is preferred for implementation.
- The team uses aider, cursor, or other CLI-based coding tools.
- Neither Codex nor Claude Code subagents are available.

## Configuration

All settings are read from `.orchestra/config.json` → `dispatchers.cli`:

| Setting | Config Key | Default |
|---------|-----------|---------|
| Command | `dispatchers.cli.command` | not set (must be configured) |
| Prompt mode | `dispatchers.cli.prompt_mode` | `argument` |
| Timeout | `dispatchers.cli.timeout_seconds` | `300` |

### Prompt Modes

| Mode | Description |
|------|-------------|
| `argument` | Prompt is appended as a quoted argument: `<command> "<TASK_PROMPT>"` |
| `stdin` | Prompt is piped via stdin: `echo "<TASK_PROMPT>" \| <command>` |
| `file` | Prompt is written to a temp file: `<command> /tmp/task-prompt.txt` |

## Dispatch Steps

1. Read the CLI configuration from `.orchestra/config.json` → `dispatchers.cli`.
2. Verify the CLI is installed:
   ```bash
   <command_base> --version
   ```
   If unavailable, report and stop.
3. Build the `TASK_PROMPT` string.
4. Execute based on `dispatchers.cli.prompt_mode`:
   - **argument**: `<command> "<TASK_PROMPT>"`
   - **stdin**: `printf '%s' "<TASK_PROMPT>" | <command>`
   - **file**: Write prompt to `/tmp/orchestra-task-prompt-<timestamp>.txt`, then `<command> /tmp/orchestra-task-prompt-<timestamp>.txt`
5. Capture exit code.
6. Clean up temp files if `prompt_mode` is `file`.

## Timeout Handling

- Read timeout from `dispatchers.cli.timeout_seconds` in `.orchestra/config.json`.
- If the process runs beyond the timeout, kill it and treat as TIMEOUT.
- Treat killed processes (exit 137) as CRASH.

## Notes

- Different CLIs have different prompt length limits. If the TASK_PROMPT is very long, use `prompt_mode: file`.
- Some CLIs require interactive confirmation — prefer CLI options that disable interactive prompts (e.g., `--yes-always` for aider).
- The CLI must be able to write to the project filesystem for the BUNDLE line to appear in `tasks.md`.
- After the CLI exits, always re-read `tasks.md` directly to verify the BUNDLE line.
