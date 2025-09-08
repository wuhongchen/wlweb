#!/bin/bash
# 服务器环境检查脚本
# 用于在部署前检查服务器环境是否满足要求

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查结果统计
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# 日志函数
log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARN_COUNT++))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_header() {
    echo
    echo -e "${BLUE}=== $1 ===${NC}"
}

# 检查操作系统
check_os() {
    log_header "操作系统检查"
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        log_info "操作系统: $PRETTY_NAME"
        
        if [[ "$ID" == "ubuntu" ]]; then
            if [[ "$VERSION_ID" == "22.04" ]]; then
                log_pass "Ubuntu 22.04 - 完全支持"
            elif [[ "$VERSION_ID" == "20.04" ]]; then
                log_warn "Ubuntu 20.04 - 基本支持，建议升级到 22.04"
            else
                log_warn "Ubuntu $VERSION_ID - 可能需要调整部署脚本"
            fi
        else
            log_fail "非 Ubuntu 系统，部署脚本可能不兼容"
        fi
        
        # 检查架构
        ARCH=$(uname -m)
        log_info "系统架构: $ARCH"
        if [[ "$ARCH" == "x86_64" ]]; then
            log_pass "64位系统架构"
        else
            log_fail "非64位系统，不支持"
        fi
    else
        log_fail "无法检测操作系统版本"
    fi
}

# 检查系统资源
check_resources() {
    log_header "系统资源检查"
    
    # 检查内存
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    log_info "总内存: ${TOTAL_MEM}MB"
    
    if [[ $TOTAL_MEM -ge 8192 ]]; then
        log_pass "内存充足 (${TOTAL_MEM}MB >= 8GB)"
    elif [[ $TOTAL_MEM -ge 4096 ]]; then
        log_warn "内存满足最低要求 (${TOTAL_MEM}MB >= 4GB)，建议8GB以上"
    else
        log_fail "内存不足 (${TOTAL_MEM}MB < 4GB)"
    fi
    
    # 检查CPU核心数
    CPU_CORES=$(nproc)
    log_info "CPU核心数: $CPU_CORES"
    
    if [[ $CPU_CORES -ge 4 ]]; then
        log_pass "CPU核心数充足 ($CPU_CORES >= 4)"
    elif [[ $CPU_CORES -ge 2 ]]; then
        log_warn "CPU核心数满足最低要求 ($CPU_CORES >= 2)，建议4核以上"
    else
        log_fail "CPU核心数不足 ($CPU_CORES < 2)"
    fi
    
    # 检查磁盘空间
    DISK_AVAIL=$(df / | awk 'NR==2 {printf "%.0f", $4/1024/1024}')
    log_info "可用磁盘空间: ${DISK_AVAIL}GB"
    
    if [[ $DISK_AVAIL -ge 50 ]]; then
        log_pass "磁盘空间充足 (${DISK_AVAIL}GB >= 50GB)"
    elif [[ $DISK_AVAIL -ge 20 ]]; then
        log_warn "磁盘空间满足最低要求 (${DISK_AVAIL}GB >= 20GB)，建议50GB以上"
    else
        log_fail "磁盘空间不足 (${DISK_AVAIL}GB < 20GB)"
    fi
}

# 检查网络连接
check_network() {
    log_header "网络连接检查"
    
    # 检查互联网连接
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log_pass "互联网连接正常"
    else
        log_fail "无法连接到互联网"
    fi
    
    # 检查DNS解析
    if nslookup google.com &> /dev/null; then
        log_pass "DNS解析正常"
    else
        log_fail "DNS解析失败"
    fi
    
    # 检查包管理器源
    if apt update &> /dev/null; then
        log_pass "APT包管理器源可访问"
    else
        log_fail "APT包管理器源不可访问"
    fi
}

# 检查端口占用
check_ports() {
    log_header "端口占用检查"
    
    REQUIRED_PORTS=(80 8001 3306 6379)
    
    for port in "${REQUIRED_PORTS[@]}"; do
        if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
            PROCESS=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | head -1)
            log_warn "端口 $port 已被占用 (进程: $PROCESS)"
        else
            log_pass "端口 $port 可用"
        fi
    done
}

# 检查权限
check_permissions() {
    log_header "权限检查"
    
    # 检查是否为root用户
    if [[ $EUID -eq 0 ]]; then
        log_pass "具有root权限"
    else
        # 检查sudo权限
        if sudo -n true 2>/dev/null; then
            log_pass "具有sudo权限"
        else
            log_fail "需要root或sudo权限"
        fi
    fi
    
    # 检查关键目录权限
    DIRS=("/etc" "/var/log" "/usr/local" "/opt")
    
    for dir in "${DIRS[@]}"; do
        if [[ -w "$dir" ]] || sudo test -w "$dir" 2>/dev/null; then
            log_pass "目录 $dir 可写"
        else
            log_fail "目录 $dir 不可写"
        fi
    done
}

# 检查已安装的软件
check_existing_software() {
    log_header "已安装软件检查"
    
    # 检查Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        log_info "Node.js已安装: $NODE_VERSION"
        
        MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ $MAJOR_VERSION -ge 18 ]]; then
            log_pass "Node.js版本满足要求 (>= 18.x)"
        else
            log_warn "Node.js版本过低，建议升级到18.x或更高版本"
        fi
    else
        log_info "Node.js未安装，将在部署时安装"
    fi
    
    # 检查Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version)
        log_info "Python已安装: $PYTHON_VERSION"
        
        if python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
            log_pass "Python版本满足要求 (>= 3.8)"
        else
            log_warn "Python版本过低，建议升级到3.11或更高版本"
        fi
    else
        log_info "Python未安装，将在部署时安装"
    fi
    
    # 检查MySQL
    if command -v mysql &> /dev/null; then
        MYSQL_VERSION=$(mysql --version)
        log_info "MySQL已安装: $MYSQL_VERSION"
        
        if systemctl is-active --quiet mysql; then
            log_pass "MySQL服务正在运行"
        else
            log_warn "MySQL服务未运行"
        fi
    else
        log_info "MySQL未安装，将在部署时安装"
    fi
    
    # 检查Redis
    if command -v redis-server &> /dev/null; then
        REDIS_VERSION=$(redis-server --version)
        log_info "Redis已安装: $REDIS_VERSION"
        
        if systemctl is-active --quiet redis-server; then
            log_pass "Redis服务正在运行"
        else
            log_warn "Redis服务未运行"
        fi
    else
        log_info "Redis未安装，将在部署时安装"
    fi
    
    # 检查Nginx
    if command -v nginx &> /dev/null; then
        NGINX_VERSION=$(nginx -v 2>&1)
        log_info "Nginx已安装: $NGINX_VERSION"
        
        if systemctl is-active --quiet nginx; then
            log_pass "Nginx服务正在运行"
        else
            log_warn "Nginx服务未运行"
        fi
    else
        log_info "Nginx未安装，将在部署时安装"
    fi
    
    # 检查Docker（可选）
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        log_info "Docker已安装: $DOCKER_VERSION"
        
        if systemctl is-active --quiet docker; then
            log_pass "Docker服务正在运行"
        else
            log_warn "Docker服务未运行"
        fi
    else
        log_info "Docker未安装（可选）"
    fi
}

# 检查安全设置
check_security() {
    log_header "安全设置检查"
    
    # 检查防火墙
    if command -v ufw &> /dev/null; then
        UFW_STATUS=$(ufw status | head -1)
        log_info "UFW防火墙: $UFW_STATUS"
        
        if echo "$UFW_STATUS" | grep -q "active"; then
            log_pass "UFW防火墙已启用"
        else
            log_warn "UFW防火墙未启用，建议启用"
        fi
    else
        log_warn "UFW防火墙未安装"
    fi
    
    # 检查SSH配置
    if [[ -f /etc/ssh/sshd_config ]]; then
        if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
            log_pass "SSH root登录已禁用"
        else
            log_warn "建议禁用SSH root登录"
        fi
        
        if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
            log_pass "SSH密码认证已禁用（使用密钥认证）"
        else
            log_warn "建议禁用SSH密码认证，使用密钥认证"
        fi
    fi
    
    # 检查自动更新
    if dpkg -l | grep -q unattended-upgrades; then
        log_pass "自动安全更新已安装"
    else
        log_warn "建议安装自动安全更新"
    fi
}

# 生成建议
generate_recommendations() {
    log_header "部署建议"
    
    if [[ $FAIL_COUNT -eq 0 ]]; then
        if [[ $WARN_COUNT -eq 0 ]]; then
            log_pass "环境检查完全通过，可以直接部署"
            echo
            echo "建议的部署命令:"
            echo "  sudo ./deploy_ubuntu.sh"
        else
            log_warn "环境基本满足要求，但有一些建议改进的地方"
            echo
            echo "可以继续部署，但建议先处理警告项:"
            echo "  sudo ./deploy_ubuntu.sh"
        fi
    else
        log_fail "环境检查发现严重问题，建议先解决后再部署"
        echo
        echo "请先解决以下问题:"
        echo "1. 确保系统满足最低要求"
        echo "2. 检查网络连接"
        echo "3. 确保有足够的权限"
        echo "4. 释放被占用的端口"
    fi
}

# 显示检查结果摘要
show_summary() {
    log_header "检查结果摘要"
    
    echo "通过: $PASS_COUNT 项"
    echo "警告: $WARN_COUNT 项"
    echo "失败: $FAIL_COUNT 项"
    echo
    
    if [[ $FAIL_COUNT -eq 0 ]]; then
        echo -e "${GREEN}✓ 环境检查总体通过${NC}"
    else
        echo -e "${RED}✗ 环境检查发现问题${NC}"
    fi
}

# 主函数
main() {
    echo "==========================================="
    echo "    游戏脚本中间件管理系统"
    echo "      服务器环境检查工具"
    echo "==========================================="
    echo
    
    check_os
    check_resources
    check_network
    check_ports
    check_permissions
    check_existing_software
    check_security
    
    echo
    show_summary
    generate_recommendations
    
    echo
    echo "==========================================="
    echo "检查完成！"
    echo "==========================================="
}

# 执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi