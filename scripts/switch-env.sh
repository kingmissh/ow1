#!/bin/bash
# switch-env.sh - 切换环境配置（使用 Git 分支）
# 使用方法: ./scripts/switch-env.sh <分支名>

set -e

if [ -z "$1" ]; then
    echo "❌ 用法: ./scripts/switch-env.sh <分支名>"
    echo ""
    echo "可用分支:"
    git branch -a | grep "env/" || echo "   (无环境分支)"
    exit 1
fi

BRANCH="$1"

echo "🔄 切换到环境: $BRANCH"
echo ""

# 检查分支是否存在
if ! git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "❌ 分支 $BRANCH 不存在"
    echo ""
    echo "创建新环境分支:"
    echo "   git checkout -b $BRANCH"
    exit 1
fi

# 切换分支
git checkout "$BRANCH"

# 重新建立链接（因为切换分支可能改变了 .config-store 内容）
echo "🔗 重新建立配置链接..."
SCRIPT_DIR="$(dirname "$0")"
"$SCRIPT_DIR/setup-env.sh"

echo ""
echo "✅ 已切换到 $BRANCH 环境"
