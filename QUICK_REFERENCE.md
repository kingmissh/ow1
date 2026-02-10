# Sync-Link 快速参考卡

## 🎯 核心承诺

**你只需要关注 Git，配置自动同步**

---

## ⚡ 日常命令（3 个）

```bash
# 1. 查看配置更改
save

# 2. 提交配置更改  
save-commit

# 3. 回滚配置（搞砸时使用）
reset-config
```

**或者直接用 Git**：
```bash
git status .config-store/     # 查看
git add .config-store/        # 暂存
git commit -m "..."           # 提交
git checkout .config-store/   # 回滚
```

---

## 🚀 首次设置

```bash
# 1. 将现有配置纳入管理
./scripts/add-tool.sh opencode .config/opencode

# 2. 提交
git add .config-store/ && git commit -m "feat: add opencode config"
git push
```

---

## 🔄 重建环境后

**全自动** - 什么都不用做：
1. 打开 Codespace
2. 等待 `init-links.sh` 自动运行
3. 运行 `source ~/.bashrc` 加载别名
4. ✅ 环境就绪

---

## 📁 关键路径

| 路径 | 说明 |
|------|------|
| `.config-store/` | 配置实际存储位置（Git 跟踪） |
| `~/.config/opencode/` | 软链接到 `.config-store/opencode/` |
| `~/.openclaw/` | 软链接到 `.config-store/openclaw/` |

---

## 🆘 故障排除

```bash
# 软链接失效
./scripts/init-links.sh

# 验证系统状态
./scripts/verify-sync-link.sh

# 手动检查链接
ls -la ~/.config/opencode
```

---

## 🔒 安全提醒

- ✅ credentials/ 在 .gitignore 中排除
- ✅ Secrets 通过 GitHub 注入
- ✅ 文件权限自动设置为 600/700

---

**文档**: ENV_SYSTEM_MASTER.md  
**版本**: Sync-Link v2.0
