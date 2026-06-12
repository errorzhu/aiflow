#!/usr/bin/env bash
set -e

DEST="${1:-$HOME/.local/bin}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📦 安装 tddloop 到 $DEST ..."

mkdir -p "$DEST"

# 创建 tddloop 包装脚本，指向发布包
cat > "$DEST/tddloop" << 'WRAPPER'
#!/usr/bin/env bash
PKG_DIR="__PKG_DIR__"
exec python3 "$PKG_DIR/tddloop.py" "$@"
WRAPPER

sed -i "s|__PKG_DIR__|$SCRIPT_DIR|g" "$DEST/tddloop"
chmod +x "$DEST/tddloop"
echo "✓ $DEST/tddloop"

# 同时创建 tddloop-init 快捷命令
cat > "$DEST/tddloop-init" << 'WRAPPER2'
#!/usr/bin/env bash
PKG_DIR="__PKG_DIR__"
exec python3 "$PKG_DIR/tddloop.py" init "$@"
WRAPPER2

sed -i "s|__PKG_DIR__|$SCRIPT_DIR|g" "$DEST/tddloop-init"
chmod +x "$DEST/tddloop-init"
echo "✓ $DEST/tddloop-init"

# 检查是否在 PATH 中
if ! echo "$PATH" | grep -q "$DEST"; then
    echo ""
    echo "⚠️  $DEST 不在 PATH 中，请添加到 shell 配置："
    echo '    export PATH="'"$DEST"':$PATH"'
fi

echo ""
echo "🎉 安装完成！试试："
echo "    cd ~/my-project && tddloop init"
