# OW1

> 这是一个使用 Sync-Link 配置管理的开发仓库

## 🏗️ 架构说明

本仓库使用 **Sync-Link** 配置管理体系，配置存储在独立的 `my-dev-ops` 中心仓库中，通过 Git 子模块引用。

```
my-dev-ops/ (中心配置仓库)
├── scripts/              # 配置管理脚本
├── .config-store/        # 配置存储
└── 文档/
         │
         │ git submodule
         ▼
ow1/ (本仓库 - 专注开发)
├── .dev-ops/ → my-dev-ops
├── src/                  # 你的开发代码
├── archive-*/            # 旧配置备份（确认安全后可删除）
└── ...
```

**优势**：
- ✅ 配置和开发代码完全分离
- ✅ 多个项目共享同一套配置
- ✅ 提交历史干净

---

## 🚀 快速开始

### 首次设置

```bash
# 1. 确保子模块已初始化
git submodule update --init --recursive

# 2. 初始化配置环境
bash .dev-ops/scripts/init-links.sh

# 3. 加载快捷命令
source ~/.bashrc
```

### 配置管理

**添加新工具**：
```bash
cd .dev-ops
./scripts/add-tool.sh <工具名> <配置路径>
# 示例: ./scripts/add-tool.sh opencode .config/opencode
```

**保存配置更改**：
```bash
cd .dev-ops
save-commit
# 或者: ./scripts/save-config.sh
```

**回滚配置**：
```bash
cd .dev-ops
reset-config
# 或者: ./scripts/reset-config.sh
```

### 日常使用

```bash
# 修改配置（通过工具界面）
opencode

# 保存到 Git（在 .dev-ops 目录中）
cd .dev-ops && save-commit

# 回到开发目录
cd ..
```

---

## 📁 目录结构

```
ow1/
├── .dev-ops/                   # ⭐ 配置管理子模块
│   ├── scripts/               # 管理脚本
│   │   ├── init-links.sh     # 初始化环境
│   │   ├── add-tool.sh       # 添加工具
│   │   ├── save-config.sh    # 保存配置
│   │   ├── reset-config.sh   # 回滚配置
│   │   └── ...
│   ├── .config-store/        # 配置存储
│   ├── USAGE_SCENARIOS.md    # 使用场景指南
│   ├── ENV_SYSTEM_MASTER.md  # 完整技术文档
│   └── ...
├── .gitmodules                # 子模块配置
├── .devcontainer/            # Codespaces 配置
├── archive-*/                # 旧配置备份（可删除）
├── src/                      # 你的开发代码
└── README.md                 # 本文件
```

---

## 📖 相关文档

| 文档 | 位置 | 说明 |
|------|------|------|
| 使用场景指南 | `.dev-ops/USAGE_SCENARIOS.md` | 8个详细使用场景 |
| 完整技术文档 | `.dev-ops/ENV_SYSTEM_MASTER.md` | 架构、脚本、故障排除 |
| 命令速查卡 | `.dev-ops/QUICK_REFERENCE.md` | 常用命令快速参考 |
| 架构参考 | `CODESPACE_ARCHITECTURE.md` | 路径架构技术参考 |

---

## 🔄 子模块操作

### 更新配置（拉取最新）

```bash
# 更新子模块到最新版本
git submodule update --remote .dev-ops

# 提交更新
git add .dev-ops
git commit -m "chore: update my-dev-ops submodule"
git push
```

### 在配置仓库中修改

```bash
# 进入配置仓库
cd .dev-ops

# 修改配置...

# 提交到 my-dev-ops
git add .
git commit -m "update: config changes"
git push

# 回到 ow1
cd ..

# 提交子模块更新
git add .dev-ops
git commit -m "chore: update my-dev-ops"
git push
```

### 初始化（重建 Codespace）

重建 Codespace 时会自动执行：
```bash
git submodule update --init --recursive
bash .dev-ops/scripts/init-links.sh
```

---

## ⚠️ 注意事项

1. **配置管理在 .dev-ops/**：所有配置操作都在子模块中进行
2. **备份目录**：`archive-*/` 是迁移前的备份，确认新系统运行正常后可删除
3. **子模块更新**：修改配置后需要同时提交到 my-dev-ops 和更新 ow1 的子模块引用

---

## 🔗 相关链接

- **配置中心仓库**: https://github.com/kingmissh/my-dev-ops
- **本仓库**: https://github.com/kingmissh/ow1

---

**状态**: 生产就绪 ✅  
**配置管理**: Sync-Link v2.0 + 子模块架构
