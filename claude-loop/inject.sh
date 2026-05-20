#!/bin/bash
# inject.sh — 将 claude-loop 注入到已有项目
#
# 用法：bash inject.sh <用户名> [项目路径]
# 示例：bash inject.sh alice
#        bash inject.sh alice /path/to/your-project

set -e

USERNAME="$1"
PROJECT_DIR="${2:-.}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/template"

# ── 参数检查 ─────────────────────────────────────────
if [ -z "$USERNAME" ]; then
  echo "用法：bash inject.sh <用户名> [项目路径]"
  echo "示例：bash inject.sh alice"
  exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
  echo "✗ 项目目录不存在：$PROJECT_DIR"
  exit 1
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "✗ 找不到 template 目录，请确保 inject.sh 和 template/ 在同一目录"
  exit 1
fi

USER_DIR="$PROJECT_DIR/.$USERNAME"
CLAUDE_DIR="$PROJECT_DIR/.claude"

echo "▶ 注入 claude-loop"
echo "  用户：$USERNAME"
echo "  项目：$(cd "$PROJECT_DIR" && pwd)"
echo "  隔离目录：.$USERNAME/"
echo ""

# ── Step 1：创建用户隔离目录 ─────────────────────────
if [ -d "$USER_DIR" ]; then
  echo "  ⚠  .$USERNAME/ 已存在，跳过（不覆盖已有内容）"
else
  mkdir -p "$USER_DIR/memory/project" \
           "$USER_DIR/memory/log" \
           "$USER_DIR/workspace"

  for SRC in CLAUDE.md loop.sh; do
    sed "s/{{USERNAME}}/$USERNAME/g" "$TEMPLATE_DIR/$SRC" > "$USER_DIR/$SRC"
  done
  chmod +x "$USER_DIR/loop.sh"

  for SRC in memory/project-index.md memory/errors.md memory/approach.md; do
    sed "s/{{USERNAME}}/$USERNAME/g" "$TEMPLATE_DIR/$SRC" > "$USER_DIR/$SRC"
  done

  echo "  ✓ .$USERNAME/ 创建完成"
fi

# ── Step 2：写入 .claude/ ────────────────────────────
mkdir -p "$CLAUDE_DIR/commands"

# settings.json
SETTINGS="$CLAUDE_DIR/settings.json"
if [ ! -f "$SETTINGS" ]; then
  cp "$TEMPLATE_DIR/.claude/settings.json" "$SETTINGS"
  echo "  ✓ .claude/settings.json 创建完成"
else
  echo "  ⚠  .claude/settings.json 已存在，跳过"
fi

# slash commands
for CMD in explore.md planner.md explore-templates.md; do
  DST="$CLAUDE_DIR/commands/$CMD"
  if [ -f "$DST" ]; then
    echo "  ⚠  .claude/commands/$CMD 已存在，跳过"
  else
    sed "s/{{USERNAME}}/$USERNAME/g" "$TEMPLATE_DIR/.claude/commands/$CMD" > "$DST"
    echo "  ✓ .claude/commands/$CMD 创建完成"
  fi
done

# ── Step 3：更新 .gitignore ──────────────────────────
GITIGNORE="$PROJECT_DIR/.gitignore"
IGNORE_LINE=".$USERNAME/"

if [ -f "$GITIGNORE" ]; then
  if grep -qxF "$IGNORE_LINE" "$GITIGNORE"; then
    echo "  ⚠  .gitignore 已有 .$USERNAME/，跳过"
  else
    printf "\n# claude-loop (%s)\n%s\n" "$USERNAME" "$IGNORE_LINE" >> "$GITIGNORE"
    echo "  ✓ .gitignore 追加 .$USERNAME/"
  fi
else
  printf "# claude-loop (%s)\n%s\n" "$USERNAME" "$IGNORE_LINE" > "$GITIGNORE"
  echo "  ✓ .gitignore 创建完成"
fi

# ── 完成 ─────────────────────────────────────────────
echo ""
echo "✓ 注入完成！"
echo ""
echo "下一步："
echo "  cd $(cd "$PROJECT_DIR" && pwd)"
echo "  claude          # 打开 Claude Code"
echo "  /explore        # 探索问题，草拟验收脚本"
echo "  /planner        # 补全验收脚本"
echo "  bash .$USERNAME/loop.sh 20 .$USERNAME/workspace/<slug>/verify.sh"
