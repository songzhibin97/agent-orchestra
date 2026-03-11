# Question Checklist

Use these prompts selectively. Do not ask all of them by default.

## Scope

- What exact behavior should become possible after this change?
- What behavior must remain untouched?
- Is this for one workflow, or should it apply everywhere the same concept appears?

## Interface

- Where does the change surface: UI, API, CLI, background job, or config?
- Does the user need new flags, fields, routes, buttons, or screens?

## Rules

- What permissions or roles matter?
- Are there validation rules, limits, or business policies?
- Are there error states or empty states that must be handled explicitly?

## Data

- Does this add or change stored data?
- Are migrations, backfills, or compatibility constraints required?
- Are there input and output samples that can be used for validation?

## Verification

- How would a human prove the change works?
- Is validation CLI, GUI, or MIXED?
- What would count as a failure even if the code compiles?
