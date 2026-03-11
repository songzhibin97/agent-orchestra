# Agent-Orchestra

[中文文档](README.zh.md)

OpenSpec orchestration package for decoupling agent roles from execution backends.

## OpenSpec Integration

Agent-Orchestra is built on top of OpenSpec.

- OpenSpec provides change artifacts, schema execution, and workflow state
- Agent-Orchestra provides role skills, dispatcher skills, and orchestration entrypoints for both Claude and Codex
- This repository does not replace OpenSpec with a separate workflow engine

## Core Principles

- Focus on skills and orchestration rules, not on building a new workflow engine
- Rely on OpenSpec for artifact DAGs and workflow state
- Keep roles and dispatchers orthogonal so they can be combined freely

## Architecture

```text
Claude commands / Codex entry skills  Role skills               Dispatcher skills
┌──────────────────────────────┐      ┌──────────────────────┐  ┌───────────────────────┐
│ /orchestra-run               │      │ openspec-interviewer │  │ dispatch-codex        │
│ /orchestra-supervisor        │      │ openspec-implementer │  │ dispatch-subagent     │
│ orchestra-run                │  ──× │ openspec-supervisor  │  │ dispatch-cli          │
│ orchestra-supervisor         │      │ openspec-verifier    │  │ dispatch-mcp          │
└──────────────────────────────┘      │ openspec-researcher  │  │ dispatch-manual       │
                                      │ openspec-feature-    │  └───────────────────────┘
                                      │ tracker              │
                                      │ openspec-committer   │
                                      └──────────────────────┘
```

## Usage

### Full automation

```text
/orchestra-run <change-id> --dispatcher codex
```

This runs the full change loop automatically.

### Step-by-step orchestration

```text
/orchestra-supervisor <change-id> --dispatcher codex --task 1.1
```

This runs one supervisor attempt for a single task.

## Naming and Entry Points

### Skills

- `openspec-*` are role skills such as `openspec-supervisor` and `openspec-implementer`
- `dispatch-*` are dispatcher skills such as `dispatch-codex` and `dispatch-manual`
- In Codex, `orchestra-run` and `orchestra-supervisor` are also installed as entrypoint skills
- Claude and Codex may list skills and commands together in the UI, but they are different entry types

### Commands

- In Claude, `orchestra-*` are executable command entry points
- `/orchestra-run <change-id> --dispatcher <name>` runs the whole change until completion or a terminal stop condition
- `/orchestra-supervisor <change-id> --dispatcher <name> [--task <task-id>]` runs one supervisor attempt for a single task

### Relationship

- Claude commands and Codex entry skills are host-specific entry shells
- Role and dispatcher skills define the reusable runtime behavior and boundaries
- Both hosts execute by loading and following the same underlying skills

## Installation

Note: install and runtime usage both depend on OpenSpec. Make sure OpenSpec CLI is installed before using `install.sh`.

```bash
bash install.sh /path/to/project
```

The installer will:

1. detect the Claude and Codex host setup
2. copy role and dispatcher skills into `.claude/skills/` and `.codex/skills/`
3. install Codex entrypoint skills `orchestra-run` and `orchestra-supervisor`
4. install shared command contracts into `.orchestra/contracts/commands/`
5. install Claude commands `/orchestra-run` and `/orchestra-supervisor`
6. install the `opsx-supervised` schema
7. generate `.orchestra/config.json` with default settings
8. write `.orchestra/manifest.json` for clean uninstall

If Agent-Orchestra is already installed, the installer will error. Run `uninstall.sh` first.

## Uninstall

```bash
bash uninstall.sh /path/to/project
```

Removes only the files installed by `install.sh`. Does not remove OpenSpec data or user-created files.

## Configuration

All runtime settings are centralized in `.orchestra/config.json`. See [Configuration Schema](docs/config-schema.md) for details.

Key configurable values:
- Dispatcher settings: command, timeout, model, prompt mode
- Governance: max attempts before MAXED, max research sources
- Actions: auto commit on/off
- Bundle: base path, folder naming, required files
- Validation: GUI tool selection

## Repository Layout

```text
agent-orchestra/
├── schemas/opsx-supervised/     # OpenSpec schema extension
├── skills/
│   ├── roles/                   # Role skills
│   ├── dispatchers/             # Dispatcher skills
│   └── entrypoints/             # Codex entrypoint skills
├── contracts/commands/          # Shared command contracts
├── templates/                   # Configuration templates
├── commands/                    # Claude command entry points
├── docs/                        # User-facing documentation
├── install.sh                   # Installer
└── uninstall.sh                 # Uninstaller
```

## Documentation

- [Chinese README](README.zh.md)
- [Getting Started](docs/getting-started.md)
- [Getting Started (Chinese)](docs/getting-started.zh.md)
- [Architecture](docs/architecture.md)
- [Architecture (Chinese)](docs/architecture.zh.md)
- [Configuration Schema](docs/config-schema.md)
- [Configuration Schema (Chinese)](docs/config-schema.zh.md)
- [Executor Guide](docs/executor-guide.md)
- [Executor Guide (Chinese)](docs/executor-guide.zh.md)

## Dependencies

- [OpenSpec CLI](https://openspec.dev)
- Claude CLI and/or Codex CLI
