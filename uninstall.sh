#!/usr/bin/env bash
# uninstall.sh — Agent-Orchestra Skills Package Uninstaller
#
# Usage:
#   bash uninstall.sh <target-project-dir>
#
# Removes only the files and directories installed by install.sh.
# Does NOT remove the openspec/ directory or user-created files.
#
set -euo pipefail

TARGET_DIR="${1:-}"

if [ -z "$TARGET_DIR" ]; then
  echo "Usage: bash uninstall.sh <target-project-dir>" >&2
  exit 1
fi

# --- Resolve target directory ---
TARGET_DIR="$(
  python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$TARGET_DIR" 2>/dev/null \
    || realpath "$TARGET_DIR" 2>/dev/null \
    || (cd "$TARGET_DIR" && pwd)
)"

MANIFEST_FILE="$TARGET_DIR/.orchestra/manifest.json"

if [ ! -f "$MANIFEST_FILE" ]; then
  echo "ERROR: No manifest found at $MANIFEST_FILE" >&2
  echo "       Agent-Orchestra does not appear to be installed at $TARGET_DIR" >&2
  exit 1
fi

echo ""
echo "Agent-Orchestra Uninstaller"
echo "==========================="
echo ""
echo "Target: $TARGET_DIR"
echo ""

# --- Read manifest and remove files ---
echo "Removing installed files..."

# Parse files from manifest using python3 for reliable JSON parsing
python3 -c "
import json, os, sys, shutil

target = sys.argv[1]
with open(sys.argv[2]) as f:
    manifest = json.load(f)

removed_files = 0
removed_dirs = 0

# Remove individual files
for rel_path in manifest.get('files', []):
    full_path = os.path.join(target, rel_path)
    if os.path.isfile(full_path):
        os.remove(full_path)
        print(f'  ✓ {rel_path}')
        removed_files += 1

# Remove directories (reverse order to handle nesting)
dirs = sorted(manifest.get('directories', []), key=len, reverse=True)
for rel_path in dirs:
    full_path = os.path.join(target, rel_path)
    if os.path.isdir(full_path):
        shutil.rmtree(full_path)
        print(f'  ✓ {rel_path}/')
        removed_dirs += 1

print(f'\nRemoved {removed_files} files and {removed_dirs} directories.')
" "$TARGET_DIR" "$MANIFEST_FILE"

# --- Remove .orchestra directory ---
echo ""
echo "Removing .orchestra/..."
rm -rf "$TARGET_DIR/.orchestra"

# --- Clean up empty parent directories ---
for dir in "$TARGET_DIR/.claude/commands" "$TARGET_DIR/.claude/skills" "$TARGET_DIR/.codex/skills"; do
  if [ -d "$dir" ] && [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
    rmdir "$dir" 2>/dev/null || true
  fi
done
for dir in "$TARGET_DIR/.claude" "$TARGET_DIR/.codex"; do
  if [ -d "$dir" ] && [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
    rmdir "$dir" 2>/dev/null || true
  fi
done

echo ""
echo "Uninstall complete."
echo ""
echo "Note: openspec/ directory was NOT removed (it belongs to OpenSpec, not Agent-Orchestra)."
echo "      To fully remove OpenSpec, run 'rm -rf $TARGET_DIR/openspec' manually."
