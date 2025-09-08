# 游戏脚本中间件管理系统 - 生产环境部署指南

本指南提供了在生产环境中部署游戏脚本中间件管理系统的详细说明，包含安全配置、性能优化和监控设置。

## 📋 目录

- [系统要求](#系统要求)
- [部署前准备](#部署前准备)
- [Docker生产环境部署](#docker生产环境部署)
- [安全配置](#安全配置)
- [性能优化](#性能优化)
- [监控和日志](#监控和日志)
- [备份策略](#备份策略)
- [故障排除](#故障排除)
- [维护指南](#维护指南)

## 🖥️ 系统要求

### 硬件要求（生产环境）
- **CPU**: 4核心以上（推荐8核心）
- **内存**: 8GB以上（推荐16GB）
- **存储**: 100GB以上SSD存储
- **网络**: 稳定的互联网连接，带宽100Mbps以上

### 软件要求
- **操作系统**: Ubuntu 22.04 LTS / CentOS 8+ / RHEL 8+
- **Docker**: 24.0+
- **Docker Compose**: 2.20+
- **权限**: sudo/root 访问权限

### 端口要求
- **80**: HTTP访问（Nginx前端）
- **443**: HTTPS访问（推荐）
- **8000**: 后端API（内部）
- **3306**: MySQL（内部）
- **6379**: Redis（内部）

## 🚀 部署前准备

### 1. 服务器初始化

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装必要工具
sudo apt install -y curl wget git vim htop

# 配置防火墙
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 2. 安装Docker

```bash
# 安装Docker官方GPG密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 添加Docker官方APT仓库
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到docker组
sudo usermod -aG docker $USER
```

### 3. 创建项目目录

```bash
# 创建项目目录
sudo mkdir -p /opt/wlweb
sudo chown $USER:$USER /opt/wlweb
cd /opt/wlweb

# 克隆项目
git clone <your-repository-url> .
```

## 🐳 Docker生产环境部署

### 1. 创建生产环境配置

```bash
# 复制环境配置模板
cp .env.example .env.production

# 编辑生产环境配置
vim .env.production
```

### 2. 生产环境配置示例

```bash
# 数据库配置
MYSQL_ROOT_PASSWORD=your_very_secure_root_password_here
MYSQL_DATABASE=wlweb_prod
MYSQL_USER=wlweb_prod
MYSQL_PASSWORD=your_very_secure_db_password_here

# 后端配置
SECRET_KEY=your_very_long_and_secure_secret_key_at_least_32_characters_long
DEBUG=false
CORS_ORIGINS=https://yourdomain.com

# 数据库连接URL
DATABASE_URL=mysql+pymysql://wlweb_prod:your_very_secure_db_password_here@mysql:3306/wlweb_prod

# Redis配置
REDIS_URL=redis://:your_redis_password@redis:6379/0
REDIS_PASSWORD=your_redis_password

# JWT配置
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 应用配置
APP_NAME=游戏脚本中间件管理系统
APP_VERSION=1.0.0
MAX_TERMINALS=1000
TASK_TIMEOUT=600
DATA_RETENTION_DAYS=90
ENABLE_AUTO_CLEANUP=true
ENABLE_REGISTRATION=false

# 日志配置
LOG_LEVEL=INFO
LOG_FILE_MAX_SIZE=50MB
LOG_FILE_BACKUP_COUNT=10

# 安全配置
ENABLE_HTTPS=true
SSL_CERT_PATH=/etc/ssl/certs/wlweb.crt
SSL_KEY_PATH=/etc/ssl/private/wlweb.key
```

### 3. 创建生产环境Docker Compose文件

```bash
# 创建生产环境compose文件
cp docker-compose.yml docker-compose.prod.yml
```

### 4. 部署命令

```bash
# 使用生产环境配置部署
docker compose -f docker-compose.prod.yml --env-file .env.production up -d

# 查看服务状态
docker compose -f docker-compose.prod.yml ps

# 查看日志
docker compose -f docker-compose.prod.yml logs -f
```

## 🔒 安全配置

### 1. SSL/TLS配置

```bash
# 安装Certbot（Let's Encrypt）
sudo apt install -y certbot python3-certbot-nginx

# 获取SSL证书
sudo certbot --nginx -d yourdomain.com

# 设置自动续期
sudo crontab -e
# 添加以下行：
# 0 12 * * * /usr/bin/certbot renew --quiet
```

### 2. 数据库安全

```bash
# 进入MySQL容器
docker compose exec mysql mysql -u root -p

# 执行安全配置
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_secure_password';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
```

### 3. Redis安全

```bash
# Redis配置文件安全设置
# 在docker-compose.prod.yml中添加Redis密码
redis:
  image: redis:7-alpine
  command: redis-server --requirepass your_redis_password
  environment:
    - REDIS_PASSWORD=your_redis_password
```

### 4. 防火墙配置

```bash
# 配置iptables规则
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -P INPUT DROP

# 保存规则
sudo iptables-save > /etc/iptables/rules.v4
```

## ⚡ 性能优化

### 1. Nginx优化

```nginx
# 在nginx.conf中添加性能优化配置
worker_processes auto;
worker_connections 2048;

# 启用HTTP/2
listen 443 ssl http2;

# 缓存配置
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary Accept-Encoding;
}

# 启用Brotli压缩（如果支持）
brotli on;
brotli_comp_level 6;
brotli_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
```

### 2. MySQL优化

```sql
-- 在MySQL中执行性能优化
SET GLOBAL innodb_buffer_pool_size = 2147483648; -- 2GB
SET GLOBAL max_connections = 200;
SET GLOBAL query_cache_size = 268435456; -- 256MB
SET GLOBAL slow_query_log = 1;
SET GLOBAL long_query_time = 2;
```

### 3. Redis优化

```bash
# Redis配置优化
redis:
  image: redis:7-alpine
  command: >
    redis-server
    --maxmemory 1gb
    --maxmemory-policy allkeys-lru
    --save 900 1
    --save 300 10
    --save 60 10000
```

## 📊 监控和日志

### 1. 日志配置

```yaml
# 在docker-compose.prod.yml中配置日志
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### 2. 健康检查

```bash
# 创建健康检查脚本
cat > /opt/wlweb/health_check.sh << 'EOF'
#!/bin/bash

# 检查服务状态
echo "检查服务状态..."
docker compose -f docker-compose.prod.yml ps

# 检查前端
echo "检查前端服务..."
curl -f http://localhost/health || echo "前端服务异常"

# 检查后端API
echo "检查后端API..."
curl -f http://localhost:8000/health || echo "后端API异常"

# 检查数据库连接
echo "检查数据库连接..."
docker compose -f docker-compose.prod.yml exec -T mysql mysqladmin ping -h localhost || echo "数据库连接异常"

# 检查Redis
echo "检查Redis服务..."
docker compose -f docker-compose.prod.yml exec -T redis redis-cli ping || echo "Redis服务异常"
EOF

chmod +x /opt/wlweb/health_check.sh

# 设置定时健康检查
echo "*/5 * * * * /opt/wlweb/health_check.sh >> /var/log/wlweb_health.log 2>&1" | crontab -
```

### 3. 系统监控

```bash
# 安装系统监控工具
sudo apt install -y htop iotop nethogs

# 创建系统监控脚本
cat > /opt/wlweb/system_monitor.sh << 'EOF'
#!/bin/bash

echo "=== 系统资源使用情况 ==="
echo "时间: $(date)"
echo "CPU使用率:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
echo "内存使用情况:"
free -h
echo "磁盘使用情况:"
df -h
echo "Docker容器状态:"
docker stats --no-stream
echo "=============================="
EOF

chmod +x /opt/wlweb/system_monitor.sh
```

## 💾 备份策略

### 1. 数据库备份

```bash
# 创建数据库备份脚本
cat > /opt/wlweb/backup_database.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/wlweb/backups"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/mysql_backup_$DATE.sql"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份数据库
docker compose -f docker-compose.prod.yml exec -T mysql mysqldump -u root -p$MYSQL_ROOT_PASSWORD --all-databases > $BACKUP_FILE

# 压缩备份文件
gzip $BACKUP_FILE

# 删除7天前的备份
find $BACKUP_DIR -name "mysql_backup_*.sql.gz" -mtime +7 -delete

echo "数据库备份完成: $BACKUP_FILE.gz"
EOF

chmod +x /opt/wlweb/backup_database.sh

# 设置每日自动备份
echo "0 2 * * * /opt/wlweb/backup_database.sh >> /var/log/wlweb_backup.log 2>&1" | crontab -
```

### 2. 应用备份

```bash
# 创建应用备份脚本
cat > /opt/wlweb/backup_application.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/opt/wlweb/backups"
DATE=$(date +"%Y%m%d_%H%M%S")
APP_BACKUP_FILE="$BACKUP_DIR/app_backup_$DATE.tar.gz"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份应用文件（排除不必要的文件）
tar -czf $APP_BACKUP_FILE \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='logs' \
    --exclude='backups' \
    /opt/wlweb

# 删除30天前的应用备份
find $BACKUP_DIR -name "app_backup_*.tar.gz" -mtime +30 -delete

echo "应用备份完成: $APP_BACKUP_FILE"
EOF

chmod +x /opt/wlweb/backup_application.sh
```

## 🔧 故障排除

### 常见问题解决

1. **服务无法启动**
```bash
# 查看详细日志
docker compose -f docker-compose.prod.yml logs -f [service_name]

# 检查端口占用
sudo netstat -tulpn | grep :80

# 重启服务
docker compose -f docker-compose.prod.yml restart [service_name]
```

2. **数据库连接失败**
```bash
# 检查数据库状态
docker compose -f docker-compose.prod.yml exec mysql mysqladmin ping

# 查看数据库日志
docker compose -f docker-compose.prod.yml logs mysql

# 重置数据库密码
docker compose -f docker-compose.prod.yml exec mysql mysql -u root -p
```

3. **内存不足**
```bash
# 查看内存使用
free -h
docker stats

# 清理Docker缓存
docker system prune -a

# 重启服务释放内存
docker compose -f docker-compose.prod.yml restart
```

## 🛠️ 维护指南

### 日常维护任务

1. **每日检查**
   - 查看服务状态
   - 检查日志错误
   - 监控系统资源

2. **每周维护**
   - 更新系统包
   - 清理日志文件
   - 检查备份完整性

3. **每月维护**
   - 更新Docker镜像
   - 优化数据库
   - 安全扫描

### 更新部署

```bash
# 拉取最新代码
cd /opt/wlweb
git pull origin main

# 重新构建并部署
docker compose -f docker-compose.prod.yml build --no-cache
docker compose -f docker-compose.prod.yml up -d

# 清理旧镜像
docker image prune -f
```

### 扩容指南

当系统负载增加时，可以考虑以下扩容方案：

1. **垂直扩容**：增加服务器CPU和内存
2. **水平扩容**：使用Docker Swarm或Kubernetes
3. **数据库优化**：读写分离、分库分表
4. **缓存优化**：Redis集群、CDN加速

---

## 📞 技术支持

如果在部署过程中遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查系统日志和应用日志
3. 联系技术支持团队

---

**注意**: 生产环境部署前请务必在测试环境中验证所有配置和功能。