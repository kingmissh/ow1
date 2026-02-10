#!/bin/bash
# init-links.sh - 初始化软链接、注入 Secrets、设置别名
# 使用方法: ./scripts/init-links.sh
# 注意: 此脚本在 postCreateCommand 中自动调用

set -e

# 动态识别当前仓库路径
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(cd "$(dirname "$0")" && pwd)")
REPO_STORE="$REPO_ROOT/.config-store"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 初始化 Sync-Link 环境..."
echo "   仓库根目录: $REPO_ROOT"
echo ""

# ==========================================
# 第一部分: 建立软链接
# ==========================================

declare -A MAPPING=(
    ["openclaw"]="$HOME/.openclaw"
    ["opencode"]="$HOME/.config/opencode"
)

for store_name in "${!MAPPING[@]}"; do
    STORE_PATH="$REPO_STORE/$store_name"
    TARGET="${MAPPING[$store_name]}"

    if [ -d "$STORE_PATH" ]; then
        echo "🔗 链接 $store_name..."
        
        mkdir -p "$(dirname "$TARGET")"
        
        # 备份原配置（如果不是链接）
        if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
            BACKUP="$TARGET.backup.$(date +%s)"
            echo "   📝 备份原配置"
            mv "$TARGET" "$BACKUP"
        fi
        
        rm -rf "$TARGET"
        ln -s "$STORE_PATH" "$TARGET"
        echo "   ✅ $TARGET"
    fi
done

echo ""

# ==========================================
# 第二部分: 注入 Secrets
# ==========================================

echo "🔐 注入 Secrets..."

inject_secret() {
    local key_name=$1
    local target_file=$2
    local json_key=$3
    
    if [ ! -z "${!key_name}" ]; then
        mkdir -p "$(dirname "$target_file")"
        echo "{\"$json_key\": \"${!key_name}\"}" > "$target_file"
        chmod 600 "$target_file"
        echo "   ✅ $key_name"
    fi
}

# 注入 API Keys
inject_secret "OPENCODE_API_KEY" "$HOME/.config/opencode/credentials.json" "api_key"
inject_secret "OPENCLAW_API_KEY" "$HOME/.openclaw/credentials/openclaw.json" "api_key"

echo ""

# ==========================================
# 第三部分: 权限防御
# ==========================================

echo "🔒 设置权限..."

# 确保 credentials 目录权限正确
for cred_dir in "$HOME/.openclaw/credentials" "$HOME/.config/opencode"; do
    if [ -d "$cred_dir" ]; then
        chmod 700 "$cred_dir"
        find "$cred_dir" -type f -exec chmod 600 {} \;
        echo "   ✅ $cred_dir (700)"
    fi
done

echo ""

# ==========================================
# 第四部分: 设置别名（关键！让你只关注 Git）
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
alias save-commit='cd $REPO_ROOT && git add .config-store/ && git commit -m "chore: update configs \$(date +%Y-%m-%d-%H:%M)"'
alias reset-config='cd $REPO_ROOT && git checkout .config-store/ && echo "✅ 配置已回滚"'
alias check-links='ls -la ~/.config/opencode ~/.openclaw 2>/dev/null | grep -E "opencode|openclaw"'
alias config-status='cd $REPO_ROOT && git status .config-store/'
# ==========================
EOF
    echo "   ✅ 已添加到 ~/.bashrc"
    echo ""
    echo "   可用快捷命令:"
    echo "      save         - 查看配置更改"
    echo "      save-commit  - 提交配置更改"
    echo "      reset-config - 一键回滚配置"
    echo "      check-links  - 检查软链接状态"
else
    echo "   ℹ️  别名已存在，跳过"
fi

echo ""
echo "🎉 初始化完成！"
echo ""
echo "💡 使用提示:"
echo "   1. 修改配置后运行: save-commit"
echo "   2. 需要回滚时运行: reset-config"
echo "   3. 或直接用 Git:   git checkout .config-store/"
echo ""
echo "⚠️  请运行: source ~/.bashrc 使别名生效"
