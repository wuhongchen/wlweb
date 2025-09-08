#!/bin/bash

# WLWeb 后端API服务部署脚本
# 功能：Python环境检测、依赖安装、配置检查、服务启动

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Python环境
check_python() {
    log_info "检查Python环境..."
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 未安装，请先安装Python 3.8+"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    log_info "检测到Python版本: $PYTHON_VERSION"
    
    # 检查Python版本是否满足要求（3.8+）
    if python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"; then
        log_success "Python版本满足要求"
    else
        log_error "Python版本过低，需要3.8或更高版本"
        exit 1
    fi
}

# 检查并安装pip
check_pip() {
    log_info "检查pip..."
    
    if ! command -v pip3 &> /dev/null; then
        log_warning "pip3 未找到，尝试安装..."
        python3 -m ensurepip --upgrade
    fi
    
    log_success "pip已就绪"
}

# 创建虚拟环境
setup_venv() {
    log_info "设置Python虚拟环境..."
    
    if [ ! -d "venv" ]; then
        log_info "创建虚拟环境..."
        python3 -m venv venv
    fi
    
    log_info "激活虚拟环境..."
    source venv/bin/activate
    
    log_success "虚拟环境已激活"
}

# 安装依赖
install_dependencies() {
    log_info "安装Python依赖包..."
    
    if [ -f "backend/requirements.txt" ]; then
        pip install --upgrade pip
        pip install -r backend/requirements.txt
        log_success "依赖包安装完成"
    else
        log_error "未找到requirements.txt文件"
        exit 1
    fi
}

# 检查配置文件
check_config() {
    log_info "检查配置文件..."
    
    if [ ! -f ".env" ]; then
        log_warning "未找到.env文件，创建默认配置..."
        cat > .env << EOF
# 数据库配置
MYSQL_SERVER=localhost
MYSQL_PORT=3306
MYSQL_USER=wlweb
MYSQL_PASSWORD=wlweb123
MYSQL_DB=wlweb

# JWT配置
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 应用配置
DEBUG=false
BACKEND_CORS_ORIGINS=*
EOF
        log_warning "已创建默认.env文件，请根据实际情况修改配置"
    fi
    
    log_success "配置文件检查完成"
}

# 检查MySQL连接
check_mysql() {
    log_info "检查MySQL连接..."
    
    # 从.env文件读取配置
    if [ -f ".env" ]; then
        source .env
    fi
    
    # 检查MySQL是否可连接
    if command -v mysql &> /dev/null; then
        if mysql -h"${MYSQL_SERVER:-localhost}" -P"${MYSQL_PORT:-3306}" -u"${MYSQL_USER:-wlweb}" -p"${MYSQL_PASSWORD:-wlweb123}" -e "SELECT 1;" &> /dev/null; then
            log_success "MySQL连接正常"
        else
            log_warning "MySQL连接失败，请确保MySQL服务正在运行并且配置正确"
        fi
    else
        log_warning "未安装MySQL客户端，跳过连接测试"
    fi
}

# 创建日志目录
setup_logs() {
    log_info "创建日志目录..."
    
    mkdir -p backend/logs
    log_success "日志目录已创建"
}

# 启动服务
start_service() {
    log_info "启动WLWeb API服务..."
    
    cd backend
    
    # 检查端口是否被占用
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null ; then
        log_warning "端口8000已被占用，尝试停止现有进程..."
        pkill -f "uvicorn.*main:app" || true
        sleep 2
    fi
    
    # 启动服务
    log_info "在端口8000启动API服务..."
    nohup python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload > logs/app.log 2>&1 &
    
    # 获取进程ID
    SERVICE_PID=$!
    echo $SERVICE_PID > logs/app.pid
    
    # 等待服务启动
    sleep 3
    
    # 检查服务是否正常启动
    if curl -s http://localhost:8000/health > /dev/null; then
        log_success "API服务启动成功！"
        log_info "服务地址: http://localhost:8000"
        log_info "API文档: http://localhost:8000/docs"
        log_info "进程ID: $SERVICE_PID"
        log_info "日志文件: backend/logs/app.log"
    else
        log_error "API服务启动失败，请检查日志文件"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "WLWeb 后端API服务部署脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  start    启动服务（默认）"
    echo "  stop     停止服务"
    echo "  restart  重启服务"
    echo "  status   查看服务状态"
    echo "  logs     查看服务日志"
    echo "  help     显示帮助信息"
}

# 停止服务
stop_service() {
    log_info "停止WLWeb API服务..."
    
    if [ -f "backend/logs/app.pid" ]; then
        PID=$(cat backend/logs/app.pid)
        if kill -0 $PID 2>/dev/null; then
            kill $PID
            log_success "服务已停止 (PID: $PID)"
        else
            log_warning "进程不存在或已停止"
        fi
        rm -f backend/logs/app.pid
    else
        log_warning "未找到PID文件，尝试强制停止..."
        pkill -f "uvicorn.*main:app" || log_warning "未找到运行中的服务进程"
    fi
}

# 查看服务状态
check_status() {
    log_info "检查服务状态..."
    
    if [ -f "backend/logs/app.pid" ]; then
        PID=$(cat backend/logs/app.pid)
        if kill -0 $PID 2>/dev/null; then
            log_success "服务正在运行 (PID: $PID)"
            if curl -s http://localhost:8000/health > /dev/null; then
                log_success "API健康检查通过"
            else
                log_warning "API健康检查失败"
            fi
        else
            log_warning "PID文件存在但进程不存在"
            rm -f backend/logs/app.pid
        fi
    else
        log_warning "服务未运行"
    fi
}

# 查看日志
show_logs() {
    if [ -f "backend/logs/app.log" ]; then
        tail -f backend/logs/app.log
    else
        log_error "日志文件不存在"
    fi
}

# 主函数
main() {
    case "${1:-start}" in
        "start")
            log_info "开始部署WLWeb后端API服务..."
            check_python
            check_pip
            setup_venv
            install_dependencies
            check_config
            check_mysql
            setup_logs
            start_service
            ;;
        "stop")
            stop_service
            ;;
        "restart")
            stop_service
            sleep 2
            start_service
            ;;
        "status")
            check_status
            ;;
        "logs")
            show_logs
            ;;
        "help")
            show_help
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"