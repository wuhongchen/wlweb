#!/bin/bash
# -*- coding: utf-8 -*-

# 系统监控脚本
# 用于监控游戏脚本中间件管理系统的运行状态

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.prod.yml"
LOG_DIR="$PROJECT_DIR/logs"
MONITOR_LOG="$LOG_DIR/monitor.log"
ALERT_LOG="$LOG_DIR/alerts.log"

# 阈值配置
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85
LOAD_THRESHOLD=5.0

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$MONITOR_LOG"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$MONITOR_LOG"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$ALERT_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$MONITOR_LOG"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$ALERT_LOG"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 创建日志目录
mkdir -p "$LOG_DIR"

# 检查Docker服务状态
check_docker_services() {
    log_step "检查Docker服务状态..."
    
    local services=("mysql" "redis" "backend" "frontend")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if ! docker-compose -f "$DOCKER_COMPOSE_FILE" ps "$service" | grep -q "Up"; then
            failed_services+=("$service")
            log_error "服务 $service 未运行"
        else
            log_info "服务 $service 运行正常"
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        log_error "发现 ${#failed_services[@]} 个服务异常: ${failed_services[*]}"
        return 1
    fi
    
    return 0
}

# 检查服务健康状态
check_service_health() {
    log_step "检查服务健康状态..."
    
    # 检查后端API健康状态
    local backend_url="http://localhost:8000/health"
    if curl -s -f "$backend_url" > /dev/null; then
        log_info "后端API健康检查通过"
    else
        log_error "后端API健康检查失败"
        return 1
    fi
    
    # 检查前端服务
    local frontend_url="http://localhost:80"
    if curl -s -f "$frontend_url" > /dev/null; then
        log_info "前端服务健康检查通过"
    else
        log_error "前端服务健康检查失败"
        return 1
    fi
    
    # 检查数据库连接
    if docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T mysql mysqladmin ping > /dev/null 2>&1; then
        log_info "数据库连接正常"
    else
        log_error "数据库连接失败"
        return 1
    fi
    
    # 检查Redis连接
    if docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T redis redis-cli ping | grep -q "PONG"; then
        log_info "Redis连接正常"
    else
        log_error "Redis连接失败"
        return 1
    fi
    
    return 0
}

# 检查系统资源使用情况
check_system_resources() {
    log_step "检查系统资源使用情况..."
    
    # 检查CPU使用率
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        log_warn "CPU使用率过高: ${cpu_usage}% (阈值: ${CPU_THRESHOLD}%)"
    else
        log_info "CPU使用率正常: ${cpu_usage}%"
    fi
    
    # 检查内存使用率
    local memory_info=$(free | grep Mem)
    local total_memory=$(echo $memory_info | awk '{print $2}')
    local used_memory=$(echo $memory_info | awk '{print $3}')
    local memory_usage=$(echo "scale=2; $used_memory * 100 / $total_memory" | bc)
    
    if (( $(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l) )); then
        log_warn "内存使用率过高: ${memory_usage}% (阈值: ${MEMORY_THRESHOLD}%)"
    else
        log_info "内存使用率正常: ${memory_usage}%"
    fi
    
    # 检查磁盘使用率
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        log_warn "磁盘使用率过高: ${disk_usage}% (阈值: ${DISK_THRESHOLD}%)"
    else
        log_info "磁盘使用率正常: ${disk_usage}%"
    fi
    
    # 检查系统负载
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    if (( $(echo "$load_avg > $LOAD_THRESHOLD" | bc -l) )); then
        log_warn "系统负载过高: $load_avg (阈值: $LOAD_THRESHOLD)"
    else
        log_info "系统负载正常: $load_avg"
    fi
}

# 检查Docker容器资源使用情况
check_container_resources() {
    log_step "检查容器资源使用情况..."
    
    # 获取容器统计信息
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | while read line; do
        if [[ $line == *"CONTAINER"* ]]; then
            continue
        fi
        
        local container=$(echo $line | awk '{print $1}')
        local cpu_perc=$(echo $line | awk '{print $2}' | sed 's/%//')
        local mem_perc=$(echo $line | awk '{print $4}' | sed 's/%//')
        
        if (( $(echo "$cpu_perc > $CPU_THRESHOLD" | bc -l) )); then
            log_warn "容器 $container CPU使用率过高: ${cpu_perc}%"
        fi
        
        if (( $(echo "$mem_perc > $MEMORY_THRESHOLD" | bc -l) )); then
            log_warn "容器 $container 内存使用率过高: ${mem_perc}%"
        fi
    done
}

# 检查日志文件大小
check_log_sizes() {
    log_step "检查日志文件大小..."
    
    local max_log_size=100  # MB
    
    find "$LOG_DIR" -name "*.log" -type f | while read logfile; do
        local size_mb=$(du -m "$logfile" | cut -f1)
        if [ "$size_mb" -gt "$max_log_size" ]; then
            log_warn "日志文件过大: $logfile (${size_mb}MB)"
            # 可以选择轮转日志
            # logrotate_file "$logfile"
        fi
    done
}

# 检查网络连接
check_network_connectivity() {
    log_step "检查网络连接..."
    
    # 检查外网连接
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        log_info "外网连接正常"
    else
        log_warn "外网连接异常"
    fi
    
    # 检查DNS解析
    if nslookup google.com > /dev/null 2>&1; then
        log_info "DNS解析正常"
    else
        log_warn "DNS解析异常"
    fi
}

# 检查安全状态
check_security_status() {
    log_step "检查安全状态..."
    
    # 检查失败的登录尝试
    local failed_logins=$(grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l || echo "0")
    if [ "$failed_logins" -gt 10 ]; then
        log_warn "检测到 $failed_logins 次失败登录尝试"
    fi
    
    # 检查端口开放情况
    local open_ports=$(netstat -tuln | grep LISTEN | wc -l)
    log_info "当前开放端口数量: $open_ports"
    
    # 检查防火墙状态
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status | head -1)
        log_info "防火墙状态: $ufw_status"
    fi
}

# 生成监控报告
generate_report() {
    local report_file="$LOG_DIR/monitor_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== 系统监控报告 ==="
        echo "生成时间: $(date)"
        echo ""
        
        echo "=== 服务状态 ==="
        docker-compose -f "$DOCKER_COMPOSE_FILE" ps
        echo ""
        
        echo "=== 系统资源 ==="
        echo "CPU使用率:"
        top -bn1 | grep "Cpu(s)"
        echo ""
        echo "内存使用情况:"
        free -h
        echo ""
        echo "磁盘使用情况:"
        df -h
        echo ""
        echo "系统负载:"
        uptime
        echo ""
        
        echo "=== 容器资源使用 ==="
        docker stats --no-stream
        echo ""
        
        echo "=== 网络连接 ==="
        netstat -tuln | grep LISTEN
        echo ""
        
        echo "=== 最近的警告和错误 ==="
        if [ -f "$ALERT_LOG" ]; then
            tail -20 "$ALERT_LOG"
        fi
        
    } > "$report_file"
    
    log_info "监控报告已生成: $report_file"
}

# 发送告警通知（可扩展）
send_alert() {
    local message="$1"
    local severity="${2:-WARN}"
    
    # 记录到告警日志
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$severity] $message" >> "$ALERT_LOG"
    
    # 这里可以添加邮件、短信、Webhook等通知方式
    # 例如：
    # curl -X POST "$WEBHOOK_URL" -d "{\"text\": \"$message\"}"
    # echo "$message" | mail -s "系统告警" admin@example.com
    
    log_warn "告警: $message"
}

# 自动修复功能
auto_repair() {
    log_step "执行自动修复..."
    
    # 重启异常的服务
    local services=("mysql" "redis" "backend" "frontend")
    for service in "${services[@]}"; do
        if ! docker-compose -f "$DOCKER_COMPOSE_FILE" ps "$service" | grep -q "Up"; then
            log_info "尝试重启服务: $service"
            docker-compose -f "$DOCKER_COMPOSE_FILE" restart "$service"
            sleep 10
            
            if docker-compose -f "$DOCKER_COMPOSE_FILE" ps "$service" | grep -q "Up"; then
                log_info "服务 $service 重启成功"
            else
                log_error "服务 $service 重启失败"
                send_alert "服务 $service 重启失败" "ERROR"
            fi
        fi
    done
    
    # 清理Docker资源
    docker system prune -f > /dev/null 2>&1
    
    # 清理临时文件
    find /tmp -name "*.tmp" -mtime +1 -delete 2>/dev/null || true
}

# 显示帮助信息
show_help() {
    echo "系统监控脚本"
    echo ""
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  check           执行完整监控检查"
    echo "  services        检查服务状态"
    echo "  health          检查服务健康状态"
    echo "  resources       检查系统资源"
    echo "  containers      检查容器资源"
    echo "  network         检查网络连接"
    echo "  security        检查安全状态"
    echo "  logs            检查日志文件"
    echo "  report          生成监控报告"
    echo "  repair          执行自动修复"
    echo "  watch           持续监控模式"
    echo "  help            显示帮助信息"
    echo ""
    echo "选项:"
    echo "  --auto-repair   自动修复检测到的问题"
    echo "  --alert         发送告警通知"
    echo "  --interval N    监控间隔（秒，默认60）"
    echo ""
    echo "示例:"
    echo "  $0 check                    # 执行完整检查"
    echo "  $0 watch --interval 30      # 每30秒监控一次"
    echo "  $0 check --auto-repair      # 检查并自动修复"
}

# 持续监控模式
watch_mode() {
    local interval="${1:-60}"
    local auto_repair="${2:-false}"
    
    log_info "启动持续监控模式，间隔: ${interval}秒"
    
    while true; do
        echo "=== $(date) ==="
        
        # 执行检查
        local check_failed=false
        
        if ! check_docker_services; then
            check_failed=true
        fi
        
        if ! check_service_health; then
            check_failed=true
        fi
        
        check_system_resources
        check_container_resources
        
        # 如果检查失败且启用自动修复
        if [ "$check_failed" = true ] && [ "$auto_repair" = true ]; then
            auto_repair
        fi
        
        echo "下次检查时间: $(date -d "+${interval} seconds")"
        echo ""
        
        sleep "$interval"
    done
}

# 主函数
main() {
    local command="$1"
    shift
    
    local auto_repair=false
    local send_alerts=false
    local interval=60
    
    # 解析选项
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-repair)
                auto_repair=true
                shift
                ;;
            --alert)
                send_alerts=true
                shift
                ;;
            --interval)
                interval="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    case "$command" in
        "check")
            check_docker_services
            check_service_health
            check_system_resources
            check_container_resources
            check_log_sizes
            check_network_connectivity
            check_security_status
            
            if [ "$auto_repair" = true ]; then
                auto_repair
            fi
            ;;
        "services")
            check_docker_services
            ;;
        "health")
            check_service_health
            ;;
        "resources")
            check_system_resources
            ;;
        "containers")
            check_container_resources
            ;;
        "network")
            check_network_connectivity
            ;;
        "security")
            check_security_status
            ;;
        "logs")
            check_log_sizes
            ;;
        "report")
            generate_report
            ;;
        "repair")
            auto_repair
            ;;
        "watch")
            watch_mode "$interval" "$auto_repair"
            ;;
        "help"|"")
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"