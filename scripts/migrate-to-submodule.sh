#!/bin/bash
# migrate-to-submodule.sh - 从本地配置迁移到子模块模式
# 使用方法: ./scripts/migrate-to-submodule.sh

set -e

echo "🚀 迁移到子模块模式"
echo "===================="
echo ""

# 检查当前目录
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [ ! -d ".dev-ops" ]; then
    echo "❌ 错误: .dev-ops 子模块不存在"
    echo "   请先运行: git submodule update --init --recursive"
    exit 1
fi

echo "📋 迁移计划:"
echo "   1. 备份本地配置"
echo "   2. 删除本地脚本和配置目录"
echo "   3. 使用子模块中的配置"
echo ""

read -p "确认迁移? (y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "⏸️  已取消"
    exit 0
fi

echo ""
echo "📦 步骤 1/3: 备份本地配置..."
BACKUP_DIR="config-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 备份现有配置
if [ -d ".config-store" ]; then
    cp -r .config-store "$BACKUP_DIR/"
    echo "   ✅ .config-store/ 已备份"
fi

if [ -d "scripts" ]; then
    cp -r scripts "$BACKUP_DIR/"
    echo "   ✅ scripts/ 已备份"
fi

if [ -f ".config-mapping" ]; then
    cp .config-mapping "$BACKUP_DIR/"
    echo "   ✅ .config-mapping 已备份"
fi

echo "   备份位置: $(pwd)/$BACKUP_DIR"
echo ""

echo "🗑️  步骤 2/3: 删除本地文件..."
# 删除本地配置（保留备份）
rm -rf scripts/
rm -rf .config-store/
rm -f .config-mapping

echo "   ✅ 本地配置已删除"
echo ""

echo "🔗 步骤 3/3: 初始化子模块配置..."
# 初始化子模块
bash .dev-ops/scripts/init-links.sh

echo ""
echo "===================="
echo "🎉 迁移完成！"
echo "===================="
echo ""
echo "📋 新的使用方式:"
echo "   管理配置: cd .dev-ops && ./scripts/add-tool.sh ..."
echo "   保存配置: cd .dev-ops && ./scripts/save-config.sh"
echo "   初始化:   bash .dev-ops/scripts/init-links.sh"
echo ""
echo "📂 备份位置: $(pwd)/$BACKUP_DIR"
echo "   如果迁移有问题，可以从备份恢复"
echo ""
echo "💡 提示:"
echo "   - 子模块配置在 .dev-ops/ 目录"
echo "   - ow1 现在是干净的开发仓库"
echo "   - 重建 Codespace 时会自动拉取子模块"
