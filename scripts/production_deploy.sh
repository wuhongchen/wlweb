#!/bin/bash
# -*- coding: utf-8 -*-

# 生产环境部署脚本
# 用于在生产服务器上部署和管理游戏脚本中间件管理系统

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 配置变量
PROJECT_NAME="wlweb"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.prod.yml"
ENV_FILE="$PROJECT_DIR/.env.production"
BACKUP_DIR="$PROJECT_DIR/backups"
LOG_FILE="$PROJECT_DIR/logs/deploy.log"

# 创建日志函数
log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 显示帮助信息
show_help() {
    echo "游戏脚本中间件管理系统 - 生产环境部署脚本"
    echo ""
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  deploy          完整部署（首次部署）"
    echo "  update          更新代码并重新部署"
    echo "  restart         重启所有服务"
    echo "  stop            停止所有服务"
    echo "  start           启动所有服务"
    echo "  status          查看服务状态"
    echo "  logs            查看服务日志"
    echo "  backup          创建数据备份"
    echo "  restore         恢复数据备份"
    echo "  cleanup         清理Docker资源"
    echo "  health          健康检查"
    echo "  ssl             配置SSL证书"
    echo "  monitor         查看系统监控"
    echo "  help            显示帮助信息"
    echo ""
    echo "选项:"
    echo "  -f, --force     强制执行（跳过确认）"
    echo "  -v, --verbose   详细输出"
    echo "  -q, --quiet     静默模式"
    echo ""
    echo "示例:"
    echo "  $0 deploy                # 首次部署"
    echo "  $0 update --force        # 强制更新"
    echo "  $0 logs backend          # 查看后端日志"
    echo "  $0 backup --verbose      # 详细备份"
}

# 检查环境
check_environment() {
    log_step "检查部署环境..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    # 检查Docker服务
    if ! docker info &> /dev/null; then
        log_error "Docker服务未运行，请启动Docker服务"
        exit 1
    fi
    
    # 检查配置文件
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log_error "Docker Compose配置文件不存在: $DOCKER_COMPOSE_FILE"
        exit 1
    fi
    
    if [ ! -f "$ENV_FILE" ]; then
        log_error "环境配置文件不存在: $ENV_FILE"
        log_info "请复制 .env.production 模板并配置相关参数"
        exit 1
    fi
    
    log_info "环境检查通过"
}

# 检查配置安全性
check_security() {
    log_step "检查安全配置..."
    
    # 检查默认密码
    if grep -q "change_this" "$ENV_FILE"; then
        log_error "检测到默认密码，请修改 $ENV_FILE 中的所有密码"
        exit 1
    fi
    
    # 检查SECRET_KEY长度
    SECRET_KEY=$(grep "^SECRET_KEY=" "$ENV_FILE" | cut -d'=' -f2)
    if [ ${#SECRET_KEY} -lt 32 ]; then
        log_error "SECRET_KEY长度不足32个字符，请生成更安全的密钥"
        log_info "生成命令: openssl rand -hex 32"
        exit 1
    fi
    
    # 检查DEBUG模式
    if grep -q "DEBUG=true" "$ENV_FILE"; then
        log_warn "生产环境不应启用DEBUG模式"
    fi
    
    log_info "安全配置检查通过"
}

# 创建必要目录
setup_directories() {
    log_step "创建必要目录..."
    
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$PROJECT_DIR/logs/nginx"
    mkdir -p "$PROJECT_DIR/logs/backend"
    mkdir -p "$PROJECT_DIR/logs/mysql"
    mkdir -p "$PROJECT_DIR/logs/redis"
    mkdir -p "$PROJECT_DIR/data/mysql"
    mkdir -p "$PROJECT_DIR/data/redis"
    mkdir -p "$PROJECT_DIR/nginx/ssl"
    mkdir -p "$PROJECT_DIR/uploads"
    mkdir -p "$PROJECT_DIR/static"
    
    # 设置权限
    chmod 755 "$PROJECT_DIR/logs"
    chmod 755 "$PROJECT_DIR/data"
    chmod 700 "$PROJECT_DIR/nginx/ssl"
    
    log_info "目录创建完成"
}

# 备份数据
backup_data() {
    log_step "备份数据..."
    
    local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    mkdir -p "$backup_path"
    
    # 备份数据库
    if docker-compose -f "$DOCKER_COMPOSE_FILE" ps mysql | grep -q "Up"; then
        log_info "备份MySQL数据库..."
        docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T mysql mysqldump \
            -u root -p"$(grep MYSQL_ROOT_PASSWORD $ENV_FILE | cut -d'=' -f2)" \
            --all-databases > "$backup_path/mysql_backup.sql"
        gzip "$backup_path/mysql_backup.sql"
    fi
    
    # 备份Redis数据
    if docker-compose -f "$DOCKER_COMPOSE_FILE" ps redis | grep -q "Up"; then
        log_info "备份Redis数据..."
        docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T redis redis-cli \
            -a "$(grep REDIS_PASSWORD $ENV_FILE | cut -d'=' -f2)" \
            --rdb "$backup_path/redis_backup.rdb" || true
    fi
    
    # 备份上传文件
    if [ -d "$PROJECT_DIR/uploads" ]; then
        log_info "备份上传文件..."
        tar -czf "$backup_path/uploads_backup.tar.gz" -C "$PROJECT_DIR" uploads
    fi
    
    # 备份配置文件
    log_info "备份配置文件..."
    cp "$ENV_FILE" "$backup_path/"
    cp "$DOCKER_COMPOSE_FILE" "$backup_path/"
    
    log_info "备份完成: $backup_path"
    log_to_file "数据备份完成: $backup_path"
}

# 部署服务
deploy_services() {
    log_step "部署服务..."
    
    cd "$PROJECT_DIR"
    
    # 拉取最新镜像
    log_info "拉取最新镜像..."
    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" --env-file "$ENV_FILE" pull; then
        log_warn "镜像拉取失败，可能是网络问题，继续构建..."
    fi
    
    # 构建镜像
    log_info "构建应用镜像..."
    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" --env-file "$ENV_FILE" build --no-cache; then
        log_warn "镜像构建失败，尝试清理缓存后重新构建..."
        
        # 清理构建缓存
        docker builder prune -f
        
        # 重试构建
        if ! docker-compose -f "$DOCKER_COMPOSE_FILE" --env-file "$ENV_FILE" build --no-cache --pull; then
            log_error "镜像构建失败，请检查网络连接和镜像源配置"
            log_info "建议检查 Docker daemon 配置文件 /etc/docker/daemon.json"
            log_info "或参考 README_DOCKER_DEPLOY.md 中的镜像源配置"
            exit 1
        fi
    fi
    
    # 启动服务
    log_info "启动服务..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" --env-file "$ENV_FILE" up -d
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 30
    
    # 检查服务状态
    check_services_health
    
    log_info "服务部署完成"
    log_to_file "服务部署完成"
}

# 检查服务健康状态
check_services_health() {
    log_step "检查服务健康状态..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "健康检查 (第 $attempt/$max_attempts 次)..."
        
        # 检查所有服务是否运行
        if docker-compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "Exit"; then
            log_warn "发现异常退出的服务"
            docker-compose -f "$DOCKER_COMPOSE_FILE" ps
        else
            log_info "所有服务运行正常"
            return 0
        fi
        
        sleep 10
        ((attempt++))
    done
    
    log_error "服务健康检查失败"
    return 1
}

# 更新服务
update_services() {
    log_step "更新服务..."
    
    cd "$PROJECT_DIR"
    
    # 拉取最新代码
    if [ -d ".git" ]; then
        log_info "拉取最新代码..."
        git pull origin main
    fi
    
    # 备份当前数据
    backup_data
    
    # 重新构建和部署
    deploy_services
    
    log_info "服务更新完成"
}

# 查看服务状态
show_status() {
    log_step "查看服务状态..."
    
    echo "=== Docker Compose 服务状态 ==="
    docker-compose -f "$DOCKER_COMPOSE_FILE" ps
    
    echo ""
    echo "=== 系统资源使用情况 ==="
    docker stats --no-stream
    
    echo ""
    echo "=== 磁盘使用情况 ==="
    df -h
    
    echo ""
    echo "=== 内存使用情况 ==="
    free -h
}

# 查看日志
show_logs() {
    local service="$1"
    local lines="${2:-100}"
    
    if [ -n "$service" ]; then
        log_info "查看 $service 服务日志..."
        docker-compose -f "$DOCKER_COMPOSE_FILE" logs --tail="$lines" -f "$service"
    else
        log_info "查看所有服务日志..."
        docker-compose -f "$DOCKER_COMPOSE_FILE" logs --tail="$lines" -f
    fi
}

# 清理Docker资源
cleanup_docker() {
    log_step "清理Docker资源..."
    
    # 清理未使用的镜像
    docker image prune -f
    
    # 清理未使用的容器
    docker container prune -f
    
    # 清理未使用的网络
    docker network prune -f
    
    # 清理未使用的卷（谨慎使用）
    # docker volume prune -f
    
    log_info "Docker资源清理完成"
}

# 配置SSL证书
setup_ssl() {
    log_step "配置SSL证书..."
    
    local domain="$1"
    
    if [ -z "$domain" ]; then
        log_error "请提供域名参数"
        log_info "用法: $0 ssl yourdomain.com"
        exit 1
    fi
    
    # 安装Certbot
    if ! command -v certbot &> /dev/null; then
        log_info "安装Certbot..."
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
    fi
    
    # 获取SSL证书
    log_info "获取SSL证书..."
    certbot certonly --standalone -d "$domain" --agree-tos --no-eff-email
    
    # 复制证书到项目目录
    cp "/etc/letsencrypt/live/$domain/fullchain.pem" "$PROJECT_DIR/nginx/ssl/cert.pem"
    cp "/etc/letsencrypt/live/$domain/privkey.pem" "$PROJECT_DIR/nginx/ssl/key.pem"
    
    # 设置证书权限
    chmod 600 "$PROJECT_DIR/nginx/ssl/key.pem"
    chmod 644 "$PROJECT_DIR/nginx/ssl/cert.pem"
    
    # 设置自动续期
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    log_info "SSL证书配置完成"
}

# 主函数
main() {
    local command="$1"
    shift
    
    case "$command" in
        "deploy")
            check_environment
            check_security
            setup_directories
            deploy_services
            ;;
        "update")
            check_environment
            update_services
            ;;
        "restart")
            log_info "重启服务..."
            docker-compose -f "$DOCKER_COMPOSE_FILE" restart
            ;;
        "stop")
            log_info "停止服务..."
            docker-compose -f "$DOCKER_COMPOSE_FILE" down
            ;;
        "start")
            log_info "启动服务..."
            docker-compose -f "$DOCKER_COMPOSE_FILE" --env-file "$ENV_FILE" up -d
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "$@"
            ;;
        "backup")
            backup_data
            ;;
        "cleanup")
            cleanup_docker
            ;;
        "health")
            check_services_health
            ;;
        "ssl")
            setup_ssl "$@"
            ;;
        "monitor")
            show_status
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