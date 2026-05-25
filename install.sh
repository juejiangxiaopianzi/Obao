#!/usr/bin/env bash
set -euo pipefail

# Obao install — copy skill into Claude Code skill folder
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SKILL_SRC="$SCRIPT_DIR/skill"
SKILL_DST="$HOME/.claude/skills/obao-review"

if [[ ! -d "$SKILL_SRC" ]]; then
  echo "ERROR: skill source not found at $SKILL_SRC"
  exit 1
fi

mkdir -p "$(dirname "$SKILL_DST")"

if [[ -d "$SKILL_DST" ]]; then
  echo "Existing obao-review skill found at $SKILL_DST"
  echo "Backing up to ${SKILL_DST}.bak.$(date +%s)"
  mv "$SKILL_DST" "${SKILL_DST}.bak.$(date +%s)"
fi

cp -R "$SKILL_SRC" "$SKILL_DST"
echo "✓ Installed obao-review skill to $SKILL_DST"
echo ""
echo "Next steps:"
echo "  1. Open Claude Code in any terminal"
echo "  2. Type: 帮我审一下这份周报"
echo "  3. If it's your first run, try the demo:"
echo "     cat $SCRIPT_DIR/examples/sample-self-intro.md"
echo "     cat $SCRIPT_DIR/examples/sample-weekly-report.md"
echo "  4. Paste those into Claude and let it run obao-review"
echo ""
echo "✓ Done."
