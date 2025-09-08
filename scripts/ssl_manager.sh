#!/bin/bash
# -*- coding: utf-8 -*-

# SSL证书管理脚本
# 用于管理游戏脚本中间件管理系统的SSL证书

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置变量
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
SSL_DIR="$PROJECT_DIR/nginx/ssl"
LOG_FILE="$PROJECT_DIR/logs/ssl.log"
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose.prod.yml"

# 证书配置
CERT_VALIDITY_DAYS=90
RENEWAL_THRESHOLD_DAYS=30

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
    mkdir -p "$SSL_DIR"
    mkdir -p "$PROJECT_DIR/logs"
    chmod 700 "$SSL_DIR"
}

# 检查系统依赖
check_dependencies() {
    log_step "检查系统依赖..."
    
    # 检查openssl
    if ! command -v openssl &> /dev/null; then
        log_error "OpenSSL未安装"
        exit 1
    fi
    
    # 检查certbot（用于Let's Encrypt）
    if ! command -v certbot &> /dev/null; then
        log_warn "Certbot未安装，无法使用Let's Encrypt自动证书"
        log_info "安装命令: apt-get install certbot python3-certbot-nginx"
    fi
    
    log_info "依赖检查完成"
}

# 生成自签名证书
generate_self_signed() {
    local domain="$1"
    local days="${2:-$CERT_VALIDITY_DAYS}"
    
    if [ -z "$domain" ]; then
        log_error "请提供域名"
        return 1
    fi
    
    log_step "生成自签名证书: $domain"
    
    local key_file="$SSL_DIR/key.pem"
    local cert_file="$SSL_DIR/cert.pem"
    local csr_file="$SSL_DIR/cert.csr"
    local config_file="$SSL_DIR/openssl.conf"
    
    # 创建OpenSSL配置文件
    cat > "$config_file" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = CN
ST = Beijing
L = Beijing
O = Game Script Middleware
OU = IT Department
CN = $domain

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $domain
DNS.2 = *.$domain
IP.1 = 127.0.0.1
EOF
    
    # 生成私钥
    openssl genrsa -out "$key_file" 2048
    
    # 生成证书签名请求
    openssl req -new -key "$key_file" -out "$csr_file" -config "$config_file"
    
    # 生成自签名证书
    openssl x509 -req -in "$csr_file" -signkey "$key_file" -out "$cert_file" \
        -days "$days" -extensions v3_req -extfile "$config_file"
    
    # 设置权限
    chmod 600 "$key_file"
    chmod 644 "$cert_file"
    
    # 清理临时文件
    rm -f "$csr_file" "$config_file"
    
    log_info "自签名证书生成完成"
    log_info "证书文件: $cert_file"
    log_info "私钥文件: $key_file"
    
    # 显示证书信息
    show_cert_info "$cert_file"
}

# 使用Let's Encrypt获取证书
get_letsencrypt_cert() {
    local domain="$1"
    local email="$2"
    local webroot="${3:-$PROJECT_DIR/static}"
    
    if [ -z "$domain" ] || [ -z "$email" ]; then
        log_error "请提供域名和邮箱地址"
        log_info "用法: $0 letsencrypt domain.com admin@domain.com"
        return 1
    fi
    
    if ! command -v certbot &> /dev/null; then
        log_error "Certbot未安装，请先安装"
        log_info "Ubuntu/Debian: apt-get install certbot python3-certbot-nginx"
        log_info "CentOS/RHEL: yum install certbot python3-certbot-nginx"
        return 1
    fi
    
    log_step "使用Let's Encrypt获取证书: $domain"
    
    # 确保webroot目录存在
    mkdir -p "$webroot"
    
    # 停止nginx以释放80端口（如果使用standalone模式）
    local use_standalone=false
    if ! curl -s http://localhost/.well-known/acme-challenge/test 2>/dev/null; then
        use_standalone=true
        log_info "使用standalone模式获取证书"
        docker-compose -f "$DOCKER_COMPOSE_FILE" stop frontend 2>/dev/null || true
    else
        log_info "使用webroot模式获取证书"
    fi
    
    # 获取证书
    if [ "$use_standalone" = true ]; then
        certbot certonly --standalone \
            -d "$domain" \
            --email "$email" \
            --agree-tos \
            --no-eff-email \
            --force-renewal
    else
        certbot certonly --webroot \
            -w "$webroot" \
            -d "$domain" \
            --email "$email" \
            --agree-tos \
            --no-eff-email \
            --force-renewal
    fi
    
    if [ $? -eq 0 ]; then
        # 复制证书到项目目录
        cp "/etc/letsencrypt/live/$domain/fullchain.pem" "$SSL_DIR/cert.pem"
        cp "/etc/letsencrypt/live/$domain/privkey.pem" "$SSL_DIR/key.pem"
        
        # 设置权限
        chmod 600 "$SSL_DIR/key.pem"
        chmod 644 "$SSL_DIR/cert.pem"
        
        log_info "Let's Encrypt证书获取成功"
        
        # 重启nginx
        if [ "$use_standalone" = true ]; then
            docker-compose -f "$DOCKER_COMPOSE_FILE" start frontend
        else
            docker-compose -f "$DOCKER_COMPOSE_FILE" restart frontend
        fi
        
        # 设置自动续期
        setup_auto_renewal "$domain" "$email"
        
        # 显示证书信息
        show_cert_info "$SSL_DIR/cert.pem"
    else
        log_error "Let's Encrypt证书获取失败"
        
        # 重启nginx
        if [ "$use_standalone" = true ]; then
            docker-compose -f "$DOCKER_COMPOSE_FILE" start frontend
        fi
        
        return 1
    fi
}

# 设置自动续期
setup_auto_renewal() {
    local domain="$1"
    local email="$2"
    
    log_step "设置证书自动续期..."
    
    # 创建续期脚本
    local renewal_script="$PROJECT_DIR/scripts/renew_ssl.sh"
    
    cat > "$renewal_script" << EOF
#!/bin/bash
# SSL证书自动续期脚本

set -e

PROJECT_DIR="$PROJECT_DIR"
SSL_DIR="$SSL_DIR"
DOMAIN="$domain"
EMAIL="$email"
LOG_FILE="$LOG_FILE"

log_info() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] [INFO] \$1" >> "\$LOG_FILE"
}

log_error() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] \$1" >> "\$LOG_FILE"
}

# 检查证书是否需要续期
if openssl x509 -checkend \$((30 * 24 * 3600)) -noout -in "\$SSL_DIR/cert.pem" 2>/dev/null; then
    log_info "证书还未到期，无需续期"
    exit 0
fi

log_info "开始续期SSL证书: \$DOMAIN"

# 续期证书
if certbot renew --quiet --deploy-hook "\$PROJECT_DIR/scripts/ssl_manager.sh deploy \$DOMAIN"; then
    log_info "证书续期成功"
else
    log_error "证书续期失败"
    exit 1
fi
EOF
    
    chmod +x "$renewal_script"
    
    # 添加到crontab
    local cron_job="0 2 * * * $renewal_script"
    
    # 检查是否已存在相同的cron任务
    if ! crontab -l 2>/dev/null | grep -q "$renewal_script"; then
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        log_info "已添加自动续期任务到crontab"
    else
        log_info "自动续期任务已存在"
    fi
}

# 部署证书（续期后的钩子）
deploy_cert() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        log_error "请提供域名"
        return 1
    fi
    
    log_step "部署证书: $domain"
    
    # 复制新证书
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
        cp "/etc/letsencrypt/live/$domain/fullchain.pem" "$SSL_DIR/cert.pem"
        cp "/etc/letsencrypt/live/$domain/privkey.pem" "$SSL_DIR/key.pem"
        
        # 设置权限
        chmod 600 "$SSL_DIR/key.pem"
        chmod 644 "$SSL_DIR/cert.pem"
        
        # 重启nginx
        docker-compose -f "$DOCKER_COMPOSE_FILE" restart frontend
        
        log_info "证书部署完成"
    else
        log_error "证书文件不存在"
        return 1
    fi
}

# 检查证书状态
check_cert_status() {
    local cert_file="${1:-$SSL_DIR/cert.pem}"
    
    if [ ! -f "$cert_file" ]; then
        log_error "证书文件不存在: $cert_file"
        return 1
    fi
    
    log_step "检查证书状态: $cert_file"
    
    # 检查证书有效性
    if ! openssl x509 -in "$cert_file" -noout -checkend 0 2>/dev/null; then
        log_error "证书已过期"
        return 1
    fi
    
    # 获取证书信息
    local subject=$(openssl x509 -in "$cert_file" -noout -subject | sed 's/subject=//')
    local issuer=$(openssl x509 -in "$cert_file" -noout -issuer | sed 's/issuer=//')
    local not_before=$(openssl x509 -in "$cert_file" -noout -startdate | sed 's/notBefore=//')
    local not_after=$(openssl x509 -in "$cert_file" -noout -enddate | sed 's/notAfter=//')
    
    # 计算剩余天数
    local end_timestamp=$(date -d "$not_after" +%s)
    local current_timestamp=$(date +%s)
    local remaining_days=$(( (end_timestamp - current_timestamp) / 86400 ))
    
    echo "=== 证书状态 ==="
    echo "证书文件: $cert_file"
    echo "主题: $subject"
    echo "颁发者: $issuer"
    echo "生效时间: $not_before"
    echo "过期时间: $not_after"
    echo "剩余天数: $remaining_days 天"
    
    # 检查是否需要续期
    if [ $remaining_days -le $RENEWAL_THRESHOLD_DAYS ]; then
        log_warn "证书将在 $remaining_days 天后过期，建议续期"
        return 2
    else
        log_info "证书状态正常，剩余 $remaining_days 天"
        return 0
    fi
}

# 显示证书详细信息
show_cert_info() {
    local cert_file="${1:-$SSL_DIR/cert.pem}"
    
    if [ ! -f "$cert_file" ]; then
        log_error "证书文件不存在: $cert_file"
        return 1
    fi
    
    log_step "证书详细信息: $cert_file"
    
    echo "=== 证书详细信息 ==="
    openssl x509 -in "$cert_file" -text -noout
    
    echo ""
    echo "=== 证书指纹 ==="
    echo "SHA1: $(openssl x509 -in "$cert_file" -noout -fingerprint -sha1 | cut -d'=' -f2)"
    echo "SHA256: $(openssl x509 -in "$cert_file" -noout -fingerprint -sha256 | cut -d'=' -f2)"
}

# 验证证书和私钥匹配
verify_cert_key_match() {
    local cert_file="${1:-$SSL_DIR/cert.pem}"
    local key_file="${2:-$SSL_DIR/key.pem}"
    
    if [ ! -f "$cert_file" ] || [ ! -f "$key_file" ]; then
        log_error "证书或私钥文件不存在"
        return 1
    fi
    
    log_step "验证证书和私钥匹配性..."
    
    local cert_modulus=$(openssl x509 -noout -modulus -in "$cert_file" | openssl md5)
    local key_modulus=$(openssl rsa -noout -modulus -in "$key_file" | openssl md5)
    
    if [ "$cert_modulus" = "$key_modulus" ]; then
        log_info "证书和私钥匹配"
        return 0
    else
        log_error "证书和私钥不匹配"
        return 1
    fi
}

# 测试SSL连接
test_ssl_connection() {
    local domain="${1:-localhost}"
    local port="${2:-443}"
    
    log_step "测试SSL连接: $domain:$port"
    
    # 测试SSL握手
    if echo | openssl s_client -connect "$domain:$port" -servername "$domain" 2>/dev/null | grep -q "Verify return code: 0"; then
        log_info "SSL连接测试成功"
        
        # 显示连接信息
        echo "=== SSL连接信息 ==="
        echo | openssl s_client -connect "$domain:$port" -servername "$domain" 2>/dev/null | \
            openssl x509 -noout -subject -issuer -dates
    else
        log_warn "SSL连接测试失败或证书验证失败"
        
        # 显示详细错误信息
        echo "=== SSL连接详情 ==="
        echo | openssl s_client -connect "$domain:$port" -servername "$domain" 2>&1
        
        return 1
    fi
}

# 备份证书
backup_certificates() {
    local backup_dir="$PROJECT_DIR/backups/ssl_$(date +%Y%m%d_%H%M%S)"
    
    log_step "备份SSL证书..."
    
    mkdir -p "$backup_dir"
    
    if [ -f "$SSL_DIR/cert.pem" ]; then
        cp "$SSL_DIR/cert.pem" "$backup_dir/"
    fi
    
    if [ -f "$SSL_DIR/key.pem" ]; then
        cp "$SSL_DIR/key.pem" "$backup_dir/"
    fi
    
    # 备份Let's Encrypt证书（如果存在）
    if [ -d "/etc/letsencrypt" ]; then
        tar -czf "$backup_dir/letsencrypt_backup.tar.gz" -C / etc/letsencrypt 2>/dev/null || true
    fi
    
    log_info "证书备份完成: $backup_dir"
}

# 恢复证书
restore_certificates() {
    local backup_dir="$1"
    
    if [ -z "$backup_dir" ] || [ ! -d "$backup_dir" ]; then
        log_error "请提供有效的备份目录"
        return 1
    fi
    
    log_step "恢复SSL证书: $backup_dir"
    
    # 备份当前证书
    if [ -f "$SSL_DIR/cert.pem" ] || [ -f "$SSL_DIR/key.pem" ]; then
        backup_certificates
    fi
    
    # 恢复证书文件
    if [ -f "$backup_dir/cert.pem" ]; then
        cp "$backup_dir/cert.pem" "$SSL_DIR/"
        chmod 644 "$SSL_DIR/cert.pem"
        log_info "证书文件已恢复"
    fi
    
    if [ -f "$backup_dir/key.pem" ]; then
        cp "$backup_dir/key.pem" "$SSL_DIR/"
        chmod 600 "$SSL_DIR/key.pem"
        log_info "私钥文件已恢复"
    fi
    
    # 验证恢复的证书
    if verify_cert_key_match; then
        log_info "证书恢复成功"
        
        # 重启nginx
        docker-compose -f "$DOCKER_COMPOSE_FILE" restart frontend
    else
        log_error "证书恢复失败，证书和私钥不匹配"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "SSL证书管理脚本"
    echo ""
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "证书生成:"
    echo "  self-signed <domain> [days]    生成自签名证书"
    echo "  letsencrypt <domain> <email>   使用Let's Encrypt获取证书"
    echo ""
    echo "证书管理:"
    echo "  status [cert_file]             检查证书状态"
    echo "  info [cert_file]               显示证书详细信息"
    echo "  verify [cert_file] [key_file]  验证证书和私钥匹配"
    echo "  test [domain] [port]           测试SSL连接"
    echo "  deploy <domain>                部署证书（续期后）"
    echo ""
    echo "备份恢复:"
    echo "  backup                         备份当前证书"
    echo "  restore <backup_dir>           恢复证书备份"
    echo ""
    echo "维护:"
    echo "  renew                          手动续期Let's Encrypt证书"
    echo "  setup-renewal <domain> <email> 设置自动续期"
    echo "  help                           显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 self-signed example.com 365        # 生成1年有效期的自签名证书"
    echo "  $0 letsencrypt example.com admin@example.com  # 获取Let's Encrypt证书"
    echo "  $0 status                              # 检查当前证书状态"
    echo "  $0 test example.com 443                # 测试SSL连接"
    echo "  $0 backup                              # 备份证书"
}

# 主函数
main() {
    local command="$1"
    shift
    
    # 初始化
    setup_directories
    check_dependencies
    
    case "$command" in
        "self-signed")
            generate_self_signed "$@"
            ;;
        "letsencrypt")
            get_letsencrypt_cert "$@"
            ;;
        "status")
            check_cert_status "$@"
            ;;
        "info")
            show_cert_info "$@"
            ;;
        "verify")
            verify_cert_key_match "$@"
            ;;
        "test")
            test_ssl_connection "$@"
            ;;
        "deploy")
            deploy_cert "$@"
            ;;
        "backup")
            backup_certificates
            ;;
        "restore")
            restore_certificates "$@"
            ;;
        "renew")
            certbot renew
            ;;
        "setup-renewal")
            setup_auto_renewal "$@"
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