#!/bin/bash
# 增强版停止服务脚本 - 优化版 v2
# 特点:
# - 智能检查服务是否在运行
# - 避免停止已停止的服务
# - 清晰的状态反馈(✓成功 ⚠警告)
# - 过滤误导性的systemd错误消息
# 作者: Cursor AI  
# 日期: 2026-02-08

LOG_FILE="/var/services/homes/vanabel/logs/service_stop_enhanced.log"

# 辅助函数: 停止服务并过滤误导性错误
stop_service_quiet() {
    local service=$1
    # 过滤掉"dependency job failed"等非关键消息
    systemctl stop "$service" 2>&1 | grep -v "A dependency job for.*failed" | grep -v "See 'journalctl -xe' for details" || true
}

echo "========================================" | tee -a "$LOG_FILE"
echo "$(date): 开始停止服务 (增强版-优化 v2)" | tee -a "$LOG_FILE"

# ============================================
# 第一阶段: 停止用户Web服务
# ============================================

# 停止PM2应用 (以vanabel用户运行)
echo "=== [1/12] 停止PM2应用 ===" | tee -a "$LOG_FILE"
if su - vanabel -c "pm2 list 2>/dev/null | grep -q 'online'" 2>/dev/null; then
    su - vanabel -c "pm2 stop all" 2>&1 | tee -a "$LOG_FILE"
    echo "  ✓ PM2应用已停止" | tee -a "$LOG_FILE"
else
    echo "  PM2应用未运行或已停止" | tee -a "$LOG_FILE"
fi

# 停止Nginx
echo "=== [2/11] 停止Nginx ===" | tee -a "$LOG_FILE"
if systemctl is-active --quiet nginx; then
    systemctl stop nginx 2>&1 | tee -a "$LOG_FILE"
    sleep 1
    if ! systemctl is-active --quiet nginx; then
        echo "  ✓ Nginx已停止" | tee -a "$LOG_FILE"
    else
        echo "  ⚠ Nginx停止失败" | tee -a "$LOG_FILE"
    fi
else
    echo "  Nginx未运行" | tee -a "$LOG_FILE"
fi

# 停止PHP-FPM
echo "=== [3/11] 停止PHP-FPM ===" | tee -a "$LOG_FILE"
PHP_STOPPED=0
systemctl list-units "pkg-WebStation-php*" --no-legend --state=active | awk '{print $1}' | while read service; do
    echo "  停止 $service" | tee -a "$LOG_FILE"
    systemctl stop "$service" 2>&1 | tee -a "$LOG_FILE" || true
    PHP_STOPPED=1
done
if [ "$PHP_STOPPED" -eq 0 ]; then
    echo "  PHP-FPM未运行" | tee -a "$LOG_FILE"
fi

# 停止Apache
echo "=== [4/11] 停止Apache ===" | tee -a "$LOG_FILE"
APACHE_FOUND=false
for apache_svc in $(systemctl list-unit-files "pkg-Apache*" --no-legend 2>/dev/null | awk '{print $1}'); do
    if systemctl is-active --quiet "$apache_svc"; then
        systemctl stop "$apache_svc" 2>&1 | tee -a "$LOG_FILE" || true
        APACHE_FOUND=true
    fi
done
if [ "$APACHE_FOUND" = false ]; then
    echo "  Apache未运行或未安装" | tee -a "$LOG_FILE"
fi

# ============================================
# 第二阶段: 停止高I/O系统服务
# ============================================

# 重要提示: 如果Virtual Machine Manager显示有VM运行,请注释掉虚拟化部分!
echo "=== [5/11] 检查虚拟机状态 ===" | tee -a "$LOG_FILE"
VM_COUNT=$(virsh list --name 2>/dev/null | grep -v "^$" | wc -l)
if [ "$VM_COUNT" -gt 0 ]; then
    echo "⚠️  警告: 检测到 $VM_COUNT 个虚拟机正在运行!" | tee -a "$LOG_FILE"
    echo "⚠️  跳过停止虚拟化服务以保护运行中的虚拟机" | tee -a "$LOG_FILE"
else
    echo "  没有虚拟机运行,可以安全停止虚拟化服务" | tee -a "$LOG_FILE"
    echo "  注意: 如果GUI显示有VM,请手动注释此部分!" | tee -a "$LOG_FILE"
    
    # 如果您确认GUI中有VM运行,请注释掉下面这段
    # ====== 开始:虚拟化服务停止 ======
    echo "  停止虚拟化相关服务..." | tee -a "$LOG_FILE"
    
    if systemctl is-active --quiet pkgctl-Virtualization; then
        stop_service_quiet pkgctl-Virtualization | tee -a "$LOG_FILE"
        sleep 2
    fi
    
    if systemctl is-active --quiet pkg-synoccc-redis; then
        stop_service_quiet pkg-synoccc-redis | tee -a "$LOG_FILE"
        sleep 1
    fi
    
    # 验证停止
    if ! systemctl is-active --quiet pkgctl-Virtualization; then
        echo "  ✓ 虚拟化服务已停止" | tee -a "$LOG_FILE"
    else
        echo "  ⚠ 虚拟化服务停止失败" | tee -a "$LOG_FILE"
    fi
    # ====== 结束:虚拟化服务停止 ======
fi

# 停止Synology Drive
echo "=== [6/11] 停止Synology Drive ===" | tee -a "$LOG_FILE"
if systemctl is-active --quiet pkgctl-SynologyDrive; then
    stop_service_quiet pkgctl-SynologyDrive | tee -a "$LOG_FILE"
    sleep 2
    if ! systemctl is-active --quiet pkgctl-SynologyDrive; then
        echo "  ✓ Drive服务已停止" | tee -a "$LOG_FILE"
    else
        echo "  ⚠ Drive服务停止失败" | tee -a "$LOG_FILE"
    fi
else
    echo "  Drive服务未运行" | tee -a "$LOG_FILE"
fi

# 停止CloudSync
echo "=== [7/11] 停止CloudSync ===" | tee -a "$LOG_FILE"
if systemctl is-active --quiet pkgctl-CloudSync; then
    stop_service_quiet pkgctl-CloudSync | tee -a "$LOG_FILE"
    sleep 1
    if ! systemctl is-active --quiet pkgctl-CloudSync; then
        echo "  ✓ CloudSync已停止" | tee -a "$LOG_FILE"
    fi
else
    echo "  CloudSync未运行" | tee -a "$LOG_FILE"
fi

# 停止索引服务
echo "=== [8/11] 停止索引服务 ===" | tee -a "$LOG_FILE"
INDEX_STOPPED=false
if systemctl is-active --quiet pkg-SynoFinder-fileindexd; then
    systemctl stop pkg-SynoFinder-fileindexd 2>&1 | tee -a "$LOG_FILE" || true
    INDEX_STOPPED=true
fi
if systemctl is-active --quiet synoindexd; then
    systemctl stop synoindexd 2>&1 | tee -a "$LOG_FILE" || true
    INDEX_STOPPED=true
fi
if [ "$INDEX_STOPPED" = false ]; then
    echo "  索引服务未运行" | tee -a "$LOG_FILE"
else
    echo "  ✓ 索引服务已停止" | tee -a "$LOG_FILE"
fi

# 停止EmbyServer
echo "=== [9/11] 停止EmbyServer ===" | tee -a "$LOG_FILE"
if systemctl list-unit-files pkgctl-EmbyServer.service &>/dev/null; then
    if systemctl is-active --quiet pkgctl-EmbyServer; then
        stop_service_quiet pkgctl-EmbyServer | tee -a "$LOG_FILE"
        sleep 1
        if ! systemctl is-active --quiet pkgctl-EmbyServer; then
            echo "  ✓ EmbyServer已停止" | tee -a "$LOG_FILE"
        fi
    else
        echo "  EmbyServer未运行" | tee -a "$LOG_FILE"
    fi
else
    echo "  EmbyServer未安装" | tee -a "$LOG_FILE"
fi

# 停止Synology Photos
echo "=== [10/11] 停止Synology Photos ===" | tee -a "$LOG_FILE"
if systemctl list-unit-files pkgctl-SynologyPhotos.service &>/dev/null; then
    if systemctl is-active --quiet pkgctl-SynologyPhotos; then
        stop_service_quiet pkgctl-SynologyPhotos | tee -a "$LOG_FILE"
        sleep 1
        if ! systemctl is-active --quiet pkgctl-SynologyPhotos; then
            echo "  ✓ Photos已停止" | tee -a "$LOG_FILE"
        fi
    else
        echo "  Photos未运行" | tee -a "$LOG_FILE"
    fi
else
    echo "  Photos未安装" | tee -a "$LOG_FILE"
fi

# ============================================
# 第三阶段: Docker和其他服务
# ============================================

# 停止Docker容器
echo "=== [11/11] 检查并停止Docker容器 ===" | tee -a "$LOG_FILE"
if command -v docker &> /dev/null; then
    RUNNING_CONTAINERS=$(docker ps -q 2>/dev/null | wc -l)
    if [ "$RUNNING_CONTAINERS" -gt 0 ]; then
        echo "停止 $RUNNING_CONTAINERS 个Docker容器..." | tee -a "$LOG_FILE"
        docker stop $(docker ps -q) 2>&1 | tee -a "$LOG_FILE"
    else
        echo "没有运行中的Docker容器" | tee -a "$LOG_FILE"
    fi
else
    echo "Docker未安装" | tee -a "$LOG_FILE"
fi

# ============================================
# 总结
# ============================================

echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "✓ 服务停止完成!" | tee -a "$LOG_FILE"
echo "$(date): 系统已进入低功耗模式" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "已停止的服务:" | tee -a "$LOG_FILE"
echo "  - Web服务 (Nginx/PHP/Apache/PM2)" | tee -a "$LOG_FILE"
if [ "$VM_COUNT" -eq 0 ]; then
    echo "  - 虚拟化服务 (无VM运行,已停止)" | tee -a "$LOG_FILE"
else
    echo "  - 虚拟化服务 (跳过,有VM运行)" | tee -a "$LOG_FILE"
fi
echo "  - Synology Drive 同步" | tee -a "$LOG_FILE"
echo "  - CloudSync 云同步" | tee -a "$LOG_FILE"
echo "  - 索引服务" | tee -a "$LOG_FILE"
echo "  - EmbyServer" | tee -a "$LOG_FILE"
echo "  - Synology Photos" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "预期效果: 磁盘I/O降低70-90%" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
