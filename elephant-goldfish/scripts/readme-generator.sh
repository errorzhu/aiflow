#!/bin/bash
# =============================================================================
# readme-generator.sh — 递归 README 生成脚本（用于现有代码库）
# Recursive README Generator for Existing Codebases
# 
# 用途：为现有代码库自下而上地生成 README.md 层级体系
# 这让 AI 能用"花生和干草"（压缩的上下文）而不是原始代码来理解系统
#
# 使用方法：
#   chmod +x scripts/readme-generator.sh
#   ./scripts/readme-generator.sh [目标目录] [可选：AI工具]
#
# 依赖：需要 Claude CLI 或其他 AI 工具（可配置）
# =============================================================================

set -e

# 配置
TARGET_DIR="${1:-.}"           # 默认当前目录
AI_TOOL="${2:-claude}"         # 默认使用 claude CLI
MAX_DEPTH="${3:-5}"            # 最大递归深度
DRY_RUN="${DRY_RUN:-false}"    # 设为 true 只打印命令不执行

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}  大象-金鱼 README 递归生成器${NC}"
echo -e "${BLUE}  Elephant-Goldfish README Generator${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""
echo -e "目标目录: ${GREEN}$TARGET_DIR${NC}"
echo -e "AI 工具:  ${GREEN}$AI_TOOL${NC}"
echo -e "最大深度: ${GREEN}$MAX_DEPTH${NC}"
echo ""

# 检查依赖
check_dependencies() {
    if ! command -v find &> /dev/null; then
        echo -e "${RED}错误：找不到 find 命令${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}注意：此脚本生成 AI 提示词供你手动使用。${NC}"
    echo -e "${YELLOW}请按照生成的提示词，在你的 AI 工具中逐步操作。${NC}"
    echo ""
}

# 获取目录深度
get_depth() {
    local dir="$1"
    local base="$2"
    local rel="${dir#$base}"
    echo "${rel//[^\/]}" | wc -c
}

# 检查目录是否有源代码文件
has_source_files() {
    local dir="$1"
    # 排除隐藏目录、node_modules、__pycache__ 等
    find "$dir" -maxdepth 1 \
        -not -path "*/.*" \
        -not -path "*/node_modules/*" \
        -not -path "*/__pycache__/*" \
        -not -name "README.md" \
        -not -name "*.lock" \
        -type f 2>/dev/null | head -1 | grep -q .
}

# 生成叶子节点 README 的提示词
generate_leaf_prompt() {
    local dir="$1"
    local files=$(find "$dir" -maxdepth 1 -type f \
        -not -name "README.md" \
        -not -name "*.lock" \
        -not -path "*/.*" \
        | sort | xargs -I{} basename {})
    
    echo "================================================"
    echo "📁 目录: $dir"
    echo "================================================"
    echo ""
    echo "请在 AI 工具中使用以下提示词："
    echo ""
    echo "---提示词开始---"
    echo "阅读目录 '$dir' 中的文件（${files}）。"
    echo ""
    echo "生成一个名为 README.md 的文件，该文件应："
    echo "(a) 用 1-2 句话解释该目录及其整体目的"
    echo "(b) 列举目录中的每个源文件，并用 1 句话描述其功能"
    echo ""
    echo "格式如下："
    echo "# [目录名]"
    echo ""
    echo "## 目的"
    echo "[1-2句描述]"
    echo ""
    echo "## 文件"
    echo "- \`文件名.py\`: 描述"
    echo "- \`文件名.js\`: 描述"
    echo "---提示词结束---"
    echo ""
    echo "⚠️  人工验证（重要）："
    echo "AI 约有 50% 的错误率，请花 5-10 分钟检查生成的 README.md"
    echo "确认后，继续处理上一级目录"
    echo ""
}

# 生成中间节点 README 的提示词
generate_parent_prompt() {
    local dir="$1"
    local subdirs=$(find "$dir" -maxdepth 1 -type d \
        -not -path "$dir" \
        -not -path "*/.*" \
        -not -name "node_modules" \
        -not -name "__pycache__" \
        | sort | xargs -I{} basename {})
    
    echo "================================================"
    echo "📂 目录: $dir（汇总子目录）"
    echo "================================================"
    echo ""
    echo "请在 AI 工具中使用以下提示词："
    echo ""
    echo "---提示词开始---"
    echo "阅读目录 '$dir' 下所有子目录（${subdirs}）中的 README.md 文件。"
    echo "然后阅读仅属于 '$dir' 本目录（非子目录）的代码文件。"
    echo ""
    echo "在 '$dir/README.md' 创建一个汇总文件，包含："
    echo "(a) 该目录的整体目的（2-3句）"
    echo "(b) 每个子目录的简短描述"
    echo "(c) 该目录本身包含的重要文件（如有）"
    echo "(d) 该模块对外暴露的主要接口/API（如有）"
    echo "---提示词结束---"
    echo ""
}

# 生成根目录验证提示词
generate_root_validation_prompt() {
    local dir="$1"
    echo "================================================"
    echo "🌳 根目录验证"
    echo "================================================"
    echo ""
    echo "所有 README.md 生成完成后，使用以下提示词验证效果："
    echo ""
    echo "---提示词开始---"
    echo "阅读 '$dir' 及所有子目录下的 README.md 文件（不需要阅读源代码）。"
    echo ""
    echo "然后，请告诉我："
    echo "1. 这个系统的主要目的是什么？"
    echo "2. 它的主要功能和特性是什么？（列出 5-10 个）"
    echo "3. 主要组件之间的关系是什么？"
    echo "4. 哪些信息你还不清楚（需要我补充 README 的地方）？"
    echo "---提示词结束---"
    echo ""
    echo "如果 AI 能准确描述系统，说明你的 README 层级体系已经成功！"
    echo ""
}

# 主流程
main() {
    check_dependencies
    
    # 转为绝对路径
    TARGET_DIR=$(realpath "$TARGET_DIR")
    
    echo -e "${GREEN}第一步：从叶子节点开始（最深层的目录）${NC}"
    echo "按以下顺序处理目录（从深到浅）："
    echo ""
    
    # 找出所有需要处理的目录（按深度排序，从深到浅）
    # 排除常见的无关目录
    DIRS=$(find "$TARGET_DIR" -type d \
        -not -path "*/.git/*" \
        -not -path "*/.git" \
        -not -path "*/node_modules/*" \
        -not -path "*/node_modules" \
        -not -path "*/__pycache__/*" \
        -not -path "*/__pycache__" \
        -not -path "*/.venv/*" \
        -not -path "*/.venv" \
        -not -path "*/dist/*" \
        -not -path "*/build/*" \
        -not -path "*/target/*" \
        | sort -r)  # 反向排序 = 从深到浅
    
    STEP=1
    for dir in $DIRS; do
        if has_source_files "$dir" || [ "$dir" = "$TARGET_DIR" ]; then
            # 判断是叶子节点还是中间节点
            subdirs=$(find "$dir" -maxdepth 1 -type d -not -path "$dir" \
                -not -path "*/.*" -not -name "node_modules" \
                2>/dev/null | wc -l)
            
            echo -e "${BLUE}步骤 $STEP${NC}"
            
            if [ "$subdirs" -eq 0 ]; then
                generate_leaf_prompt "$dir"
            elif [ "$dir" = "$TARGET_DIR" ]; then
                generate_parent_prompt "$dir"
            else
                generate_parent_prompt "$dir"
            fi
            
            STEP=$((STEP + 1))
        fi
    done
    
    echo ""
    echo -e "${GREEN}最后一步：验证整体效果${NC}"
    generate_root_validation_prompt "$TARGET_DIR"
    
    echo -e "${GREEN}=================================================${NC}"
    echo -e "${GREEN}  README 生成计划完成！${NC}"
    echo -e "${GREEN}=================================================${NC}"
    echo ""
    echo "预计时间：每个目录约 10-15 分钟（包含人工验证）"
    echo "总目录数：$((STEP - 1))"
    echo ""
    echo "完成后，你的代码库就可以用于大象-金鱼工作流程了！"
}

main
