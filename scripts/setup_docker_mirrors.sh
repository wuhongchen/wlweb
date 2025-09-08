#!/bin/bash
# -*- coding: utf-8 -*-

# Docker镜像源配置脚本
# 用于快速配置Docker镜像源以解决镜像拉取问题

set -e

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

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# 配置Linux系统的Docker镜像源
setup_linux_mirrors() {
    log_step "配置Linux系统Docker镜像源..."
    
    # 创建Docker配置目录
    sudo mkdir -p /etc/docker
    
    # 备份现有配置
    if [ -f "/etc/docker/daemon.json" ]; then
        log_info "备份现有配置..."
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 选择镜像源
    echo "请选择镜像源:"
    echo "1) 网易云镜像源（推荐）"
    echo "2) 七牛云镜像源"
    echo "3) 多镜像源配置"
    echo "4) 自定义阿里云镜像源"
    read -p "请输入选择 (1-4): " choice
    
    case $choice in
        1)
            log_info "配置网易云镜像源..."
            sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://hub-mirror.c.163.com"],
  "dns": ["8.8.8.8", "114.114.114.114"]
}
EOF
            ;;
        2)
            log_info "配置七牛云镜像源..."
            sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://reg-mirror.qiniu.com"],
  "dns": ["8.8.8.8", "114.114.114.114"]
}
EOF
            ;;
        3)
            log_info "配置多镜像源..."
            sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://reg-mirror.qiniu.com",
    "https://mirror.baidubce.com"
  ],
  "dns": ["8.8.8.8", "114.114.114.114"]
}
EOF
            ;;
        4)
            read -p "请输入您的阿里云镜像加速地址: " aliyun_mirror
            if [ -n "$aliyun_mirror" ]; then
                log_info "配置阿里云镜像源..."
                sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["$aliyun_mirror"],
  "dns": ["8.8.8.8", "114.114.114.114"]
}
EOF
            else
                log_error "未输入有效的镜像地址"
                exit 1
            fi
            ;;
        *)
            log_error "无效选择"
            exit 1
            ;;
    esac
    
    # 重启Docker服务
    log_info "重启Docker服务..."
    sudo systemctl restart docker
    
    log_info "Linux Docker镜像源配置完成"
}

# 配置macOS Docker Desktop镜像源
setup_macos_mirrors() {
    log_step "配置macOS Docker Desktop镜像源..."
    
    log_info "macOS用户请按以下步骤手动配置:"
    echo "1. 打开Docker Desktop应用"
    echo "2. 点击右上角设置图标 (齿轮图标)"
    echo "3. 选择 'Docker Engine'"
    echo "4. 在JSON配置中添加以下内容:"
    
    echo "选择镜像源配置:"
    echo "1) 网易云镜像源（推荐）"
    echo "2) 七牛云镜像源"
    echo "3) 多镜像源配置"
    read -p "请输入选择 (1-3): " choice
    
    case $choice in
        1)
            echo '{
  "registry-mirrors": ["https://hub-mirror.c.163.com"],
  "dns": ["8.8.8.8", "114.114.114.114"]
}'
            ;;
        2)
            echo '{
  "registry-mirrors": ["https://reg-mirror.qiniu.com"],
  "dns": ["8.8.8.8", "114.114.114.114"]
}'
            ;;
        3)
            echo '{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://reg-mirror.qiniu.com",
    "https://mirror.baidubce.com"
  ],
  "dns": ["8.8.8.8", "114.114.114.114"]
}'
            ;;
        *)
            log_error "无效选择"
            exit 1
            ;;
    esac
    
    echo ""
    echo "5. 点击 'Apply & Restart' 应用配置"
    echo "6. 等待Docker Desktop重启完成"
    
    log_info "配置完成后，可以运行以下命令验证:"
    echo "docker info | grep -i registry"
}

# 测试镜像拉取
test_docker_pull() {
    log_step "测试Docker镜像拉取..."
    
    log_info "测试拉取Python镜像..."
    if docker pull python:3.11-slim; then
        log_info "Python镜像拉取成功"
    else
        log_error "Python镜像拉取失败"
        return 1
    fi
    
    log_info "测试拉取Node镜像..."
    if docker pull node:18-alpine; then
        log_info "Node镜像拉取成功"
    else
        log_error "Node镜像拉取失败"
        return 1
    fi
    
    log_info "镜像拉取测试通过"
}

# 显示当前配置
show_current_config() {
    log_step "显示当前Docker配置..."
    
    echo "=== Docker信息 ==="
    docker info | grep -A 10 "Registry Mirrors" || echo "未配置镜像源"
    
    echo ""
    echo "=== 配置文件 ==="
    if [[ "$(detect_os)" == "linux" ]]; then
        if [ -f "/etc/docker/daemon.json" ]; then
            cat /etc/docker/daemon.json
        else
            echo "未找到配置文件 /etc/docker/daemon.json"
        fi
    else
        echo "macOS用户请在Docker Desktop中查看配置"
    fi
}

# 重置配置
reset_config() {
    log_step "重置Docker配置..."
    
    if [[ "$(detect_os)" == "linux" ]]; then
        if [ -f "/etc/docker/daemon.json" ]; then
            log_info "备份并删除现有配置..."
            sudo mv /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
            sudo systemctl restart docker
            log_info "配置已重置"
        else
            log_info "未找到配置文件，无需重置"
        fi
    else
        log_info "macOS用户请在Docker Desktop中手动删除镜像源配置"
    fi
}

# 显示帮助信息
show_help() {
    echo "Docker镜像源配置脚本"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  setup     配置镜像源（默认）"
    echo "  test      测试镜像拉取"
    echo "  show      显示当前配置"
    echo "  reset     重置配置"
    echo "  help      显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 setup   # 配置镜像源"
    echo "  $0 test    # 测试镜像拉取"
    echo "  $0 show    # 显示当前配置"
}

# 主函数
main() {
    local action=${1:-setup}
    
    log_info "Docker镜像源配置脚本"
    log_info "检测到操作系统: $(detect_os)"
    
    case $action in
        "setup")
            if [[ "$(detect_os)" == "linux" ]]; then
                setup_linux_mirrors
            elif [[ "$(detect_os)" == "macos" ]]; then
                setup_macos_mirrors
            else
                log_error "不支持的操作系统"
                exit 1
            fi
            ;;
        "test")
            test_docker_pull
            ;;
        "show")
            show_current_config
            ;;
        "reset")
            reset_config
            ;;
        "help")
            show_help
            ;;
        *)
            log_error "未知命令: $action"
            show_help
            exit 1
            ;;
    esac
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi