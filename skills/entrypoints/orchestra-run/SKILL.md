---
name: orchestra-run
description: Codex entrypoint for fully automated execution of all tasks in an OpenSpec change. Use when Codex itself should run the whole change loop until completion or a terminal stop condition.
---

# Orchestra Run

Codex-side entrypoint for full change execution.

Follow the same workflow contract as [`../../../.orchestra/contracts/commands/orchestra-run.md`](../../../.orchestra/contracts/commands/orchestra-run.md), but use this skill as the entrypoint when the user is operating inside Codex rather than Claude.

## Required Inputs

- `change-id`
- optional dispatcher name

If `change-id` is missing, ask for it.
If dispatcher is missing, follow the command contract and ask the user to choose.

## Execution Contract

1. Read [`../../../.orchestra/contracts/commands/orchestra-run.md`](../../../.orchestra/contracts/commands/orchestra-run.md) first.
2. Execute the workflow exactly as defined there.
3. Load any referenced role and dispatcher skills as required by that contract.
4. Preserve role boundaries during dispatch, validation, and bookkeeping.

## Guardrails

- Do not downgrade this into a single-task attempt.
- Do not skip validation, retry, MAXED, or completion checks defined by the command contract.
- Do not invent Codex-specific orchestration semantics.
