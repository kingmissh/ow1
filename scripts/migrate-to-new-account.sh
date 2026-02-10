#!/bin/bash
# migrate-to-new-account.sh - 一键复刻配置到新 GitHub 账号
# 使用方法: NEW_GITHUB_USERNAME='new-name' NEW_REPO_NAME='my-dev-ops' ./scripts/migrate-to-new-account.sh

set -e

echo "🚀 Codespaces 配置迁移工具"
echo "================================"
echo ""

# 检查必要的环境变量
if [ -z "$NEW_GITHUB_USERNAME" ] || [ -z "$NEW_REPO_NAME" ]; then
    echo "❌ 错误: 请设置必要的环境变量"
    echo ""
    echo "用法:"
    echo "  export NEW_GITHUB_USERNAME='your-new-username'"
    echo "  export NEW_REPO_NAME='my-dev-ops'"
    echo "  ./scripts/migrate-to-new-account.sh"
    echo ""
    exit 1
fi

NEW_REPO_URL="https://github.com/$NEW_GITHUB_USERNAME/$NEW_REPO_NAME.git"

echo "📋 迁移配置:"
echo "   原仓库: $(git remote get-url origin 2>/dev/null || echo '未设置')"
echo "   新仓库: $NEW_REPO_URL"
echo ""

# 步骤 1: 检查当前仓库
echo "📦 步骤 1/5: 验证当前仓库..."
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [ ! -d ".config-store" ]; then
    echo "❌ 错误: 当前目录不是配置仓库（缺少 .config-store/）"
    exit 1
fi

echo "   ✅ 当前仓库: $(pwd)"
echo "   ✅ Git 状态:"
git status -s | head -5 || echo "   (工作区干净)"
echo ""

# 步骤 2: 检查敏感信息保护
echo "🔒 步骤 2/5: 验证敏感信息保护..."
if [ ! -f ".gitignore" ]; then
    echo "⚠️  警告: 缺少 .gitignore 文件"
    echo "   正在创建..."
    cat > .gitignore << 'EOF'
# 敏感信息（永不提交）
.config-store/**/credentials/
.config-store/**/identity/
.config-store/**/*.key
.config-store/**/*.pem
.config-store/**/.env

# 临时文件
*.backup.*
*.tmp
*.log
.DS_Store
EOF
    echo "   ✅ 已创建 .gitignore"
else
    echo "   ✅ .gitignore 已存在"
    if grep -q "credentials/" .gitignore; then
        echo "   ✅ credentials/ 已排除"
    else
        echo "⚠️  警告: .gitignore 中未排除 credentials/"
    fi
fi
echo ""

# 步骤 3: 推送到新账号
echo "📤 步骤 3/5: 推送到新仓库..."

# 检查是否已有新账号的 remote
if git remote | grep -q "new-account"; then
    echo "   更新现有 remote 'new-account'..."
    git remote set-url new-account "$NEW_REPO_URL"
else
    echo "   添加新 remote 'new-account'..."
    git remote add new-account "$NEW_REPO_URL"
fi

echo "   推送分支到 new-account..."
if git push new-account main 2>/dev/null || git push new-account master 2>/dev/null; then
    echo "   ✅ 代码已推送到 $NEW_REPO_URL"
else
    echo "❌ 推送失败"
    echo "   请确保:"
    echo "   1. 新账号已创建仓库: $NEW_REPO_NAME"
    echo "   2. 你有新仓库的写入权限"
    echo "   3. 已配置 Git 凭据"
    exit 1
fi
echo ""

# 步骤 4: 验证 Secrets 配置
echo "🔐 步骤 4/5: Secrets 配置检查清单..."
echo ""
echo "⚠️  请手动确认以下 Secrets 已在新账号配置:"
echo ""
echo "   必需 Secrets:"
echo "   □ OPENCODE_API_KEY    - OpenCode API 密钥"
echo "   □ OPENCLAW_API_KEY    - OpenClaw API 密钥（如使用）"
echo ""
echo "   配置路径:"
echo "   1. 登录 GitHub 新账号"
echo "   2. Settings → Codespaces → Secrets"
echo "   3. 添加以上 Secrets"
echo ""

read -p "已完成 Secrets 配置? (y/n): " confirmed
if [[ ! $confirmed =~ ^[Yy]$ ]]; then
    echo ""
    echo "⏸️  迁移暂停"
    echo "   请在配置完成后重新运行此脚本"
    echo "   或者手动完成剩余步骤"
    exit 0
fi
echo ""

# 步骤 5: 生成迁移后操作指南
echo "✅ 步骤 5/5: 迁移完成！"
echo ""
echo "================================"
echo "📋 新账号环境配置步骤:"
echo "================================"
echo ""
echo "1. 在新账号下创建 Codespace:"
echo "   访问: https://github.com/$NEW_GITHUB_USERNAME/$NEW_REPO_NAME"
echo "   点击: 'Code' → 'Codespaces' → 'Create codespace'"
echo ""
echo "2. 运行环境恢复脚本:"
echo "   ./scripts/setup-env.sh"
echo ""
echo "3. 验证配置:"
echo "   ls -la ~/.config/opencode     # 检查软链接"
echo "   opencode --version            # 测试工具"
echo ""
echo "4. 在新项目中使用（子模块模式）:"
echo "   cd /workspaces/new-project"
echo "   git submodule add $NEW_REPO_URL .dev-ops"
echo "   bash .dev-ops/scripts/setup-env.sh"
echo ""
echo "================================"
echo "🔗 重要链接:"
echo "================================"
echo "   新仓库: $NEW_REPO_URL"
echo "   完整文档: $NEW_REPO_URL/blob/main/CROSS_ACCOUNT_MIGRATION.md"
echo ""
echo "🎉 迁移完成！"
echo ""

# 可选：生成迁移报告
REPORT_FILE="migration-report-$(date +%Y%m%d-%H%M%S).txt"
cat > "$REPORT_FILE" << EOF
迁移报告
====================
时间: $(date)
原仓库: $(git remote get-url origin 2>/dev/null || echo 'unknown')
新仓库: $NEW_REPO_URL
状态: 成功

已推送内容:
$(git ls-files | grep -E "^(scripts/|.config-store/|.gitignore)" | head -20)

下一步:
1. 配置 GitHub Secrets
2. 测试新 Codespace
3. 更新其他项目中的配置引用
EOF

echo "📄 迁移报告已保存: $REPORT_FILE"
