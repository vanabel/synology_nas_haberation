# NAS 硬盘休眠问题指南

> 详细诊断和解决Synology NAS硬盘无法休眠的问题

**系统**: 群晖 DSM (Linux 4.4.302+)  
**更新时间**: 2026-02-08

---

## 📋 目录

1. [问题概述](#问题概述)
2. [关键发现](#关键发现)
3. [阻止休眠的服务列表](#阻止休眠的服务列表)
4. [解决方案](#解决方案)
5. [诊断工具使用](#诊断工具使用)

---

## 问题概述

### 症状
- 硬盘设置为10分钟无活动后休眠
- 实际上硬盘从不进入休眠状态
- 功耗居高不下，噪音持续

### 根本原因
多个后台服务持续产生磁盘I/O操作，阻止硬盘进入休眠状态。

---

## 关键发现

### ⚠️ 最严重问题：虚拟化服务空跑

```bash
# 检查虚拟机
virsh list --all
# 结果: 没有任何虚拟机运行！

# 但虚拟化服务仍在运行
ps aux | grep -i virt
# 结果: 24个后台进程仍在运行！
```

**资源占用**:
- 24个后台进程
- ~150MB内存
- etcd持续写入磁盘（7.5小时CPU累计）
- 持续的磁盘I/O活动

**结论**: 这是阻止休眠的最大元凶！

---

## 阻止休眠的服务列表

### 🥇 极高影响 (⭐⭐⭐⭐⭐)

| 服务 | 进程数 | 内存占用 | 磁盘I/O | 建议 |
|------|--------|----------|---------|------|
| **Virtualization** | 24个 | ~150MB | 持续写入 | ✅ 立即停止 |
| **PostgreSQL WAL** | 5个 | ~100MB | 每秒写入 | ⚠️ 优化配置 |

**虚拟化服务详情**:
```
主要进程:
├─ libvirtd - 虚拟机管理守护进程
├─ synocccd - 虚拟机控制中心
├─ synohostcmdd (88MB) - 虚拟机主机管理
├─ synocccstated (104MB) - 虚拟机状态管理
├─ etcd (16MB, 7.5h CPU) - 分布式配置存储
├─ redis-server - 虚拟化专用Redis
└─ 11个 vmm_etcd_cached 工作进程
```

**停止方法**:
```bash
sudo systemctl stop pkgctl-Virtualization
sudo systemctl stop pkg-synoccc-redis
```

### 🥈 高影响 (⭐⭐⭐⭐)

| 服务 | 进程数 | 内存占用 | 磁盘I/O | 建议 |
|------|--------|----------|---------|------|
| **Synology Drive** | 7个 | ~50MB | 持续同步 | ✅ 夜间可停止 |
| **索引服务** | 6个 | ~40MB | 持续扫描 | ✅ 夜间可停止 |
| **MariaDB** | 2个 | ~73MB | 定期写入 | ⚠️ 看需求 |

**Synology Drive详情**:
```
运行进程:
├─ cloud-daemon.exe
├─ cloud-monitor
├─ syno-cloud-clientd (1.5h CPU)
├─ cloud-workerd (58min CPU)
├─ cloud-vmtouchd
├─ cloud-authd
└─ redis-server (Drive专用)
```

**停止方法**:
```bash
sudo systemctl stop pkgctl-SynologyDrive
```

### 🥉 中等影响 (⭐⭐⭐)

| 服务 | 进程数 | 内存占用 | 磁盘I/O | 建议 |
|------|--------|----------|---------|------|
| **EmbyServer** | 1个 | 196MB | 定期扫描 | ✅ 夜间可停止 |
| **CloudSync** | 1个 | ~27MB | 定期同步 | ✅ 夜间可停止 |
| **Synology Photos** | 3个 | ~30MB | 定期索引 | ✅ 夜间可停止 |
| **Neo4j** | 1个 | 491MB | 定期写入 | ⚠️ 看需求 |

### 较低影响 (⭐⭐)

| 服务 | 建议 |
|------|------|
| **Web服务** (Nginx/PHP/Apache) | 💚 可以保持运行 |
| **PM2应用** | 💚 可以保持运行 |
| **Docker容器** | ⚠️ 取决于容器内运行的服务 |

---

## 解决方案

### 🎯 推荐方案：分场景管理

#### 方案1: 夜间节能模式（推荐）

**停止高影响服务，保留基础功能**

```bash
# 使用提供的脚本
sudo bash /var/services/homes/vanabel/scripts/stop_services_enhanced.sh
```

**停止的服务**:
- ✅ 虚拟化服务（最重要！）
- ✅ Synology Drive
- ✅ CloudSync  
- ✅ 索引服务
- ✅ EmbyServer
- ✅ Synology Photos

**保留的服务**:
- 💚 Nginx (Web访问)
- 💚 PM2应用 (如果需要)

**预期效果**:
- 磁盘I/O降低 **70-90%**
- 功耗降低约 **30-50W**
- 硬盘能够在10-15分钟后进入休眠

#### 方案2: 完全休眠模式

**停止所有可能的服务**

```bash
# 停止服务
sudo bash /var/services/homes/vanabel/scripts/stop_services_enhanced.sh

# 额外停止Web服务（如果不需要Web访问）
sudo systemctl stop nginx
```

**预期效果**:
- 磁盘I/O降低 **90-95%**
- 功耗降低约 **50-70W**
- 硬盘能够在5-10分钟后进入休眠

#### 方案3: 工作日模式

**白天保持所有服务运行**

```bash
# 启动所有服务
sudo bash /var/services/homes/vanabel/scripts/start_services_enhanced.sh
```

---

## 诊断工具使用

### 1. 服务状态检查

```bash
bash /var/services/homes/vanabel/scripts/test_service_status.sh
```

**输出示例**:
```
【系统服务】
✓ 虚拟化服务: 运行中
✓ Synology Drive: 运行中
✗ Synology Photos: 已停止/禁用

【用户应用】
✓ PM2: 8 个应用运行中, 0 个已停止

【Docker容器】
✓ Docker: 6 个容器运行中, 6 个已停止
```

### 2. 休眠问题诊断

```bash
bash /var/services/homes/vanabel/scripts/diagnose_hibernation.sh
```

**功能**:
- 检查所有运行的服务
- 识别阻止休眠的进程
- 提供优化建议
- 估算可节省的资源

### 3. 手动检查磁盘活动

```bash
# 检查磁盘I/O
sudo iotop -o -d 5

# 检查哪些进程在访问磁盘
sudo lsof +D /volume1 | head -20

# 检查虚拟化服务状态
ps aux | grep -E '(virt|etcd|synoccc)' | grep -v grep
```

---

## 自动化方案

### 使用定时任务实现自动化

#### 1. 创建定时任务脚本

```bash
# 编辑root的crontab
sudo crontab -e
```

#### 2. 添加定时规则

```bash
# 每晚23:00停止服务
0 23 * * * /var/services/homes/vanabel/scripts/stop_services_enhanced.sh >> /var/services/homes/vanabel/logs/cron.log 2>&1

# 每早7:00启动服务
0 7 * * * /var/services/homes/vanabel/scripts/start_services_enhanced.sh >> /var/services/homes/vanabel/logs/cron.log 2>&1
```

#### 3. 验证定时任务

```bash
# 查看已设置的定时任务
sudo crontab -l

# 查看执行日志
tail -f /var/services/homes/vanabel/logs/cron.log
```

---

## PostgreSQL优化（高级）

如果需要保持PostgreSQL运行，但想减少其I/O：

### 调整WAL配置

编辑 `/usr/local/pgsql/share/postgresql.conf`:

```ini
# 减少WAL写入频率
wal_level = minimal
max_wal_senders = 0
wal_keep_segments = 0

# 延长checkpoint间隔
checkpoint_timeout = 30min
checkpoint_completion_target = 0.9

# 增大shared_buffers减少磁盘访问
shared_buffers = 256MB
```

**重启PostgreSQL**:
```bash
sudo systemctl restart pgsql-adapter
```

⚠️ **注意**: 修改数据库配置有风险，请先备份！

---

## 监控和验证

### 1. 检查硬盘状态

```bash
# 检查硬盘是否进入休眠
sudo hdparm -C /dev/sda

# 输出:
# active/idle    - 硬盘活动中
# standby        - 硬盘已休眠 ✓
```

### 2. 监控功耗变化

**预期功耗对比**:
- 全部服务运行: ~80-100W
- 夜间节能模式: ~30-50W
- 完全休眠模式: ~20-30W

### 3. 查看日志

```bash
# 查看启动日志
tail -100 /var/services/homes/vanabel/logs/service_start_enhanced.log

# 查看停止日志
tail -100 /var/services/homes/vanabel/logs/service_stop_enhanced.log
```

---

## 常见问题

### Q1: 停止虚拟化服务安全吗？
**A**: 如果没有运行虚拟机，完全安全。可以随时重新启动。

### Q2: 停止服务后会影响什么？
**A**: 
- ✅ Web访问（Nginx）: 不受影响
- ✅ SSH访问: 不受影响
- ✅ 文件共享（SMB/NFS）: 不受影响
- ⚠️ Drive同步: 暂停，重启后继续
- ⚠️ 云同步: 暂停，重启后继续
- ⚠️ 媒体服务器: 暂停，重启后恢复

### Q3: 如何恢复所有服务？
**A**: 
```bash
sudo bash /var/services/homes/vanabel/scripts/start_services_enhanced.sh
```

### Q4: PostgreSQL必须停止吗？
**A**: 不是。PostgreSQL通常由套件依赖，建议保持运行。可以通过优化配置减少I/O。

### Q5: 如何判断哪些服务在使用磁盘？
**A**: 
```bash
# 实时监控磁盘I/O
sudo iotop -o -d 5

# 查看进程的磁盘读写
sudo iotop -P -a
```

---

## 效果评估

### 测试场景

**测试条件**:
1. 设置硬盘休眠时间: 10分钟
2. 停止高影响服务
3. 等待15分钟
4. 检查硬盘状态

**预期结果**:

| 场景 | 服务状态 | 硬盘状态 | 功耗 |
|------|---------|---------|------|
| 停止前 | 全部运行 | ❌ 不休眠 | 80-100W |
| 停止后(10分钟) | 已停止高影响 | ⚠️ 待休眠 | 60-70W |
| 停止后(15分钟) | 已停止高影响 | ✅ 已休眠 | 30-50W |

---

## 总结

### 关键点

1. **虚拟化服务是最大问题** - 即使没有VM也在持续运行
2. **Drive和索引服务** - 持续同步和扫描
3. **PostgreSQL** - 可以优化但不建议停止
4. **使用脚本自动化** - 定时启动/停止服务

### 推荐行动

1. ✅ **立即停止虚拟化服务**（如果不使用VM）
2. ✅ **设置定时任务**实现自动化管理
3. ✅ **监控效果**确认硬盘能够休眠
4. ⚠️ **谨慎优化PostgreSQL**（高级用户）

---

**相关脚本**: 
- `stop_services_enhanced.sh` - 停止服务
- `start_services_enhanced.sh` - 启动服务
- `test_service_status.sh` - 检查状态
- `diagnose_hibernation.sh` - 诊断问题

**相关文档**:
- **[README.md](README.md)** - 脚本使用说明
- **[CHANGELOG.md](CHANGELOG.md)** - 版本历史
- **[INDEX.md](INDEX.md)** - 文档索引

---

**作者**: Cursor AI  
**最后更新**: 2026-02-08
