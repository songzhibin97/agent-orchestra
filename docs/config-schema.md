# Configuration Schema

All Agent-Orchestra runtime configuration lives in `.orchestra/config.json`. This file is generated automatically by `install.sh` and can be edited manually.

> Looking for practical examples? See **[Configuration Examples](config-examples.md)** for ready-to-use configs for Codex, aider, Kimi MCP, and more.

When a config value is `null`, the feature is disabled or uses the documented default behavior.

## dispatchers

### dispatchers.codex

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `command` | string | `"codex exec --full-auto --skip-git-repo-check"` | Shell command to invoke Codex |
| `timeout_seconds` | integer | `600` | Max wall-clock seconds before treating the run as TIMEOUT |
| `model` | string \| null | `null` | Appends `--model <value>` when set |
| `reasoning_effort` | string \| null | `null` | One of `high`, `medium`, `low`. Appends `--reasoning-effort <value>` |

### dispatchers.cli

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `command` | string \| null | `null` | Shell command for the CLI tool (e.g., `"aider --yes-always --message"`) |
| `prompt_mode` | string | `"argument"` | How the task prompt is passed: `argument`, `stdin`, or `file` |
| `timeout_seconds` | integer | `300` | Max wall-clock seconds |

### dispatchers.mcp

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `server_name` | string \| null | `null` | MCP server name registered in the session |
| `tool_name` | string \| null | `null` | Tool name exposed by the MCP server |
| `prompt_field` | string | `"prompt"` | Parameter name used to pass the task prompt |
| `timeout_seconds` | integer | `300` | Max wall-clock seconds |
| `cli_command` | string \| null | `null` | CLI command used inside the MCP server (e.g., `"kimi -p {PROMPT} -y --no-thinking"`) |

**Prerequisites**: Using `dispatch-mcp` requires `python3` and `pip install "mcp>=1.26.0"`. See `dispatch-mcp/examples/mcp-server-template.py`.

### dispatchers.subagent

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `isolation` | string | `"none"` | `"none"` or `"worktree"`. When `"worktree"`, the subagent runs in a git worktree |
| `max_turns` | integer \| null | `null` | Limit the subagent's execution turns |
| `timeout_seconds` | integer \| null | `null` | Not enforced by default (subagent manages its own lifecycle) |

### dispatchers.manual

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `timeout_seconds` | integer \| null | `null` | Manual dispatch waits indefinitely by default |

## governance

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `max_attempts` | integer | `3` | Consecutive FAIL results before a task is marked MAXED |
| `max_research_sources` | integer | `5` | Maximum providers/sources the researcher queries per pass |

## actions

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `auto_commit` | boolean | `false` | When `true`, the committer creates checkpoint git commits on PASS, but only after a clean-worktree gate (`git status --porcelain`) confirms no extra caches, build outputs, local binaries, or unrelated files remain |

## bundle

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `base_path` | string | `"auto_test_orchestra"` | Root directory for validation bundles |
| `run_folder_pattern` | string | `"run-{RUN4}__task-{TASK_ID}__ref-{REF}__{TIMESTAMP}"` | Naming pattern for run folders. PASS validation requires the actual bundle directory name to match this pattern |
| `required_files` | string[] | `["task.md", "run.sh", "run.bat", "logs/worker_startup.txt"]` | Files that must exist in every bundle. Missing files are a hard FAIL, not a warning |

## validation

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `dispatcher` | string \| null | `null` | When set, validation is dispatched to the named dispatcher (e.g., `"codex"`, `"subagent"`, `"cli"`, `"mcp"`, `"manual"`) instead of running locally. The dispatcher config is read from `dispatchers.<name>`. When `null`, validation runs locally (original behavior). Dispatched validators must still return bundle-integrity fields in addition to PASS/FAIL |
| `gui_tool` | string | `"mcp__playwright__*"` | MCP tool pattern used for GUI validation |
