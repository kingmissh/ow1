#!/bin/bash
# save-config.sh - 保存配置更改（实际脚本，不只是别名）
# 使用方法: ./scripts/save-config.sh [提交信息]

set -e

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# 自动生成提交信息
if [ -z "$1" ]; then
    MSG="chore: update configs ($(date '+%Y-%m-%d %H:%M'))"
else
    MSG="$1"
fi

echo "💾 保存配置更改..."
echo ""

# 检查是否有更改
if [ -z "$(git status --porcelain .config-store/ 2>/dev/null)" ]; then
    echo "✨ .config-store/ 没有更改"
else
    echo "📦 发现以下更改:"
    git status --short .config-store/
    echo ""
    
    git add .config-store/
    git commit -m "$MSG"
    echo ""
    echo "✅ 已提交: $MSG"
fi

echo ""
read -p "📤 推送到远程? (y/n): " push

if [[ $push =~ ^[Yy]$ ]]; then
    git push
    echo "✅ 已推送！"
else
    echo "⏸️  已保存但未推送，稍后运行: git push"
fi
