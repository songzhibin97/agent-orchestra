---
name: dispatch-mcp
description: Dispatch a task via an MCP tool call. Use when an MCP server provides a code generation or task execution tool that can receive a task prompt and produce implementation output.
---

# MCP Dispatcher

## Applicable Scenarios

Use when:
- An MCP server is configured in the current session with a code generation or execution tool.
- The supervisor wants to delegate implementation to an MCP-based service.
- Custom tooling is exposed via the MCP protocol.
- You want to integrate third-party AI CLI tools (Kimi, aider, etc.) via the MCP protocol.

## Prerequisites

- The MCP server must be configured and active in the current session.
- Verify by checking that the tool appears in the available tools list.
- **Dependencies**: `python3` and `pip install "mcp>=1.26.0"` (only if running a custom MCP server).

## Configuration

All settings are read from `.orchestra/config.json` → `dispatchers.mcp`:

| Setting | Config Key | Default |
|---------|-----------|---------|
| Server name | `dispatchers.mcp.server_name` | not set (must be configured) |
| Tool name | `dispatchers.mcp.tool_name` | not set (must be configured) |
| Prompt field | `dispatchers.mcp.prompt_field` | `prompt` |
| Timeout | `dispatchers.mcp.timeout_seconds` | `300` |
| CLI command | `dispatchers.mcp.cli_command` | not set |

The tool call becomes: `mcp__<server_name>__<tool_name>(<prompt_field>="<TASK_PROMPT>")`

## Dispatch Steps

1. Read the MCP configuration from `.orchestra/config.json` → `dispatchers.mcp`.
2. Confirm the tool is available in the current session.
3. Build the `TASK_PROMPT` from the supervisor's Dispatch Protocol.
4. Invoke the MCP tool:
   ```
   mcp__<server_name>__<tool_name>(prompt="<TASK_PROMPT>")
   ```
5. Read the tool's return value.
6. Check whether the return value or side effects include:
   - A new `BUNDLE (RUN #n)` line in `tasks.md`.
   - A bundle directory at the expected path.
7. Re-read `tasks.md` directly to verify independently.

## Result Interpretation

MCP tools may return:
- A text summary of what was done.
- A structured JSON response with status and artifact paths.
- Nothing (side effects only).

Always verify against the filesystem, not just the tool's return value.

## Error Handling

- If the MCP tool call fails (throws an error), treat as CRASH.
- If the tool returns successfully but no BUNDLE line exists, treat as SILENT_FAILURE.
- If the tool is unavailable, fall back to `dispatch-manual` or another dispatcher.

## Creating an MCP Server

To wrap any CLI tool as an MCP server, use the FastMCP template provided:

```
examples/mcp-server-template.py
```

The template uses [FastMCP](https://pypi.org/project/mcp/) to expose a CLI tool as an MCP tool. It reads timeout and CLI command from `.orchestra/config.json` → `dispatchers.mcp`.

### Quick Setup

1. Copy `examples/mcp-server-template.py` and customize the `TOOL_COMMAND`:
   ```python
   TOOL_COMMAND = "kimi -p {PROMPT} -y --no-thinking"
   ```

2. Or set the command in `.orchestra/config.json`:
   ```json
   {
     "dispatchers": {
       "mcp": {
         "server_name": "my-worker",
         "tool_name": "execute_task",
         "cli_command": "kimi -p {PROMPT} -y --no-thinking"
       }
     }
   }
   ```

3. Register the server in Claude desktop config:
   ```json
   {
     "mcpServers": {
       "my-worker": {
         "command": "python3",
         "args": ["/path/to/my_server.py"]
       }
     }
   }
   ```

4. The supervisor can now use `--dispatcher mcp` to route tasks through this server.

## Notes

- MCP tools must be pre-configured in the session — they cannot be added dynamically.
- The tool's implementation determines how code is generated and written to disk.
- Ensure the MCP server has write access to the project filesystem.
