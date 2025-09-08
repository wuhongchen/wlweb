#!/bin/bash
# -*- coding: utf-8 -*-

# 游戏脚本中间件管理系统 - Ubuntu 22.04 自动部署脚本
# 适用于 Ubuntu 22.04 64-bit 系统
# 功能：自动安装依赖、配置环境、部署前后端服务

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
LOG_DIR="$PROJECT_DIR/logs"
BACKUP_DIR="$PROJECT_DIR/backup"
SERVICE_USER="wlweb"
NODE_VERSION="18"
PYTHON_VERSION="3.11"

# 端口配置
FRONTEND_PORT=5175
BACKEND_PORT=8001
MYSQL_PORT=3306
REDIS_PORT=6379
NGINX_PORT=80

# 数据库配置
MYSQL_ROOT_PASSWORD="root123"
MYSQL_DATABASE="wlweb"
MYSQL_USER="wlweb"
MYSQL_PASSWORD="wlweb123"

# 创建必要目录
create_directories() {
    log_step "创建必要目录"
    mkdir -p "$LOG_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "/var/log/$PROJECT_NAME"
    mkdir -p "/etc/$PROJECT_NAME"
}

# 检查系统要求
check_system() {
    log_step "检查系统要求"
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法检测操作系统版本"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]] || [[ "$VERSION_ID" != "22.04" ]]; then
        log_warn "此脚本专为 Ubuntu 22.04 设计，当前系统: $PRETTY_NAME"
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行，请使用 sudo"
        exit 1
    fi
    
    log_info "系统检查通过: $PRETTY_NAME"
}

# 更新系统包
update_system() {
    log_step "更新系统包"
    apt update
    apt upgrade -y
    apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
}

# 安装 Node.js
install_nodejs() {
    log_step "安装 Node.js $NODE_VERSION"
    
    # 检查是否已安装
    if command -v node &> /dev/null; then
        CURRENT_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ "$CURRENT_VERSION" == "$NODE_VERSION" ]]; then
            log_info "Node.js $NODE_VERSION 已安装"
            return
        fi
    fi
    
    # 安装 NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    apt install -y nodejs
    
    # 验证安装
    node --version
    npm --version
    
    # 配置npm镜像源（可选）
    npm config set registry https://registry.npmmirror.com
    
    log_info "Node.js 安装完成"
}

# 安装 Python
install_python() {
    log_step "安装 Python $PYTHON_VERSION"
    
    # 检查是否已安装
    if command -v python3.11 &> /dev/null; then
        log_info "Python $PYTHON_VERSION 已安装"
    else
        # 添加 deadsnakes PPA
        add-apt-repository ppa:deadsnakes/ppa -y
        apt update
        apt install -y python3.11 python3.11-venv python3.11-dev
    fi
    
    # 安装 pip
    apt install -y python3-pip
    
    # 创建软链接
    ln -sf /usr/bin/python3.11 /usr/bin/python3
    
    # 验证安装
    python3 --version
    pip3 --version
    
    log_info "Python 安装完成"
}

# 安装 MySQL
install_mysql() {
    log_step "安装 MySQL 8.0"
    
    # 检查是否已安装
    if systemctl is-active --quiet mysql; then
        log_info "MySQL 已安装并运行"
        return
    fi
    
    # 预配置 MySQL
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"
    
    # 安装 MySQL
    apt install -y mysql-server mysql-client
    
    # 启动服务
    systemctl start mysql
    systemctl enable mysql
    
    # 创建数据库和用户
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    log_info "MySQL 安装和配置完成"
}

# 安装 Redis
install_redis() {
    log_step "安装 Redis"
    
    # 检查是否已安装
    if systemctl is-active --quiet redis-server; then
        log_info "Redis 已安装并运行"
        return
    fi
    
    apt install -y redis-server
    
    # 配置 Redis
    sed -i 's/^supervised no/supervised systemd/' /etc/redis/redis.conf
    
    # 启动服务
    systemctl start redis-server
    systemctl enable redis-server
    
    log_info "Redis 安装完成"
}

# 安装 Nginx
install_nginx() {
    log_step "安装 Nginx"
    
    # 检查是否已安装
    if systemctl is-active --quiet nginx; then
        log_info "Nginx 已安装并运行"
        return
    fi
    
    apt install -y nginx
    
    # 启动服务
    systemctl start nginx
    systemctl enable nginx
    
    log_info "Nginx 安装完成"
}

# 创建系统用户
create_user() {
    log_step "创建系统用户"
    
    if id "$SERVICE_USER" &>/dev/null; then
        log_info "用户 $SERVICE_USER 已存在"
    else
        useradd -r -s /bin/bash -d "/home/$SERVICE_USER" -m "$SERVICE_USER"
        log_info "用户 $SERVICE_USER 创建完成"
    fi
    
    # 设置项目目录权限
    chown -R "$SERVICE_USER:$SERVICE_USER" "$PROJECT_DIR"
    chmod -R 755 "$PROJECT_DIR"
}

# 安装前端依赖
install_frontend_deps() {
    log_step "安装前端依赖"
    
    cd "$PROJECT_DIR"
    
    # 清理缓存
    sudo -u "$SERVICE_USER" npm cache clean --force
    
    # 安装依赖
    sudo -u "$SERVICE_USER" npm install
    
    log_info "前端依赖安装完成"
}

# 安装后端依赖
install_backend_deps() {
    log_step "安装后端依赖"
    
    cd "$PROJECT_DIR/backend"
    
    # 创建虚拟环境
    sudo -u "$SERVICE_USER" python3 -m venv venv
    
    # 激活虚拟环境并安装依赖
    sudo -u "$SERVICE_USER" bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"
    
    log_info "后端依赖安装完成"
}

# 配置环境变量
setup_environment() {
    log_step "配置环境变量"
    
    # 复制环境变量文件
    if [[ ! -f "$PROJECT_DIR/.env" ]]; then
        cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
        
        # 更新数据库连接
        sed -i "s|DATABASE_URL=.*|DATABASE_URL=mysql+pymysql://$MYSQL_USER:$MYSQL_PASSWORD@localhost:$MYSQL_PORT/$MYSQL_DATABASE|" "$PROJECT_DIR/.env"
        sed -i "s|REDIS_URL=.*|REDIS_URL=redis://localhost:$REDIS_PORT/0|" "$PROJECT_DIR/.env"
        
        # 生成随机密钥
        SECRET_KEY=$(openssl rand -hex 32)
        sed -i "s|SECRET_KEY=.*|SECRET_KEY=$SECRET_KEY|" "$PROJECT_DIR/.env"
        
        log_info "环境变量配置完成"
    else
        log_info "环境变量文件已存在"
    fi
    
    chown "$SERVICE_USER:$SERVICE_USER" "$PROJECT_DIR/.env"
    chmod 600 "$PROJECT_DIR/.env"
}

# 初始化数据库
init_database() {
    log_step "初始化数据库"
    
    cd "$PROJECT_DIR/backend"
    
    # 运行数据库迁移
    if [[ -f "migrations/mysql_full_schema.sql" ]]; then
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < migrations/mysql_full_schema.sql
        log_info "数据库初始化完成"
    else
        log_warn "未找到数据库迁移文件"
    fi
}

# 构建前端
build_frontend() {
    log_step "构建前端"
    
    cd "$PROJECT_DIR"
    
    # 构建前端
    sudo -u "$SERVICE_USER" npm run build
    
    log_info "前端构建完成"
}

# 配置 Nginx
setup_nginx() {
    log_step "配置 Nginx"
    
    # 复制 Nginx 配置
    cp "$PROJECT_DIR/nginx.conf" "/etc/nginx/sites-available/$PROJECT_NAME"
    
    # 更新配置中的路径
    sed -i "s|/app/dist|$PROJECT_DIR/dist|g" "/etc/nginx/sites-available/$PROJECT_NAME"
    sed -i "s|proxy_pass http://backend|proxy_pass http://localhost:$BACKEND_PORT|g" "/etc/nginx/sites-available/$PROJECT_NAME"
    
    # 启用站点
    ln -sf "/etc/nginx/sites-available/$PROJECT_NAME" "/etc/nginx/sites-enabled/"
    
    # 删除默认站点
    rm -f /etc/nginx/sites-enabled/default
    
    # 测试配置
    nginx -t
    
    # 重启 Nginx
    systemctl reload nginx
    
    log_info "Nginx 配置完成"
}

# 创建系统服务
create_systemd_services() {
    log_step "创建系统服务"
    
    # 后端服务
    cat > "/etc/systemd/system/$PROJECT_NAME-backend.service" <<EOF
[Unit]
Description=$PROJECT_NAME Backend Service
After=network.target mysql.service redis-server.service
Requires=mysql.service redis-server.service

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$PROJECT_DIR/backend
Environment=PATH=$PROJECT_DIR/backend/venv/bin
EnvironmentFile=$PROJECT_DIR/.env
ExecStart=$PROJECT_DIR/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port $BACKEND_PORT
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载 systemd
    systemctl daemon-reload
    
    # 启用服务
    systemctl enable "$PROJECT_NAME-backend.service"
    
    log_info "系统服务创建完成"
}

# 配置防火墙
setup_firewall() {
    log_step "配置防火墙"
    
    # 安装 ufw
    apt install -y ufw
    
    # 配置防火墙规则
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # 允许必要端口
    ufw allow ssh
    ufw allow $NGINX_PORT
    ufw allow $BACKEND_PORT
    
    # 启用防火墙
    ufw --force enable
    
    log_info "防火墙配置完成"
}

# 启动服务
start_services() {
    log_step "启动服务"
    
    # 启动后端服务
    systemctl start "$PROJECT_NAME-backend.service"
    
    # 检查服务状态
    sleep 5
    if systemctl is-active --quiet "$PROJECT_NAME-backend.service"; then
        log_info "后端服务启动成功"
    else
        log_error "后端服务启动失败"
        systemctl status "$PROJECT_NAME-backend.service"
        exit 1
    fi
    
    # 重启 Nginx
    systemctl restart nginx
    
    log_info "所有服务启动完成"
}

# 健康检查
health_check() {
    log_step "执行健康检查"
    
    # 检查后端 API
    for i in {1..10}; do
        if curl -f "http://localhost:$BACKEND_PORT/health" &>/dev/null; then
            log_info "后端 API 健康检查通过"
            break
        fi
        if [[ $i -eq 10 ]]; then
            log_error "后端 API 健康检查失败"
            exit 1
        fi
        sleep 2
    done
    
    # 检查前端
    if curl -f "http://localhost:$NGINX_PORT" &>/dev/null; then
        log_info "前端健康检查通过"
    else
        log_error "前端健康检查失败"
        exit 1
    fi
    
    log_info "所有健康检查通过"
}

# 显示部署信息
show_deployment_info() {
    log_step "部署完成"
    
    echo
    echo "==========================================="
    echo "         部署成功完成！"
    echo "==========================================="
    echo
    echo "访问地址:"
    echo "  前端: http://$(hostname -I | awk '{print $1}'):$NGINX_PORT"
    echo "  后端 API: http://$(hostname -I | awk '{print $1}'):$BACKEND_PORT"
    echo
    echo "服务管理命令:"
    echo "  启动后端: systemctl start $PROJECT_NAME-backend"
    echo "  停止后端: systemctl stop $PROJECT_NAME-backend"
    echo "  重启后端: systemctl restart $PROJECT_NAME-backend"
    echo "  查看状态: systemctl status $PROJECT_NAME-backend"
    echo "  查看日志: journalctl -u $PROJECT_NAME-backend -f"
    echo
    echo "数据库信息:"
    echo "  数据库: $MYSQL_DATABASE"
    echo "  用户: $MYSQL_USER"
    echo "  端口: $MYSQL_PORT"
    echo
    echo "日志目录: $LOG_DIR"
    echo "配置文件: $PROJECT_DIR/.env"
    echo
    echo "==========================================="
}

# 清理函数
cleanup() {
    log_info "清理临时文件"
    apt autoremove -y
    apt autoclean
}

# 主函数
main() {
    log_info "开始部署 $PROJECT_NAME"
    log_info "项目目录: $PROJECT_DIR"
    
    # 执行部署步骤
    check_system
    create_directories
    update_system
    install_nodejs
    install_python
    install_mysql
    install_redis
    install_nginx
    create_user
    install_frontend_deps
    install_backend_deps
    setup_environment
    init_database
    build_frontend
    setup_nginx
    create_systemd_services
    setup_firewall
    start_services
    health_check
    cleanup
    show_deployment_info
    
    log_info "部署完成！"
}

# 错误处理
trap 'log_error "部署过程中发生错误，请检查日志"; exit 1' ERR

# 执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi