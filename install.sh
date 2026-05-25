#!/usr/bin/env bash
set -euo pipefail

# Obao install — copies the skill into every supported Agent's skill folder
# Supports: Claude Code · Cursor · Codex CLI / OpenCode

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SKILL_SRC="$SCRIPT_DIR/skill"
SKILL_NAME="obao-review"

if [[ ! -d "$SKILL_SRC" ]]; then
  echo "ERROR: skill source not found at $SKILL_SRC"
  exit 1
fi

# (label · agent_home · target_dir)
TARGETS=(
  "Claude Code|$HOME/.claude|$HOME/.claude/skills/$SKILL_NAME"
  "Cursor|$HOME/.cursor|$HOME/.cursor/skills/$SKILL_NAME"
  "Codex CLI / OpenCode|$HOME/.codex|$HOME/.codex/skills/$SKILL_NAME"
)

installed_any=0
echo "Installing Obao skill ($SKILL_NAME):"
echo ""

for entry in "${TARGETS[@]}"; do
  IFS='|' read -r label home dst <<< "$entry"
  parent="$(dirname "$dst")"

  # Only install if the agent's home dir already exists
  # (i.e. user has actually used this agent before)
  if [[ -d "$home" ]]; then
    mkdir -p "$parent"

    if [[ -d "$dst" ]]; then
      backup="${dst}.bak.$(date +%s)"
      mv "$dst" "$backup"
      echo "  ↻  $label · existing skill backed up → $backup"
    fi

    cp -R "$SKILL_SRC" "$dst"
    echo "  ✓  $label · installed to $dst"
    installed_any=1
  else
    echo "  ⊘  $label · skipped (no $home/ found — you don't seem to use this agent)"
  fi
done

echo ""

if [[ $installed_any -eq 0 ]]; then
  echo "⚠️  No supported Agent home found on this machine."
  echo ""
  echo "Install at least one of:"
  echo "    - Claude Code:  https://claude.com/claude-code"
  echo "    - Cursor:       https://cursor.com"
  echo "    - Codex CLI:    https://github.com/openai/codex"
  echo ""
  echo "Then re-run this script."
  exit 1
fi

cat <<'NEXT'
✓ Done.

Next steps:
  1. Open your Agent (Claude Code / Cursor / Codex CLI)
  2. Type: 帮我审一下这份周报
  3. On first run, try the demo:
     - examples/sample-self-intro.md
     - examples/sample-weekly-report.md
     Paste those into the agent and let it run obao-review.

If your agent has cached its skill list, restart it once so the new skill is picked up.
NEXT
