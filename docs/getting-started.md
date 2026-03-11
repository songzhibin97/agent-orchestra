# Getting Started

## Naming and Entry Points

`openspec-*` and `dispatch-*` are shared runtime skills. `orchestra-*` are host entrypoints.

- `openspec-*`: role skills such as `openspec-supervisor` and `openspec-implementer`
- `dispatch-*`: dispatcher skills such as `dispatch-codex` and `dispatch-manual`
- In Claude: `orchestra-*` command entry points such as `/orchestra-run` and `/orchestra-supervisor`
- In Codex: `orchestra-*` skill entry points such as `orchestra-run` and `orchestra-supervisor`

Claude and Codex may display skills and commands together in the UI. The runtime skills are shared, while the entrypoint type is host-specific.

## Prerequisites

See **[Prerequisites](prerequisites.md)** for the complete dependency list. Quick summary:

- [OpenSpec CLI](https://openspec.dev) in `PATH`
- Claude Code CLI and/or Codex CLI
- Node.js + npm (for MCP tools auto-registration)

The installer will automatically register `context7` and `playwright` MCP tools into `~/.claude/settings.json`.

## Installation

Note: Agent-Orchestra depends on OpenSpec. Install OpenSpec CLI first, then install this package into your target project.

```bash
bash /path/to/agent-orchestra/install.sh /path/to/your/project
```

This installs all skills, commands, contracts, schema, and configuration.

If already installed, the installer will error. To reinstall:

```bash
bash /path/to/agent-orchestra/uninstall.sh /path/to/your/project
bash /path/to/agent-orchestra/install.sh /path/to/your/project
```

## Configuration

After installation, customize `.orchestra/config.json` to adjust dispatcher settings, timeouts, and other runtime parameters:

```bash
# View the config
cat /path/to/your/project/.orchestra/config.json
```

See [Configuration Schema](config-schema.md) for all available settings. Key examples:

```json
{
  "dispatchers": {
    "codex": {
      "timeout_seconds": 900,
      "model": "o3"
    }
  },
  "governance": {
    "max_attempts": 5
  },
  "actions": {
    "auto_commit": true
  }
}
```

## Quickstart: Full Automation with Codex

```bash
# 1. Install skills
bash install.sh ./my-project

# 2. Initialize and create a change
cd my-project
openspec init

# 3. Run the whole change automatically
# In Claude Code:
/orchestra-run my-change-001 --dispatcher codex
# Or in Codex:
# use skill `orchestra-run` with change-id `my-change-001` and dispatcher `codex`
```

`--dispatcher codex` means the supervisor will delegate implementation to the `dispatch-codex` dispatcher, which runs Codex CLI as the implementer.

## Quickstart: Manual Orchestration

```bash
# 1. Install skills
bash install.sh ./my-project

# 2. Use the implementer skill in Codex
# Codex implements the task and writes the BUNDLE line

# 3. Validate in Claude
/orchestra-supervisor my-change-001 --dispatcher manual --task 1.1
```

Manual orchestration is useful when you want to control implementation and validation separately.

## Workflow Steps

### Step 1: Clarify Requirements

Use the interviewer skill when the request is ambiguous:

```text
# In Claude Code:
Ask Claude to use the openspec-interviewer skill
```

### Step 2: Initialize a Change

```bash
openspec init
# Create a change under openspec/changes/<change-id>/
# Create tasks.md with checkbox tasks and [#R1] style refs
# Generate feature_list.json when needed
```

### Step 3: Run Tasks

Option A: full automation

```text
/orchestra-run my-change --dispatcher codex
# Or in Codex: use skill `orchestra-run`
```

Option B: one task at a time

```text
/orchestra-supervisor my-change --dispatcher codex --task 1.1
/orchestra-supervisor my-change --dispatcher codex --task 1.2
# Or in Codex: use skill `orchestra-supervisor`
```

Option C: mixed execution

```text
# Codex implements with openspec-implementer
# Then Claude validates:
/orchestra-supervisor my-change --dispatcher manual --task 1.1
```

Entry shell vs runtime skill:

- In Claude, `/orchestra-run` and `/orchestra-supervisor` are command entry shells
- In Codex, `orchestra-run` and `orchestra-supervisor` are skill entry shells
- `openspec-supervisor`, `openspec-implementer`, and `dispatch-codex` are shared runtime skills used by both hosts

### Step 4: Monitor Progress

```bash
openspec status --change my-change
cat openspec/changes/my-change/progress.txt
```

### Step 5: Handle Failures

If a task fails:

1. check `REVIEW GUIDANCE` in `tasks.md`
2. optionally trigger `openspec-researcher`
3. if the task is `MAXED`, review `unblock-note.md` and add `UNBLOCK GUIDANCE`
4. re-run the supervisor

## Skills Reference

### Role Skills

| Skill | When to use | 使用时机 |
|-------|-------------|---------|
| `openspec-interviewer` | Before writing tasks, clarify ambiguous requirements. | 在编写 tasks 之前，用来澄清模糊需求。 |
| `openspec-implementer` | Give this to the coding agent such as Codex or a subagent. | 分配给编码执行者，例如 Codex 或 subagent。 |
| `openspec-supervisor` | Orchestrate one task attempt end to end. | 负责单次 task attempt 的端到端编排。 |
| `openspec-verifier` | Run standalone validation after manual implementation. | 在人工实现后，单独执行验证。 |
| `openspec-committer` | Finalize bookkeeping and commitment after verification passes. | 在验证通过后，负责记账和最终提交。 |
| `openspec-researcher` | Investigate repeated failures and unblock the next attempt. | 在任务反复失败时分析原因并辅助解阻。 |
| `openspec-feature-tracker` | Generate or repair `feature_list.json`. | 用于生成或修复 `feature_list.json`。 |

### Dispatcher Skills

| Dispatcher | Best for | 适用场景 |
|-----------|---------|---------|
| `dispatch-codex` | Automated Codex execution. | 适合用 Codex 全自动执行实现任务。 |
| `dispatch-subagent` | Claude Code subagent isolation. | 适合通过 Claude Code subagent 隔离执行实现任务。 |
| `dispatch-cli` | Other AI CLI tools such as aider. | 适合接入其他 AI CLI 工具，例如 aider。 |
| `dispatch-mcp` | Custom MCP-based tools. | 适合接入自定义 MCP 工具链。 |
| `dispatch-manual` | Human implementation with AI supervision. | 适合人工实现、AI 负责监督和验收。 |

## Uninstall

```bash
bash /path/to/agent-orchestra/uninstall.sh /path/to/your/project
```

Removes only the files installed by `install.sh`. Does not remove OpenSpec data or user-created content.

## Troubleshooting

- No `BUNDLE` line after dispatch: the implementer did not follow the contract
- `MAXED` after repeated attempts: use `openspec-researcher` and add unblock guidance
- `feature_list.json` drift: run `openspec-feature-tracker`
- Wrong dispatcher: change the `--dispatcher` argument
- Timeout too short: adjust `dispatchers.<name>.timeout_seconds` in `.orchestra/config.json`
