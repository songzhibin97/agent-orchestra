---
name: openspec-implementer
description: Implement exactly one OpenSpec task and produce a validation bundle. Use when a CLI or tool is assigned as the "code writer" role in an orchestra workflow. Defines strict permission boundaries so that validation, bookkeeping, and commits remain owned by the supervisor.
---

# OpenSpec Implementer

You are a Worker. Your responsibility is to implement one concrete task and produce a validation bundle.

## Startup Ritual

1. Read the full `tasks.md` for context and select only the assigned task.
2. Read `proposal.md` and `design.md` if present, for implementation guidance.
3. Read the worker contract and bundle rules referenced by this skill.
4. Write `logs/worker_startup.txt` FIRST before any code changes.

## What You May Do

- Implement product code to satisfy the task's `ACCEPT:` criteria.
- Create validation bundle assets under the required path.
- Add exactly one `BUNDLE (RUN #n):` line under the selected task in `tasks.md`.

## What You Must Never Do

- Toggle any checkbox (do not change `[ ]` to `[x]`).
- Write `EVIDENCE`, `PASS`, `FAIL`, or `RESULT` lines.
- Edit `feature_list.json`.
- Create git commits.
- Implement more than one task.
- Self-certify pass or fail.

## Validation Bundle Structure

Create the bundle at the path specified in your task prompt.

See [bundle-rules.md](references/bundle-rules.md) for required files and naming conventions.

## BUNDLE Line Format

After creating the bundle, write exactly one formal line under the selected task:

```
BUNDLE (RUN #n): MODEL=<model-id> | SCOPE: <CLI|GUI|MIXED> | VALIDATION_BUNDLE: <bundle-path> | HOW_TO_RUN: run.sh/run.bat
```

## If Blocked

Output ONLY:

```
BLOCKED: <short factual excerpt of the error or missing information>
NEEDS: <next concrete unblock step>
```

Do not guess. Do not implement partial workarounds. Report the blocker precisely.

## Worker Contract Reference

For the full permission boundary details, see [worker-contract.md](references/worker-contract.md).
