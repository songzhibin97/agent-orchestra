---
name: openspec-researcher
description: Research blockers in an OpenSpec implementation workflow and turn them into actionable unblock guidance. Use when a task is blocked, validation keeps failing, a dependency or library issue is suspected, a worker crashed or timed out, or the supervisor needs evidence-backed next steps instead of ad hoc debugging.
---

# OpenSpec Researcher

Research only. Do not implement the fix inside this skill.

## Inputs

Gather as much of this as available:

- task text and ref tag
- relevant `REVIEW`, `BLOCKED`, or `UNBLOCK GUIDANCE` notes
- exact error excerpt
- commands already attempted
- repo or upstream package involved
- failure type: TIMEOUT, CRASH, SILENT_FAILURE, or FAIL

## Workflow

1. Restate the blocker in one sentence.
2. Identify whether it looks like:
   - local code bug
   - environment issue
   - library or upstream bug
   - tooling misuse
   - unclear requirement
   - worker contract violation (SILENT_FAILURE)
3. Query the configured providers in order from highest authority to broadest search.
4. Stop when you have enough evidence to suggest the next concrete move.
5. Return executable guidance, not a vague summary.

Use [provider-ordering.md](references/provider-ordering.md) to choose sources.
Use [provider-fallback.md](references/provider-fallback.md) when a configured provider is unavailable.
Use [conflict-resolution.md](references/conflict-resolution.md) when providers give contradictory answers.
Use [evidence-threshold.md](references/evidence-threshold.md) to know when to stop searching.

## Output Contract

Return a compact unblock note with:

```md
Blocker:
Likely cause:
Evidence:
- source or file
- source or file
Next steps:
1. ...
2. ...
If still failing:
```

Write the output to `openspec/changes/<change-id>/unblock-note.md`.

## Guardrails

- Prefer primary sources, official docs, or repo evidence over forum noise.
- Quote error strings and versions exactly when they matter.
- If the issue is really a missing requirement, say so directly.
- If you cannot verify a claimed fix path, label it as a HYPOTHESIS.
- Research only — do not modify product code, tasks.md, or feature_list.json.
