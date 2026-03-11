# 配置示例

以下是常见场景的完整配置，可以直接复制到 `.orchestra/config.json` 使用。每个示例只修改该场景需要调整的字段，其余保持默认值。

---

## 场景一：Codex + 延长超时 + 指定模型

适合任务复杂、Codex 需要更多时间，或需要固定使用特定模型的场景。

```json
{
  "dispatchers": {
    "codex": {
      "command": "codex exec --full-auto --skip-git-repo-check",
      "timeout_seconds": 900,
      "model": "o3",
      "reasoning_effort": "high"
    }
  },
  "governance": {
    "max_attempts": 3,
    "max_research_sources": 5
  },
  "actions": {
    "auto_commit": false
  },
  "bundle": {
    "base_path": "auto_test_orchestra",
    "run_folder_pattern": "run-{RUN4}__task-{TASK_ID}__ref-{REF}__{TIMESTAMP}",
    "required_files": ["task.md", "run.sh", "run.bat", "logs/worker_startup.txt"]
  },
  "validation": {
    "gui_tool": "mcp__playwright__*"
  }
}
```

**使用方式：**
```text
/orchestra-run my-change --dispatcher codex
```

---

## 场景二：用 aider 作为 CLI 调度器

适合想用 [aider](https://aider.chat) 替代 Codex 负责实现的场景。

```json
{
  "dispatchers": {
    "cli": {
      "command": "aider --yes-always --message",
      "prompt_mode": "argument",
      "timeout_seconds": 600
    }
  },
  "governance": {
    "max_attempts": 3,
    "max_research_sources": 5
  },
  "actions": {
    "auto_commit": false
  },
  "bundle": {
    "base_path": "auto_test_orchestra",
    "run_folder_pattern": "run-{RUN4}__task-{TASK_ID}__ref-{REF}__{TIMESTAMP}",
    "required_files": ["task.md", "run.sh", "run.bat", "logs/worker_startup.txt"]
  },
  "validation": {
    "gui_tool": "mcp__playwright__*"
  }
}
```

**使用方式：**
```text
/orchestra-run my-change --dispatcher cli
```

**前置条件：** `pip install aider-chat`

---

## 场景三：通过 FastMCP 接入 Kimi

适合想把 [Kimi CLI](https://github.com/moonshot-ai/kimi-cli) 包装成 MCP server 来使用的场景。这和 `cc-orchestrator` 项目的模式完全一致。

### 第一步：编辑 `.orchestra/config.json`

```json
{
  "dispatchers": {
    "mcp": {
      "server_name": "kimi-worker",
      "tool_name": "execute_task",
      "prompt_field": "task",
      "timeout_seconds": 300,
      "cli_command": "kimi -p {PROMPT} -y --no-thinking"
    }
  },
  "governance": {
    "max_attempts": 3,
    "max_research_sources": 5
  },
  "actions": {
    "auto_commit": false
  },
  "bundle": {
    "base_path": "auto_test_orchestra",
    "run_folder_pattern": "run-{RUN4}__task-{TASK_ID}__ref-{REF}__{TIMESTAMP}",
    "required_files": ["task.md", "run.sh", "run.bat", "logs/worker_startup.txt"]
  },
  "validation": {
    "gui_tool": "mcp__playwright__*"
  }
}
```

### 第二步：部署 MCP server

把模板复制到一个固定位置：

```bash
mkdir -p ~/.orchestra-servers
cp skills/dispatchers/dispatch-mcp/examples/mcp-server-template.py \
   ~/.orchestra-servers/kimi_server.py
```

### 第三步：在 Claude 中注册 MCP server

编辑 `~/Library/Application Support/Claude/claude_desktop_config.json`（macOS）：

```json
{
  "mcpServers": {
    "kimi-worker": {
      "command": "python3",
      "args": ["~/.orchestra-servers/kimi_server.py"]
    }
  }
}
```

重启 Claude desktop app。

### 第四步：安装依赖并登录

```bash
pip install kimi-cli "mcp>=1.26.0"
kimi login
```

### 第五步：使用

```text
/orchestra-run my-change --dispatcher mcp
```

整个调用链是：

```
Claude → dispatch-mcp skill → mcp__kimi-worker__execute_task(task="...")
       → kimi_server.py 读取 config.json → 执行 "kimi -p {task} -y --no-thinking"
       → kimi 在 tasks.md 中写入 BUNDLE 行
```

---

## 场景四：宽松治理（原型阶段）

适合在快速迭代原型阶段，不想太早把任务标记为 MAXED 的场景。

```json
{
  "dispatchers": {
    "codex": {
      "command": "codex exec --full-auto --skip-git-repo-check",
      "timeout_seconds": 600,
      "model": null,
      "reasoning_effort": null
    }
  },
  "governance": {
    "max_attempts": 10,
    "max_research_sources": 8
  },
  "actions": {
    "auto_commit": true
  },
  "bundle": {
    "base_path": "auto_test_orchestra",
    "run_folder_pattern": "run-{RUN4}__task-{TASK_ID}__ref-{REF}__{TIMESTAMP}",
    "required_files": ["task.md", "run.sh", "run.bat", "logs/worker_startup.txt"]
  },
  "validation": {
    "gui_tool": "mcp__playwright__*"
  }
}
```

**修改了什么：**
- `governance.max_attempts`: `3` → `10` — 任务最多尝试 10 次才 MAXED
- `governance.max_research_sources`: `5` → `8` — researcher 可以查阅更多来源
- `actions.auto_commit`: `false` → `true` — 每次 PASS 自动创建 git commit

---

## 场景五：手动实现 + 自动提交

适合人工写代码，但希望 Claude 负责监督验收并自动提交的场景。

```json
{
  "dispatchers": {
    "manual": {
      "timeout_seconds": null
    }
  },
  "governance": {
    "max_attempts": 3,
    "max_research_sources": 5
  },
  "actions": {
    "auto_commit": true
  },
  "bundle": {
    "base_path": "auto_test_orchestra",
    "run_folder_pattern": "run-{RUN4}__task-{TASK_ID}__ref-{REF}__{TIMESTAMP}",
    "required_files": ["task.md", "run.sh", "run.bat", "logs/worker_startup.txt"]
  },
  "validation": {
    "gui_tool": "mcp__playwright__*"
  }
}
```

**使用方式：**
```text
/orchestra-supervisor my-change --dispatcher manual --task 1.1
```

---

## 场景六：Codex CLI — 标准配置（默认）

最简单的生产可用配置，使用 Codex 全自动模式、默认参数。

```json
{
  "dispatchers": {
    "codex": {
      "command": "codex exec --full-auto --skip-git-repo-check",
      "timeout_seconds": 600,
      "model": null,
      "reasoning_effort": null
    }
  },
  "governance": {
    "max_attempts": 3,
    "max_research_sources": 5
  },
  "actions": {
    "auto_commit": false
  },
  "bundle": {
    "base_path": "auto_test_orchestra",
    "run_folder_pattern": "run-{RUN4}__task-{TASK_ID}__ref-{REF}__{TIMESTAMP}",
    "required_files": ["task.md", "run.sh", "run.bat", "logs/worker_startup.txt"]
  },
  "validation": {
    "gui_tool": "mcp__playwright__*"
  }
}
```

**使用方式：**
```text
/orchestra-run my-change --dispatcher codex
```

**前置条件：** `npm install -g @openai/codex` 然后 `codex auth`

---

## 场景七：通过 dispatch-cli 调用 Claude CLI

适合想把 Claude Code CLI（`claude`）作为实现者，用 CLI dispatcher 以子进程方式调用的场景。常见于 Codex 上下文中反向调用 Claude。

```json
{
  "dispatchers": {
    "cli": {
      "command": "claude --dangerously-skip-permissions -p",
      "prompt_mode": "argument",
      "timeout_seconds": 600
    }
  },
  "governance": {
    "max_attempts": 3,
    "max_research_sources": 5
  },
  "actions": {
    "auto_commit": false
  },
  "bundle": {
    "base_path": "auto_test_orchestra",
    "run_folder_pattern": "run-{RUN4}__task-{TASK_ID}__ref-{REF}__{TIMESTAMP}",
    "required_files": ["task.md", "run.sh", "run.bat", "logs/worker_startup.txt"]
  },
  "validation": {
    "gui_tool": "mcp__playwright__*"
  }
}
```

**使用方式：**
```text
/orchestra-run my-change --dispatcher cli
```

**调用链：**
```
supervisor → dispatch-cli → 执行: claude --dangerously-skip-permissions -p "<TASK_PROMPT>"
           → Claude CLI 实现任务，在 tasks.md 中写入 BUNDLE 行
```

**前置条件：** `npm install -g @anthropic-ai/claude-code` 然后 `claude login`

> 注意：`--dangerously-skip-permissions` 用于关闭交互式权限提示，使 Claude CLI 可以非交互式运行。请只在可信的受控环境中使用。

---

## 场景八：Claude Code Subagent（dispatch-subagent）

适合 **supervisor 本身已在 Claude Code 内部运行**，想通过内置 Agent tool 委派给一个隔离的 Claude 子 agent 来实现任务。无需额外 CLI。

```json
{
  "dispatchers": {
    "subagent": {
      "isolation": "none",
      "max_turns": null,
      "timeout_seconds": null
    }
  },
  "governance": {
    "max_attempts": 3,
    "max_research_sources": 5
  },
  "actions": {
    "auto_commit": false
  },
  "bundle": {
    "base_path": "auto_test_orchestra",
    "run_folder_pattern": "run-{RUN4}__task-{TASK_ID}__ref-{REF}__{TIMESTAMP}",
    "required_files": ["task.md", "run.sh", "run.bat", "logs/worker_startup.txt"]
  },
  "validation": {
    "gui_tool": "mcp__playwright__*"
  }
}
```

**使用方式：**
```text
/orchestra-run my-change --dispatcher subagent
```

**调用链：**
```
Claude（supervisor）→ dispatch-subagent → Agent tool 启动 subagent
                   → subagent 使用 openspec-implementer skill
                   → subagent 在 tasks.md 中写入 BUNDLE 行
                   → supervisor 验证
```

**开启 Worktree 隔离**（防止任务间文件冲突）：
```json
"subagent": {
  "isolation": "worktree",
  "max_turns": 50,
  "timeout_seconds": null
}
```

**前置条件：** 无。使用 Claude Code 内置 Agent tool，无需额外安装。

---

## 场景九：Codex 实现 + Claude Subagent 验证（混合模式）

适合希望 Codex 负责写代码（成本低、速度快），Claude 负责运行验证（能力更强）的场景。

```json
{
  "dispatchers": {
    "codex": {
      "command": "codex exec --full-auto --skip-git-repo-check",
      "timeout_seconds": 600,
      "model": null,
      "reasoning_effort": null
    },
    "subagent": {
      "isolation": "none",
      "max_turns": null,
      "timeout_seconds": null
    }
  },
  "governance": {
    "max_attempts": 3,
    "max_research_sources": 5
  },
  "actions": {
    "auto_commit": false
  },
  "bundle": {
    "base_path": "auto_test_orchestra",
    "run_folder_pattern": "run-{RUN4}__task-{TASK_ID}__ref-{REF}__{TIMESTAMP}",
    "required_files": ["task.md", "run.sh", "run.bat", "logs/worker_startup.txt"]
  },
  "validation": {
    "gui_tool": "mcp__playwright__*"
  }
}
```

**使用方式：**
```text
# 实现阶段用 Codex：
/orchestra-supervisor my-change --dispatcher codex --task 1.1

# 验证阶段用 Claude subagent（复杂验证场景）：
/orchestra-supervisor my-change --dispatcher subagent --task 1.1
```

---

## 快速查找

| 想做什么 | Dispatcher | 关键配置 |
|---------|-----------|---------|
| 使用 Codex（默认） | `codex` | `command`、`timeout_seconds` |
| Codex + 指定模型 | `codex` | `model: "o3"`、`reasoning_effort: "high"` |
| Claude CLI 子进程 | `cli` | `command: "claude --dangerously-skip-permissions -p"` |
| Claude Subagent（内置） | `subagent` | `isolation: "none"` 或 `"worktree"` |
| 使用 aider | `cli` | `command: "aider --yes-always --message"` |
| 使用 Kimi via FastMCP | `mcp` | 参见场景三 |
| 人工实现 | `manual` | — |
| 增加重试次数 | — | `governance.max_attempts: 10` |
| 每次 PASS 自动 commit | — | `actions.auto_commit: true` |

