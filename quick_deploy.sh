#!/bin/bash
# 快速部署脚本 - 适用于已配置好基础环境的服务器

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 配置
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_USER="wlweb"
BACKEND_PORT=8001
FRONTEND_PORT=5175

# 检查依赖
check_dependencies() {
    log_info "检查系统依赖..."
    
    local missing_deps=()
    
    command -v node >/dev/null 2>&1 || missing_deps+=("nodejs")
    command -v python3 >/dev/null 2>&1 || missing_deps+=("python3")
    command -v mysql >/dev/null 2>&1 || missing_deps+=("mysql")
    command -v redis-cli >/dev/null 2>&1 || missing_deps+=("redis")
    command -v nginx >/dev/null 2>&1 || missing_deps+=("nginx")
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少以下依赖: ${missing_deps[*]}"
        log_info "请先运行完整部署脚本: sudo ./deploy_ubuntu.sh"
        exit 1
    fi
    
    log_info "依赖检查通过"
}

# 停止现有服务
stop_services() {
    log_info "停止现有服务..."
    
    systemctl stop wlweb-backend || true
    
    # 停止可能占用端口的进程
    pkill -f "uvicorn.*app.main:app" || true
    pkill -f "node.*vite" || true
    
    sleep 2
}

# 更新代码
update_code() {
    log_info "更新代码..."
    
    cd "$PROJECT_DIR"
    
    # 如果是git仓库，拉取最新代码
    if [ -d ".git" ]; then
        git pull origin main || git pull origin master || true
    fi
    
    # 设置权限
    chown -R "$SERVICE_USER:$SERVICE_USER" "$PROJECT_DIR"
}

# 安装/更新前端依赖
update_frontend() {
    log_info "更新前端依赖和构建..."
    
    cd "$PROJECT_DIR"
    
    # 安装依赖
    sudo -u "$SERVICE_USER" npm install
    
    # 构建前端
    sudo -u "$SERVICE_USER" npm run build
    
    log_info "前端构建完成"
}

# 安装/更新后端依赖
update_backend() {
    log_info "更新后端依赖..."
    
    cd "$PROJECT_DIR/backend"
    
    # 激活虚拟环境并更新依赖
    if [ -d "venv" ]; then
        sudo -u "$SERVICE_USER" bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"
    else
        log_error "虚拟环境不存在，请运行完整部署脚本"
        exit 1
    fi
    
    log_info "后端依赖更新完成"
}

# 数据库迁移
run_migrations() {
    log_info "运行数据库迁移..."
    
    cd "$PROJECT_DIR/backend"
    
    # 检查是否有新的迁移文件
    if [ -d "migrations" ] && [ "$(ls -A migrations/*.sql 2>/dev/null)" ]; then
        log_info "发现迁移文件，请手动检查并执行必要的数据库更新"
        ls -la migrations/*.sql
    fi
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    # 启动后端服务
    systemctl start wlweb-backend
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet wlweb-backend; then
        log_info "后端服务启动成功"
    else
        log_error "后端服务启动失败"
        systemctl status wlweb-backend
        exit 1
    fi
    
    # 重新加载 Nginx
    systemctl reload nginx
    
    log_info "服务启动完成"
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    
    # 检查后端 API
    for i in {1..10}; do
        if curl -f "http://localhost:$BACKEND_PORT/health" &>/dev/null; then
            log_info "后端 API 健康检查通过"
            break
        fi
        if [[ $i -eq 10 ]]; then
            log_error "后端 API 健康检查失败"
            journalctl -u wlweb-backend --no-pager -n 20
            exit 1
        fi
        sleep 2
    done
    
    # 检查前端
    if curl -f "http://localhost" &>/dev/null; then
        log_info "前端健康检查通过"
    else
        log_warn "前端可能需要检查 Nginx 配置"
    fi
}

# 显示状态
show_status() {
    echo
    echo "==========================================="
    echo "         快速部署完成！"
    echo "==========================================="
    echo
    echo "服务状态:"
    systemctl status wlweb-backend --no-pager -l
    echo
    echo "访问地址:"
    echo "  前端: http://$(hostname -I | awk '{print $1}')"
    echo "  后端 API: http://$(hostname -I | awk '{print $1}'):$BACKEND_PORT"
    echo
    echo "查看日志: journalctl -u wlweb-backend -f"
    echo "==========================================="
}

# 主函数
main() {
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行，请使用 sudo"
        exit 1
    fi
    
    log_info "开始快速部署..."
    
    check_dependencies
    stop_services
    update_code
    update_frontend
    update_backend
    run_migrations
    start_services
    health_check
    show_status
    
    log_info "快速部署完成！"
}

# 错误处理
trap 'log_error "部署过程中发生错误"; exit 1' ERR

# 执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi