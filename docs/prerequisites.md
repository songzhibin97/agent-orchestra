# Prerequisites / 前置依赖

## Required（必须）

| Dependency | Install |
|-----------|---------|
| [OpenSpec CLI](https://openspec.dev) | Follow official docs |
| Claude Code CLI | `npm install -g @anthropic-ai/claude-code` |
| Codex CLI *(if using `dispatch-codex`)* | `npm install -g @openai/codex` |
| Node.js + npm | [nodejs.org](https://nodejs.org) |

## Automatically Configured by `install.sh`（安装时自动配置）

The installer will register these MCP tools into `~/.claude/settings.json` if not already present, as long as `npx` is available:

| MCP Tool | Package | Used by |
|----------|---------|---------|
| `context7` | `@upstash/context7-mcp@latest` | `openspec-researcher` — library documentation lookup |
| `playwright` | `@playwright/mcp@latest` | `openspec-verifier` — GUI validation |

After install, **restart Claude Code** for the MCP tools to take effect.

### Manual Registration

If the installer skipped MCP (e.g., `npx` not found), add them manually to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "description": "Context7 文档查询 MCP"
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"],
      "description": "Playwright GUI 测试 MCP"
    }
  }
}
```

## Optional — for `dispatch-mcp`（可选，仅使用 MCP 调度器时需要）

Only needed if you use `dispatch-mcp` with a custom MCP server:

```bash
pip install "mcp>=1.26.0"   # FastMCP framework
pip install kimi-cli         # if wrapping Kimi
# or: pip install aider-chat, etc.
```

See [config-examples.zh.md](config-examples.zh.md) Scenario 3 for the full Kimi MCP setup.

## Checking Your Setup

After install, verify everything works:

```bash
# Check MCP tools are registered
cat ~/.claude/settings.json | python3 -m json.tool | grep -A3 "context7\|playwright"

# Check openspec
openspec --version

# Check codex
codex --version
```
