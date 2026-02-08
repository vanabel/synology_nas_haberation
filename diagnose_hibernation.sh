#!/bin/bash
# 群晖NAS休眠问题诊断工具
# 基于群晖官方文档和实际系统诊断
# 作者: Cursor AI
# 日期: 2026-02-07

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         群晖NAS休眠问题诊断工具 v1.0                          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "正在检查可能阻止NAS休眠的因素..."
echo ""

ISSUES_FOUND=0
WARNINGS=0

# 颜色定义
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# ============================================
# 1. 检查储存空间状态
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. 储存空间状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RAID_STATUS=$(cat /proc/mdstat 2>/dev/null | grep -E "degraded|recovering")
if [ -n "$RAID_STATUS" ]; then
    echo -e "${RED}✗ 警告: RAID阵列状态异常!${NC}"
    echo "  $RAID_STATUS"
    ((ISSUES_FOUND++))
else
    echo -e "${GREEN}✓ RAID阵列状态正常${NC}"
fi

# ============================================
# 2. 检查高I/O服务
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. 高I/O服务检查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 虚拟化
if systemctl is-active --quiet pkgctl-Virtualization; then
    VM_COUNT=$(virsh list --name 2>/dev/null | grep -v "^$" | wc -l)
    if [ "$VM_COUNT" -gt 0 ]; then
        echo -e "${RED}✗ Virtual Machine Manager: $VM_COUNT 个虚拟机运行中${NC}"
        ((ISSUES_FOUND++))
    else
        echo -e "${YELLOW}⚠ Virtual Machine Manager: 服务运行但无VM (可停止)${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${GREEN}✓ Virtual Machine Manager: 未运行${NC}"
fi

# Synology Drive
if systemctl is-active --quiet pkgctl-SynologyDrive; then
    DRIVE_CONN=$(ps aux | grep -c "cloud-daemon\|cloud-worker" | grep -v grep)
    echo -e "${YELLOW}⚠ Synology Drive: 运行中 (持续同步)${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ Synology Drive: 未运行${NC}"
fi

# CloudSync
if systemctl is-active --quiet pkgctl-CloudSync; then
    echo -e "${YELLOW}⚠ CloudSync: 运行中 (云同步)${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ CloudSync: 未运行${NC}"
fi

# 索引服务
if ps aux | grep -q "[s]ynoindexd"; then
    echo -e "${YELLOW}⚠ 索引服务: 运行中 (持续扫描文件)${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ 索引服务: 未运行${NC}"
fi

# EmbyServer
if systemctl is-active --quiet pkgctl-EmbyServer; then
    echo -e "${YELLOW}⚠ EmbyServer: 运行中 (媒体库扫描)${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ EmbyServer: 未运行${NC}"
fi

# Synology Photos
if systemctl is-active --quiet pkgctl-SynologyPhotos; then
    echo -e "${YELLOW}⚠ Synology Photos: 运行中 (照片索引)${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ Synology Photos: 未运行${NC}"
fi

# ============================================
# 3. 检查数据库服务
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. 数据库服务"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ps aux | grep -q "[m]ariadbd\|[m]ysqld"; then
    echo -e "${YELLOW}⚠ MariaDB/MySQL: 运行中 (定期写入)${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ MariaDB/MySQL: 未运行${NC}"
fi

if ps aux | grep -q "[p]ostgres.*walwriter"; then
    echo -e "${YELLOW}⚠ PostgreSQL: 运行中 (WAL持续写入)${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ PostgreSQL: 未运行${NC}"
fi

REDIS_COUNT=$(ps aux | grep -c "[r]edis-server" | grep -v grep)
if [ "$REDIS_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠ Redis: $REDIS_COUNT 个实例运行中${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ Redis: 未运行${NC}"
fi

# ============================================
# 4. 检查网络服务
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. 网络服务"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 文件服务
if systemctl is-active --quiet smbd; then
    echo -e "${YELLOW}⚠ SMB: 运行中 (广播可能唤醒)${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ SMB: 未运行${NC}"
fi

if systemctl is-active --quiet nmbd; then
    echo -e "${YELLOW}⚠ NetBIOS: 运行中${NC}"
    ((WARNINGS++))
fi

if systemctl is-active --quiet nfs-server; then
    echo -e "${YELLOW}⚠ NFS: 运行中${NC}"
    ((WARNINGS++))
fi

# ============================================
# 5. 检查USB设备
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. USB设备"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

USB_DEVICES=$(lsusb 2>/dev/null | grep -v "Linux Foundation\|hub" | wc -l)
if [ "$USB_DEVICES" -gt 0 ]; then
    echo -e "${YELLOW}⚠ 检测到 $USB_DEVICES 个USB设备${NC}"
    lsusb | grep -v "Linux Foundation\|hub"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ 无外接USB设备${NC}"
fi

# ============================================
# 6. 检查系统设置
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. 系统设置检查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 脏页写回间隔
DIRTY_WRITEBACK=$(cat /proc/sys/vm/dirty_writeback_centisecs 2>/dev/null)
DIRTY_EXPIRE=$(cat /proc/sys/vm/dirty_expire_centisecs 2>/dev/null)

echo "脏页写回设置:"
if [ "$DIRTY_WRITEBACK" -lt 1000 ]; then
    echo -e "  ${YELLOW}⚠ dirty_writeback_centisecs = $DIRTY_WRITEBACK (建议 ≥1500)${NC}"
    ((WARNINGS++))
else
    echo -e "  ${GREEN}✓ dirty_writeback_centisecs = $DIRTY_WRITEBACK${NC}"
fi

if [ "$DIRTY_EXPIRE" -lt 3000 ]; then
    echo -e "  ${YELLOW}⚠ dirty_expire_centisecs = $DIRTY_EXPIRE (建议 ≥6000)${NC}"
    ((WARNINGS++))
else
    echo -e "  ${GREEN}✓ dirty_expire_centisecs = $DIRTY_EXPIRE${NC}"
fi

# ============================================
# 7. 检查用户应用
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. 用户应用"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# PM2应用
PM2_APPS=$(su - vanabel -c "pm2 list" 2>/dev/null | grep -c "online" || echo "0")
if [ "$PM2_APPS" -gt 0 ]; then
    echo -e "${YELLOW}⚠ PM2: $PM2_APPS 个Node.js应用运行中${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ PM2: 无应用运行${NC}"
fi

# Docker
if command -v docker &> /dev/null; then
    DOCKER_CONTAINERS=$(docker ps -q 2>/dev/null | wc -l)
    if [ "$DOCKER_CONTAINERS" -gt 0 ]; then
        echo -e "${YELLOW}⚠ Docker: $DOCKER_CONTAINERS 个容器运行中${NC}"
        ((WARNINGS++))
    else
        echo -e "${GREEN}✓ Docker: 无容器运行${NC}"
    fi
fi

# ============================================
# 8. 磁盘I/O实时检测
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. 磁盘I/O活动 (采样5秒)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v iostat &> /dev/null; then
    echo "正在采样..."
    IOSTAT_OUTPUT=$(iostat -x 5 2 2>/dev/null | tail -20)
    echo "$IOSTAT_OUTPUT" | grep -E "Device|md" | head -5
    
    # 检查写入活动
    WRITE_ACTIVITY=$(echo "$IOSTAT_OUTPUT" | grep "md" | awk '{if ($5 > 10) print $1}')
    if [ -n "$WRITE_ACTIVITY" ]; then
        echo -e "${RED}✗ 检测到持续磁盘写入活动!${NC}"
        ((ISSUES_FOUND++))
    else
        echo -e "${GREEN}✓ 磁盘I/O活动较低${NC}"
    fi
else
    echo -e "${YELLOW}⚠ iostat命令不可用，跳过I/O检测${NC}"
fi

# ============================================
# 总结报告
# ============================================
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                     诊断总结                                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "严重问题: ${RED}$ISSUES_FOUND${NC}"
echo -e "警告项目: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ "$ISSUES_FOUND" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}✓ 恭喜！未发现明显的休眠阻止因素${NC}"
    echo "  如果仍无法休眠，请查看官方文档中的其他设置"
elif [ "$ISSUES_FOUND" -gt 0 ]; then
    echo -e "${RED}✗ 发现严重问题，这些会阻止NAS休眠${NC}"
    echo "  建议: 解决上述红色标记的问题"
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}⚠ 发现 $WARNINGS 个可能影响休眠的服务/设置${NC}"
    echo "  建议: 使用stop_services_enhanced.sh停止这些服务"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "快速操作建议:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. 停止高I/O服务:"
echo "   sudo bash ~/scripts/stop_services_enhanced.sh"
echo ""
echo "2. 优化系统参数:"
echo "   sudo sysctl -w vm.dirty_writeback_centisecs=1500"
echo "   sudo sysctl -w vm.dirty_expire_centisecs=6000"
echo ""
echo "3. 设置定时任务 (DSM控制面板 → 任务计划)"
echo ""
echo "4. 查看详细文档:"
echo "   cat ~/nas_hibernation_deep_analysis.md | less"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "诊断完成时间: $(date)"
