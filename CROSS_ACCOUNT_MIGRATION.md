# 🏗️ Codespaces 配置管理中心化体系

> **核心理念**: 配置中心化，应用链接化  
> **目标**: 通过 GitHub Codespaces 的持久化层（Layer 1）对抗系统层（Layer 2）的不确定性

---

## 📖 文档导航

- [架构设计](#架构设计) - 三层数据模型与目录结构
- [核心脚本](#核心脚本) - 2 个核心脚本 + 快捷命令
- [快速开始](#快速开始) - 首次配置指南
- [标准操作流程](#标准操作流程-sop) - 4 大场景操作手册
- [跨账号迁移](#跨账号迁移指南) - 多账号/团队协作方案
- [故障排除](#故障排除) - 常见问题与解决方案

---

## 架构设计

### 三层数据模型

```
┌─────────────────────────────────────────────────────────────────┐
│  🔴 Layer 3: 临时层 (Ephemeral)                                  │
│  /usr/bin, /etc/, /tmp/                                         │
│  → 随容器重建完全重置                                            │
├─────────────────────────────────────────────────────────────────┤
│  🟡 Layer 2: 系统层 (System)                                     │
│  /home/codespace/.local/, ~/.npm/, ~/.cache/                    │
│  → 可选持久化，存在不确定性                                       │
├─────────────────────────────────────────────────────────────────┤
│  🟢 Layer 1: 持久化层 (Persistent)  ⭐ 核心资产                  │
│  /workspaces/ow1/, /home/codespace/.config/                     │
│  → 与 Git 仓库同步，可跨环境复刻                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 目录结构

```
ow1/                                        # 项目仓库（Layer 1）
├── .config-store/                          # ⭐ 配置保险箱
│   ├── openclaw/                          # → 链接到 ~/.openclaw/
│   ├── opencode/                          # → 链接到 ~/.config/opencode/
│   ├── git/                               # → 链接到 ~/.config/git/
│   └── .gitignore                         # 敏感信息排除规则
├── scripts/                               # 环境管理脚本
│   ├── add-tool.sh                   # 将配置纳入 Git 管理
│   ├── init-links.sh                       # 一键恢复环境
│   ├── save-config.sh                     # 保存配置更改
│   └── switch-env.sh                      # 切换环境分支
├── .devcontainer/
│   └── devcontainer.json                  # Codespaces 配置
└── CROSS_ACCOUNT_MIGRATION.md             # 跨账号迁移指南（本文档）
```

### 软链接工作原理

```
┌─────────────────────────────────────────────────────────────┐
│  Git 仓库 (.config-store/)                                   │
│  ├─ opencode/          ← 配置文件实际存储位置（Layer 1）     │
│  ├─ openclaw/                                               │
│  └─ .gitignore       ← 排除敏感信息                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 软链接 (Symbolic Link)
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  系统路径 (~/.config/opencode/)                              │
│  → 实际指向 .config-store/opencode/                         │
│  → 应用程序无感知，实时同步                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 核心脚本

### 脚本 A: add-tool.sh（纳入管理）

**用途**: 将现有配置从 `~/.config/` 移动到 `.config-store/`，并建立软链接

```bash
#!/bin/bash
# add-tool.sh - 将现有配置纳入 Git 管理

set -e

# 定义需要管理的配置列表 (路径相对于 $HOME)
declare -A CONFIGS=(
    [".openclaw"]="openclaw"
    [".config/opencode"]="opencode"
    [".config/git"]="git"
)

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "/workspaces/ow1")
REPO_STORE="$REPO_ROOT/.config-store"
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
        
        # 备份现有存储
        if [ -e "$STORE_PATH" ]; then
            BACKUP="$STORE_PATH.backup.$(date +%s)"
            echo "   📝 备份现有存储到 $BACKUP"
            mv "$STORE_PATH" "$BACKUP"
        fi

        # 复制到仓库（排除敏感目录）
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
```

### 脚本 B: init-links.sh（一键恢复）

**用途**: 从 `.config-store/` 恢复软链接，自动注入 Secrets

```bash
#!/bin/bash
# init-links.sh - 一键恢复环境配置

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
REPO_STORE="$REPO_ROOT/.config-store"

# 定义配置映射: 存储名称 -> 目标路径
declare -A MAPPING=(
    ["openclaw"]="$HOME/.openclaw"
    ["opencode"]="$HOME/.config/opencode"
    ["git"]="$HOME/.config/git"
)

echo "🚀 开始恢复环境配置..."
echo ""

# 检查仓库目录是否存在
if [ ! -d "$REPO_STORE" ]; then
    echo "❌ 错误: $REPO_STORE 不存在"
    echo "   请先运行 ./scripts/add-tool.sh 纳入配置"
    exit 1
fi

for store_name in "${!MAPPING[@]}"; do
    STORE_PATH="$REPO_STORE/$store_name"
    TARGET="${MAPPING[$store_name]}"

    if [ -d "$STORE_PATH" ]; then
        echo "🔗 正在恢复 $store_name..."
        
        # 确保父目录存在
        mkdir -p "$(dirname "$TARGET")"
        
        # 如果目标已存在且不是链接，备份它
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

# 🔐 自动注入敏感信息 (利用 GitHub Secrets 环境变量)
echo ""
echo "🔐 检查 Secrets 注入..."

if [ ! -z "$OPENCODE_API_KEY" ]; then
    mkdir -p "$HOME/.config/opencode"
    echo "{\"api_key\": \"$OPENCODE_API_KEY\"}" > "$HOME/.config/opencode/credentials.json"
    chmod 600 "$HOME/.config/opencode/credentials.json"
    echo "   ✅ OpenCode API 密钥已注入"
fi

if [ ! -z "$OPENCLAW_API_KEY" ]; then
    mkdir -p "$HOME/.openclaw/credentials"
    echo "{\"api_key\": \"$OPENCLAW_API_KEY\"}" > "$HOME/.openclaw/credentials/openclaw.json"
    chmod 600 "$HOME/.openclaw/credentials/openclaw.json"
    echo "   ✅ OpenClaw API 密钥已注入"
fi

echo ""
echo "🎉 环境恢复完成！"
echo ""
echo "📋 下一步:"
echo "   • 运行 'opencode auth login' 验证授权（如需要）"
echo "   • 检查工具配置是否生效"
```

### 快捷命令: save-commit (保存)（保存更改）

**用途**: 保存 `.config-store/` 的更改到 Git

```bash
#!/bin/bash
# save-config.sh - 保存当前配置更改到 Git

set -e

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo /workspaces/ow1)"

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
```

### 快捷命令: reset-config (回滚)（环境切换）

**用途**: 切换 Git 分支并恢复对应配置

```bash
#!/bin/bash
# switch-env.sh - 切换环境配置（使用 Git 分支）

set -e

if [ -z "$1" ]; then
    echo "❌ 用法: ./scripts/switch-env.sh <分支名>"
    echo ""
    echo "当前分支: $(git branch --show-current)"
    echo ""
    echo "可用环境分支:"
    git branch -a | grep "env/" || echo "   (无环境分支)"
    echo ""
    echo "快速创建环境分支:"
    echo "   git checkout -b env/<name>"
    exit 1
fi

BRANCH="$1"

echo "🔄 切换到环境: $BRANCH"
echo ""

# 检查分支是否存在
if ! git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "❌ 本地分支 $BRANCH 不存在"
    echo ""
    read -p "是否创建新分支? (y/n): " create
    if [[ $create =~ ^[Yy]$ ]]; then
        git checkout -b "$BRANCH"
        echo "✅ 已创建并切换到 $BRANCH"
    else
        exit 1
    fi
else
    # 切换分支
    git checkout "$BRANCH"
fi

# 重新建立链接（因为切换分支可能改变了 .config-store 内容）
echo ""
echo "🔗 重新建立配置链接..."
"$(dirname "$0")/init-links.sh"

echo ""
echo "✅ 已切换到 $BRANCH 环境"
```

### .gitignore 安全过滤

```
# 敏感信息（永不提交）
.config-store/**/credentials/
.config-store/**/identity/
.config-store/**/*.key
.config-store/**/*.pem
.config-store/**/.env
.config-store/**/secrets*

# 临时文件
*.backup.*
*.tmp
*.log
.DS_Store

# 不需要版本化的缓存
.config-store/**/cache/
.config-store/**/node_modules/
.config-store/**/.cache/

# 用户特定配置（可选）
.config-store/**/history
.config-store/**/local/
```

---

## 快速开始

### 首次配置（单账号）

```bash
# 1. 克隆仓库（如果尚未克隆）
git clone https://github.com/yourname/ow1.git
cd ow1

# 2. 安装并配置你的工具
npm install -g opencode
opencode auth login  # 完成初始配置

# 3. 将配置纳入 Git 管理
./scripts/add-tool.sh

# 4. 提交配置
./scripts/save-config.sh "feat: init opencode config"

# 5. 推送到远程
git push
```

### 重建环境（重建 Codespace）

```bash
# 自动执行（已通过 devcontainer.json 配置）
./scripts/init-links.sh

# 验证
ls -la ~/.config/opencode  # 应该是软链接
opencode --version         # 测试工具
```

---

## 标准操作流程 (SOP)

### 场景 1: 安装新工具并保存

```bash
# 安装工具并配置
npm install -g some-tool
some-tool configure

# 更新配置列表（编辑 add-tool.sh）
# declare -A CONFIGS=(
#     ...
#     [".config/some-tool"]="some-tool"
# )

# 纳入管理并保存
./scripts/add-tool.sh
./scripts/save-config.sh "feat: add some-tool config"
```

### 场景 2: 实验失败，回退重来

```bash
# 方法 A: Git 回退（推荐）
git checkout .config-store/  # 配置文件立即恢复

# 方法 B: 切换分支回到稳定版本
./scripts/switch-env.sh main

# 方法 C: 完全重建（终极方案）
# 1. 在 Codespaces 面板点击 "Rebuild Container"
# 2. 重启后自动运行 init-links.sh
```

### 场景 3: 多环境测试（GPT-4 vs Claude）

```bash
# 创建 Claude 环境
git checkout -b env/claude
# 修改 .config-store/opencode/settings.json
./scripts/save-config.sh "env: configure for Claude"

# 创建 GPT-4 环境
git checkout -b env/gpt4
# 修改配置
./scripts/save-config.sh "env: configure for GPT-4"

# 快速切换环境
./scripts/switch-env.sh env/claude
./scripts/switch-env.sh env/gpt4
```

### 场景 4: 日常使用 - 修改并保存配置

```bash
# 修改配置（如通过 opencode 界面）
opencode

# 保存更改
./scripts/save-config.sh

# 推送到远程（可选）
git push
```

---

## 跨账号迁移指南

### 概述

跨账号迁移的核心是**"配置资产迁移"**和**"环境重新授权"**。敏感信息（Secrets）不会随仓库自动迁移，需要在新账号中手动配置。

### 第一阶段：迁移中心配置仓库

#### 方式 A: 邀请协作（最快，适合团队）

1. 在原账号的 `config-repo` 仓库设置中，将新账号添加为 **Collaborator**
2. 新账号接受邀请后即可访问

#### 方式 B: 仓库克隆与重新上传（推荐，适合个人）

```bash
# 1. 在原账号中克隆仓库到本地
git clone https://github.com/old-account/config-repo.git
cd config-repo

# 2. 添加新账号的远程仓库
git remote add new-origin https://github.com/new-account/config-repo.git

# 3. 推送到新账号
# 注意：由于 .gitignore 配置，敏感信息不会被推送
git push new-origin main

# 或者在新账号重新创建仓库
# 1. 在 GitHub 新账号创建空的私有仓库 config-repo
# 2. git remote set-url origin https://github.com/new-account/config-repo.git
# 3. git push -u origin main
```

### 第二阶段：在新账号配置 Secrets

GitHub Secrets 是绑定在账号或仓库级别的，必须重新配置。

#### 配置步骤

1. **登录新账号**，进入 GitHub 主页
2. **访问 Secrets 设置**:
   - **Codespaces 级别**: `Settings` → `Codespaces` → `Secrets`
   - **仓库级别**: 进入具体仓库 → `Settings` → `Secrets and variables` → `Codespaces`

3. **添加 Secrets**:

| Secret 名称 | 用途 | 示例值 |
|------------|------|--------|
| `OPENCODE_API_KEY` | OpenCode API 密钥 | `sk-...` |
| `OPENCLAW_API_KEY` | OpenClaw API 密钥 | `oc-...` |
| `GITHUB_TOKEN` | GitHub 访问令牌 | `ghp_...` |

4. **设置访问范围**: 确保 Secret 的访问权限包含所有需要使用该密钥的仓库

### 第三阶段：在新项目中使用

#### 方式 A: 直接克隆（单项目）

```bash
# 1. 在新账号下克隆配置仓库
git clone https://github.com/new-account/config-repo.git
cd config-repo

# 2. 运行恢复脚本
./scripts/init-links.sh

# 3. 验证敏感信息注入
ls -la ~/.config/opencode/credentials.json  # 应存在且由 Secrets 注入
```

#### 方式 B: 子模块模式（多项目复用，推荐）

```bash
# 1. 在新项目中添加配置中心为子模块
cd /workspaces/new-project
git submodule add https://github.com/new-account/config-repo.git .dev-ops
git submodule update --init --recursive

# 2. 运行设置脚本
bash .dev-ops/scripts/init-links.sh

# 3. 配置自动化（devcontainer.json）
# 在 .devcontainer/devcontainer.json 中添加:
{
  "postCreateCommand": "git submodule update --init --recursive && bash .dev-ops/scripts/init-links.sh",
  "remoteEnv": {
    "OPENCODE_API_KEY": "${secrets.OPENCODE_API_KEY}",
    "OPENCLAW_API_KEY": "${secrets.OPENCLAW_API_KEY}"
  }
}
```

#### 方式 C: 一键复刻脚本

创建 `migrate-to-new-account.sh`:

```bash
#!/bin/bash
# migrate-to-new-account.sh - 一键复刻到新账号

set -e

echo "🚀 开始迁移到新账号..."
echo ""

# 检查必要的环境变量
if [ -z "$NEW_GITHUB_USERNAME" ] || [ -z "$NEW_REPO_NAME" ]; then
    echo "❌ 错误: 请设置环境变量"
    echo "   export NEW_GITHUB_USERNAME='your-new-username'"
    echo "   export NEW_REPO_NAME='config-repo'"
    exit 1
fi

NEW_REPO_URL="https://github.com/$NEW_GITHUB_USERNAME/$NEW_REPO_NAME.git"

echo "📦 步骤 1/4: 检查当前仓库..."
cd "$(git rev-parse --show-toplevel)"
git status

echo ""
echo "📤 步骤 2/4: 推送到新账号..."
git remote add new-account "$NEW_REPO_URL" 2>/dev/null || echo "远程仓库已存在"
git push new-account main

echo ""
echo "🔐 步骤 3/4: 验证 Secrets 配置..."
echo "⚠️  请手动检查以下 Secrets 是否已在新账号配置:"
echo "   • OPENCODE_API_KEY"
echo "   • OPENCLAW_API_KEY"
read -p "已完成配置? (y/n): " confirmed

if [[ ! $confirmed =~ ^[Yy]$ ]]; then
    echo "⏸️  迁移暂停，请在配置完成后重新运行脚本"
    exit 0
fi

echo ""
echo "✅ 步骤 4/4: 验证迁移..."
echo "   新仓库地址: $NEW_REPO_URL"
echo ""
echo "📋 迁移完成后的检查清单:"
echo "   □ 在新 Codespace 克隆仓库"
echo "   □ 运行 ./scripts/init-links.sh"
echo "   □ 验证工具配置"
echo "   □ 测试 API 调用"
echo ""
echo "🎉 迁移完成！"
```

### 第四阶段：验证与测试

```bash
# 1. 验证链接
ls -la ~/.config/opencode
# 预期输出: ~/.config/opencode -> /workspaces/.../.config-store/opencode

# 2. 验证 Secrets 注入
cat ~/.config/opencode/credentials.json
# 预期输出包含从 Secrets 注入的 API Key

# 3. 测试工具
opencode --version
opencode list  # 或任意需要授权的命令

# 4. 验证 Git 配置
git config --global user.name
git config --global user.email
```

### 第五阶段：多账号同步策略

如果你有多个 GitHub 账号（如个人 + 公司），可以使用以下策略：

#### 策略 A: 主从同步

```bash
# 在个人账号作为主仓库
# 公司账号定期拉取更新

# 公司账号操作
git remote add personal https://github.com/personal-account/config-repo.git
git fetch personal
git merge personal/main  # 合并个人账号的更新
```

#### 策略 B: 分支隔离

```bash
# 在配置仓库中创建账号专用分支

# 个人账号分支
git checkout -b account/personal
# 配置个人专属设置
./scripts/save-config.sh "account: personal settings"

# 公司账号分支
git checkout -b account/company
# 配置公司专属设置
./scripts/save-config.sh "account: company settings"

# 切换账号环境
./scripts/switch-env.sh account/personal
./scripts/switch-env.sh account/company
```

#### 策略 C: 独立仓库 + 共享模板

```bash
# 1. 创建一个公开的模板仓库（不含敏感信息）
# config-repo-template/  # 公开
#   ├── scripts/
#   ├── .gitignore
#   └── README.md

# 2. 每个账号 fork 或复制模板
git clone https://github.com/template/config-repo-template.git config-repo
cd config-repo

# 3. 添加自己的配置
./scripts/add-tool.sh
./scripts/save-config.sh "init: personal config"

# 4. 推送到自己的私有仓库
git remote set-url origin https://github.com/my-account/config-repo.git
git push -u origin main
```

---

## 故障排除

### 问题 1: 软链接失效

**症状**: 提示 "No such file or directory"

**解决方案**:
```bash
# 重新建立链接
./scripts/init-links.sh

# 如果链接指向错误路径，先删除再重建
rm -rf ~/.config/opencode
./scripts/init-links.sh
```

### 问题 2: Secrets 未注入

**症状**: 工具提示需要登录或 API Key 无效

**解决方案**:
```bash
# 1. 检查环境变量
echo $OPENCODE_API_KEY

# 2. 手动注入（临时方案）
mkdir -p ~/.config/opencode
echo '{"api_key": "your-key-here"}' > ~/.config/opencode/credentials.json

# 3. 检查 Secrets 配置（永久方案）
# 前往 GitHub Settings -> Codespaces -> Secrets 重新配置
```

### 问题 3: Git 提交包含敏感信息

**症状**: 不小心提交了 credentials/

**解决方案**:
```bash
# 1. 从 Git 历史中移除（谨慎操作）
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch -r .config-store/*/credentials/' \
  --prune-empty --tag-name-filter cat -- --all

# 2. 强制推送（会重写历史！）
git push origin --force --all

# 3. 更新 .gitignore 防止再次发生
echo ".config-store/**/credentials/" >> .gitignore
```

### 问题 4: 配置冲突

**症状**: 不同分支的配置互相覆盖

**解决方案**:
```bash
# 备份当前配置
mv ~/.openclaw ~/.openclaw.backup.$(date +%s)

# 重新建立链接
./scripts/init-links.sh

# 或使用 stow 模式管理多版本（高级）
```

---

## 最佳实践总结

### 日常操作清单

| 操作 | 命令 | 频率 |
|------|------|------|
| 修改配置 | 正常使用工具 | 每天 |
| 保存配置 | `./scripts/save-config.sh` | 每次修改后 |
| 推送远程 | `git push` | 每天/每周 |
| 创建环境 | `./scripts/switch-env.sh env/name` | 按需 |
| 重建环境 | `./scripts/init-links.sh` | 重建后 |

### 安全清单

- [x] `.gitignore` 已排除 `credentials/`, `identity/`, `*.key`
- [x] Secrets 存储在 GitHub Codespaces Secrets 中
- [x] API Key 文件权限设置为 600 (`chmod 600`)
- [x] 定期审查 Git 历史确保无敏感信息泄漏
- [x] 使用个人访问令牌而非密码

### 性能优化

```bash
# 使用 --depth=1 克隆子模块（节省空间）
git submodule add --depth=1 https://github.com/... .dev-ops

# 定期清理备份文件
find .config-store -name "*.backup.*" -mtime +30 -delete
```

---

## 附录

### A. 完整 devcontainer.json 模板

```json
{
  "name": "Config-Centric Workspace",
  "image": "mcr.microsoft.com/devcontainers/universal:2",
  
  "features": {
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/devcontainers/features/node:1": {
      "version": "lts"
    }
  },
  
  "postCreateCommand": "bash scripts/init-links.sh",
  
  "postStartCommand": "echo '✅ 环境已恢复。如需配置 API Key，检查 GitHub Secrets 设置'",
  
  "customizations": {
    "vscode": {
      "extensions": [
        "GitHub.copilot",
        "eamodio.gitlens",
        "ms-vscode.vscode-json"
      ],
      "settings": {
        "git.enableSmartCommit": true,
        "git.confirmSync": false,
        "terminal.integrated.defaultProfile.linux": "bash"
      }
    }
  },
  
  "remoteEnv": {
    "OPENCODE_API_KEY": "${secrets.OPENCODE_API_KEY}",
    "OPENCLAW_API_KEY": "${secrets.OPENCLAW_API_KEY}",
    "CONFIG_STORE": "${containerWorkspaceFolder}/.config-store"
  },
  
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/codespace/.ssh,type=bind,consistency=cached"
  ]
}
```

### B. 常用命令速查

```bash
# 配置管理
./scripts/add-tool.sh      # 纳入管理
./scripts/init-links.sh          # 恢复环境
./scripts/save-config.sh        # 保存更改
./scripts/switch-env.sh <branch> # 切换环境

# Git 操作
git add .config-store/
git commit -m "feat: update configs"
git push

# 软链接检查
ls -la ~/.config/opencode       # 查看链接
readlink ~/.config/opencode     # 查看目标

# Secrets 调试
echo $OPENCODE_API_KEY          # 检查变量
env | grep API_KEY              # 列出所有 Key
```

### C. 资源链接

- [GitHub Codespaces 文档](https://docs.github.com/codespaces)
- [Git 子模块指南](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [GitHub Secrets 文档](https://docs.github.com/codespaces/managing-your-codespaces/managing-encrypted-secrets-for-your-codespaces)

---

**文档版本**: v1.0  
**最后更新**: 2026-02-10  
**作者**: GitHub Copilot + OpenCode
