# Executor Guide: Adding Custom Dispatchers

This guide explains how to create a custom dispatcher skill for any tool or service.

Dispatcher skills are shared runtime skills. They can be used from:

- Claude entry commands such as `/orchestra-run`
- Codex entry skills such as `orchestra-run`

## Dispatcher Naming

- User-facing entry usage: `--dispatcher <name>`
- Skill directory name: `dispatch-<name>`

Example:

- entry argument: `--dispatcher codex`
- skill loaded by the workflow: `skills/dispatchers/dispatch-codex/`

## What a Dispatcher Does

A dispatcher skill answers one question: how do I send a `TASK_PROMPT` to an external tool and get back a bundle the supervisor can validate?

The dispatcher does not:

- build the `TASK_PROMPT`
- validate the result
- handle retries, `MAXED`, or workflow recovery

## Dispatcher Contract

A compliant dispatcher must:

1. accept a `TASK_PROMPT` string
2. invoke the external tool with that prompt
3. produce either:
   - a new `BUNDLE (RUN #n)` line in `tasks.md`, or
   - a clear failure signal such as a non-zero exit code
4. avoid modifying `tasks.md` directly except through the implementer writing the bundle line

## File Structure

```text
skills/dispatchers/dispatch-<name>/
├── SKILL.md
└── agents/
    └── openai.yaml
```

`SKILL.md` is required. `agents/openai.yaml` is optional and can improve how the dispatcher appears in Codex-compatible interfaces.

## SKILL.md Template

```markdown
---
name: dispatch-<name>
description: <Brief description of what tool this dispatches to and when to use it.>
---

# <Name> Dispatcher

## Applicable Scenarios

Use when: <specific conditions>

## Prerequisites

<How to verify the tool is available.>

## Dispatch Steps

1. <Step 1>
2. <Step 2>
...
N. Re-read `tasks.md` directly to verify the BUNDLE line.

## Configuration

All settings are read from `.orchestra/config.json` → `dispatchers.<name>`:

| Setting | Config Key | Default |
|---------|-----------|--------|
| Timeout | `dispatchers.<name>.timeout_seconds` | `300` |
| ... | ... | ... |

## Timeout Handling

<How timeouts are detected and what exit code they produce.>

## Error Handling

<What constitutes CRASH vs SILENT_FAILURE for this tool.>

## Notes

<Any tool-specific quirks the supervisor should know.>
```

## Required Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Must match the directory name |
| `description` | Yes | Shown in the dispatcher selection UI |
| `## Dispatch Steps` | Yes | Numbered supervisor procedure |
| `## Timeout Handling` | Yes | How timeout is detected |
| `## Error Handling` | Yes | How failures are classified |

## Example: `dispatch-my-tool`

```markdown
---
name: dispatch-my-tool
description: Dispatch tasks to MyTool API for AI-assisted code generation.
---

# MyTool Dispatcher

## Applicable Scenarios

Use when the team has a MyTool API key configured and wants to use MyTool for implementation.

## Prerequisites

Verify the MyTool CLI is available:
```bash
mytool --version
```

Set `MYTOOL_API_KEY` environment variable.

## Dispatch Steps

1. Build the `TASK_PROMPT` from the supervisor dispatch protocol.
2. Write the prompt to `/tmp/orchestra-prompt.txt`.
3. Execute:
   ```bash
   mytool run --prompt-file /tmp/orchestra-prompt.txt --output-mode auto
   ```
4. Capture the exit code.
5. Clean up the temp prompt file.
6. Re-read `tasks.md` to verify the `BUNDLE` line.

## Configuration

Timeout is read from `.orchestra/config.json` → `dispatchers.my-tool.timeout_seconds` (default: 300).

## Timeout Handling

If the process exceeds the configured timeout, kill it and treat exit code `137` as timeout.

## Error Handling

- exit `0` but no bundle line → `SILENT_FAILURE`
- exit `1` → `CRASH`
- exit `137` → `TIMEOUT`
```

## Installing a Custom Dispatcher

1. Create a dispatcher directory under `skills/dispatchers/`
2. Write `SKILL.md`
3. Optionally add `agents/openai.yaml`
4. Add default settings to `templates/config-template.json` under `dispatchers.<name>`
5. Reinstall into the target project:

```bash
bash uninstall.sh /path/to/project
bash install.sh /path/to/project
```

5. Use it:

```text
In Claude: /orchestra-run my-change --dispatcher my-tool
In Codex: use skill `orchestra-run` with dispatcher `my-tool`
```

## Testing Your Dispatcher

At minimum, test:

1. availability checks
2. the happy path
3. timeout classification
4. silent failure detection
