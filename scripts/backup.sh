#!/bin/bash
# -*- coding: utf-8 -*-

# 数据备份和恢复脚本
# 用于游戏脚本中间件管理系统的数据备份和恢复

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
ENV_FILE="$PROJECT_DIR/.env.production"
BACKUP_DIR="$PROJECT_DIR/backups"
LOG_FILE="$PROJECT_DIR/logs/backup.log"

# 备份保留策略
DAILY_BACKUPS_KEEP=7    # 保留7天的每日备份
WEEKLY_BACKUPS_KEEP=4   # 保留4周的每周备份
MONTHLY_BACKUPS_KEEP=12 # 保留12个月的每月备份

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 创建必要目录
setup_directories() {
    mkdir -p "$BACKUP_DIR/daily"
    mkdir -p "$BACKUP_DIR/weekly"
    mkdir -p "$BACKUP_DIR/monthly"
    mkdir -p "$PROJECT_DIR/logs"
}

# 获取数据库配置
get_db_config() {
    if [ ! -f "$ENV_FILE" ]; then
        log_error "环境配置文件不存在: $ENV_FILE"
        exit 1
    fi
    
    MYSQL_ROOT_PASSWORD=$(grep "^MYSQL_ROOT_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    MYSQL_DATABASE=$(grep "^MYSQL_DATABASE=" "$ENV_FILE" | cut -d'=' -f2)
    REDIS_PASSWORD=$(grep "^REDIS_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    
    if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_DATABASE" ]; then
        log_error "数据库配置不完整"
        exit 1
    fi
}

# 检查服务状态
check_services() {
    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" ps mysql | grep -q "Up"; then
        log_error "MySQL服务未运行"
        return 1
    fi
    
    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" ps redis | grep -q "Up"; then
        log_warn "Redis服务未运行"
    fi
    
    return 0
}

# 备份MySQL数据库
backup_mysql() {
    local backup_path="$1"
    local backup_name="mysql_$(date +%Y%m%d_%H%M%S).sql"
    local backup_file="$backup_path/$backup_name"
    
    log_step "备份MySQL数据库..."
    
    # 创建数据库备份
    docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T mysql mysqldump \
        -u root -p"$MYSQL_ROOT_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --all-databases > "$backup_file"
    
    if [ $? -eq 0 ]; then
        # 压缩备份文件
        gzip "$backup_file"
        backup_file="${backup_file}.gz"
        
        local file_size=$(du -h "$backup_file" | cut -f1)
        log_info "MySQL备份完成: $backup_file (大小: $file_size)"
        
        # 验证备份文件
        if [ -s "$backup_file" ]; then
            log_info "备份文件验证通过"
        else
            log_error "备份文件为空或损坏"
            return 1
        fi
    else
        log_error "MySQL备份失败"
        return 1
    fi
    
    echo "$backup_file"
}

# 备份Redis数据
backup_redis() {
    local backup_path="$1"
    local backup_name="redis_$(date +%Y%m%d_%H%M%S).rdb"
    local backup_file="$backup_path/$backup_name"
    
    log_step "备份Redis数据..."
    
    # 触发Redis保存
    if [ -n "$REDIS_PASSWORD" ]; then
        docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T redis redis-cli -a "$REDIS_PASSWORD" BGSAVE
    else
        docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T redis redis-cli BGSAVE
    fi
    
    # 等待保存完成
    sleep 5
    
    # 复制RDB文件
    docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T redis cat /data/dump.rdb > "$backup_file"
    
    if [ $? -eq 0 ] && [ -s "$backup_file" ]; then
        # 压缩备份文件
        gzip "$backup_file"
        backup_file="${backup_file}.gz"
        
        local file_size=$(du -h "$backup_file" | cut -f1)
        log_info "Redis备份完成: $backup_file (大小: $file_size)"
    else
        log_warn "Redis备份失败或文件为空"
        return 1
    fi
    
    echo "$backup_file"
}

# 备份上传文件
backup_uploads() {
    local backup_path="$1"
    local backup_name="uploads_$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_file="$backup_path/$backup_name"
    
    log_step "备份上传文件..."
    
    if [ -d "$PROJECT_DIR/uploads" ] && [ "$(ls -A $PROJECT_DIR/uploads)" ]; then
        tar -czf "$backup_file" -C "$PROJECT_DIR" uploads
        
        if [ $? -eq 0 ]; then
            local file_size=$(du -h "$backup_file" | cut -f1)
            log_info "上传文件备份完成: $backup_file (大小: $file_size)"
        else
            log_error "上传文件备份失败"
            return 1
        fi
    else
        log_info "没有上传文件需要备份"
        return 0
    fi
    
    echo "$backup_file"
}

# 备份配置文件
backup_configs() {
    local backup_path="$1"
    local config_backup_dir="$backup_path/configs"
    
    log_step "备份配置文件..."
    
    mkdir -p "$config_backup_dir"
    
    # 备份环境配置
    cp "$ENV_FILE" "$config_backup_dir/"
    
    # 备份Docker配置
    cp "$DOCKER_COMPOSE_FILE" "$config_backup_dir/"
    
    # 备份Nginx配置
    if [ -f "$PROJECT_DIR/nginx/nginx.prod.conf" ]; then
        cp "$PROJECT_DIR/nginx/nginx.prod.conf" "$config_backup_dir/"
    fi
    
    # 备份SSL证书（如果存在）
    if [ -d "$PROJECT_DIR/nginx/ssl" ]; then
        cp -r "$PROJECT_DIR/nginx/ssl" "$config_backup_dir/"
    fi
    
    log_info "配置文件备份完成: $config_backup_dir"
}

# 创建完整备份
create_full_backup() {
    local backup_type="${1:-daily}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="full_backup_${timestamp}"
    local backup_path="$BACKUP_DIR/$backup_type/$backup_name"
    
    log_step "创建完整备份: $backup_name"
    
    # 创建备份目录
    mkdir -p "$backup_path"
    
    # 创建备份信息文件
    {
        echo "备份信息"
        echo "========"
        echo "备份时间: $(date)"
        echo "备份类型: $backup_type"
        echo "系统信息: $(uname -a)"
        echo "Docker版本: $(docker --version)"
        echo "项目版本: $(git -C $PROJECT_DIR rev-parse HEAD 2>/dev/null || echo 'Unknown')"
        echo ""
    } > "$backup_path/backup_info.txt"
    
    # 执行各项备份
    local mysql_backup=$(backup_mysql "$backup_path")
    local redis_backup=$(backup_redis "$backup_path")
    local uploads_backup=$(backup_uploads "$backup_path")
    
    backup_configs "$backup_path"
    
    # 创建备份清单
    {
        echo "备份文件清单"
        echo "============"
        echo "MySQL备份: $(basename "$mysql_backup" 2>/dev/null || echo 'Failed')"
        echo "Redis备份: $(basename "$redis_backup" 2>/dev/null || echo 'Failed')"
        echo "上传文件备份: $(basename "$uploads_backup" 2>/dev/null || echo 'No files')"
        echo "配置文件备份: configs/"
        echo ""
        echo "文件列表:"
        ls -la "$backup_path"
    } >> "$backup_path/backup_info.txt"
    
    # 计算备份总大小
    local total_size=$(du -sh "$backup_path" | cut -f1)
    
    log_info "完整备份创建完成: $backup_path (总大小: $total_size)"
    
    # 创建符号链接到最新备份
    local latest_link="$BACKUP_DIR/$backup_type/latest"
    rm -f "$latest_link"
    ln -s "$backup_name" "$latest_link"
    
    echo "$backup_path"
}

# 恢复MySQL数据库
restore_mysql() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        log_error "MySQL备份文件不存在: $backup_file"
        return 1
    fi
    
    log_step "恢复MySQL数据库..."
    log_warn "这将覆盖当前数据库中的所有数据！"
    
    # 解压备份文件（如果是压缩的）
    local sql_file="$backup_file"
    if [[ "$backup_file" == *.gz ]]; then
        sql_file="${backup_file%.gz}"
        gunzip -c "$backup_file" > "$sql_file"
    fi
    
    # 恢复数据库
    docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T mysql mysql \
        -u root -p"$MYSQL_ROOT_PASSWORD" < "$sql_file"
    
    if [ $? -eq 0 ]; then
        log_info "MySQL数据库恢复完成"
        
        # 清理临时文件
        if [[ "$backup_file" == *.gz ]]; then
            rm -f "$sql_file"
        fi
    else
        log_error "MySQL数据库恢复失败"
        return 1
    fi
}

# 恢复Redis数据
restore_redis() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        log_error "Redis备份文件不存在: $backup_file"
        return 1
    fi
    
    log_step "恢复Redis数据..."
    
    # 停止Redis服务
    docker-compose -f "$DOCKER_COMPOSE_FILE" stop redis
    
    # 解压并复制RDB文件
    local rdb_file="$backup_file"
    if [[ "$backup_file" == *.gz ]]; then
        rdb_file="${backup_file%.gz}"
        gunzip -c "$backup_file" > "$rdb_file"
    fi
    
    # 复制到Redis数据目录
    docker-compose -f "$DOCKER_COMPOSE_FILE" run --rm -v "$rdb_file:/tmp/dump.rdb" redis \
        sh -c "cp /tmp/dump.rdb /data/dump.rdb && chown redis:redis /data/dump.rdb"
    
    # 启动Redis服务
    docker-compose -f "$DOCKER_COMPOSE_FILE" start redis
    
    # 等待服务启动
    sleep 5
    
    # 验证恢复
    if docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T redis redis-cli ping | grep -q "PONG"; then
        log_info "Redis数据恢复完成"
        
        # 清理临时文件
        if [[ "$backup_file" == *.gz ]]; then
            rm -f "$rdb_file"
        fi
    else
        log_error "Redis数据恢复失败"
        return 1
    fi
}

# 恢复上传文件
restore_uploads() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        log_error "上传文件备份不存在: $backup_file"
        return 1
    fi
    
    log_step "恢复上传文件..."
    
    # 备份当前上传文件
    if [ -d "$PROJECT_DIR/uploads" ]; then
        mv "$PROJECT_DIR/uploads" "$PROJECT_DIR/uploads.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 解压上传文件
    tar -xzf "$backup_file" -C "$PROJECT_DIR"
    
    if [ $? -eq 0 ]; then
        log_info "上传文件恢复完成"
    else
        log_error "上传文件恢复失败"
        return 1
    fi
}

# 从完整备份恢复
restore_full_backup() {
    local backup_path="$1"
    
    if [ ! -d "$backup_path" ]; then
        log_error "备份目录不存在: $backup_path"
        return 1
    fi
    
    log_step "从完整备份恢复: $backup_path"
    
    # 显示备份信息
    if [ -f "$backup_path/backup_info.txt" ]; then
        echo "=== 备份信息 ==="
        cat "$backup_path/backup_info.txt"
        echo ""
    fi
    
    # 确认恢复操作
    read -p "确认要恢复此备份吗？这将覆盖当前所有数据 [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "恢复操作已取消"
        return 0
    fi
    
    # 恢复MySQL
    local mysql_backup=$(find "$backup_path" -name "mysql_*.sql.gz" | head -1)
    if [ -n "$mysql_backup" ]; then
        restore_mysql "$mysql_backup"
    fi
    
    # 恢复Redis
    local redis_backup=$(find "$backup_path" -name "redis_*.rdb.gz" | head -1)
    if [ -n "$redis_backup" ]; then
        restore_redis "$redis_backup"
    fi
    
    # 恢复上传文件
    local uploads_backup=$(find "$backup_path" -name "uploads_*.tar.gz" | head -1)
    if [ -n "$uploads_backup" ]; then
        restore_uploads "$uploads_backup"
    fi
    
    log_info "完整备份恢复完成"
}

# 清理旧备份
cleanup_old_backups() {
    log_step "清理旧备份..."
    
    # 清理每日备份
    find "$BACKUP_DIR/daily" -maxdepth 1 -type d -name "full_backup_*" | \
        sort -r | tail -n +$((DAILY_BACKUPS_KEEP + 1)) | \
        xargs -r rm -rf
    
    # 清理每周备份
    find "$BACKUP_DIR/weekly" -maxdepth 1 -type d -name "full_backup_*" | \
        sort -r | tail -n +$((WEEKLY_BACKUPS_KEEP + 1)) | \
        xargs -r rm -rf
    
    # 清理每月备份
    find "$BACKUP_DIR/monthly" -maxdepth 1 -type d -name "full_backup_*" | \
        sort -r | tail -n +$((MONTHLY_BACKUPS_KEEP + 1)) | \
        xargs -r rm -rf
    
    log_info "旧备份清理完成"
}

# 列出可用备份
list_backups() {
    local backup_type="${1:-all}"
    
    log_step "可用备份列表"
    
    if [ "$backup_type" = "all" ] || [ "$backup_type" = "daily" ]; then
        echo "=== 每日备份 ==="
        if [ -d "$BACKUP_DIR/daily" ]; then
            ls -la "$BACKUP_DIR/daily" | grep "full_backup_" || echo "无每日备份"
        fi
        echo ""
    fi
    
    if [ "$backup_type" = "all" ] || [ "$backup_type" = "weekly" ]; then
        echo "=== 每周备份 ==="
        if [ -d "$BACKUP_DIR/weekly" ]; then
            ls -la "$BACKUP_DIR/weekly" | grep "full_backup_" || echo "无每周备份"
        fi
        echo ""
    fi
    
    if [ "$backup_type" = "all" ] || [ "$backup_type" = "monthly" ]; then
        echo "=== 每月备份 ==="
        if [ -d "$BACKUP_DIR/monthly" ]; then
            ls -la "$BACKUP_DIR/monthly" | grep "full_backup_" || echo "无每月备份"
        fi
        echo ""
    fi
}

# 验证备份完整性
verify_backup() {
    local backup_path="$1"
    
    if [ ! -d "$backup_path" ]; then
        log_error "备份目录不存在: $backup_path"
        return 1
    fi
    
    log_step "验证备份完整性: $backup_path"
    
    local errors=0
    
    # 检查备份信息文件
    if [ ! -f "$backup_path/backup_info.txt" ]; then
        log_error "缺少备份信息文件"
        ((errors++))
    fi
    
    # 检查MySQL备份
    local mysql_backup=$(find "$backup_path" -name "mysql_*.sql.gz" | head -1)
    if [ -n "$mysql_backup" ]; then
        if ! gunzip -t "$mysql_backup" 2>/dev/null; then
            log_error "MySQL备份文件损坏: $mysql_backup"
            ((errors++))
        else
            log_info "MySQL备份文件验证通过"
        fi
    else
        log_warn "未找到MySQL备份文件"
    fi
    
    # 检查Redis备份
    local redis_backup=$(find "$backup_path" -name "redis_*.rdb.gz" | head -1)
    if [ -n "$redis_backup" ]; then
        if ! gunzip -t "$redis_backup" 2>/dev/null; then
            log_error "Redis备份文件损坏: $redis_backup"
            ((errors++))
        else
            log_info "Redis备份文件验证通过"
        fi
    else
        log_warn "未找到Redis备份文件"
    fi
    
    # 检查上传文件备份
    local uploads_backup=$(find "$backup_path" -name "uploads_*.tar.gz" | head -1)
    if [ -n "$uploads_backup" ]; then
        if ! tar -tzf "$uploads_backup" >/dev/null 2>&1; then
            log_error "上传文件备份损坏: $uploads_backup"
            ((errors++))
        else
            log_info "上传文件备份验证通过"
        fi
    fi
    
    # 检查配置文件
    if [ ! -d "$backup_path/configs" ]; then
        log_error "缺少配置文件备份"
        ((errors++))
    else
        log_info "配置文件备份验证通过"
    fi
    
    if [ $errors -eq 0 ]; then
        log_info "备份完整性验证通过"
        return 0
    else
        log_error "备份完整性验证失败，发现 $errors 个错误"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "数据备份和恢复脚本"
    echo ""
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "备份命令:"
    echo "  backup [daily|weekly|monthly]  创建完整备份（默认：daily）"
    echo "  mysql                          仅备份MySQL数据库"
    echo "  redis                          仅备份Redis数据"
    echo "  uploads                        仅备份上传文件"
    echo "  configs                        仅备份配置文件"
    echo ""
    echo "恢复命令:"
    echo "  restore <backup_path>          从完整备份恢复"
    echo "  restore-mysql <backup_file>    恢复MySQL数据库"
    echo "  restore-redis <backup_file>    恢复Redis数据"
    echo "  restore-uploads <backup_file>  恢复上传文件"
    echo ""
    echo "管理命令:"
    echo "  list [daily|weekly|monthly]    列出可用备份"
    echo "  verify <backup_path>           验证备份完整性"
    echo "  cleanup                        清理旧备份"
    echo "  help                           显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 backup daily                # 创建每日备份"
    echo "  $0 list                        # 列出所有备份"
    echo "  $0 restore /path/to/backup     # 恢复备份"
    echo "  $0 verify /path/to/backup      # 验证备份"
    echo "  $0 cleanup                     # 清理旧备份"
}

# 主函数
main() {
    local command="$1"
    shift
    
    # 初始化
    setup_directories
    get_db_config
    
    case "$command" in
        "backup")
            local backup_type="${1:-daily}"
            check_services
            create_full_backup "$backup_type"
            cleanup_old_backups
            ;;
        "mysql")
            check_services
            backup_mysql "$BACKUP_DIR/manual"
            ;;
        "redis")
            check_services
            backup_redis "$BACKUP_DIR/manual"
            ;;
        "uploads")
            backup_uploads "$BACKUP_DIR/manual"
            ;;
        "configs")
            backup_configs "$BACKUP_DIR/manual"
            ;;
        "restore")
            local backup_path="$1"
            if [ -z "$backup_path" ]; then
                log_error "请指定备份路径"
                exit 1
            fi
            check_services
            restore_full_backup "$backup_path"
            ;;
        "restore-mysql")
            local backup_file="$1"
            if [ -z "$backup_file" ]; then
                log_error "请指定MySQL备份文件"
                exit 1
            fi
            check_services
            restore_mysql "$backup_file"
            ;;
        "restore-redis")
            local backup_file="$1"
            if [ -z "$backup_file" ]; then
                log_error "请指定Redis备份文件"
                exit 1
            fi
            check_services
            restore_redis "$backup_file"
            ;;
        "restore-uploads")
            local backup_file="$1"
            if [ -z "$backup_file" ]; then
                log_error "请指定上传文件备份"
                exit 1
            fi
            restore_uploads "$backup_file"
            ;;
        "list")
            list_backups "$1"
            ;;
        "verify")
            local backup_path="$1"
            if [ -z "$backup_path" ]; then
                log_error "请指定备份路径"
                exit 1
            fi
            verify_backup "$backup_path"
            ;;
        "cleanup")
            cleanup_old_backups
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