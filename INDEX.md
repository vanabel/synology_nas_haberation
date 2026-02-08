# 📚 文档索引

## 快速导航

| 文档 | 用途 | 适合人群 |
|------|------|---------|
| **[README.md](README.md)** | 主文档 - 脚本使用说明和快速开始 | 所有用户 ⭐ |
| **[CHANGELOG.md](CHANGELOG.md)** | 完整的版本历史和修复记录 | 开发者/维护者 |
| **[HIBERNATION_GUIDE.md](HIBERNATION_GUIDE.md)** | 硬盘休眠问题诊断和解决方案 | 遇到休眠问题的用户 |
| **INDEX.md** | 本文档 - 文档索引 | - |

---

## 📖 详细说明

### [README.md](README.md) - 主文档
**推荐首先阅读** ⭐

**包含内容**:
- 🚀 快速开始指南
- 📁 脚本列表和用途
- ✨ v2版本特性说明
- 📝 管理的服务列表
- 🎯 常见使用场景
- 🔧 故障排查
- 🔑 权限说明

**适合**:
- 首次使用的用户
- 需要了解基本功能
- 快速查找命令

---

### [CHANGELOG.md](CHANGELOG.md) - 版本历史
**了解更新内容**

**包含内容**:
- 📅 v2.1, v2.0, v1.0 的详细变更
- 🐛 Bug修复记录
- 🔧 技术改进说明
- 📊 v1 vs v2 对比表
- 📋 文档整理历史
- 🔮 未来计划

**适合**:
- 想了解脚本演进历史
- 需要查找特定版本的修复
- 开发者和维护者

---

### [HIBERNATION_GUIDE.md](HIBERNATION_GUIDE.md) - 休眠问题指南
**解决硬盘无法休眠**

**包含内容**:
- 📋 问题概述和症状
- ⚠️ 关键发现（虚拟化服务等）
- 📊 阻止休眠的服务列表（按影响分级）
- 🎯 3种解决方案（推荐/完全/工作日）
- 🔧 诊断工具使用方法
- ⏰ 定时任务自动化配置
- 📈 PostgreSQL优化（高级）
- ❓ 常见问题解答

**适合**:
- 硬盘无法进入休眠状态
- 想降低NAS功耗
- 需要诊断磁盘I/O问题

---

## 🔍 按需求查找

### 我想...

#### 开始使用脚本
→ 阅读 [README.md](README.md) 的"快速开始"部分

#### 了解哪些服务会被管理
→ 阅读 [README.md](README.md) 的"管理的服务"部分

#### 设置夜间自动停止服务
→ 阅读 [HIBERNATION_GUIDE.md](HIBERNATION_GUIDE.md) 的"自动化方案"部分

#### 解决硬盘无法休眠问题
→ 完整阅读 [HIBERNATION_GUIDE.md](HIBERNATION_GUIDE.md)

#### 了解最新更新内容
→ 阅读 [CHANGELOG.md](CHANGELOG.md) 的 v2.1 部分

#### 查看所有历史变更
→ 完整阅读 [CHANGELOG.md](CHANGELOG.md)

#### 排查脚本错误
→ 阅读 [README.md](README.md) 的"故障排查"部分

#### 了解为什么需要sudo
→ 阅读 [README.md](README.md) 的"权限说明"部分

---

## 📂 目录结构

```
/var/services/homes/vanabel/scripts/
├── 📄 脚本文件
│   ├── start_services_enhanced.sh    # 启动服务
│   ├── stop_services_enhanced.sh     # 停止服务
│   ├── test_service_status.sh        # 状态检查
│   └── diagnose_hibernation.sh       # 休眠诊断
│
├── 📖 文档文件
│   ├── README.md                     # 主文档 ⭐
│   ├── CHANGELOG.md                  # 版本历史
│   ├── HIBERNATION_GUIDE.md          # 休眠指南
│   └── INDEX.md                      # 本文档
│
└── 📁 日志目录
    └── /var/services/homes/vanabel/logs/
        ├── service_start_enhanced.log
        ├── service_stop_enhanced.log
        └── cron.log (如果设置了定时任务)
```

---

## 🎓 学习路径

### 新手用户
1. 📖 阅读 [README.md](README.md) - 了解基本功能
2. 🚀 尝试运行 `test_service_status.sh` - 查看当前状态
3. 🎯 根据需要运行启动/停止脚本
4. ⚠️ 如有问题，查看 README 的"故障排查"部分

### 高级用户
1. 📖 阅读 [README.md](README.md) - 快速了解功能
2. 📊 阅读 [HIBERNATION_GUIDE.md](HIBERNATION_GUIDE.md) - 优化系统
3. ⏰ 设置定时任务实现自动化
4. 🔧 根据需要调整脚本配置

### 开发者/维护者
1. 📖 阅读 [README.md](README.md) - 了解当前功能
2. 📅 阅读 [CHANGELOG.md](CHANGELOG.md) - 了解技术演进
3. 🔍 查看脚本源代码 - 理解实现细节
4. 🛠️ 根据需要修改和优化脚本

---

## 📊 文档统计

| 项目 | 数量/大小 |
|------|----------|
| 总文档数 | 4个 (含本索引) |
| 总大小 | ~21KB |
| 脚本文件 | 4个 |
| 主要文档 | 3个 |

**文档大小**:
- README.md: ~5.2KB
- CHANGELOG.md: ~6.2KB
- HIBERNATION_GUIDE.md: ~9.5KB
- INDEX.md: ~1KB (本文档)

---

## 📝 文档维护

### 文档整理历史
- **2026-02-08**: 重大整理
  - 合并 9个文档 → 3个核心文档
  - 删除重复内容
  - 统一文档格式
  - 创建文档索引

### 已归档的文档
以下文档已被合并到新文档中：
- ~~README_SCRIPTS.md~~ → README.md
- ~~COMPARISON.md~~ → CHANGELOG.md
- ~~FIX_LOG.md~~ → CHANGELOG.md
- ~~TROUBLESHOOTING.md~~ → README.md
- ~~STREAMLIT_REMOVAL.md~~ → CHANGELOG.md
- ~~nas_hibernation_analysis.md~~ → HIBERNATION_GUIDE.md
- ~~nas_hibernation_deep_analysis.md~~ → HIBERNATION_GUIDE.md
- ~~HIBERNATION_SOLUTION_SUMMARY.md~~ → HIBERNATION_GUIDE.md

---

## 🔗 外部资源

### Synology官方文档
- [DSM用户指南](https://www.synology.com/zh-cn/support/documentation)
- [硬盘休眠设置](https://kb.synology.com/zh-cn/DSM/help/DSM/AdminCenter/system_hardware_hibernation)

### 相关工具
- systemctl - 系统服务管理
- pm2 - Node.js进程管理
- docker - 容器管理

---

**最后更新**: 2026-02-08  
**维护者**: Cursor AI
