#!/bin/bash
# loop.sh — 自动循环驱动
# 位置：.<username>/loop.sh
#
# 用法：bash .<username>/loop.sh <最大轮数> <verify路径>
# 示例：bash .alice/loop.sh 20 .alice/workspace/fix-check-hint/verify.sh

MAX=${1:-20}
VERIFY="$2"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$BASE_DIR/memory/log"
MAIN_LOG="$LOG_DIR/loop.log"
CLAUDE_MD="$BASE_DIR/CLAUDE.md"
L1_FILE="$BASE_DIR/memory/l1-summary.md"
INDEX_FILE="$BASE_DIR/memory/project-index.md"

# ── 前置检查 ─────────────────────────────────────────
if [ -z "$VERIFY" ]; then
  echo "✗ 请指定 verify 脚本路径"
  echo "  用法：bash $0 <最大轮数> <verify路径>"
  exit 1
fi

if [ ! -f "$VERIFY" ]; then
  echo "✗ 找不到 $VERIFY，请先运行 /planner"
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "✗ 找不到 claude 命令，请先安装 Claude Code CLI"
  exit 1
fi

mkdir -p "$LOG_DIR"

# 初始化 L1（首次使用）
[ ! -f "$L1_FILE" ] && echo "状态：未开始
最近失败：无
关键结论：无
下一步：刚初始化" > "$L1_FILE"

# ── 动态组装 CLAUDE.md ───────────────────────────────
assemble_claude_md() {
  python3 -c "
import re
content = open('$CLAUDE_MD').read()
l1 = open('$L1_FILE').read().strip()
index = open('$INDEX_FILE').read().strip()
content = re.sub(r'<!-- L1_START -->.*?<!-- L1_END -->', '<!-- L1_START -->\n' + l1 + '\n<!-- L1_END -->', content, flags=re.DOTALL)
content = re.sub(r'<!-- PROJECT_INDEX_START -->.*?<!-- PROJECT_INDEX_END -->', '<!-- PROJECT_INDEX_START -->\n' + index + '\n<!-- PROJECT_INDEX_END -->', content, flags=re.DOTALL)
open('$CLAUDE_MD', 'w').write(content)
" 2>/dev/null || true
}

# ── 主循环 ───────────────────────────────────────────
echo "▶ loop 启动（最多 $MAX 轮）"
echo "  verify : $VERIFY"
echo ""

for i in $(seq 1 $MAX); do
  ROUND_LOG="$LOG_DIR/round-$(printf '%03d' $i).log"
  TIMESTAMP=$(date '+%H:%M:%S')

  echo "━━━ Round $i / $MAX  [$TIMESTAMP]" | tee -a "$MAIN_LOG"

  assemble_claude_md

  # Claude 在 session 内自行决定何时运行 verify.sh
  # session 结束后 loop.sh 再做最终判定
  claude --model qwen3.6-plus --dangerously-skip-permissions --print \
    "读取 $CLAUDE_MD 了解当前任务和状态。需要细节时按需读取 memory/ 下对应文件。完成阶段性工作后主动运行 bash $VERIFY 检查进度，根据结果决定继续还是结束。session 结束前覆盖更新 $L1_FILE（不超过 20 行）。" \
    2>&1 | tee "$ROUND_LOG" | tee -a "$MAIN_LOG"

  echo "" | tee -a "$MAIN_LOG"

  # loop.sh 最终判定，客观依据
  if bash "$VERIFY" >> "$MAIN_LOG" 2>&1; then
    echo "✓ 验证通过，共 $i 轮" | tee -a "$MAIN_LOG"
    exit 0
  fi

  echo "  → 未通过，继续下一轮" | tee -a "$MAIN_LOG"
  echo "" | tee -a "$MAIN_LOG"
  sleep 2
done

echo "✗ 达到最大轮数 $MAX" | tee -a "$MAIN_LOG"
echo "  查看 $LOG_DIR/ 了解每轮详情"
exit 1
