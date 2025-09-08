#!/bin/bash
# -*- coding: utf-8 -*-

# 游戏脚本中间件管理系统 - Docker 自动部署脚本
# 功能：基于Docker的自动部署和更新

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
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
ENV_FILE="$PROJECT_DIR/.env"
ENV_EXAMPLE_FILE="$PROJECT_DIR/.env.example"
BACKUP_DIR="$PROJECT_DIR/backup"
LOG_FILE="$PROJECT_DIR/deploy.log"

# 创建日志函数
log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 检查Docker和Docker Compose
check_docker() {
    log_step "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        log_info "安装命令: curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    # 检查Docker服务状态
    if ! docker info &> /dev/null; then
        log_error "Docker服务未运行，请启动Docker服务"
        log_info "启动命令: sudo systemctl start docker"
        exit 1
    fi
    
    log_info "Docker环境检查通过"
    log_to_file "Docker环境检查通过"
}

# 检查必要文件
check_files() {
    log_step "检查项目文件..."
    
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log_error "docker-compose.yml文件不存在"
        exit 1
    fi
    
    if [ ! -f "$ENV_EXAMPLE_FILE" ]; then
        log_error ".env.example文件不存在"
        exit 1
    fi
    
    log_info "项目文件检查通过"
}

# 创建环境配置文件
setup_env() {
    log_step "配置环境变量..."
    
    if [ ! -f "$ENV_FILE" ]; then
        log_info "创建.env文件..."
        cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
        
        # 生成随机密钥
        JWT_SECRET=$(openssl rand -hex 32)
        sed -i "s/your-secret-key-here/$JWT_SECRET/g" "$ENV_FILE"
        
        log_warn "请检查并修改.env文件中的配置项"
        log_info "配置文件位置: $ENV_FILE"
    else
        log_info "环境配置文件已存在"
    fi
}

# 创建备份
create_backup() {
    log_step "创建数据备份..."
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 备份时间戳
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_NAME="backup_$TIMESTAMP"
    
    # 检查是否有运行中的容器
    if docker-compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "Up"; then
        log_info "备份MySQL数据..."
        
        # 备份MySQL数据
        docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T mysql mysqldump -u root -p\$MYSQL_ROOT_PASSWORD wlweb > "$BACKUP_DIR/${BACKUP_NAME}_mysql.sql" 2>/dev/null || {
            log_warn "MySQL备份失败，可能是首次部署"
        }
        
        # 备份数据卷
        log_info "备份数据卷..."
        docker run --rm -v wlweb_mysql_data:/data -v "$BACKUP_DIR":/backup alpine tar czf "/backup/${BACKUP_NAME}_volumes.tar.gz" -C /data . 2>/dev/null || {
            log_warn "数据卷备份失败，可能是首次部署"
        }
    else
        log_info "没有运行中的容器，跳过数据备份"
    fi
    
    log_to_file "创建备份: $BACKUP_NAME"
}

# 拉取最新代码
update_code() {
    log_step "更新代码..."
    
    if [ -d "$PROJECT_DIR/.git" ]; then
        log_info "拉取最新代码..."
        cd "$PROJECT_DIR"
        git fetch origin
        git reset --hard origin/main
        log_info "代码更新完成"
        log_to_file "代码更新完成"
    else
        log_warn "不是Git仓库，跳过代码更新"
    fi
}

# 构建和启动服务
deploy_services() {
    log_step "部署服务..."
    
    cd "$PROJECT_DIR"
    
    # 停止现有服务
    log_info "停止现有服务..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" down
    
    # 清理未使用的镜像和容器
    log_info "清理Docker资源..."
    docker system prune -f
    
    # 构建镜像
    log_info "构建Docker镜像..."
    
    # 尝试使用不同的镜像源构建
    if ! docker-compose -f "$DOCKER_COMPOSE_FILE" build --no-cache; then
        log_warn "镜像构建失败，可能是网络问题，尝试重新构建..."
        
        # 清理构建缓存
        docker builder prune -f
        
        # 重试构建
        if ! docker-compose -f "$DOCKER_COMPOSE_FILE" build --no-cache --pull; then
            log_error "镜像构建失败，请检查网络连接和镜像源配置"
            log_info "建议检查 Docker daemon 配置文件 /etc/docker/daemon.json"
            log_info "或参考 README_DOCKER_DEPLOY.md 中的镜像源配置"
            exit 1
        fi
    fi
    
    # 启动服务
    log_info "启动服务..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
    
    log_to_file "服务部署完成"
}

# 健康检查
health_check() {
    log_step "执行健康检查..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_info "健康检查 ($attempt/$max_attempts)..."
        
        # 检查容器状态
        if docker-compose -f "$DOCKER_COMPOSE_FILE" ps | grep -q "Up (healthy)\|Up"; then
            # 检查前端服务
            if curl -f http://localhost:3000 >/dev/null 2>&1; then
                log_info "前端服务健康检查通过"
            else
                log_warn "前端服务暂未就绪"
            fi
            
            # 检查后端服务
            if curl -f http://localhost:8000/health >/dev/null 2>&1; then
                log_info "后端服务健康检查通过"
                log_info "所有服务部署成功！"
                log_to_file "健康检查通过，部署成功"
                return 0
            else
                log_warn "后端服务暂未就绪"
            fi
        fi
        
        sleep 10
        ((attempt++))
    done
    
    log_error "健康检查失败，请检查服务状态"
    log_to_file "健康检查失败"
    return 1
}

# 显示服务状态
show_status() {
    log_step "显示服务状态..."
    
    echo "==================== 服务状态 ===================="
    docker-compose -f "$DOCKER_COMPOSE_FILE" ps
    
    echo "\n==================== 访问地址 ===================="
    echo "前端地址: http://localhost:3000"
    echo "后端API: http://localhost:8000"
    echo "API文档: http://localhost:8000/docs"
    echo "\n==================== 管理命令 ===================="
    echo "查看日志: docker-compose -f $DOCKER_COMPOSE_FILE logs -f"
    echo "重启服务: docker-compose -f $DOCKER_COMPOSE_FILE restart"
    echo "停止服务: docker-compose -f $DOCKER_COMPOSE_FILE down"
    echo "================================================="
}

# 清理函数
cleanup() {
    log_step "清理资源..."
    
    # 停止所有容器
    docker-compose -f "$DOCKER_COMPOSE_FILE" down
    
    # 删除未使用的镜像
    docker image prune -f
    
    # 删除未使用的卷（可选，谨慎使用）
    read -p "是否删除数据卷？这将删除所有数据 (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker volume prune -f
        log_warn "数据卷已删除"
    fi
    
    log_info "清理完成"
}

# 显示帮助信息
show_help() {
    echo "游戏脚本中间件管理系统 - Docker部署脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  deploy    完整部署（默认）"
    echo "  update    更新代码并重新部署"
    echo "  restart   重启服务"
    echo "  stop      停止服务"
    echo "  status    显示服务状态"
    echo "  logs      显示服务日志"
    echo "  cleanup   清理Docker资源"
    echo "  backup    仅创建备份"
    echo "  help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 deploy   # 完整部署"
    echo "  $0 update   # 更新并重新部署"
    echo "  $0 status   # 查看状态"
}

# 主函数
main() {
    local action=${1:-deploy}
    
    # 创建日志文件
    touch "$LOG_FILE"
    
    log_info "开始执行Docker部署脚本..."
    log_to_file "开始执行Docker部署脚本 - 操作: $action"
    
    case $action in
        "deploy")
            check_docker
            check_files
            setup_env
            create_backup
            deploy_services
            health_check
            show_status
            ;;
        "update")
            check_docker
            check_files
            create_backup
            update_code
            deploy_services
            health_check
            show_status
            ;;
        "restart")
            check_docker
            log_info "重启服务..."
            docker-compose -f "$DOCKER_COMPOSE_FILE" restart
            health_check
            show_status
            ;;
        "stop")
            check_docker
            log_info "停止服务..."
            docker-compose -f "$DOCKER_COMPOSE_FILE" down
            log_info "服务已停止"
            ;;
        "status")
            check_docker
            show_status
            ;;
        "logs")
            check_docker
            docker-compose -f "$DOCKER_COMPOSE_FILE" logs -f
            ;;
        "cleanup")
            check_docker
            cleanup
            ;;
        "backup")
            check_docker
            create_backup
            ;;
        "help")
            show_help
            ;;
        *)
            log_error "未知操作: $action"
            show_help
            exit 1
            ;;
    esac
    
    log_info "操作完成！"
    log_to_file "操作完成: $action"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi