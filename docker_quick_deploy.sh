#!/bin/bash
# -*- coding: utf-8 -*-

# 游戏脚本中间件管理系统 - Docker 快速部署脚本
# 功能：快速更新代码并重新部署，适用于开发和测试环境

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
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"

# 快速部署函数
quick_deploy() {
    log_info "开始快速部署..."
    
    cd "$PROJECT_DIR"
    
    # 拉取最新代码
    if [ -d ".git" ]; then
        log_info "拉取最新代码..."
        git pull origin main
    fi
    
    # 重新构建并启动
    log_info "重新构建服务..."
    docker-compose down
    docker-compose build --no-cache
    docker-compose up -d
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 15
    
    # 显示状态
    log_info "服务状态:"
    docker-compose ps
    
    log_info "快速部署完成！"
    log_info "前端: http://localhost:3000"
    log_info "后端: http://localhost:8000"
}

# 检查Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker未安装"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker服务未运行"
    exit 1
fi

# 执行快速部署
quick_deploy