#!/bin/bash
# 增强版启动服务脚本 - 优化版 v2
# 特点:
# - 智能检查服务是否已启用
# - 避免重复启动已运行的服务
# - 清晰的状态反馈(✓成功 ⚠警告)
# - 过滤误导性的systemd错误消息
# 作者: Cursor AI
# 日期: 2026-02-08

LOG_FILE="/var/services/homes/vanabel/logs/service_start_enhanced.log"

# 辅助函数: 启动服务并过滤误导性错误
start_service_quiet() {
    local service=$1
    # 过滤掉"dependency job failed"等非关键消息
    systemctl start "$service" 2>&1 | grep -v "A dependency job for.*failed" | grep -v "See 'journalctl -xe' for details" || true
}

echo "========================================" | tee -a "$LOG_FILE"
echo "$(date): 开始启动服务 (增强版-优化 v2)" | tee -a "$LOG_FILE"

# ============================================
# 第一阶段: 启动系统服务
# ============================================

# 启动虚拟化服务
echo "=== [1/11] 启动虚拟化服务 ===" | tee -a "$LOG_FILE"
if systemctl list-unit-files pkgctl-Virtualization.service &>/dev/null; then
    # 先检查Redis是否已运行
    if ! systemctl is-active --quiet pkg-synoccc-redis; then
        start_service_quiet pkg-synoccc-redis | tee -a "$LOG_FILE"
        # 等待Redis启动
        for i in {1..10}; do
            if systemctl is-active --quiet pkg-synoccc-redis; then
                echo "  Redis已启动" | tee -a "$LOG_FILE"
                break
            fi
            sleep 1
        done
    else
        echo "  Redis已在运行" | tee -a "$LOG_FILE"
    fi
    
    # 启动虚拟化服务
    if ! systemctl is-active --quiet pkgctl-Virtualization; then
        start_service_quiet pkgctl-Virtualization | tee -a "$LOG_FILE"
        sleep 3
    fi
    
    # 验证状态
    if systemctl is-active --quiet pkgctl-Virtualization; then
        echo "  ✓ 虚拟化服务已启动" | tee -a "$LOG_FILE"
    else
        echo "  ⚠ 虚拟化服务启动失败或已禁用" | tee -a "$LOG_FILE"
    fi
else
    echo "  虚拟化服务未安装" | tee -a "$LOG_FILE"
fi

# 启动Synology Drive
echo "=== [2/11] 启动Synology Drive ===" | tee -a "$LOG_FILE"
if systemctl list-unit-files pkgctl-SynologyDrive.service &>/dev/null; then
    # 检查是否已启用
    if systemctl is-enabled --quiet pkgctl-SynologyDrive 2>/dev/null; then
        if ! systemctl is-active --quiet pkgctl-SynologyDrive; then
            start_service_quiet pkgctl-SynologyDrive | tee -a "$LOG_FILE"
            sleep 3
        fi
        
        # 验证状态
        if systemctl is-active --quiet pkgctl-SynologyDrive; then
            echo "  ✓ Drive服务已启动" | tee -a "$LOG_FILE"
        else
            echo "  ⚠ Drive服务启动失败" | tee -a "$LOG_FILE"
        fi
    else
        echo "  Drive服务已禁用,跳过" | tee -a "$LOG_FILE"
    fi
else
    echo "  Drive未安装" | tee -a "$LOG_FILE"
fi

# 启动CloudSync  
echo "=== [3/11] 启动CloudSync ===" | tee -a "$LOG_FILE"
if systemctl list-unit-files pkgctl-CloudSync.service &>/dev/null; then
    if systemctl is-enabled --quiet pkgctl-CloudSync 2>/dev/null; then
        if ! systemctl is-active --quiet pkgctl-CloudSync; then
            start_service_quiet pkgctl-CloudSync | tee -a "$LOG_FILE"
            sleep 2
        fi
        if systemctl is-active --quiet pkgctl-CloudSync; then
            echo "  ✓ CloudSync已启动" | tee -a "$LOG_FILE"
        fi
    else
        echo "  CloudSync已禁用,跳过" | tee -a "$LOG_FILE"
    fi
else
    echo "  CloudSync未安装" | tee -a "$LOG_FILE"
fi

# 启动索引服务
echo "=== [4/11] 启动索引服务 ===" | tee -a "$LOG_FILE"
if systemctl list-unit-files pkg-SynoFinder-fileindexd.service &>/dev/null; then
    systemctl start pkg-SynoFinder-fileindexd 2>&1 | tee -a "$LOG_FILE" || true
fi
if systemctl list-unit-files synoindexd.service &>/dev/null; then
    systemctl start synoindexd 2>&1 | tee -a "$LOG_FILE" || true
fi
sleep 2
echo "  索引服务已处理" | tee -a "$LOG_FILE"

# 启动Synology Photos
echo "=== [5/11] 启动Synology Photos ===" | tee -a "$LOG_FILE"
if systemctl list-unit-files pkgctl-SynologyPhotos.service &>/dev/null; then
    # 检查是否已启用
    if systemctl is-enabled --quiet pkgctl-SynologyPhotos 2>/dev/null; then
        if ! systemctl is-active --quiet pkgctl-SynologyPhotos; then
            start_service_quiet pkgctl-SynologyPhotos | tee -a "$LOG_FILE"
            sleep 3
        fi
        
        # 验证状态
        if systemctl is-active --quiet pkgctl-SynologyPhotos; then
            echo "  ✓ Photos服务已启动" | tee -a "$LOG_FILE"
        else
            echo "  ⚠ Photos服务启动失败" | tee -a "$LOG_FILE"
        fi
    else
        echo "  Photos服务已禁用,跳过" | tee -a "$LOG_FILE"
    fi
else
    echo "  Photos未安装" | tee -a "$LOG_FILE"
fi

# 启动EmbyServer
echo "=== [6/11] 启动EmbyServer ===" | tee -a "$LOG_FILE"
if systemctl list-unit-files pkgctl-EmbyServer.service &>/dev/null; then
    if systemctl is-enabled --quiet pkgctl-EmbyServer 2>/dev/null; then
        if ! systemctl is-active --quiet pkgctl-EmbyServer; then
            start_service_quiet pkgctl-EmbyServer | tee -a "$LOG_FILE"
            sleep 2
        fi
        if systemctl is-active --quiet pkgctl-EmbyServer; then
            echo "  ✓ EmbyServer已启动" | tee -a "$LOG_FILE"
        fi
    else
        echo "  EmbyServer已禁用,跳过" | tee -a "$LOG_FILE"
    fi
else
    echo "  EmbyServer未安装" | tee -a "$LOG_FILE"
fi

# ============================================
# 第二阶段: 启动Web服务
# ============================================

# 启动Nginx
echo "=== [7/11] 启动Nginx ===" | tee -a "$LOG_FILE"
if ! systemctl is-active --quiet nginx; then
    systemctl start nginx 2>&1 | tee -a "$LOG_FILE"
    sleep 2
fi
if systemctl is-active --quiet nginx; then
    echo "  ✓ Nginx已启动" | tee -a "$LOG_FILE"
else
    echo "  ⚠ Nginx启动失败" | tee -a "$LOG_FILE"
fi

# 启动PHP-FPM (正确的方法)
echo "=== [8/11] 启动PHP-FPM ===" | tee -a "$LOG_FILE"
# 启动所有已启用的PHP-FPM实例
for php_instance in $(systemctl list-units "pkg-WebStation-php*" --no-legend --state=inactive,failed | awk '{print $1}'); do
    echo "  启动 $php_instance" | tee -a "$LOG_FILE"
    systemctl start "$php_instance" 2>&1 | tee -a "$LOG_FILE" || true
done
sleep 2

# Apache (检查是否存在)
echo "=== [9/11] 启动Apache ===" | tee -a "$LOG_FILE"
if systemctl list-unit-files "pkg-Apache*" &>/dev/null; then
    for apache_svc in $(systemctl list-unit-files "pkg-Apache*" --no-legend | awk '{print $1}'); do
        systemctl start "$apache_svc" 2>&1 | tee -a "$LOG_FILE" || true
    done
else
    echo "  Apache未安装" | tee -a "$LOG_FILE"
fi
sleep 2

# ============================================
# 第三阶段: 启动用户应用
# ============================================

# 启动PM2应用
echo "=== [10/10] 启动PM2应用 ===" | tee -a "$LOG_FILE"
su - vanabel -c "pm2 start all" 2>&1 | tee -a "$LOG_FILE"
sleep 3

# ============================================
# Docker容器 (可选)
# ============================================

if command -v docker &> /dev/null; then
    STOPPED_CONTAINERS=$(docker ps -a -f "status=exited" --format "{{.Names}}" 2>/dev/null | wc -l)
    if [ "$STOPPED_CONTAINERS" -gt 0 ]; then
        echo "" | tee -a "$LOG_FILE"
        echo "提示: 检测到 $STOPPED_CONTAINERS 个已停止的Docker容器" | tee -a "$LOG_FILE"
        echo "如需启动,请手动运行: docker start <container_name>" | tee -a "$LOG_FILE"
    fi
fi

# ============================================
# 总结
# ============================================

echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "✓ 服务启动流程完成!" | tee -a "$LOG_FILE"
echo "$(date): NAS已恢复运行" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "请等待2-3分钟让所有服务完全启动" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "验证服务状态:" | tee -a "$LOG_FILE"
echo "  pm2 list" | tee -a "$LOG_FILE"
echo "  systemctl status nginx" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
