# 配置说明

Agent-Orchestra 的所有运行时配置集中在 `.orchestra/config.json`。该文件由 `install.sh` 自动生成，可手动编辑。

> 想看实际配置？参见 **[配置示例](config-examples.zh.md)**，包含 Codex、aider、Kimi MCP 等场景的完整配置。

当配置值为 `null` 时，表示该功能未启用或使用文档中描述的默认行为。

## dispatchers（调度器）

### dispatchers.codex

| 键 | 类型 | 默认值 | 说明 |
|----|------|--------|------|
| `command` | string | `"codex exec --full-auto --skip-git-repo-check"` | 调用 Codex 的 shell 命令 |
| `timeout_seconds` | integer | `600` | 超时秒数，超时后视为 TIMEOUT |
| `model` | string \| null | `null` | 设置后追加 `--model <value>` |
| `reasoning_effort` | string \| null | `null` | `high`、`medium`、`low` 之一，追加 `--reasoning-effort <value>` |

### dispatchers.cli

| 键 | 类型 | 默认值 | 说明 |
|----|------|--------|------|
| `command` | string \| null | `null` | CLI 工具的 shell 命令（如 `"aider --yes-always --message"`） |
| `prompt_mode` | string | `"argument"` | 任务 prompt 的传递方式：`argument`、`stdin`、`file` |
| `timeout_seconds` | integer | `300` | 超时秒数 |

### dispatchers.mcp

| 键 | 类型 | 默认值 | 说明 |
|----|------|--------|------|
| `server_name` | string \| null | `null` | 会话中注册的 MCP server 名称 |
| `tool_name` | string \| null | `null` | MCP server 暴露的 tool 名称 |
| `prompt_field` | string | `"prompt"` | 传递任务 prompt 的参数名 |
| `timeout_seconds` | integer | `300` | 超时秒数 |
| `cli_command` | string \| null | `null` | MCP server 内部调用的 CLI 命令（如 `"kimi -p {PROMPT} -y --no-thinking"`） |

**前置条件**：使用 `dispatch-mcp` 需要 `python3` 和 `pip install "mcp>=1.26.0"`。参见 `dispatch-mcp/examples/mcp-server-template.py`。

### dispatchers.subagent

| 键 | 类型 | 默认值 | 说明 |
|----|------|--------|------|
| `isolation` | string | `"none"` | `"none"` 或 `"worktree"`。使用 worktree 时 subagent 在 git worktree 中运行 |
| `max_turns` | integer \| null | `null` | 限制 subagent 执行轮数 |
| `timeout_seconds` | integer \| null | `null` | 默认不强制超时（subagent 自行管理生命周期） |

### dispatchers.manual

| 键 | 类型 | 默认值 | 说明 |
|----|------|--------|------|
| `timeout_seconds` | integer \| null | `null` | 手动调度默认无限等待 |

## governance（治理策略）

| 键 | 类型 | 默认值 | 说明 |
|----|------|--------|------|
| `max_attempts` | integer | `3` | 连续 FAIL 达到此数后标记 MAXED |
| `max_research_sources` | integer | `5` | researcher 每次查询的最大 provider/源数量 |

## actions（动作开关）

| 键 | 类型 | 默认值 | 说明 |
|----|------|--------|------|
| `auto_commit` | boolean | `false` | 为 `true` 时，committer 在 PASS 后创建 checkpoint git commit，但前提是通过工作区洁净门禁（`git status --porcelain`），确认没有额外缓存、构建产物、本地二进制或无关文件残留 |

## bundle（验证包）

| 键 | 类型 | 默认值 | 说明 |
|----|------|--------|------|
| `base_path` | string | `"auto_test_orchestra"` | 验证包根目录 |
| `run_folder_pattern` | string | `"run-{RUN4}__task-{TASK_ID}__ref-{REF}__{TIMESTAMP}"` | 运行文件夹命名格式。只有实际 bundle 目录名匹配该格式，才允许判定 PASS |
| `required_files` | string[] | `["task.md", "run.sh", "run.bat", "logs/worker_startup.txt"]` | 每个 bundle 必须包含的文件。缺任何文件都属于硬 FAIL，不是提示信息 |

## validation（验证）

| 键 | 类型 | 默认值 | 说明 |
|----|------|--------|------|
| `dispatcher` | string \| null | `null` | 设置后，验证阶段将通过指定的调度器派发（如 `"codex"`、`"subagent"`、`"cli"`、`"mcp"`、`"manual"`），而非本地执行。调度器配置从 `dispatchers.<name>` 读取。为 `null` 时走本地验证（原有行为）。即使是派发验证，也必须返回 bundle 完整性字段，不能只返回 PASS/FAIL |
| `gui_tool` | string | `"mcp__playwright__*"` | GUI 验证使用的 MCP tool 匹配模式 |
