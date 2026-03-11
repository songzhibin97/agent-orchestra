---
name: orchestra-supervisor
description: Codex entrypoint for a single supervised OpenSpec task attempt. Use when Codex itself should run one task attempt for step-by-step orchestration or debugging.
---

# Orchestra Supervisor

Codex-side entrypoint for one supervised task attempt.

Follow the same workflow contract as [`../../../.orchestra/contracts/commands/orchestra-supervisor.md`](../../../.orchestra/contracts/commands/orchestra-supervisor.md), but use this skill as the entrypoint when the user is operating inside Codex rather than Claude.

## Required Inputs

- `change-id`
- optional dispatcher name
- optional `task-id`

If `change-id` is missing, ask for it.
If dispatcher is missing, follow the command contract and ask the user to choose.

## Execution Contract

1. Read [`../../../.orchestra/contracts/commands/orchestra-supervisor.md`](../../../.orchestra/contracts/commands/orchestra-supervisor.md) first.
2. Execute exactly one supervised task attempt as defined there.
3. Load any referenced role and dispatcher skills as required by that contract.
4. Preserve role boundaries during dispatch, validation, and bookkeeping.

## Guardrails

- Stop after one attempt.
- Do not silently expand this into full change execution.
- Do not invent Codex-specific shortcut behavior.
