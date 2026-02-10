# Sync-Link 使用场景指南

> 本文档通过具体场景展示 Sync-Link 系统的完整使用流程

---

## 📌 核心概念

**Sync-Link** 是一套**配置管理自动化系统**，核心原理是：

```
┌─────────────────────────────────────────────────────┐
│  Git 仓库 (ow1/.config-store/)                        │
│  ├── opencode/  ← 配置实际存储在这里                  │
│  └── openclaw/                                      │
└─────────────────────────────────────────────────────┘
                         │ 软链接 (Symbolic Link)
                         ▼
┌─────────────────────────────────────────────────────┐
│  系统路径 (~/.config/opencode/)                       │
│  → 实际指向 .config-store/opencode/                  │
│  → 应用程序无感知，实时同步                            │
└─────────────────────────────────────────────────────┘
```

**关键点**：
- 修改 `~/.config/opencode/` = 修改 `.config-store/opencode/`
- `git status` 立即看到更改
- `git reset` 立即回滚配置

---

## 🎬 场景一：首次配置新工具

### 背景
你在 Codespace 中安装了 opencode，需要将其配置纳入版本管理。

### 完整流程

**步骤 1：安装并配置工具**

```bash
# 安装 opencode
npm install -g opencode

# 完成初始配置
opencode auth login
```

此时配置存储在 `~/.config/opencode/`（普通目录）

**步骤 2：纳入 Sync-Link 管理**

```bash
./scripts/add-tool.sh opencode .config/opencode
```

脚本执行过程：
```
🚀 添加新工具: opencode
   源路径: /home/codespace/.config/opencode
   存储路径: /workspaces/ow1/.config-store/opencode

📦 复制配置到仓库...
sending incremental file list
./
settings.json
package.json

🔗 建立软链接...
   ✅ /home/codespace/.config/opencode

✅ opencode 已纳入管理！

📝 已添加到 .config-mapping

📋 下一步:
   1. 检查配置: ls -la /workspaces/ow1/.config-store/opencode
   2. 测试工具: opencode --version
   3. 提交更改: ./scripts/save-config.sh
```

**发生了什么**：
1. ✅ 检查 `~/.config/opencode` 存在
2. 📦 复制配置到 `.config-store/opencode/`
3. 🔗 删除原目录，创建软链接
4. 📝 更新 `.config-mapping` 文件

**步骤 3：提交到 Git**

```bash
# 查看更改
git status

# 提交
 git add .config-store/ .config-mapping
 git commit -m "feat: add opencode config"
 git push
```

**验证**：
```bash
# 确认软链接
ls -la ~/.config/opencode
# 输出: ~/.config/opencode -> /workspaces/ow1/.config-store/opencode

# 测试工具
opencode --version
```

---

## 🎬 场景二：日常开发 - 修改配置

### 背景
你需要修改 opencode 的设置（比如切换 AI 模型或添加 MCP Server）。

### 完整流程

**步骤 1：通过工具界面修改**

```bash
# 打开 opencode 交互界面
opencode

# 在界面中修改设置，例如：
# - 切换模型从 GPT-3.5 到 GPT-4
# - 添加新的 MCP Server
# - 修改主题颜色
```

**关键**：修改会自动同步到 `.config-store/opencode/`（因为软链接实时同步）

**步骤 2：查看更改**

```bash
save
```

输出示例：
```
💾 保存配置更改...

📦 发现以下更改:
 M .config-store/opencode/settings.json
 M .config-store/opencode/mcp.json

✅ 已提交: chore: update configs (2025-02-10-14:30)

📤 推送到远程? (y/n): 
```

**步骤 3：提交更改**

选项 A - 使用快捷命令：
```bash
save-commit
```

选项 B - 手动提交：
```bash
git add .config-store/
git commit -m "update: switch to GPT-4 model and add filesystem MCP"
git push
```

**步骤 4：编写有意义的提交信息**

```bash
# 好的提交信息示例
git commit -m "config: switch OpenCode model to Claude-3-opus"
git commit -m "feat: add filesystem MCP server for project access"
git commit -m "fix: correct API endpoint for enterprise account"
```

---

## 🎬 场景三：实验失败 - 回滚配置

### 背景
你尝试了一个新的 MCP Server 配置，结果导致 opencode 崩溃或行为异常。

### 完整流程

**方法 1：使用快捷命令（推荐）**

```bash
reset-config
```

交互过程：
```
🔄 回滚配置更改...

📦 将丢弃以下更改:
 M .config-store/opencode/mcp.json
 M .config-store/opencode/settings.json

确认回滚? (y/n): y
✅ 配置已回滚
```

**发生了什么**：
- `git checkout .config-store/` 将文件恢复到上一个提交状态
- 软链接实时同步，`~/.config/opencode/` 立即恢复
- opencode 无需重启，配置已回滚

**方法 2：使用 Git 命令**

情况 A - 回滚未提交的更改：
```bash
git checkout .config-store/
```

情况 B - 回滚到上一个提交（已提交但想撤销）：
```bash
git reset --hard HEAD^
```

情况 C - 回滚到特定提交：
```bash
# 查看提交历史
git log --oneline .config-store/

# 回滚到特定提交
git checkout <commit-hash> -- .config-store/
```

**验证回滚**：
```bash
# 检查配置文件
cat .config-store/opencode/mcp.json

# 重启 opencode 验证
opencode
```

---

## 🎬 场景四：Codespace 重建 - 全自动恢复

### 背景
你点击了 "Rebuild Container"，Codespace 完全重置了，所有系统层数据丢失。

### 完整流程

**步骤 1：等待自动初始化（全自动，无需操作）**

Codespace 启动后自动执行 `.devcontainer/devcontainer.json` 中的：
```json
"postCreateCommand": "bash scripts/init-links.sh"
```

脚本自动完成：
```
🚀 初始化 Sync-Link 环境...
   仓库根目录: /workspaces/ow1

🔗 建立软链接...
   链接 opencode...
   ✅ /home/codespace/.config/opencode
   链接 openclaw...
   ✅ /home/codespace/.openclaw

🔐 注入 Secrets...
   ✅ OPENCODE_API_KEY

🔒 权限检查完成

⚡ 配置快捷命令...
   ✅ 已添加到 ~/.bashrc

   可用快捷命令:
      save         - 查看配置更改
      save-commit  - 提交配置更改
      reset-config - 一键回滚配置

🎉 初始化完成！

💡 使用提示:
   1. 修改配置后运行: ./scripts/save-config.sh 或 save-commit
   2. 需要回滚时运行: ./scripts/reset-config.sh 或 reset-config
   3. 或直接用 Git:    git checkout .config-store/

⚠️  请运行: source ~/.bashrc 使别名生效
```

**步骤 2：加载别名**

```bash
source ~/.bashrc
```

**步骤 3：验证环境**

```bash
# 检查软链接
ls -la ~/.config/opencode
# 输出: ~/.config/opencode -> /workspaces/ow1/.config-store/opencode

# 验证配置
opencode --version

# 检查快捷命令
alias | grep save
```

**结果**：
- ✅ 配置完全恢复（来自 Git 仓库）
- ✅ Secrets 已注入（来自 GitHub Codespaces Secrets）
- ✅ 快捷命令可用
- ✅ 可以立即开始工作

---

## 🎬 场景五：添加第二个工具

### 背景
你已经管理了 opencode，现在想把 git 的配置也纳入管理。

### 完整流程

**步骤 1：检查当前 git 配置**

```bash
# 查看 git 配置
ls -la ~/.config/git/
# 或者
git config --list --show-origin
```

**步骤 2：纳入 Sync-Link 管理**

```bash
./scripts/add-tool.sh git .config/git
```

输出：
```
🚀 添加新工具: git
   源路径: /home/codespace/.config/git
   存储路径: /workspaces/ow1/.config-store/git

📦 复制配置到仓库...
sending incremental file list
./
config
ignore

🔗 建立软链接...
   ✅ /home/codespace/.config/git

✅ git 已纳入管理！

📝 已添加到 .config-mapping

📋 下一步:
   1. 检查配置: ls -la /workspaces/ow1/.config-store/git
   2. 测试工具: git config --list
   3. 提交更改: ./scripts/save-config.sh
```

**步骤 3：提交更改**

```bash
save-commit
```

或者手动：
```bash
git add .config-store/ .config-mapping
git commit -m "feat: add git config to sync-link"
git push
```

**步骤 4：验证**

```bash
# 修改 git 配置
git config --global user.name "New Name"

# 查看更改
git status
# 应该显示 .config-store/git/config 被修改

# 提交
git add .config-store/
git commit -m "update: change git username"
```

**现在**：
- git 配置也在 `.config-store/git/`
- 修改 git 配置会自动同步
- 可以回滚 git 配置

---

## 🎬 场景六：多环境测试

### 背景
你想测试不同的模型配置（GPT-4 vs Claude），需要在不同配置间快速切换。

### 完整流程

**步骤 1：创建 Claude 环境分支**

```bash
# 创建并切换到新分支
git checkout -b env/claude

# 修改配置（手动编辑或使用 opencode 界面）
vim .config-store/opencode/settings.json
# 修改模型为 Claude-3-opus

# 提交
save-commit
```

**步骤 2：创建 GPT-4 环境分支**

```bash
# 切换回 main
git checkout main

# 创建 GPT-4 分支
git checkout -b env/gpt4

# 修改配置
vim .config-store/opencode/settings.json
# 修改模型为 GPT-4

# 提交
save-commit
```

**步骤 3：快速切换环境**

```bash
# 切换到 Claude 环境
git checkout env/claude
# 软链接自动同步，opencode 现在使用 Claude 配置

# 测试...
opencode

# 切换回 GPT-4
git checkout env/gpt4
# 配置立即切换
```

**优势**：
- ⚡ 秒级切换（Git 切换分支即可）
- 🔄 无需手动修改配置
- 📊 可以同时维护多个环境配置

---

## 🎬 场景七：跨账号迁移

### 背景
你创建了一个新的 GitHub 账号（如从个人切换到工作账号），想把这套配置迁移过去。

### 完整流程

**步骤 1：在新账号创建空仓库**

1. 访问 https://github.com/new
2. Repository name: `my-config`
3. 选择 Private
4. **不要**勾选 "Add a README"
5. 点击 Create repository

**步骤 2：运行迁移脚本**

```bash
# 设置目标账号信息
export NEW_GITHUB_USERNAME='new-username'
export NEW_REPO_NAME='my-config'

# 运行迁移脚本
./scripts/migrate-to-new-account.sh
```

输出：
```
🚀 Codespaces 配置迁移工具
================================

📋 迁移配置:
   原仓库: https://github.com/old-username/ow1
   新仓库: https://github.com/new-username/my-config

📦 步骤 1/5: 验证当前仓库...
   ✅ 当前仓库: /workspaces/ow1
   ✅ Git 状态:
   (工作区干净)

🔒 步骤 2/5: 验证敏感信息保护...
   ✅ .gitignore 已存在
   ✅ credentials/ 已排除

📤 步骤 3/5: 推送到新仓库...
   添加新 remote 'new-account'...
   推送分支到 new-account...
   ✅ 代码已推送到 https://github.com/new-username/my-config

🔐 步骤 4/5: Secrets 配置检查清单...

⚠️  请手动确认以下 Secrets 已在新账号配置:

   必需 Secrets:
   □ OPENCODE_API_KEY    - OpenCode API 密钥
   □ OPENCLAW_API_KEY    - OpenClaw API 密钥（如使用）

已完成 Secrets 配置? (y/n): y

✅ 步骤 5/5: 迁移完成！

📋 新账号环境配置步骤:

1. 在新账号下创建 Codespace:
   访问: https://github.com/new-username/my-config
   点击: 'Code' → 'Codespaces' → 'Create codespace'

2. 运行环境恢复脚本:
   ./scripts/init-links.sh

🎉 迁移完成！
📄 迁移报告已保存: migration-report-20250210-143000.txt
```

**步骤 3：配置 Secrets（新账号）**

1. 登录 GitHub 新账号
2. 进入 Settings → Codespaces → Secrets
3. 添加以下 Secrets：
   - `OPENCODE_API_KEY`
   - `OPENCLAW_API_KEY`

**步骤 4：在新账号使用**

```bash
# 克隆仓库
git clone https://github.com/new-username/my-config.git
cd my-config

# 初始化 Sync-Link
./scripts/init-links.sh

# 加载别名
source ~/.bashrc

# 验证
verify-sync-link.sh
```

---

## 🎬 场景八：故障排查

### 背景
你发现配置没有正确同步，或者软链接失效了。

### 完整流程

**步骤 1：运行系统验证**

```bash
./scripts/verify-sync-link.sh
```

输出示例（正常）：
```
🔍 Sync-Link 系统验证
======================

1. 检查目录结构...
   ✅ .config-store/ 存在

2. 检查核心脚本...
   ✅ init-links.sh 可执行
   ✅ add-tool.sh 可执行
   ✅ save-config.sh 可执行
   ✅ reset-config.sh 可执行

3. 检查软链接...
   ✅ opencode: /home/codespace/.config/opencode -> /workspaces/ow1/.config-store/opencode
   ✅ openclaw: /home/codespace/.openclaw -> /workspaces/ow1/.config-store/openclaw

4. 检查快捷命令...
   ✅ save 别名已配置

5. 检查安全配置...
   ✅ credentials/ 已排除

6. 检查自动化配置...
   ✅ devcontainer.json 配置正确

======================
验证结果: 7 通过, 0 失败

🎉 所有检查通过！Sync-Link 系统就绪
```

输出示例（有问题）：
```
🔍 Sync-Link 系统验证
======================

3. 检查软链接...
   ℹ️  opencode: /home/codespace/.config/opencode 未创建（首次运行请先执行 init-links.sh）

4. 检查快捷命令...
   ⚠️  别名未配置（请运行 source ~/.bashrc 或重新登录）

======================
验证结果: 5 通过, 2 失败

⚠️  发现 2 个问题，请检查上述输出

修复建议:
   - 重新初始化: ./scripts/init-links.sh
   - 加载别名: source ~/.bashrc
```

**步骤 2：常见问题的修复**

问题 A - 软链接失效：
```bash
# 重新初始化
./scripts/init-links.sh

# 验证
ls -la ~/.config/opencode
```

问题 B - 别名未生效：
```bash
# 加载别名
source ~/.bashrc

# 或者手动运行脚本（不依赖别名）
./scripts/save-config.sh
./scripts/reset-config.sh
```

问题 C - 配置文件冲突：
```bash
# 备份当前配置
mv ~/.config/opencode ~/.config/opencode.backup

# 重新建立链接
./scripts/init-links.sh
```

---

## 📋 命令速查表

### 日常命令

| 命令 | 作用 | 场景 |
|------|------|------|
| `save` | 查看配置更改 | 日常检查 |
| `save-commit` | 提交配置更改 | 保存修改 |
| `reset-config` | 回滚配置 | 实验失败 |
| `check-links` | 检查软链接状态 | 故障排查 |
| `config-status` | 查看配置仓库状态 | 日常检查 |

### 管理命令

| 命令 | 作用 | 场景 |
|------|------|------|
| `./scripts/init-links.sh` | 初始化环境 | 重建 Codespace |
| `./scripts/add-tool.sh` | 添加新工具 | 首次配置 |
| `./scripts/save-config.sh` | 保存配置（实际脚本）| 不依赖别名时使用 |
| `./scripts/reset-config.sh` | 回滚配置（实际脚本）| 不依赖别名时使用 |
| `./scripts/verify-sync-link.sh` | 验证系统 | 故障排查 |
| `./scripts/migrate-to-new-account.sh` | 跨账号迁移 | 迁移配置 |

### Git 命令（备用）

```bash
# 查看配置更改
git status .config-store/

# 提交配置更改
git add .config-store/
git commit -m "update: config changes"

# 回滚配置
git checkout .config-store/

# 推送到远程
git push
```

---

## 💡 最佳实践

1. **频繁提交**：修改配置后立即 `save-commit`，避免丢失
2. **有意义的提交信息**：使用 `config:`, `feat:`, `fix:` 等前缀
3. **使用分支**：实验性配置在分支上进行，稳定配置在 main
4. **定期验证**：运行 `verify-sync-link.sh` 确保系统健康
5. **备份敏感信息**：API Keys 只在 GitHub Secrets 中存储

---

*文档版本: v1.0*  
*最后更新: 2025-02-10*
