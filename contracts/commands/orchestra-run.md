---
description: Fully automated execution of all tasks in an OpenSpec change. Loops through eligible tasks, dispatches each to the configured executor, validates, and commits. Stops on CHANGE_COMPLETE or unrecoverable error.
argument-hint: <change-id> [--dispatcher <name>]
---

# /orchestra-run

Fully automated execution of an OpenSpec change.

## Arguments

- `<change-id>` — required. The OpenSpec change identifier.
- `--dispatcher <name>` — optional. One of: `codex`, `subagent`, `cli`, `mcp`, `manual`. If omitted, asks the user to choose.

## Startup

1. Read `openspec/changes/<change-id>/tasks.md`, `feature_list.json`, and `progress.txt`.
2. Read `openspec/project.md` as the shared protocol contract.
3. Read `.orchestra/config.json`. If `validation.dispatcher` is set, verify the named dispatcher skill exists (`skills/dispatchers/dispatch-<name>/SKILL.md`). If not found, report error and stop.
4. If `--dispatcher` not provided:
   - List available dispatchers (check which dispatcher skills are installed).
   - Ask the user to choose one.
4. Load the chosen dispatcher skill (`skills/dispatchers/dispatch-<name>/SKILL.md`).
5. Load the supervisor skill (`skills/roles/openspec-supervisor/SKILL.md`).

## Main Loop

Repeat until all tasks are in a terminal state:

### Step 1 — Select Task

Apply supervisor's task selection rules:
- First unchecked task with no `NOT_EXECUTABLE`, `SKIP`, or `MAXED` marker.
- Not blocked by unmet prerequisites.

If no eligible task → go to Completion Check.

### Step 2 — Build TASK_PROMPT

Following supervisor's Dispatch Protocol:
1. Base: task description + `openspec-implementer` worker-contract + bundle-rules.
2. If retry: append prior `REVIEW GUIDANCE` and `UNBLOCK GUIDANCE`.
3. If `unblock-note.md` exists with new content: append `Next steps`.

### Step 3 — Dispatch

Follow the selected dispatcher's Dispatch Steps with the built TASK_PROMPT.

### Step 4 — Validate

Read `validation.dispatcher` from `.orchestra/config.json`.

**If `validation.dispatcher` is null (default — local validation):**

Following `openspec-verifier` skill rules:
- Check for BUNDLE line in `tasks.md`.
- Verify the referenced bundle path exists, matches `.orchestra/config.json.bundle.run_folder_pattern`, and contains every file in `.orchestra/config.json.bundle.required_files`.
- Run bundle validation locally.
- Write EVIDENCE line with PASS or FAIL.

**If `validation.dispatcher` is set (dispatched validation):**

- Check for BUNDLE line in `tasks.md`.
- Verify the referenced bundle path exists, matches `.orchestra/config.json.bundle.run_folder_pattern`, and contains every file in `.orchestra/config.json.bundle.required_files`.
- Build a `VALIDATION_PROMPT` (see supervisor skill's Dispatched Validation section).
- Dispatch validation to the named dispatcher (e.g., `codex`, `subagent`, `cli`, `mcp`, `manual`).
- Read the validation agent's structured result, including bundle integrity fields.
- The supervisor writes the EVIDENCE line based on the returned result.
- If the validation agent fails to return a result, or integrity fields are missing / false, treat as FAIL.

**Common (both modes):**

On TIMEOUT / CRASH / SILENT_FAILURE:
- Follow `timeout-recovery.md` rules.
- Count toward MAXED.
- Trigger researcher if available.

### Step 5 — Commit (on PASS)

Following `openspec-committer` skill rules:
- Toggle checkbox to `[x]`.
- Update `feature_list.json`.
- Append to `progress.txt`.
- Create checkpoint commit if `auto_commit` is enabled and `git status --porcelain` contains only current-task changes, bookkeeping files, and the current run bundle.

### Step 6 — Research (on FAIL)

- Check if task is MAXED (see `maxed-policy.md`).
- If MAXED: mark and continue to next task.
- If not MAXED: trigger `openspec-researcher` skill to analyze the failure.
- Incorporate researcher output into the next attempt's TASK_PROMPT.

## Completion Check

When no eligible tasks remain:

1. Apply `completion-policy.md` rules.
2. Verify `feature_list.json` consistency.
3. Write completion summary to `progress.txt`.
4. Output:
   ```
   ── CHANGE_COMPLETE ────────────────────────────────────────
   Change: <change-id>
   Passed: <n> | Maxed: <n> | Skipped: <n> | Total: <n>
   ───────────────────────────────────────────────────────────
   ```
   Or if gaps exist:
   ```
   ── COMPLETE_WITH_GAPS ─────────────────────────────────────
   NEEDS_ATTENTION:
   - <task-id>: <reason>
   ───────────────────────────────────────────────────────────
   ```

## Stop Conditions

Stop immediately (do not continue the loop) if:
- A task is in an unrecoverable state not handled by MAXED policy.
- The dispatcher signals a permanent failure (e.g., Codex not installed).
- The user manually interrupts.

## Guardrails

- Do not implement product code in this command.
- Do not skip validation — every task requires a PASS EVIDENCE line to be marked done.
- Do not treat `EXIT_CODE: 0` as sufficient for PASS — bundle integrity checks must also pass.
- Do not run multiple tasks in parallel — one task per loop iteration.
