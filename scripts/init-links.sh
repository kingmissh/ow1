#!/bin/bash
# init-links.sh - 初始化软链接、注入 Secrets、设置别名
# 使用方法: ./scripts/init-links.sh
# 注意: 此脚本在 postCreateCommand 中自动调用

set -e

# 加载共享库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO_ROOT=$(get_repo_root)
REPO_STORE=$(get_repo_store)

echo "🚀 初始化 Sync-Link 环境..."
echo "   仓库根目录: $REPO_ROOT"
echo ""

# ==========================================
# 第一部分: 建立软链接（从配置文件读取）
# ==========================================

echo "🔗 建立软链接..."

# 检查依赖
check_dependencies "git" || exit 1

# 从配置文件加载映射
declare -A MAPPING
load_config_mapping MAPPING

# 建立链接
for store_name in "${!MAPPING[@]}"; do
    STORE_PATH="$REPO_STORE/$store_name"
    TARGET="${MAPPING[$store_name]}"
    
    if [ -d "$STORE_PATH" ]; then
        echo "   链接 $store_name..."
        create_symlink "$STORE_PATH" "$TARGET" "$store_name"
        
        # 自动设置权限（如果是 credentials 目录）
        if [[ "$TARGET" == *"credentials"* ]] && [ -d "$TARGET" ]; then
            tighten_permissions "$TARGET"
        fi
    fi
done

echo ""

# ==========================================
# 第二部分: 注入 Secrets
# ==========================================

echo "🔐 注入 Secrets..."

inject_secret "OPENCODE_API_KEY" "$HOME/.config/opencode/credentials.json" "api_key"
inject_secret "OPENCLAW_API_KEY" "$HOME/.openclaw/credentials/openclaw.json" "api_key"

echo ""

# ==========================================
# 第三部分: 权限防御（已在链接时设置）
# ==========================================

echo "🔒 权限检查完成"
echo ""

# ==========================================
# 第四部分: 设置别名（可选增强）
# ==========================================

echo "⚡ 配置快捷命令..."

BASHRC="$HOME/.bashrc"
ALIASES_MARKER="# === Sync-Link Aliases ==="

# 检查是否已存在标记
if ! grep -q "$ALIASES_MARKER" "$BASHRC" 2>/dev/null; then
    cat >> "$BASHRC" << EOF

$ALIASES_MARKER
# 配置管理快捷命令 - 自动同步到 Git
alias save='cd $REPO_ROOT && git add .config-store/ && git status .config-store/'
alias save-commit='bash $REPO_ROOT/scripts/save-config.sh'
alias reset-config='bash $REPO_ROOT/scripts/reset-config.sh'
alias check-links='ls -la ~/.config/opencode ~/.openclaw 2>/dev/null | grep -E "opencode|openclaw"'
alias config-status='cd $REPO_ROOT && git status .config-store/'
# ==========================
EOF
    echo "   ✅ 已添加到 ~/.bashrc"
    echo ""
    echo "   可用快捷命令:"
    echo "      save         - 查看配置更改"
    echo "      save-commit  - 提交配置更改 (也可直接运行脚本)"
    echo "      reset-config - 一键回滚配置 (也可直接运行脚本)"
else
    echo "   ℹ️  别名已存在，跳过"
fi

echo ""
echo "🎉 初始化完成！"
echo ""
echo "💡 使用提示:"
echo "   1. 修改配置后运行: ./scripts/save-config.sh 或 save-commit"
echo "   2. 需要回滚时运行: ./scripts/reset-config.sh 或 reset-config"
echo "   3. 或直接用 Git:    git checkout .config-store/"
echo ""
echo "⚠️  请运行: source ~/.bashrc 使别名生效"
