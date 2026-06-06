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

就一个 skill：obao-review（自己适应环境 · 有飞书走飞书承载页闭环，没飞书出本地 HTML）。

下一步：
  1. 打开你的 Agent（Claude Code / OpenClaw / Cursor / Codex）
  2. 第一次说「帮我审周报」会先做 onboarding（收角色 + 目标体系 OKR/OGSM 都行 + 红线），之后不再问
  3. 说：帮我审这份飞书周报 <飞书文档链接>
  4. Agent 建一份「目标骨架承载页」、把追问标成评论；你在承载页上改/删/回复后说「可以推送了」，
     它就把认可的评论发回原周报、按你的纠正自学。

没有飞书的话，直接说「帮我审这份周报」+ 贴周报正文，出本地 HTML 审阅页。

如果 Agent 缓存了 skill 列表，重启一次让它生效。
NEXT
