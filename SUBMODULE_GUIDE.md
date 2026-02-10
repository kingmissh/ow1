# 子模块操作指南

> 本文档说明如何使用 my-dev-ops 子模块

---

## 🎯 常见操作

### 1. 拉取最新配置

当 my-dev-ops 有更新时，拉取最新版本：

```bash
# 更新子模块到最新
git submodule update --remote .dev-ops

# 查看更改
git diff .dev-ops

# 提交更新
git add .dev-ops
git commit -m "chore: update my-dev-ops submodule to latest"
git push
```

### 2. 在 my-dev-ops 中修改配置

如果你需要修改配置并推送到 my-dev-ops：

```bash
# 进入子模块
cd .dev-ops

# 修改配置（例如添加新工具）
./scripts/add-tool.sh git .config/git

# 或者修改现有配置
vim .config-store/opencode/settings.json

# 提交到 my-dev-ops
git add .
git commit -m "feat: add git config"
git push

# 回到 ow1
cd ..

# 此时 .dev-ops 指向新提交，需要更新 ow1 的引用
git add .dev-ops
git commit -m "chore: update my-dev-ops submodule"
git push
```

### 3. 初始化（首次克隆或重建）

```bash
# 初始化并更新子模块
git submodule update --init --recursive

# 初始化配置环境
bash .dev-ops/scripts/init-links.sh

# 加载别名
source ~/.bashrc
```

### 4. 重置子模块（如果出现问题）

```bash
# 重置子模块到最近一次提交的版本
git submodule foreach --recursive 'git reset --hard && git clean -fd'

# 重新初始化
bash .dev-ops/scripts/init-links.sh
```

---

## 🔧 故障排除

### 问题 1：子模块显示为修改状态

**症状**：
```bash
git status
# 显示：modified: .dev-ops (new commits)
```

**解决**：
```bash
# 这是正常的，表示子模块指向了新提交
# 需要提交这个更改到 ow1
git add .dev-ops
git commit -m "chore: update submodule"
```

### 问题 2：子模块为空

**症状**：`.dev-ops/` 目录存在但没有文件

**解决**：
```bash
# 初始化子模块
git submodule update --init --recursive
```

### 问题 3：无法推送子模块更改

**症状**：在 `.dev-ops/` 中 `git push` 失败

**解决**：
```bash
# 检查远程仓库权限
cd .dev-ops
git remote -v

# 如果需要，使用 Token 或 SSH
git remote set-url origin https://<token>@github.com/kingmissh/my-dev-ops.git
```

---

## 📝 最佳实践

1. **经常更新**：定期运行 `git submodule update --remote .dev-ops` 获取最新配置

2. **原子提交**：
   - 在 my-dev-ops 中修改并提交
   - 然后在 ow1 中更新子模块引用
   - 分两步提交，清晰明了

3. **提交信息规范**：
   - my-dev-ops: `feat:`, `fix:`, `config:` 等
   - ow1: `chore: update my-dev-ops submodule`

4. **备份**：修改配置前，可以先创建分支：
   ```bash
   cd .dev-ops
   git checkout -b backup-before-change
   git checkout main
   ```

---

## 🔗 相关链接

- **配置中心**: https://github.com/kingmissh/my-dev-ops
- **Git 子模块文档**: https://git-scm.com/book/en/v2/Git-Tools-Submodules

---

**提示**: 本文档位于 `SUBMODULE_GUIDE.md`
