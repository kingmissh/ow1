#!/bin/bash
# reset-config.sh - 回滚配置更改（实际脚本，不只是别名）
# 使用方法: ./scripts/reset-config.sh

set -e

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "🔄 回滚配置更改..."
echo ""

# 检查是否有更改可以回滚
if [ -z "$(git status --porcelain .config-store/ 2>/dev/null)" ]; then
    echo "✨ .config-store/ 没有未提交的更改"
    echo ""
    read -p "是否回滚到上一个提交? (y/n): " rollback
    if [[ $rollback =~ ^[Yy]$ ]]; then
        git checkout HEAD -- .config-store/
        echo "✅ 已回滚到上一个提交"
    else
        echo "⏸️  未执行回滚"
        exit 0
    fi
else
    echo "📦 将丢弃以下更改:"
    git status --short .config-store/
    echo ""
    read -p "确认回滚? (y/n): " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        git checkout .config-store/
        echo "✅ 配置已回滚"
    else
        echo "⏸️  已取消"
        exit 0
    fi
fi
