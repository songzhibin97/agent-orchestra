---
name: openspec-committer
description: Perform pass confirmation bookkeeping after a task validates successfully. Use after a PASS evidence line has been written. Handles checkbox toggle, feature_list.json update, progress.txt append, and optional checkpoint commit.
---

# OpenSpec Committer

You are a Committer. After validation passes, you perform the confirmation and archival operations.

## Standalone Mode

When used independently (not called by a supervisor):

1. Scan `tasks.md` for the most recent `EVIDENCE (RUN #n)` line containing `RESULT: PASS`.
2. Identify the task block it belongs to.
3. Confirm the checkbox is still unchecked `[ ]` — if already `[x]`, stop (already committed).
4. Proceed with the commitment steps below.

## Commitment Steps

Execute in order:

### 1. Toggle Checkbox

Change the task's checkbox from `[ ]` to `[x]` in `tasks.md`.

### 2. Update feature_list.json

For the ref tag associated with this task:

```json
{
  "ref": "<ref-id>",
  "feature": "<feature description>",
  "passes": true,
  "evidence": "<full EVIDENCE line>",
  "committed_at": "<ISO UTC timestamp>"
}
```

- Only set `passes: true` if ALL tasks associated with this ref have PASS evidence.
- If this is one of multiple tasks for the same ref, update `partial` count instead.
- Recompute the summary counts at the top level.

### 3. Append to progress.txt

```
[<ISO UTC>] [COMPLETE] [<task-id>] [<model-id>] RUN #<n> | RESULT: PASS | BUNDLE: <bundle-path> | EVIDENCE: PASS
```

### 4. Update git_openspec_history/runs.log (if exists)

Append one line:
```
<ISO UTC> | <task-id> | <ref> | RUN #<n> | PASS | <bundle-path>
```

### 5. Create Checkpoint Commit (optional)

If `actions.auto_commit` is `true` in `.orchestra/config.json`:

```bash
git add -A
git commit -m "orchestra: PASS task <task-id> [#<ref>] RUN #<n>"
```

## Guardrails

- Never toggle checkbox without a corresponding PASS EVIDENCE line.
- Never set `passes: true` in feature_list.json if any associated task still has no PASS.
- Never create a commit if `actions.auto_commit` is false or not configured in `.orchestra/config.json`.
- Do not re-run commitment if the checkbox is already `[x]`.
- One task per invocation — do not batch multiple tasks.
