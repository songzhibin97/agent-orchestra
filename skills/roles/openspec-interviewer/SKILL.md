---
name: openspec-interviewer
description: Clarify OpenSpec change requests before proposal or implementation. Use when a user has a vague feature idea, a rough proposal, or an existing change-id and needs to turn ambiguous intent into concrete scope, constraints, acceptance criteria, edge cases, and implementation-ready notes for OpenSpec.
---

# OpenSpec Interviewer

Use a short interview to remove ambiguity before writing or revising OpenSpec artifacts.

## Workflow

1. Read the current proposal, spec, or change folder if the user supplied one.
2. Ask only the minimum unanswered questions needed to make the change executable.
3. Prioritize questions that affect scope, acceptance, safety, data shape, and UX.
4. Convert answers into a compact implementation brief:
   - goal
   - non-goals
   - user-visible behavior
   - constraints
   - acceptance criteria
   - open risks or assumptions
5. If the user wants OpenSpec output next, use the brief to draft or refine proposal/tasks content.

## Question Strategy

Ask about missing information in this order:

1. Problem and outcome: what should change and who benefits.
2. Boundaries: what must stay unchanged.
3. Entry points: API, CLI, UI, background job, config, data migration.
4. Acceptance: observable success criteria.
5. Edge cases: failure modes, empty states, permission rules, rollback concerns.
6. Verification: CLI, GUI, or mixed validation.

Use [question-checklist.md](references/question-checklist.md) when you need concrete prompts.

## Output Contract

Produce one concise brief. Prefer this shape:

```md
Goal:
Non-goals:
Actors / entry points:
Constraints:
Acceptance criteria:
Validation scope: CLI | GUI | MIXED
Open questions or assumptions:
```

## Guardrails

- Do not ask broad discovery questions if the repo already answers them.
- Do not ask more than needed. Short rounds beat one long questionnaire.
- If the user already gave a change-id, anchor every question to that change.
- When a requirement stays ambiguous, record it explicitly as an assumption instead of pretending it is settled.
