#!/bin/bash
# 服务状态检查脚本
# 用于验证启动/停止脚本的效果
# 作者: Cursor AI
# 日期: 2026-02-08

echo "========================================"
echo "NAS服务状态检查"
echo "========================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_service() {
    local service=$1
    local display_name=$2
    
    if systemctl list-unit-files "$service" &>/dev/null; then
        if systemctl is-active --quiet "$service"; then
            echo -e "${GREEN}✓${NC} $display_name: 运行中"
        elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
            echo -e "${YELLOW}⚠${NC} $display_name: 已启用但未运行"
        else
            echo -e "${RED}✗${NC} $display_name: 已停止/禁用"
        fi
    else
        echo -e "  $display_name: 未安装"
    fi
}

# 系统服务
echo "【系统服务】"
check_service "pkgctl-Virtualization.service" "虚拟化服务"
check_service "pkg-synoccc-redis.service" "Redis (虚拟化依赖)"
check_service "pkgctl-SynologyDrive.service" "Synology Drive"
check_service "pkgctl-CloudSync.service" "CloudSync"
check_service "pkg-SynoFinder-fileindexd.service" "文件索引服务"
check_service "synoindexd.service" "系统索引服务"
check_service "pkgctl-SynologyPhotos.service" "Synology Photos"
check_service "pkgctl-EmbyServer.service" "EmbyServer"
echo ""

# Web服务
echo "【Web服务】"
check_service "nginx.service" "Nginx"

# PHP-FPM
PHP_COUNT=$(systemctl list-units "pkg-WebStation-php*" --no-legend --state=active 2>/dev/null | wc -l)
if [ "$PHP_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} PHP-FPM: $PHP_COUNT 个实例运行中"
else
    echo -e "${RED}✗${NC} PHP-FPM: 未运行"
fi

# Apache
APACHE_COUNT=$(systemctl list-unit-files "pkg-Apache*" --no-legend 2>/dev/null | wc -l)
if [ "$APACHE_COUNT" -gt 0 ]; then
    APACHE_ACTIVE=0
    for apache_svc in $(systemctl list-unit-files "pkg-Apache*" --no-legend 2>/dev/null | awk '{print $1}'); do
        if systemctl is-active --quiet "$apache_svc"; then
            APACHE_ACTIVE=1
        fi
    done
    if [ "$APACHE_ACTIVE" -eq 1 ]; then
        echo -e "${GREEN}✓${NC} Apache: 运行中"
    else
        echo -e "${RED}✗${NC} Apache: 已停止"
    fi
else
    echo -e "  Apache: 未安装"
fi
echo ""

# 用户应用
echo "【用户应用】"

# PM2 (简化版本,避免卡顿)
PM2_CHECK=$(timeout 3 su - vanabel -c "pm2 list 2>/dev/null | grep -E '(online|stopped)' | head -1" 2>/dev/null || echo "")
if [ -n "$PM2_CHECK" ]; then
    # 获取状态并移除所有空白字符和换行
    PM2_ONLINE=$(timeout 3 su - vanabel -c "pm2 list 2>/dev/null | grep -c 'online'" 2>/dev/null | head -1 | tr -d ' \n\r\t' || echo "0")
    PM2_STOPPED=$(timeout 3 su - vanabel -c "pm2 list 2>/dev/null | grep -c 'stopped'" 2>/dev/null | head -1 | tr -d ' \n\r\t' || echo "0")
    
    # 设置默认值防止为空
    [ -z "$PM2_ONLINE" ] && PM2_ONLINE=0
    [ -z "$PM2_STOPPED" ] && PM2_STOPPED=0
    
    # 使用printf确保单行输出
    if [ "$PM2_ONLINE" -gt 0 ] 2>/dev/null; then
        printf "${GREEN}✓${NC} PM2: %s 个应用运行中, %s 个已停止\n" "$PM2_ONLINE" "$PM2_STOPPED"
    else
        printf "${RED}✗${NC} PM2: 所有应用已停止 (%s 个)\n" "$PM2_STOPPED"
    fi
else
    echo -e "${YELLOW}⚠${NC} PM2: 未安装或无法访问"
fi

echo ""

# Docker
echo "【Docker容器】"
if command -v docker &> /dev/null; then
    RUNNING_CONTAINERS=$(docker ps -q 2>/dev/null | wc -l)
    STOPPED_CONTAINERS=$(docker ps -a -f "status=exited" --format "{{.Names}}" 2>/dev/null | wc -l)
    if [ "$RUNNING_CONTAINERS" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Docker: $RUNNING_CONTAINERS 个容器运行中, $STOPPED_CONTAINERS 个已停止"
    else
        echo -e "${YELLOW}⚠${NC} Docker: 所有容器已停止 ($STOPPED_CONTAINERS 个)"
    fi
else
    echo -e "  Docker: 未安装"
fi
echo ""

# 虚拟机
echo "【虚拟机】"
if command -v virsh &> /dev/null; then
    VM_COUNT=$(virsh list --name 2>/dev/null | grep -v "^$" | wc -l)
    if [ "$VM_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} 虚拟机: $VM_COUNT 个VM运行中"
        virsh list --name 2>/dev/null | grep -v "^$" | while read vm_name; do
            echo "    - $vm_name"
        done
    else
        echo -e "${YELLOW}⚠${NC} 虚拟机: 无VM运行"
    fi
else
    echo -e "  虚拟机: virsh未安装"
fi

echo ""
echo "========================================"
echo "检查完成 - $(date)"
echo "========================================"
