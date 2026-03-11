---
name: dispatch-subagent
description: Dispatch a task by launching a Claude Code subagent via the Agent tool. Use when the supervisor is running inside Claude Code and wants to delegate implementation to an isolated subagent with optional worktree isolation.
---

# Subagent Dispatcher

## Applicable Scenarios

Use when:
- The supervisor is running inside Claude Code (not Codex).
- The implementation should run in a controlled subprocess.
- Optional worktree isolation is desired to prevent cross-task interference.

## Prerequisites

This dispatcher uses Claude Code's built-in Agent tool. No additional installation required.

## Configuration

All settings are read from `.orchestra/config.json` → `dispatchers.subagent`:

| Setting | Config Key | Default |
|---------|-----------|---------|
| Isolation | `dispatchers.subagent.isolation` | `none` |
| Max turns | `dispatchers.subagent.max_turns` | not set |
| Timeout | `dispatchers.subagent.timeout_seconds` | not set |

## Dispatch Steps

1. Build the `TASK_PROMPT` from the supervisor's Dispatch Protocol.
2. Read `dispatchers.subagent` settings from `.orchestra/config.json`.
3. Launch a subagent using the Agent tool with these parameters:
   - `subagent_type`: `"general-purpose"`
   - `prompt`: the full `TASK_PROMPT`
   - `isolation`: value from `dispatchers.subagent.isolation` (default `"none"`, or `"worktree"`)
4. Wait for the subagent to return its result.
5. Check the returned result for:
   - Confirmation that a `BUNDLE (RUN #n)` line was written to `tasks.md`.
   - Confirmation that the bundle directory exists.
6. Re-read `tasks.md` to verify the BUNDLE line independently.

## Worktree Isolation

When `dispatchers.subagent.isolation` is `"worktree"`:
- The subagent works in a temporary git worktree copy of the repository.
- File changes are isolated until the worktree is merged or discarded.
- Use this when tasks might interfere with each other if run in sequence.

When `isolation` is `"none"`:
- The subagent shares the current project filesystem.
- Faster, but tasks must not have conflicting file changes.

## Context Limits

- Subagents inherit the current Claude model but have their own context window.
- Use `dispatchers.subagent.max_turns` to limit subagent execution if needed.
- Very long or complex tasks may exhaust the subagent's context — consider splitting.

## Error Handling

- If the subagent returns without a BUNDLE line, treat as SILENT_FAILURE.
- If the subagent reports an error or is stopped, treat as CRASH.
- Always re-read `tasks.md` directly — do not trust the subagent's summary alone.

## Notes

- The subagent has the `openspec-implementer` skill in its instructions (via the TASK_PROMPT).
- The TASK_PROMPT must include the implementer's worker-contract so the subagent knows its boundaries.
- Subagents do not have access to MCP tools unless configured.
