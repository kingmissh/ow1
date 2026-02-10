#!/bin/bash
# add-tool.sh - 将新工具配置纳入 Git 管理
# 使用方法: ./scripts/add-tool.sh <工具名> <配置路径>
# 示例: ./scripts/add-tool.sh opencode .config/opencode

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(cd "$(dirname "$0")" && pwd)")
REPO_STORE="$REPO_ROOT/.config-store"

# 检查参数
if [ $# -lt 2 ]; then
    echo "❌ 用法: ./scripts/add-tool.sh <工具名> <配置路径>"
    echo ""
    echo "示例:"
    echo "  ./scripts/add-tool.sh opencode .config/opencode"
    echo "  ./scripts/add-tool.sh git .config/git"
    echo "  ./scripts/add-tool.sh vim .vimrc        # 单文件"
    echo ""
    echo "当前已管理的工具:"
    ls -1 "$REPO_STORE" 2>/dev/null | grep -v ".gitignore" || echo "  (暂无)"
    exit 1
fi

TOOL_NAME=$1
SOURCE_PATH="$HOME/$2"
STORE_PATH="$REPO_STORE/$TOOL_NAME"

echo "🚀 添加新工具: $TOOL_NAME"
echo "   源路径: $SOURCE_PATH"
echo "   存储路径: $STORE_PATH"
echo ""

# 检查源路径是否存在
if [ ! -e "$SOURCE_PATH" ]; then
    echo "❌ 错误: $SOURCE_PATH 不存在"
    echo "   请先安装并配置该工具"
    exit 1
fi

# 检查是否已是软链接
if [ -L "$SOURCE_PATH" ]; then
    echo "⚠️  $TOOL_NAME 已经是软链接，跳过"
    exit 0
fi

# 备份现有存储
if [ -e "$STORE_PATH" ]; then
    BACKUP="$STORE_PATH.backup.$(date +%s)"
    echo "📝 备份现有存储..."
    mv "$STORE_PATH" "$BACKUP"
fi

# 复制配置到仓库
echo "📦 复制配置到仓库..."
mkdir -p "$STORE_PATH"

if [ -d "$SOURCE_PATH" ]; then
    # 目录模式
    rsync -av --progress \
        --exclude='credentials/' \
        --exclude='identity/' \
        --exclude='*.key' \
        --exclude='*.pem' \
        --exclude='.env' \
        "$SOURCE_PATH/" "$STORE_PATH/"
else
    # 单文件模式
    cp "$SOURCE_PATH" "$STORE_PATH/$(basename "$SOURCE_PATH")"
fi

echo ""

# 删除原配置并建立软链接
echo "🔗 建立软链接..."
rm -rf "$SOURCE_PATH"
ln -s "$STORE_PATH" "$SOURCE_PATH"

echo ""
echo "✅ $TOOL_NAME 已纳入管理！"
echo ""
echo "📋 下一步:"
echo "   1. 检查配置: ls -la $STORE_PATH"
echo "   2. 测试工具: $TOOL_NAME --version"
echo "   3. 提交更改: save-commit"
echo ""
echo "💡 提示: 配置更改会自动同步到 Git"
