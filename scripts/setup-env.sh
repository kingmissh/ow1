#!/bin/bash
# setup-env.sh - 一键恢复环境配置
# 使用方法: ./scripts/setup-env.sh

set -e

# 动态识别当前仓库路径
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(cd "$(dirname "$0")" && pwd)")
REPO_STORE="$REPO_ROOT/.config-store"

# 定义配置映射: 存储名称 -> 目标路径
declare -A MAPPING=(
    ["openclaw"]="$HOME/.openclaw"
    ["opencode"]="$HOME/.config/opencode"
)

echo "🚀 开始恢复环境配置..."
echo ""

# 检查仓库目录是否存在
if [ ! -d "$REPO_STORE" ]; then
    echo "❌ 错误: $REPO_STORE 不存在"
    echo "   请先运行 ./scripts/manage-config.sh 纳入配置"
    exit 1
fi

for store_name in "${!MAPPING[@]}"; do
    STORE_PATH="$REPO_STORE/$store_name"
    TARGET="${MAPPING[$store_name]}"

    if [ -d "$STORE_PATH" ]; then
        echo "🔗 正在恢复 $store_name..."
        
        # 确保父目录存在
        mkdir -p "$(dirname "$TARGET")"
        
        # 如果目标已存在，备份它
        if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
            BACKUP="$TARGET.backup.$(date +%s)"
            echo "   📝 备份原配置到 $BACKUP"
            mv "$TARGET" "$BACKUP"
        fi
        
        # 删除现有链接或目录
        rm -rf "$TARGET"
        
        # 建立软链接
        ln -s "$STORE_PATH" "$TARGET"
        echo "   ✅ $TARGET → $STORE_PATH"
    else
        echo "⚠️  $store_name 不存在于仓库中，跳过"
    fi
done

echo ""
echo "🎉 环境恢复完成！"
echo ""
echo "📋 注意事项:"
echo "   • 敏感信息(credentials/等)需要从 GitHub Secrets 恢复"
echo "   • 如需配置 API Key，请运行: opencode auth login"
