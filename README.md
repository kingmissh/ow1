# OW1 - Codespaces 配置管理中心

> 🏗️ 配置中心化，应用链接化  
> 通过 GitHub Codespaces 持久化层对抗系统层的不确定性

## 🚀 快速开始

```bash
# 1. 将现有配置纳入管理
./scripts/manage-config.sh

# 2. 保存并推送
./scripts/save-config.sh "feat: init config"
git push

# 3. 重建环境后自动恢复
./scripts/setup-env.sh
```

## 📚 完整文档

- **[CROSS_ACCOUNT_MIGRATION.md](./CROSS_ACCOUNT_MIGRATION.md)** - 完整的历史版本管理与跨账号迁移指南
  - 系统架构设计
  - 4 大核心脚本详解
  - 标准操作流程 (SOP)
  - 跨账号/团队协作方案
  - 故障排除指南

- **[CONFIG_MANAGEMENT.md](./CONFIG_MANAGEMENT.md)** - 配置管理基础指南

- **[CODESPACE_ARCHITECTURE.md](./CODESPACE_ARCHITECTURE.md)** - Codespace 路径架构参考

## 🎯 核心功能

| 功能 | 脚本 | 说明 |
|------|------|------|
| 纳入管理 | `manage-config.sh` | 将配置移入 Git 并建立软链接 |
| 恢复环境 | `setup-env.sh` | 重建软链接，自动注入 Secrets |
| 保存配置 | `save-config.sh` | 一键提交配置更改 |
| 切换环境 | `switch-env.sh` | 多环境/分支快速切换 |

## 🔄 典型工作流

```bash
# 日常修改配置
opencode  # 修改设置...

# 保存更改
./scripts/save-config.sh "update: model settings"
git push

# 重建环境后
./scripts/setup-env.sh  # 自动恢复所有配置
```

## 🔒 安全特性

- ✅ 敏感信息通过 `.gitignore` 排除
- ✅ API Keys 通过 GitHub Secrets 注入
- ✅ 配置文件权限严格限制
- ✅ 支持跨账号迁移而不泄漏密钥

## 📖 推荐阅读

如果你是第一次使用这套系统，建议按以下顺序阅读：

1. [快速开始指南](#快速开始) - 5 分钟上手
2. [完整文档](./CROSS_ACCOUNT_MIGRATION.md#快速开始) - 了解所有功能
3. [跨账号迁移](./CROSS_ACCOUNT_MIGRATION.md#跨账号迁移指南) - 多账号/团队协作方案

## 🤝 贡献

本配置体系为个人开发环境优化，欢迎根据自身需求调整脚本。

---

**项目状态**: 生产就绪  
**维护者**: OpenCode + GitHub Copilot
