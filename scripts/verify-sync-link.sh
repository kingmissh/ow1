#!/bin/bash
# verify-sync-link.sh - 验证 Sync-Link 系统是否正常工作
# 使用方法: ./scripts/verify-sync-link.sh

# 加载共享库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO_ROOT=$(get_repo_root)

echo "🔍 Sync-Link 系统验证"
echo "======================"
echo ""

PASS=0
FAIL=0

# 测试 1: 检查目录结构
echo "1. 检查目录结构..."
if [ -d "$REPO_ROOT/.config-store" ]; then
    echo "   ✅ .config-store/ 存在"
    ((PASS++))
else
    echo "   ❌ .config-store/ 不存在"
    ((FAIL++))
fi

# 测试 2: 检查脚本
echo ""
echo "2. 检查核心脚本..."
for script in init-links.sh add-tool.sh save-config.sh reset-config.sh; do
    if [ -x "$REPO_ROOT/scripts/$script" ]; then
        echo "   ✅ $script 可执行"
        ((PASS++))
    else
        echo "   ❌ $script 不存在或不可执行"
        ((FAIL++))
    fi
done

# 测试 3: 检查软链接（从配置文件读取）
echo ""
echo "3. 检查软链接..."

# 从配置文件加载映射
declare -A MAPPING
load_config_mapping MAPPING

for store_name in "${!MAPPING[@]}"; do
    link="${MAPPING[$store_name]}"
    if [ -L "$link" ]; then
        target=$(readlink "$link")
        if [[ "$target" == *".config-store"* ]]; then
            echo "   ✅ $store_name: $link -> $target"
            ((PASS++))
        else
            echo "   ⚠️  $store_name: $link 存在但指向非仓库路径"
            ((FAIL++))
        fi
    else
        echo "   ℹ️  $store_name: $link 未创建（首次运行请先执行 init-links.sh）"
    fi
done

# 测试 4: 检查别名
echo ""
echo "4. 检查快捷命令..."
if grep -q "alias save=" "$HOME/.bashrc" 2>/dev/null; then
    echo "   ✅ save 别名已配置"
    ((PASS++))
else
    echo "   ⚠️  别名未配置（请运行 source ~/.bashrc 或重新登录）"
fi

# 测试 5: 检查 .gitignore
echo ""
echo "5. 检查安全配置..."
if [ -f "$REPO_ROOT/.gitignore" ] && grep -q "credentials/" "$REPO_ROOT/.gitignore"; then
    echo "   ✅ credentials/ 已排除"
    ((PASS++))
else
    echo "   ❌ credentials/ 未在 .gitignore 中排除"
    ((FAIL++))
fi

# 测试 6: 检查 devcontainer.json
echo ""
echo "6. 检查自动化配置..."
if [ -f "$REPO_ROOT/.devcontainer/devcontainer.json" ] && grep -q "init-links.sh" "$REPO_ROOT/.devcontainer/devcontainer.json"; then
    echo "   ✅ devcontainer.json 配置正确"
    ((PASS++))
else
    echo "   ❌ devcontainer.json 未配置 init-links.sh"
    ((FAIL++))
fi

# 总结
echo ""
echo "======================"
echo "验证结果: $PASS 通过, $FAIL 失败"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "🎉 所有检查通过！Sync-Link 系统就绪"
    echo ""
    echo "快速开始:"
    echo "   1. 修改配置（通过工具界面）"
    echo "   2. 运行: ./scripts/save-config.sh 或 save-commit"
    echo "   3. 搞砸了？运行: ./scripts/reset-config.sh 或 reset-config"
    exit 0
else
    echo "⚠️  发现 $FAIL 个问题，请检查上述输出"
    echo ""
    echo "修复建议:"
    if [ ! -d "$REPO_ROOT/.config-store" ]; then
        echo "   - 创建目录: mkdir -p $REPO_ROOT/.config-store"
    fi
    if ! grep -q "alias save=" "$HOME/.bashrc" 2>/dev/null; then
        echo "   - 加载别名: source ~/.bashrc"
    fi
    exit 1
fi
