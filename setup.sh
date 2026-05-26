#!/usr/bin/env bash
set -euo pipefail

# Claude Code skills setup script
# Symlinks each skill from this repo into ~/.claude/skills/
# so they are available as user-level skills across all repositories.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$CLAUDE_SKILLS_DIR"

if [ ! -d "$REPO_DIR/skills" ]; then
  echo "No skills/ directory found in $REPO_DIR"
  exit 1
fi

shopt -s nullglob
skill_dirs=("$REPO_DIR/skills"/*/)
if [ ${#skill_dirs[@]} -eq 0 ]; then
  echo "No skills found in $REPO_DIR/skills/ — nothing to install."
  exit 0
fi

for skill_src in "${skill_dirs[@]}"; do
  skill_name="$(basename "$skill_src")"
  skill_dest="$CLAUDE_SKILLS_DIR/$skill_name"

  # Back up existing non-symlink targets
  if [ -e "$skill_dest" ] && [ ! -L "$skill_dest" ]; then
    backup="$skill_dest.bak.$(date +%Y%m%d%H%M%S)"
    echo "BACKUP $skill_dest -> $backup"
    mv "$skill_dest" "$backup"
  fi

  # Remove existing symlink if it points somewhere else
  if [ -L "$skill_dest" ]; then
    current="$(readlink "$skill_dest")"
    if [ "$current" = "$skill_src" ]; then
      echo "OK     $skill_name (already linked)"
      continue
    fi
    rm "$skill_dest"
  fi

  ln -s "$skill_src" "$skill_dest"
  echo "LINK   $skill_dest -> $skill_src"
done

echo ""
echo "Done. Skills are now symlinked from $REPO_DIR/skills/ into $CLAUDE_SKILLS_DIR/"
echo "Invoke a skill in Claude Code with: /<skill-name>"
