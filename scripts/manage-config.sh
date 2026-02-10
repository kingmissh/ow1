#!/bin/bash
# manage-config.sh - 将现有配置纳入 Git 管理
# 使用方法: ./scripts/manage-config.sh

set -e

# 动态识别当前仓库路径
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(cd "$(dirname "$0")" && pwd)")
REPO_STORE="$REPO_ROOT/.config-store"

# 定义需要管理的配置列表 (路径相对于 $HOME)
# 格式: "源路径:存储名称"
declare -A CONFIGS=(
    [".openclaw"]="openclaw"
    [".config/opencode"]="opencode"
)
mkdir -p "$REPO_STORE"

echo "🚀 开始纳入配置管理..."
echo ""

for source_path in "${!CONFIGS[@]}"; do
    store_name="${CONFIGS[$source_path]}"
    TARGET="$HOME/$source_path"
    STORE_PATH="$REPO_STORE/$store_name"

    if [ -e "$TARGET" ]; then
        if [ -L "$TARGET" ]; then
            echo "⚠️  $source_path 已经是软链接，跳过"
            continue
        fi

        echo "📦 正在将 $source_path 纳入 Git 管理..."
        
        # 如果存储目录已存在，先备份
        if [ -e "$STORE_PATH" ]; then
            BACKUP="$STORE_PATH.backup.$(date +%s)"
            echo "   📝 备份现有存储到 $BACKUP"
            mv "$STORE_PATH" "$BACKUP"
        fi

        # 复制到仓库 (排除敏感目录)
        mkdir -p "$STORE_PATH"
        rsync -av --progress \
            --exclude='credentials/' \
            --exclude='identity/' \
            --exclude='*.key' \
            --exclude='*.pem' \
            --exclude='.env' \
            "$TARGET/" "$STORE_PATH/"

        # 删除原目录/文件并建立软链接
        rm -rf "$TARGET"
        ln -s "$STORE_PATH" "$TARGET"
        
        echo "   ✅ $source_path → $STORE_PATH"
        echo ""
    else
        echo "⚠️  $source_path 不存在，跳过"
    fi
done

echo "🎉 配置纳入完成！"
echo ""
echo "📋 下一步:"
echo "   1. 检查 .config-store/ 内容"
echo "   2. git add .config-store/"
echo "   3. git commit -m 'feat: add tool configurations'"
