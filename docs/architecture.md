# Architecture

## Design Philosophy

Agent-Orchestra is a skills package, not a workflow engine. It defines:

- what each role should do through role skills
- how external tools are invoked through dispatcher skills
- how each host enters the workflow through Claude commands or Codex entrypoint skills

OpenSpec remains responsible for actual workflow execution and artifact state. Agent-Orchestra layers role boundaries and orchestration rules on top.

## Naming Convention

- `openspec-*`: role skills
- `dispatch-*`: dispatcher skills
- `orchestra-*`: host entrypoints, exposed as Claude commands and Codex skills

## Component Overview

```text
agent-orchestra/
├── skills/
│   ├── roles/          ← Role skills
│   ├── dispatchers/    ← Dispatcher skills
│   └── entrypoints/    ← Codex entrypoint skills
├── .orchestra/
│   ├── contracts/      ← Shared command contracts
│   └── config.json     ← Centralized runtime configuration
├── commands/           ← Claude command entry points
├── schemas/            ← OpenSpec schema extension
├── templates/          ← Configuration templates
├── install.sh          ← Platform installer
└── uninstall.sh        ← Platform uninstaller
```

Host entrypoint vs runtime skill:

- Claude commands decide when a workflow starts and what arguments it accepts in Claude
- Codex entrypoint skills provide the same workflow entry surface in Codex
- Role and dispatcher skills decide how the runtime behaves after the workflow starts

## Role Skills

Each role skill defines the behavior and permission boundary of one role.

| Skill | Role | Owns |
|-------|------|------|
| `openspec-interviewer` | Clarify requirements | `brief.md` |
| `openspec-implementer` | Write code | Product code and validation bundle |
| `openspec-supervisor` | Orchestrate a task attempt | Checkbox toggles, evidence, bookkeeping |
| `openspec-verifier` | Run validation | Evidence lines |
| `openspec-committer` | Confirm a pass | `feature_list.json` updates and checkpoint commits |
| `openspec-researcher` | Unblock failures | `unblock-note.md` |
| `openspec-feature-tracker` | Maintain feature ledger | `feature_list.json` |

Key principle: role skills do not call each other directly. The supervisor coordinates them.

## Dispatcher Skills

Each dispatcher skill defines how implementation work is sent to an external executor.

| Skill | Tool | Mechanism |
|-------|------|-----------|
| `dispatch-codex` | Codex CLI | `codex exec --full-auto` |
| `dispatch-subagent` | Claude Code | Agent tool |
| `dispatch-cli` | Generic CLI | Shell execution |
| `dispatch-mcp` | MCP tool | MCP tool call |
| `dispatch-manual` | Human | Manual handoff |

Key principle: dispatchers only delegate implementer work. Validation stays with the supervisor unless `validation.dispatcher` is configured (see below).

When you pass `--dispatcher codex`, the active entrypoint resolves that name to the `dispatch-codex` skill.

## Validation Dispatcher

By default, validation runs locally — the supervisor (or verifier) executes the bundle and captures evidence. When `validation.dispatcher` is set in `.orchestra/config.json`, the supervisor dispatches validation to the named dispatcher instead.

PASS requires more than `EXIT_CODE: 0`: the bundle path must exist, the run-folder name must match `bundle.run_folder_pattern`, every path in `bundle.required_files` must exist, and the committer must pass a clean-worktree gate before auto-commit.

```text
validation.dispatcher = null (default):
  supervisor → verifier runs bundle locally → EVIDENCE

validation.dispatcher = "codex":
  supervisor → dispatch-codex → Codex runs bundle → returns result → supervisor writes EVIDENCE
```

This enables cross-agent workflows where different agents handle implementation and validation:

```text
CC implements + Codex validates:
  --dispatcher subagent, validation.dispatcher = "codex"

Codex implements + CC validates:
  --dispatcher codex, validation.dispatcher = "subagent"
```

The implementation dispatcher (`--dispatcher`) and validation dispatcher (`validation.dispatcher`) are independent — any combination is valid.

## Role × Dispatcher Matrix

Roles and dispatchers are orthogonal:

```text
implementer × codex       → Codex writes code
implementer × subagent    → Claude subagent writes code
implementer × manual      → Human writes code

supervisor × (any)        → Supervisor coordinates, dispatcher determines who implements
```

When `validation.dispatcher` is configured, validation also becomes part of the matrix:

```text
verifier × codex          → Codex validates
verifier × subagent       → Claude subagent validates
verifier × cli            → CLI tool validates
```

## Data Flow

```text
tasks.md                feature_list.json      progress.txt
    │                          │                    │
    ▼                          ▼                    ▼
[supervisor reads]      [committer writes]    [supervisor/committer appends]
    │
    ├─ [dispatch] → implementer → BUNDLE line in tasks.md
    │
    ├─ [validate] → verifier → EVIDENCE line in tasks.md
    │
    └─ [commit] → committer → checkbox [x], feature passes, git commit
```

## OpenSpec Integration

Agent-Orchestra extends OpenSpec without replacing it.

| OpenSpec provides | Agent-Orchestra provides |
|------------------|------------------------|
| `openspec init` | `install.sh` / `uninstall.sh` |
| `openspec status` | role skills, dispatcher skills, and host entrypoints |
| Artifact DAG | `opsx-supervised` schema extension |
| `/opsx:apply` | `/orchestra-run`, `/orchestra-supervisor`, `orchestra-run`, `orchestra-supervisor` |
| Standard artifacts | `brief.md`, `feature_list.json`, `progress.txt`, `unblock-note.md` |
| — | `.orchestra/config.json` (centralized runtime configuration) |

## Audit Trail

Every execution leaves an auditable trail:

```text
tasks.md:
  - [ ] 1.1 Task description [#R1]
    BUNDLE (RUN #1): ...
    EVIDENCE (RUN #1): ... RESULT: PASS

progress.txt:
  [2024-01-01T12:00:00Z] [COMPLETE] [1.1] RUN #1 | RESULT: PASS | ...

feature_list.json:
  [{"ref": "R1", "feature": "...", "passes": true, "evidence": "..."}]
```
