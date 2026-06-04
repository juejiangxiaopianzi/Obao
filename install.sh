#!/usr/bin/env bash
set -euo pipefail

# Obao install — copies every skill in ./skills/ into each supported Agent's skill folder.
# Supports: Claude Code · Cursor · Codex CLI / OpenCode · OpenClaw · Generic (~/.agents)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SKILLS_SRC="$SCRIPT_DIR/skills"

if [[ ! -d "$SKILLS_SRC" ]]; then
  echo "ERROR: skills source not found at $SKILLS_SRC"
  exit 1
fi

# (label · agent_home · skills_dir)
TARGETS=(
  "Claude Code|$HOME/.claude|$HOME/.claude/skills"
  "Cursor|$HOME/.cursor|$HOME/.cursor/skills"
  "Codex CLI|$HOME/.codex|$HOME/.codex/skills"
  "OpenClaw|$HOME/.openclaw|$HOME/.openclaw/skills"
  "Generic Agents (~/.agents)|$HOME/.agents|$HOME/.agents/skills"
)

# skills to install
SKILLS=()
for d in "$SKILLS_SRC"/*/; do
  [[ -d "$d" ]] && SKILLS+=( "$(basename "$d")" )
done

echo "Installing Obao skills: ${SKILLS[*]}"
echo ""

installed_any=0
for entry in "${TARGETS[@]}"; do
  IFS='|' read -r label home skills_dir <<< "$entry"
  # Only install if the agent's home dir already exists (i.e. you use this agent)
  if [[ -d "$home" ]]; then
    mkdir -p "$skills_dir"
    for s in "${SKILLS[@]}"; do
      dst="$skills_dir/$s"
      [[ -d "$dst" ]] && rm -rf "$dst"   # hard overwrite, no stale backups
      cp -R "$SKILLS_SRC/$s" "$dst"
    done
    echo "  ✓  $label · installed ${#SKILLS[@]} skill(s) → $skills_dir/"
    installed_any=1
  else
    echo "  ⊘  $label · skipped (no $home/ found)"
  fi
done

echo ""

if [[ $installed_any -eq 0 ]]; then
  echo "⚠️  No supported Agent home found. Install one of:"
  echo "    Claude Code https://claude.com/claude-code · Cursor https://cursor.com · Codex https://github.com/openai/codex"
  exit 1
fi

cat <<'NEXT'
✓ Done.

Two skills installed:
  • obao-feishu-loop  ← 主推：完全基于飞书文档的周报审阅闭环（副本当承载页·可改可纠正·自学）
                        需要 lark-cli + 飞书账号
  • obao-review       ← 兜底：没有飞书时，生成一份本地 HTML 审阅页

下一步（飞书闭环）：
  1. 打开你的 Agent（Claude Code / OpenClaw / Cursor / Codex）
  2. 说：帮我审这份飞书周报 <飞书文档链接>
  3. Agent 会复制一份副本、把追问标成划词评论；你在副本上改/删/回复后说「可以推送了」，
     它就把认可的评论发回原周报、按你的纠正自学、再删掉副本。

没有飞书的话，直接说「帮我审这份周报」+ 贴周报正文，走 obao-review 出本地 HTML。

如果 Agent 缓存了 skill 列表，重启一次让它生效。
NEXT
