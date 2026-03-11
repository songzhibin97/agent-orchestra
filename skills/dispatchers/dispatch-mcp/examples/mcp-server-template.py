#!/usr/bin/env python3
"""
MCP Server Template for Agent-Orchestra dispatch-mcp

This template shows how to wrap any CLI tool as an MCP server using FastMCP,
so that Agent-Orchestra's dispatch-mcp skill can call it as a tool.

Based on the pattern from cc-orchestrator (kimi_mcp_server.py).

Prerequisites:
  pip install "mcp>=1.26.0"
  # Plus whatever CLI tool you want to wrap (e.g., kimi-cli, aider, etc.)

Usage:
  1. Copy this file and customize the TOOL_COMMAND and server/tool names.
  2. Run: python my_server.py
  3. Register the server in your Claude desktop config or MCP session.
  4. Set .orchestra/config.json → dispatchers.mcp.server_name / tool_name.

Example Claude desktop config entry:
  {
    "mcpServers": {
      "my-worker": {
        "command": "python3",
        "args": ["/path/to/my_server.py"]
      }
    }
  }
"""

import asyncio
import json
import os
import re
import shutil
from pathlib import Path

from mcp.server.fastmcp import FastMCP

# ── Configuration ────────────────────────────────────────────────────────────
# Customize these for your CLI tool:

SERVER_NAME = "orchestra-worker"      # MCP server name
TOOL_NAME = "execute_task"            # Tool name exposed to clients

# The CLI command to wrap. Use {PROMPT} as a placeholder for the task prompt.
# Examples:
#   "kimi -p {PROMPT} -y --no-thinking"
#   "aider --yes-always --message {PROMPT}"
TOOL_COMMAND = None  # Set this or read from config.json

DEFAULT_TIMEOUT = 300  # seconds


# ── Helpers ──────────────────────────────────────────────────────────────────

def load_orchestra_config(workdir: str) -> dict:
    """Load .orchestra/config.json from the working directory."""
    config_path = os.path.join(workdir, ".orchestra", "config.json")
    if os.path.exists(config_path):
        with open(config_path) as f:
            return json.load(f)
    return {}


def get_tool_command(workdir: str) -> str:
    """Resolve the CLI command from config or module constant."""
    if TOOL_COMMAND:
        return TOOL_COMMAND
    config = load_orchestra_config(workdir)
    cmd = config.get("dispatchers", {}).get("mcp", {}).get("cli_command")
    if cmd:
        return cmd
    raise RuntimeError(
        "No CLI command configured. Set TOOL_COMMAND in this file "
        "or dispatchers.mcp.cli_command in .orchestra/config.json"
    )


def get_timeout(workdir: str) -> int:
    """Resolve timeout from config or module constant."""
    config = load_orchestra_config(workdir)
    return (
        config.get("dispatchers", {}).get("mcp", {}).get("timeout_seconds")
        or DEFAULT_TIMEOUT
    )


def strip_ansi(text: str) -> str:
    """Remove ANSI escape sequences from output."""
    return re.sub(r"\x1b\[[0-9;]*m", "", text)


# ── MCP Server ───────────────────────────────────────────────────────────────

mcp_server = FastMCP(SERVER_NAME)


@mcp_server.tool()
async def execute_task(task: str, workdir: str = ".") -> str:
    """Execute a coding task via the configured CLI tool. Returns the output."""
    cmd_template = get_tool_command(workdir)
    timeout = get_timeout(workdir)

    # Build the command
    if "{PROMPT}" in cmd_template:
        # Template mode: replace {PROMPT} placeholder
        cmd_str = cmd_template.replace("{PROMPT}", task)
        cmd_parts = cmd_str.split()
    else:
        # Append mode: add task as the last argument
        cmd_parts = cmd_template.split() + [task]

    # Find the executable
    executable = shutil.which(cmd_parts[0])
    if executable is None:
        raise RuntimeError(
            f"CLI tool '{cmd_parts[0]}' not found in PATH. "
            f"Install it first or update the command in config."
        )
    cmd_parts[0] = executable

    # Execute
    proc = await asyncio.create_subprocess_exec(
        *cmd_parts,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        cwd=workdir,
    )

    try:
        stdout, stderr = await asyncio.wait_for(
            proc.communicate(), timeout=timeout
        )
    except asyncio.TimeoutError:
        proc.kill()
        await proc.communicate()
        raise RuntimeError(
            f"Task timed out after {timeout} seconds. "
            f"Adjust dispatchers.mcp.timeout_seconds in .orchestra/config.json"
        )

    output = stdout.decode("utf-8", errors="replace")
    err_output = stderr.decode("utf-8", errors="replace")

    if proc.returncode != 0:
        raise RuntimeError(
            f"CLI tool exited with code {proc.returncode}: "
            f"{strip_ansi(err_output[:500])}"
        )

    return strip_ansi(output + err_output)


if __name__ == "__main__":
    mcp_server.run(transport="stdio")
