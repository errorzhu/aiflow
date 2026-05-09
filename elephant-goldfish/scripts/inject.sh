#!/bin/bash
# =============================================================================
# inject.sh — 将大象-金鱼框架注入任意项目
# Inject Elephant-Goldfish framework into any project
#
# 使用方法：
#   ./inject.sh [目标项目路径] [可选：目录名，默认 .ai-assist]
#
# 效果：
#   - 所有框架文件放入 <project>/.ai-assist/（不影响项目结构）
#   - 在项目根写一个最小 CLAUDE.md（只有3行，指向框架目录）
#   - 如果项目根已有 CLAUDE.md，备份后追加跳转指令，不覆盖
#
# 卸载：
#   ./inject.sh --eject [目标项目路径]
# =============================================================================

set -e

# ── 颜色 ──────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── 参数解析 ──────────────────────────────────────────────────────────────────
EJECT_MODE=false
if [[ "$1" == "--eject" ]]; then
    EJECT_MODE=true
    shift
fi

TARGET_PROJECT="${1:-$(pwd)}"
NAMESPACE="${2:-.ai-assist}"          # 隐藏目录名，用户可自定义

# ── 路径计算 ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"   # inject.sh 的上级 = 框架根
TARGET_PROJECT="$(realpath "$TARGET_PROJECT")"
INJECT_DIR="$TARGET_PROJECT/$NAMESPACE"
TARGET_CLAUDE_MD="$TARGET_PROJECT/CLAUDE.md"

# ══════════════════════════════════════════════════════════════════════════════
# EJECT 模式 — 卸载框架
# ══════════════════════════════════════════════════════════════════════════════
if $EJECT_MODE; then
    echo -e "${YELLOW}🗑  卸载模式 / Eject Mode${NC}"
    echo -e "目标项目: ${CYAN}$TARGET_PROJECT${NC}"
    echo ""

    # 删除注入目录
    if [ -d "$INJECT_DIR" ]; then
        rm -rf "$INJECT_DIR"
        echo -e "${GREEN}✓ 已删除 $NAMESPACE/${NC}"
    else
        echo -e "${YELLOW}⚠ 未找到 $NAMESPACE/，跳过${NC}"
    fi

    # 恢复 CLAUDE.md 备份（如果有）
    BACKUP="$TARGET_CLAUDE_MD.before-inject"
    if [ -f "$BACKUP" ]; then
        mv "$BACKUP" "$TARGET_CLAUDE_MD"
        echo -e "${GREEN}✓ 已恢复原始 CLAUDE.md${NC}"
    elif [ -f "$TARGET_CLAUDE_MD" ]; then
        # 检查是否是我们生成的跳转文件（第一行有标记）
        if head -1 "$TARGET_CLAUDE_MD" | grep -q "elephant-goldfish-inject"; then
            rm "$TARGET_CLAUDE_MD"
            echo -e "${GREEN}✓ 已删除注入的 CLAUDE.md${NC}"
        else
            echo -e "${YELLOW}⚠ CLAUDE.md 似乎已被修改，保留不动${NC}"
        fi
    fi

    echo ""
    echo -e "${GREEN}✅ 卸载完成${NC}"
    exit 0
fi

# ══════════════════════════════════════════════════════════════════════════════
# INJECT 模式 — 注入框架
# ══════════════════════════════════════════════════════════════════════════════
echo -e "${BLUE}${BOLD}"
echo "╔══════════════════════════════════════════════════╗"
echo "║  🐘🐟 大象-金鱼框架注入器                       ║"
echo "║  Elephant-Goldfish Framework Injector            ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "框架来源:  ${CYAN}$FRAMEWORK_ROOT${NC}"
echo -e "目标项目:  ${CYAN}$TARGET_PROJECT${NC}"
echo -e "注入目录:  ${CYAN}$NAMESPACE/${NC}"
echo ""

# ── 确认 ──────────────────────────────────────────────────────────────────────
read -p "$(echo -e ${YELLOW}"确认注入？(y/N) "${NC})" confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "已取消。"
    exit 0
fi
echo ""

# ── Step 1：创建注入目录 ───────────────────────────────────────────────────────
echo -e "${BOLD}Step 1/4  创建框架目录${NC}"

mkdir -p "$INJECT_DIR/docs"
mkdir -p "$INJECT_DIR/commands"    # 对应 .claude/commands，放在命名空间下

echo -e "  ${GREEN}✓${NC} $NAMESPACE/"
echo -e "  ${GREEN}✓${NC} $NAMESPACE/docs/"
echo -e "  ${GREEN}✓${NC} $NAMESPACE/commands/"

# ── Step 2：复制框架文件（路径引用自动替换为命名空间） ─────────────────────────
echo ""
echo -e "${BOLD}Step 2/4  复制框架文件${NC}"

# 辅助：复制并替换内部路径引用
copy_and_patch() {
    local src="$1"
    local dst="$2"
    # 将框架内路径引用 (.claude/commands/, docs/, scripts/) 替换为命名空间路径
    sed \
        -e "s|\.claude/commands/|$NAMESPACE/commands/|g" \
        -e "s|docs/|$NAMESPACE/docs/|g" \
        -e "s|scripts/readme-generator\.sh|$NAMESPACE/readme-generator.sh|g" \
        -e "s|claude-progress\.md|$NAMESPACE/claude-progress.md|g" \
        -e "s|feature_list\.json|$NAMESPACE/feature_list.json|g" \
        "$src" > "$dst"
}

# --- CLAUDE.md（框架主文档，放进命名空间，路径打补丁）
copy_and_patch "$FRAMEWORK_ROOT/CLAUDE.md" "$INJECT_DIR/CLAUDE.md"
echo -e "  ${GREEN}✓${NC} $NAMESPACE/CLAUDE.md"

# --- 进度 & 功能列表
cp "$FRAMEWORK_ROOT/claude-progress.md" "$INJECT_DIR/claude-progress.md"
cp "$FRAMEWORK_ROOT/feature_list.json"  "$INJECT_DIR/feature_list.json"
echo -e "  ${GREEN}✓${NC} $NAMESPACE/claude-progress.md"
echo -e "  ${GREEN}✓${NC} $NAMESPACE/feature_list.json"

# --- 设计文档
cp "$FRAMEWORK_ROOT/docs/elephant-goldfish-model.md" "$INJECT_DIR/docs/elephant-goldfish-model.md"
echo -e "  ${GREEN}✓${NC} $NAMESPACE/docs/elephant-goldfish-model.md"

# --- readme-generator 脚本（放进命名空间，不污染 scripts/）
cp "$FRAMEWORK_ROOT/scripts/readme-generator.sh" "$INJECT_DIR/readme-generator.sh"
chmod +x "$INJECT_DIR/readme-generator.sh"
echo -e "  ${GREEN}✓${NC} $NAMESPACE/readme-generator.sh"

# --- 斜杠命令（路径打补丁后复制）
# Claude Code 识别 .claude/commands/ — 我们同时放一份到项目级 .claude/commands/
REAL_COMMANDS_DIR="$TARGET_PROJECT/.claude/commands"
mkdir -p "$REAL_COMMANDS_DIR"

for cmd_src in "$FRAMEWORK_ROOT"/.claude/commands/*.md; do
    cmd_name="$(basename "$cmd_src")"
    # 写进命名空间（存档/可读）
    copy_and_patch "$cmd_src" "$INJECT_DIR/commands/$cmd_name"
    # 写进 .claude/commands/（Claude Code 识别）
    copy_and_patch "$cmd_src" "$REAL_COMMANDS_DIR/$cmd_name"
    echo -e "  ${GREEN}✓${NC} $NAMESPACE/commands/$cmd_name  →  .claude/commands/$cmd_name"
done

# ── Step 3：处理根目录 CLAUDE.md ───────────────────────────────────────────────
echo ""
echo -e "${BOLD}Step 3/4  配置根目录 CLAUDE.md${NC}"

INJECT_MARKER="elephant-goldfish-inject"   # 标记行，用于识别是否是我们生成的

if [ -f "$TARGET_CLAUDE_MD" ]; then
    # 已存在：备份，然后追加跳转块
    cp "$TARGET_CLAUDE_MD" "$TARGET_CLAUDE_MD.before-inject"
    echo -e "  ${YELLOW}⚠${NC} 已有 CLAUDE.md，备份至 CLAUDE.md.before-inject"

    cat >> "$TARGET_CLAUDE_MD" << EOF

---
<!-- $INJECT_MARKER -->
## 🐘🐟 AI 工作框架 (Elephant-Goldfish)

所有 AI 工作流文件位于 \`$NAMESPACE/\`，请先阅读：

> 📖 阅读 \`$NAMESPACE/CLAUDE.md\` 获取完整的 Agent 操作手册。
> 📋 阅读 \`$NAMESPACE/claude-progress.md\` 了解当前进度。
> 📦 阅读 \`$NAMESPACE/feature_list.json\` 查看功能状态。
EOF
    echo -e "  ${GREEN}✓${NC} 已追加跳转指令到现有 CLAUDE.md"

else
    # 不存在：生成最小跳转文件
    cat > "$TARGET_CLAUDE_MD" << EOF
<!-- $INJECT_MARKER -->
# AI 工作框架入口 / AI Workflow Entry

本项目使用大象-金鱼框架管理 AI 辅助开发流程。所有框架文件位于 \`$NAMESPACE/\`。

## 启动步骤

1. 阅读 \`$NAMESPACE/CLAUDE.md\` — 完整操作手册
2. 阅读 \`$NAMESPACE/claude-progress.md\` — 当前进度
3. 阅读 \`$NAMESPACE/feature_list.json\` — 功能状态
4. 使用斜杠命令开始工作（见 .claude/commands/）

> 此文件由 inject.sh 自动生成，请勿手动修改核心内容。
> 如需卸载：运行 \`inject.sh --eject $TARGET_PROJECT\`
EOF
    echo -e "  ${GREEN}✓${NC} 已生成最小跳转 CLAUDE.md"
fi

# ── Step 4：更新 .gitignore（可选） ───────────────────────────────────────────
echo ""
echo -e "${BOLD}Step 4/4  更新 .gitignore${NC}"

GITIGNORE="$TARGET_PROJECT/.gitignore"
GITIGNORE_ENTRIES=(
    ""
    "# 大象-金鱼框架（AI 工作流，不提交到仓库）"
    "$NAMESPACE/"
    "CLAUDE.md.before-inject"
)

if [ -f "$GITIGNORE" ]; then
    # 检查是否已有条目
    if grep -q "$NAMESPACE/" "$GITIGNORE" 2>/dev/null; then
        echo -e "  ${YELLOW}⚠${NC} .gitignore 已包含 $NAMESPACE/，跳过"
    else
        read -p "$(echo -e "  ${YELLOW}是否将 $NAMESPACE/ 添加到 .gitignore？(Y/n) ${NC}")" gi_confirm
        if [[ ! "$gi_confirm" =~ ^[Nn]$ ]]; then
            printf '%s\n' "${GITIGNORE_ENTRIES[@]}" >> "$GITIGNORE"
            echo -e "  ${GREEN}✓${NC} 已添加到 .gitignore"
        else
            echo -e "  ${YELLOW}⚠${NC} 跳过 .gitignore 更新"
        fi
    fi
else
    read -p "$(echo -e "  ${YELLOW}未找到 .gitignore，是否创建？(Y/n) ${NC}")" gi_create
    if [[ ! "$gi_create" =~ ^[Nn]$ ]]; then
        printf '%s\n' "${GITIGNORE_ENTRIES[@]}" > "$GITIGNORE"
        echo -e "  ${GREEN}✓${NC} 已创建 .gitignore"
    fi
fi

# ── 完成摘要 ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════╗"
echo "║  ✅ 注入完成！                                   ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "项目目录变化（最小化）："
echo -e "  ${CYAN}新增${NC} $NAMESPACE/          ← 所有框架文件"
echo -e "  ${CYAN}新增${NC} .claude/commands/    ← Claude Code 斜杠命令"
echo -e "  ${CYAN}新增/修改${NC} CLAUDE.md       ← 最小跳转入口"
echo ""
echo -e "可用斜杠命令："
echo -e "  ${BOLD}/design-start${NC}    开始新功能设计讨论"
echo -e "  ${BOLD}/design-draft${NC}    生成设计文档"
echo -e "  ${BOLD}/goldfish-test${NC}   理解力测试"
echo -e "  ${BOLD}/goldfish-critic${NC} 批评者审查"
echo -e "  ${BOLD}/goldfish-ready${NC}  就绪检查"
echo -e "  ${BOLD}/implement${NC}       按文档实施编码"
echo -e "  ${BOLD}/code-review${NC}     毒舌代码评审"
echo -e "  ${BOLD}/done${NC}            会话结束更新进度"
echo ""
echo -e "卸载命令："
echo -e "  ${CYAN}$(realpath "$FRAMEWORK_ROOT/scripts/inject.sh") --eject $TARGET_PROJECT${NC}"
echo ""
echo -e "下一步：用 Claude Code 打开 ${CYAN}$TARGET_PROJECT${NC}，输入 ${BOLD}/design-start${NC} 开始！"
