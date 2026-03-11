---
description: Supervisor loop for a single OpenSpec task attempt. More granular than orchestra-run — can target a specific task and stops after one attempt. Use for step-by-step orchestration or debugging.
argument-hint: <change-id> [--dispatcher <name>] [--task <task-id>]
---

# /orchestra-supervisor

Execute the supervisor loop for exactly one task attempt.

## Arguments

- `<change-id>` — required. The OpenSpec change identifier.
- `--dispatcher <name>` — optional. One of: `codex`, `subagent`, `cli`, `mcp`, `manual`. If omitted, asks the user to choose.
- `--task <task-id>` — optional. Target a specific task (e.g., `1.2`). If omitted, selects the first eligible task.

## Startup

1. Read `openspec/changes/<change-id>/tasks.md`, `feature_list.json`, and `progress.txt`.
2. Read `openspec/project.md` as the shared protocol contract.
3. If `--dispatcher` not provided, ask the user to choose from available dispatchers.
4. Load the chosen dispatcher skill (`skills/dispatchers/dispatch-<name>/SKILL.md`).
5. Load the supervisor skill (`skills/roles/openspec-supervisor/SKILL.md`).

## Task Selection

If `--task <task-id>` is provided:
- Locate the task in `tasks.md`.
- Verify it is eligible (not `[x]`, not `NOT_EXECUTABLE`, not `MAXED`).
- If ineligible, report the reason and stop.

If `--task` is omitted:
- Apply supervisor's task selection rules to find the first eligible unchecked task.
- If no eligible task, report COMPLETE or BLOCKED and stop.

## Single Attempt Execution

### Phase 1 — Build TASK_PROMPT

Following supervisor's Dispatch Protocol:
1. Base: task description + `openspec-implementer` worker-contract + bundle-rules.
2. If this is a retry: append prior `REVIEW GUIDANCE` and `UNBLOCK GUIDANCE`.
3. If `unblock-note.md` has relevant content: append `Next steps`.

### Phase 2 — Dispatch

Follow the selected dispatcher's Dispatch Steps with the built TASK_PROMPT.

### Phase 3 — Validate

Following `openspec-verifier` skill rules:
- Check for BUNDLE line in `tasks.md`.
- Run bundle validation (CLI / GUI / MIXED).
- Write EVIDENCE line with PASS or FAIL.

On TIMEOUT / CRASH / SILENT_FAILURE:
- Follow `timeout-recovery.md` rules.
- Write REVIEW GUIDANCE.
- Stop after recording.

### Phase 4 — Commit (on PASS)

Following `openspec-committer` skill rules:
- Toggle checkbox to `[x]`.
- Update `feature_list.json`.
- Append to `progress.txt`.
- Create checkpoint commit if `auto_commit` is enabled.

### Phase 5 — Research (on FAIL)

- Check MAXED status per `maxed-policy.md`.
- If MAXED: mark and report.
- If not MAXED: optionally trigger `openspec-researcher` skill.
- Stop after one attempt — do not retry automatically.

## Output

Report the result at the end:

```
── Task Attempt Complete ───────────────────────────────────
Task: <task-id> [#<ref>] RUN #<n>
Dispatcher: <name>
Result: PASS | FAIL | TIMEOUT | CRASH | SILENT_FAILURE | MAXED
Next: <suggested action>
────────────────────────────────────────────────────────────
```

## Difference from /orchestra-run

| Feature | /orchestra-supervisor | /orchestra-run |
|---------|----------------------|----------------|
| Scope | One task, one attempt | All tasks, all attempts |
| Retry | Never (stops after one attempt) | Automatic (up to MAXED) |
| Task targeting | `--task` flag available | Always sequential |
| Use case | Step-by-step, debugging | Full automation |

## Guardrails

- Do not implement product code in this command.
- Stop after exactly one attempt — do not loop.
- Do not skip validation for any reason.
