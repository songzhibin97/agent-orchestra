# Configuration Examples

Practical, copy-paste configurations for common scenarios. Each example is a complete `.orchestra/config.json` that only changes what matters for that scenario — everything else stays at its default.

---

## Scenario 1: Codex with Longer Timeout and Specific Model

Use this when your tasks are complex and Codex needs more time, or when you want to pin a specific model.

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

**Usage:**
```text
/orchestra-run my-change --dispatcher codex
```

---

## Scenario 2: Aider as CLI Dispatcher

Use this when you want to use [aider](https://aider.chat) instead of Codex for implementation.

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

**Usage:**
```text
/orchestra-run my-change --dispatcher cli
```

**Prerequisites:** `pip install aider-chat`

---

## Scenario 3: Kimi via FastMCP

Use this when you want to integrate the [Kimi CLI](https://github.com/moonshot-ai/kimi-cli) as an MCP server. This follows the same pattern as the `cc-orchestrator` project.

### Step 1: Configure `.orchestra/config.json`

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

### Step 2: Set up the MCP server

Copy the template from `skills/dispatchers/dispatch-mcp/examples/mcp-server-template.py` to a permanent location (e.g., `~/.orchestra-servers/kimi_server.py`).

```bash
mkdir -p ~/.orchestra-servers
cp skills/dispatchers/dispatch-mcp/examples/mcp-server-template.py ~/.orchestra-servers/kimi_server.py
```

### Step 3: Register the server with Claude

Add to `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS):

```json
{
  "mcpServers": {
    "kimi-worker": {
      "command": "python3",
      "args": ["~/.orchestra-servers/kimi_server.py"],
      "env": {}
    }
  }
}
```

Restart Claude desktop app.

### Step 4: Verify and use

```bash
# Install kimi-cli and mcp package first
pip install kimi-cli "mcp>=1.26.0"
kimi login
```

```text
# In Claude:
/orchestra-run my-change --dispatcher mcp
```

The call chain is:
```
Claude → dispatch-mcp skill → mcp__kimi-worker__execute_task(task="...")
       → kimi_server.py reads config.json → runs "kimi -p {task} -y --no-thinking"
       → kimi writes BUNDLE line to tasks.md
```

---

## Scenario 4: Relaxed Governance for Prototype Work

Use this when you're iterating fast and want more attempts before a task is marked MAXED.

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

**What changed:**
- `governance.max_attempts`: `3` → `10` — tasks get 10 tries before MAXED
- `governance.max_research_sources`: `5` → `8` — researcher checks more sources
- `actions.auto_commit`: `false` → `true` — automatic git commit on every PASS

---

## Scenario 5: Manual Dispatch with Auto-Commit

Use this when a human implements the code but you want Claude to supervise validation and auto-commit on success.

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

**Usage:**
```text
/orchestra-supervisor my-change --dispatcher manual --task 1.1
```

---

## Scenario 6: Codex CLI — Standard (Default Config)

The simplest production-ready setup. Uses Codex in full-auto mode with default settings.

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

**Usage:**
```text
/orchestra-run my-change --dispatcher codex
```

**Prerequisites:** `npm install -g @openai/codex` then `codex auth`

---

## Scenario 7: Claude CLI via dispatch-cli

Use this when you want Claude Code CLI (`claude`) to act as the implementer, called as a subprocess from the CLI dispatcher. Useful when running in Codex context and want to delegate to Claude.

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

**Usage:**
```text
/orchestra-run my-change --dispatcher cli
```

**How it works:**
```
supervisor → dispatch-cli → runs: claude --dangerously-skip-permissions -p "<TASK_PROMPT>"
           → Claude CLI implements the task, writes BUNDLE line to tasks.md
```

**Prerequisites:** `npm install -g @anthropic-ai/claude-code` then `claude login`

> Note: `--dangerously-skip-permissions` disables the interactive permission prompt so Claude CLI can run non-interactively. Only use in a controlled, trusted environment.

---

## Scenario 8: Claude Code Subagent (dispatch-subagent)

Use this when the **supervisor is already inside Claude Code** and wants to delegate to an isolated Claude subagent using the built-in Agent tool. No extra CLI needed.

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

**Usage:**
```text
/orchestra-run my-change --dispatcher subagent
```

**How it works:**
```
Claude (supervisor) → dispatch-subagent → Agent tool launches a subagent
                    → subagent uses openspec-implementer skill
                    → subagent writes BUNDLE line to tasks.md
                    → supervisor validates
```

**With worktree isolation** (tasks cannot conflict):
```json
"subagent": {
  "isolation": "worktree",
  "max_turns": 50,
  "timeout_seconds": null
}
```

**Prerequisites:** None. This uses the Claude Code built-in Agent tool.

---

## Scenario 9: Codex implements, Claude subagent validates (Hybrid)

Use this when you want Codex to write code (cheap, fast) but Claude to run validation (more capable). Split the roles across dispatchers.

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

**Usage:** Run implementation with codex, validation/research pass with subagent:
```text
# Codex implements:
/orchestra-supervisor my-change --dispatcher codex --task 1.1

# Claude subagent validates (if needed for complex validation):
/orchestra-supervisor my-change --dispatcher subagent --task 1.1
```

---

## Quick Reference

| Want to... | Dispatcher | Key Config |
|-----------|-----------|-----------|
| Use Codex (default) | `codex` | `command`, `timeout_seconds` |
| Use Codex with specific model | `codex` | `model: "o3"`, `reasoning_effort: "high"` |
| Use Claude CLI as subprocess | `cli` | `command: "claude --dangerously-skip-permissions -p"` |
| Use Claude subagent (built-in) | `subagent` | `isolation: "none"` or `"worktree"` |
| Use aider | `cli` | `command: "aider --yes-always --message"` |
| Use Kimi via FastMCP | `mcp` | See Scenario 3 |
| Human implements | `manual` | — |
| Get more retries | — | `governance.max_attempts: 10` |
| Auto-commit on pass | — | `actions.auto_commit: true` |

