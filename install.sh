#!/usr/bin/env bash
# install.sh — Agent-Orchestra Skills Package Installer
#
# Usage:
#   bash install.sh <target-project-dir>
#
# Installs all skills, commands, contracts, schema, and config into the target
# project. Errors if Agent-Orchestra is already installed (run uninstall.sh first).
#
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-}"

if [ -z "$TARGET_DIR" ]; then
  echo "Usage: bash install.sh <target-project-dir>" >&2
  exit 1
fi

# --- Resolve target directory ---
TARGET_DIR="$(
  python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$TARGET_DIR" 2>/dev/null \
    || realpath "$TARGET_DIR" 2>/dev/null \
    || (cd "$TARGET_DIR" && pwd)
)"
mkdir -p "$TARGET_DIR"

# --- Check for existing installation ---
if [ -d "$TARGET_DIR/.orchestra" ]; then
  echo "ERROR: Agent-Orchestra is already installed at $TARGET_DIR" >&2
  echo "       Run 'bash uninstall.sh $TARGET_DIR' first to reinstall." >&2
  exit 1
fi

# --- Helpers ---
log() { echo "  $*"; }

MANIFEST_FILES=()
MANIFEST_DIRS=()

track_dir() {
  MANIFEST_DIRS+=("$1")
}

copy_dir() {
  local src="$1"
  local dst="$2"
  cp -r "$src" "$dst"
  find "$dst" -name '.DS_Store' -delete 2>/dev/null || true
  find "$dst" -name '.git' -type d -exec rm -rf {} + 2>/dev/null || true
  track_dir "${dst#$TARGET_DIR/}"
}

copy_file() {
  local src="$1"
  local dst="$2"
  cp "$src" "$dst"
  MANIFEST_FILES+=("${dst#$TARGET_DIR/}")
}

# --- Header ---
echo ""
echo "Agent-Orchestra Installer"
echo "========================"
echo ""
echo "Target: $TARGET_DIR"
echo ""

# --- Check prerequisites ---
if ! command -v openspec >/dev/null 2>&1; then
  echo "WARNING: openspec CLI not found in PATH."
  echo "         Schema installation requires openspec."
  echo ""
fi

# --- Initialize OpenSpec (if needed) ---
if [ ! -d "$TARGET_DIR/openspec" ]; then
  echo "Initializing OpenSpec project..."
  if command -v openspec >/dev/null 2>&1; then
    (cd "$TARGET_DIR" && openspec init --tools codex,claude .)
  else
    echo "  SKIP: openspec not available. Run 'openspec init' manually."
  fi
fi

# --- Create directories ---
mkdir -p "$TARGET_DIR/.claude/skills"
mkdir -p "$TARGET_DIR/.claude/commands"
mkdir -p "$TARGET_DIR/.codex/skills"
mkdir -p "$TARGET_DIR/.orchestra/contracts/commands"

# --- Install Role Skills ---
echo ""
echo "Installing role skills..."

for skill_dir in "$PACKAGE_DIR/skills/roles"/*/; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue
  skill_name="$(basename "$skill_dir")"

  log "→ .claude/skills/$skill_name"
  copy_dir "$skill_dir" "$TARGET_DIR/.claude/skills/$skill_name"

  log "→ .codex/skills/$skill_name"
  copy_dir "$skill_dir" "$TARGET_DIR/.codex/skills/$skill_name"
done

# --- Install Dispatcher Skills ---
echo ""
echo "Installing dispatcher skills..."

for skill_dir in "$PACKAGE_DIR/skills/dispatchers"/*/; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue
  skill_name="$(basename "$skill_dir")"

  log "→ .claude/skills/$skill_name"
  copy_dir "$skill_dir" "$TARGET_DIR/.claude/skills/$skill_name"

  log "→ .codex/skills/$skill_name"
  copy_dir "$skill_dir" "$TARGET_DIR/.codex/skills/$skill_name"
done

# --- Install Entrypoint Skills (Codex only) ---
echo ""
echo "Installing entrypoint skills..."

for skill_dir in "$PACKAGE_DIR/skills/entrypoints"/*/; do
  [ -d "$skill_dir" ] || continue
  [ -f "$skill_dir/SKILL.md" ] || continue
  skill_name="$(basename "$skill_dir")"

  log "→ .codex/skills/$skill_name"
  copy_dir "$skill_dir" "$TARGET_DIR/.codex/skills/$skill_name"
done

# --- Install Claude Commands ---
echo ""
echo "Installing Claude commands..."

for cmd_file in "$PACKAGE_DIR/commands/"*.md; do
  [ -f "$cmd_file" ] || continue
  cmd_name="$(basename "$cmd_file")"
  log "→ .claude/commands/$cmd_name"
  copy_file "$cmd_file" "$TARGET_DIR/.claude/commands/$cmd_name"
done

# --- Install Shared Command Contracts ---
echo ""
echo "Installing shared command contracts..."

for cmd_file in "$PACKAGE_DIR/contracts/commands/"*.md; do
  [ -f "$cmd_file" ] || continue
  cmd_name="$(basename "$cmd_file")"
  log "→ .orchestra/contracts/commands/$cmd_name"
  copy_file "$cmd_file" "$TARGET_DIR/.orchestra/contracts/commands/$cmd_name"
done

# --- Install Config ---
echo ""
echo "Installing configuration..."

log "→ .orchestra/config.json"
copy_file "$PACKAGE_DIR/templates/config-template.json" "$TARGET_DIR/.orchestra/config.json"

# --- Install Schema ---
echo ""
echo "Installing OpenSpec schema..."

SCHEMA_SRC="$PACKAGE_DIR/schemas/opsx-supervised"
SCHEMA_DST="$TARGET_DIR/openspec/schemas/opsx-supervised"
mkdir -p "$TARGET_DIR/openspec/schemas"
log "→ openspec/schemas/opsx-supervised"
copy_dir "$SCHEMA_SRC" "$SCHEMA_DST"

# Write openspec/config.yaml if missing
CONFIG_FILE="$TARGET_DIR/openspec/config.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
  log "→ openspec/config.yaml"
  cat > "$CONFIG_FILE" <<'EOF'
schema: opsx-supervised

context: |
  Project uses the agent-orchestra OpenSpec workflow.
  Native OpenSpec artifacts remain proposal, design, specs, and tasks.
  Added workflow artifacts are brief.md, feature_list.json, progress.txt, and unblock-note.md.
  Tasks must remain standard checkbox items.

rules:
  brief:
    - Keep the brief compact and implementation-oriented.
    - "State validation scope explicitly as CLI, GUI, or MIXED."
  tasks:
    - Keep checkbox syntax exactly valid for OpenSpec apply tracking.
    - "Each task MUST include exactly one stable ref tag like [#R1] in the checkbox line."
    - "Each task MUST have an ACCEPT: block with observable acceptance criteria."
    - "Each task MUST have a TEST: block starting with SCOPE: CLI | GUI | MIXED."
    - "Each task MUST have empty BUNDLE: and EVIDENCE: placeholder lines."
EOF
  MANIFEST_FILES+=("openspec/config.yaml")
fi

# --- Write Manifest ---
echo ""
echo "Writing manifest..."

MANIFEST_FILE="$TARGET_DIR/.orchestra/manifest.json"
{
  printf '%s\n' "${MANIFEST_FILES[@]}"
  echo "---"
  printf '%s\n' "${MANIFEST_DIRS[@]}"
} | python3 -c "
import json, sys

lines = sys.stdin.read().strip().split('\n')
sep = lines.index('---')
files = [l for l in lines[:sep] if l]
dirs = [l for l in lines[sep+1:] if l]

manifest = {
    'installed_at': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
    'files': files,
    'directories': dirs
}

with open(sys.argv[1], 'w') as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)
" "$MANIFEST_FILE"

log "→ .orchestra/manifest.json"

# --- Optional: Register MCP tools in Claude settings ---
echo ""
echo "Setting up optional MCP tools..."

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
REGISTERED_MCP=""

register_mcp_if_missing() {
  local name="$1"
  local cmd="$2"
  shift 2
  local description="${!#}"  # last argument is description
  local args=("${@:1:$#-1}")  # all except last are args
  local description="$description"

  if [ ! -f "$CLAUDE_SETTINGS" ]; then
    return
  fi

  # Check if server already registered and register if missing (single Python call)
  python3 - "$CLAUDE_SETTINGS" "$name" "$cmd" "$description" "${args[@]}" <<'PYEOF'
import json, sys, os

cfg_path = sys.argv[1]
name = sys.argv[2]
cmd = sys.argv[3]
description = sys.argv[4]
args = [a for a in sys.argv[5:] if a]

with open(cfg_path) as f:
    cfg = json.load(f)

if name in cfg.get("mcpServers", {}):
    print(f"  SKIP {name} (already registered)")
    sys.exit(0)

cfg.setdefault("mcpServers", {})
cfg["mcpServers"][name] = {
    "command": cmd,
    "args": args,
    "description": description
}

with open(cfg_path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)

print(f"  → Registered MCP: {name}")
PYEOF
  if [ $? -eq 0 ]; then
    REGISTERED_MCP="$REGISTERED_MCP $name"
  fi
}

if command -v npx >/dev/null 2>&1; then
  # context7 — documentation query provider used by openspec-researcher
  register_mcp_if_missing \
    "context7" \
    "npx" \
    "-y" "@upstash/context7-mcp@latest" \
    "Context7 文档查询 MCP"

  # playwright — GUI validation tool used by openspec-verifier
  register_mcp_if_missing \
    "playwright" \
    "npx" \
    "-y" "@playwright/mcp@latest" \
    "Playwright GUI 测试 MCP"
else
  echo "  SKIP: npx not found. Install Node.js to enable optional MCP tools."
  echo "        Manually add context7 and playwright MCP servers to ~/.claude/settings.json"
fi

# --- Summary ---
echo ""
echo "Installation complete."
echo ""
echo "Installed to:"
echo "  Claude skills:      $TARGET_DIR/.claude/skills/"
echo "  Claude commands:    $TARGET_DIR/.claude/commands/"
echo "  Codex skills:       $TARGET_DIR/.codex/skills/"
echo "  Shared contracts:   $TARGET_DIR/.orchestra/contracts/commands/"
echo "  Configuration:      $TARGET_DIR/.orchestra/config.json"
echo "  Schema:             $TARGET_DIR/openspec/schemas/opsx-supervised/"
if [ -n "$REGISTERED_MCP" ]; then
  echo "  MCP tools:         $REGISTERED_MCP (registered to ~/.claude/settings.json)"
fi
echo ""
echo "Next steps:"
echo "  1. Edit .orchestra/config.json to customize dispatchers, timeouts, etc."
echo "  2. Run: openspec status (to check project health)"
echo "  3. In Claude: /orchestra-run <change-id> --dispatcher codex"
echo "  4. In Codex: use the orchestra-run skill"
if [ -n "$REGISTERED_MCP" ]; then
  echo "  5. Restart Claude Code for new MCP tools to take effect"
fi
echo ""
echo "To uninstall: bash $(dirname "${BASH_SOURCE[0]}")/uninstall.sh $TARGET_DIR"

