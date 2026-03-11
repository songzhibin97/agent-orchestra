---
name: openspec-feature-tracker
description: Build, repair, or review feature_list.json under an OpenSpec change folder. Use when a change needs durable ref-based feature tracking, when refs in tasks.md and feature entries drift, when multiple tasks reference the same ref, or when a supervisor needs a clean pass/fail checklist per stable ref tag.
---

# OpenSpec Feature Tracker

Create a durable feature checklist keyed by stable ref tags such as `[#R1]`.

## Workflow

1. Read `openspec/changes/<change-id>/tasks.md`.
2. Extract every stable ref tag and its associated acceptance intent.
3. Create or repair `feature_list.json` so each stable ref appears exactly once.
4. Default all entries to failing until supervisor validation proves otherwise.
5. If the file exists, preserve entry meaning unless the source-of-truth tasks changed.

Use [feature-list-schema.md](references/feature-list-schema.md) for the expected shape.
Use [multi-ref-merge.md](references/multi-ref-merge.md) when multiple tasks share the same ref.

## Generation Rules

- One feature entry per unique stable ref.
- The `ref` value is the bare token without brackets, such as `R1`.
- Keep feature statements end-to-end and user-observable, not implementation trivia.
- Keep `passes` false until supervisor evidence exists.
- If a task lacks a stable ref, report the gap instead of inventing one silently.

## Repair Rules

- Preserve existing refs when still present in `tasks.md`.
- Remove only entries that no longer map to any real ref after confirming the tasks changed.
- Do not let worker roles mutate the file during implementation runs.
- If a matching ref entry is missing in a live workflow, report it as blocked.
- On repair, reset `passes` to false only if the associated task changed meaning.

## Output

Prefer deterministic JSON with a small, stable structure. Keep descriptions brief and auditable.

If you need a template, use the example in [feature-list-schema.md](references/feature-list-schema.md).

## Guardrails

- Do not define features at task-step granularity unless the step itself is the user-visible unit.
- Do not change pass-state from false to true without explicit validated evidence in the workflow.
- Do not invent feature entries that cannot be traced back to a stable ref.
- Do not merge refs — one ref always maps to exactly one feature entry.
