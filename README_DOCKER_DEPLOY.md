# Docker 部署指南

本文档提供了游戏脚本中间件管理系统的 Docker 部署方案，包括开发环境和生产环境的完整部署流程。

## 目录

- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [开发环境部署](#开发环境部署)
- [生产环境部署](#生产环境部署)
- [环境配置](#环境配置)
- [服务管理](#服务管理)
- [监控和维护](#监控和维护)
- [备份和恢复](#备份和恢复)
- [SSL证书管理](#ssl证书管理)
- [故障排除](#故障排除)

## 脚本说明

### 1. docker_deploy.sh - 完整部署脚本

功能完整的部署脚本，支持多种操作模式，适用于生产环境。

**主要功能：**
- 环境检查（Docker、Docker Compose）
- 自动创建环境配置文件
- 数据备份（MySQL数据和数据卷）
- 代码更新（Git拉取）
- 服务构建和部署
- 健康检查
- 状态监控

**使用方法：**
```bash
# 完整部署（首次部署推荐）
./docker_deploy.sh deploy

# 更新代码并重新部署
./docker_deploy.sh update

# 重启服务
./docker_deploy.sh restart

# 停止服务
./docker_deploy.sh stop

# 查看服务状态
./docker_deploy.sh status

# 查看服务日志
./docker_deploy.sh logs

# 创建备份
./docker_deploy.sh backup

# 清理Docker资源
./docker_deploy.sh cleanup

# 显示帮助信息
./docker_deploy.sh help
```

### 2. docker_quick_deploy.sh - 快速部署脚本

轻量级的快速部署脚本，适用于开发和测试环境的快速迭代。

**主要功能：**
- 快速拉取最新代码
- 重新构建和启动服务
- 基本状态检查

**使用方法：**
```bash
# 快速部署
./docker_quick_deploy.sh
```

## 系统要求

### 开发环境
- Docker 20.10+
- Docker Compose 2.0+
- 至少 4GB 内存
- 至少 10GB 可用磁盘空间
- Linux/macOS/Windows 操作系统
- Git（用于代码更新）

### 生产环境
- Docker 20.10+
- Docker Compose 2.0+
- 至少 8GB 内存
- 至少 50GB 可用磁盘空间
- Linux 操作系统（推荐 Ubuntu 20.04+ 或 CentOS 8+）
- 固定IP地址或域名
- SSL证书（推荐使用 Let's Encrypt）
- Git（用于代码更新）

## 快速开始

### 开发环境快速部署

```bash
# 1. 克隆项目
git clone <repository-url>
cd wlweb

# 2. 运行快速部署脚本
chmod +x docker_quick_deploy.sh
./docker_quick_deploy.sh

# 3. 访问应用
# 前端应用: http://localhost
# 后端API: http://localhost:8000
# API文档: http://localhost:8000/docs
```

### 生产环境快速部署

```bash
# 1. 克隆项目
git clone <repository-url>
cd wlweb

# 2. 配置生产环境
cp .env.production .env.production.local
# 编辑 .env.production.local 配置文件

# 3. 运行生产部署脚本
chmod +x scripts/production_deploy.sh
./scripts/production_deploy.sh deploy

# 4. 配置SSL证书（可选）
./scripts/ssl_manager.sh letsencrypt yourdomain.com admin@yourdomain.com
```

## 开发环境部署

### 部署前准备

### 安装Docker

**Ubuntu/Debian:**
```bash
# 安装Docker
curl -fsSL https://get.docker.com | sh

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 添加用户到docker组（可选）
sudo usermod -aG docker $USER
```

**CentOS/RHEL:**
```bash
# 安装Docker
curl -fsSL https://get.docker.com | sh

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker
```

**macOS:**
```bash
# 使用Homebrew安装
brew install --cask docker

# 或下载Docker Desktop
# https://www.docker.com/products/docker-desktop
```

### 验证安装

```bash
# 检查Docker版本
docker --version

# 检查Docker Compose版本
docker-compose --version
# 或
docker compose version

# 测试Docker运行
docker run hello-world
```

### 首次部署步骤

#### 1. 克隆项目

```bash
git clone <repository-url>
cd wlweb
```

#### 2. 执行完整部署

```bash
# 给脚本执行权限
chmod +x docker_deploy.sh docker_quick_deploy.sh

# 执行完整部署
./docker_deploy.sh deploy
```

#### 3. 配置环境变量

脚本会自动创建 `.env` 文件，请根据需要修改配置：

```bash
# 编辑环境配置
vim .env
```

主要配置项：
- `MYSQL_ROOT_PASSWORD`: MySQL root密码
- `MYSQL_PASSWORD`: 应用数据库密码
- `JWT_SECRET_KEY`: JWT密钥（自动生成）
- `REDIS_PASSWORD`: Redis密码

#### 4. 访问应用

部署完成后，可以通过以下地址访问：

- **前端应用**: http://localhost:3000
- **后端API**: http://localhost:8000
- **API文档**: http://localhost:8000/docs
- **交互式API文档**: http://localhost:8000/redoc

### 日常使用

#### 代码更新部署

```bash
# 方法1：使用完整脚本更新
./docker_deploy.sh update

# 方法2：使用快速脚本
./docker_quick_deploy.sh
```

#### 服务管理

```bash
# 查看服务状态
./docker_deploy.sh status

# 查看实时日志
./docker_deploy.sh logs

# 重启服务
./docker_deploy.sh restart

# 停止服务
./docker_deploy.sh stop
```

#### 数据备份

```bash
# 创建备份
./docker_deploy.sh backup

# 备份文件位置
ls backup/
```

## 生产环境部署

### 生产环境配置

生产环境使用独立的配置文件和部署脚本，提供更高的安全性和性能。

#### 1. 环境配置

```bash
# 复制生产环境配置模板
cp .env.production .env.production.local

# 编辑生产环境配置
vim .env.production.local
```

主要配置项：
- `DOMAIN`: 生产环境域名
- `SSL_EMAIL`: SSL证书申请邮箱
- `MYSQL_ROOT_PASSWORD`: MySQL root密码（强密码）
- `MYSQL_PASSWORD`: 应用数据库密码（强密码）
- `JWT_SECRET_KEY`: JWT密钥（复杂密钥）
- `REDIS_PASSWORD`: Redis密码（强密码）
- `ENVIRONMENT`: 设置为 `production`

#### 2. 生产部署

```bash
# 给脚本执行权限
chmod +x scripts/production_deploy.sh

# 执行生产部署
./scripts/production_deploy.sh deploy
```

#### 3. SSL证书配置

```bash
# 自动申请Let's Encrypt证书
./scripts/ssl_manager.sh letsencrypt yourdomain.com admin@yourdomain.com

# 或者使用自定义证书
./scripts/ssl_manager.sh custom /path/to/cert.pem /path/to/key.pem
```

#### 4. 生产环境访问

- **前端应用**: https://yourdomain.com
- **后端API**: https://yourdomain.com/api
- **API文档**: https://yourdomain.com/api/docs

### 生产环境管理

```bash
# 查看服务状态
./scripts/production_deploy.sh status

# 更新应用
./scripts/production_deploy.sh update

# 重启服务
./scripts/production_deploy.sh restart

# 查看日志
./scripts/production_deploy.sh logs

# 创建备份
./scripts/production_deploy.sh backup

# 恢复备份
./scripts/production_deploy.sh restore backup_20231201_120000.tar.gz
```

## 监控和维护

### 系统监控

使用内置的监控脚本来监控系统状态：

```bash
# 执行完整监控检查
./scripts/monitor.sh check

# 检查服务状态
./scripts/monitor.sh services

# 检查系统资源
./scripts/monitor.sh resources

# 持续监控模式（每60秒检查一次）
./scripts/monitor.sh watch --interval 60

# 启用自动修复的持续监控
./scripts/monitor.sh watch --interval 30 --auto-repair

# 生成监控报告
./scripts/monitor.sh report
```

### 性能监控

```bash
# 查看容器资源使用情况
docker stats

# 查看服务日志
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f frontend

# 查看系统负载
htop
iotop
```

## 备份和恢复

### 数据备份

使用内置的备份脚本来管理数据备份：

```bash
# 创建完整备份
./scripts/backup.sh backup daily

# 创建每周备份
./scripts/backup.sh backup weekly

# 创建每月备份
./scripts/backup.sh backup monthly

# 仅备份数据库
./scripts/backup.sh mysql

# 仅备份Redis数据
./scripts/backup.sh redis

# 仅备份上传文件
./scripts/backup.sh uploads

# 仅备份配置文件
./scripts/backup.sh configs
```

### 数据恢复

```bash
# 列出可用备份
./scripts/backup.sh list

# 从完整备份恢复
./scripts/backup.sh restore /path/to/backup/full_backup_20231201_120000

# 恢复特定组件
./scripts/backup.sh restore-mysql /path/to/mysql_backup.sql.gz
./scripts/backup.sh restore-redis /path/to/redis_backup.rdb.gz
./scripts/backup.sh restore-uploads /path/to/uploads_backup.tar.gz

# 验证备份完整性
./scripts/backup.sh verify /path/to/backup
```

### 自动备份

设置定时备份任务：

```bash
# 添加到crontab
crontab -e

# 每天凌晨2点创建备份
0 2 * * * /path/to/wlweb/scripts/backup.sh backup daily

# 每周日凌晨3点创建周备份
0 3 * * 0 /path/to/wlweb/scripts/backup.sh backup weekly

# 每月1号凌晨4点创建月备份
0 4 1 * * /path/to/wlweb/scripts/backup.sh backup monthly
```

## SSL证书管理

### Let's Encrypt证书

自动申请和管理Let's Encrypt免费SSL证书：

```bash
# 申请SSL证书
./scripts/ssl_manager.sh letsencrypt yourdomain.com admin@yourdomain.com

# 检查证书状态
./scripts/ssl_manager.sh status

# 手动续期证书
./scripts/ssl_manager.sh renew

# 测试SSL连接
./scripts/ssl_manager.sh test yourdomain.com 443
```

### 自定义SSL证书

使用自己的SSL证书：

```bash
# 生成自签名证书（开发环境）
./scripts/ssl_manager.sh self-signed yourdomain.com 365

# 部署自定义证书
cp your-cert.pem nginx/ssl/cert.pem
cp your-key.pem nginx/ssl/key.pem
chmod 600 nginx/ssl/key.pem
chmod 644 nginx/ssl/cert.pem

# 验证证书
./scripts/ssl_manager.sh verify
```

### 证书备份和恢复

```bash
# 备份证书
./scripts/ssl_manager.sh backup

# 恢复证书
./scripts/ssl_manager.sh restore /path/to/ssl_backup

# 查看证书详细信息
./scripts/ssl_manager.sh info
```

## 故障排除

### 常见问题

#### 1. 端口被占用
```bash
# 查看端口占用
netstat -tulpn | grep :80
netstat -tulpn | grep :443
netstat -tulpn | grep :8000

# 停止占用端口的服务
sudo systemctl stop nginx
sudo systemctl stop apache2
```

#### 2. Docker服务问题
```bash
# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 检查Docker状态
sudo systemctl status docker

# 重启Docker服务
sudo systemctl restart docker
```

#### 3. 权限问题
```bash
# 将用户添加到docker组
sudo usermod -aG docker $USER
newgrp docker

# 修复文件权限
sudo chown -R $USER:$USER /path/to/wlweb
chmod +x scripts/*.sh
```

#### 4. 磁盘空间不足
```bash
# 清理Docker资源
docker system prune -a
docker volume prune
docker image prune -a

# 清理日志文件
sudo journalctl --vacuum-time=7d
find logs/ -name "*.log" -mtime +7 -delete
```

#### 5. 数据库连接问题
```bash
# 检查MySQL容器状态
docker-compose -f docker-compose.prod.yml ps mysql

# 查看MySQL日志
docker-compose -f docker-compose.prod.yml logs mysql

# 重启MySQL服务
docker-compose -f docker-compose.prod.yml restart mysql
```

#### 6. SSL证书问题
```bash
# 检查证书状态
./scripts/ssl_manager.sh status

# 验证证书配置
./scripts/ssl_manager.sh verify

# 测试SSL连接
./scripts/ssl_manager.sh test yourdomain.com 443

# 重新申请证书
./scripts/ssl_manager.sh letsencrypt yourdomain.com admin@yourdomain.com
```

#### 7. Docker镜像源问题

当遇到镜像拉取失败或DNS解析错误时：

```bash
# 检查当前Docker镜像源配置
docker info | grep -i registry

# 方案1：重置Docker Desktop网络配置
# 关闭Docker Desktop
osascript -e 'quit app "Docker Desktop"'
sleep 10
# 重新启动Docker Desktop
open -a "Docker Desktop"
sleep 45

# 方案2：配置国内镜像源
# 创建或编辑Docker daemon配置文件
sudo mkdir -p /etc/docker

# 选项1：网易云镜像源（推荐）
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://hub-mirror.c.163.com"],
  "dns": ["8.8.8.8", "114.114.114.114"]
}
EOF

# 选项2：七牛云镜像源
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://reg-mirror.qiniu.com"],
  "dns": ["8.8.8.8", "114.114.114.114"]
}
EOF

# 选项3：阿里云镜像源（需要注册获取专属加速地址）
# 地址格式：https://<你的阿里云加速ID>.mirror.aliyuncs.com
# sudo tee /etc/docker/daemon.json <<-'EOF'
# {
#   "registry-mirrors": ["https://<你的阿里云加速ID>.mirror.aliyuncs.com"],
#   "dns": ["8.8.8.8", "114.114.114.114"]
# }
# EOF

# 选项4：多镜像源配置（备用方案）
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

# 重启Docker服务（Linux系统）
sudo systemctl restart docker

# macOS Docker Desktop重启
osascript -e 'quit app "Docker Desktop"'
sleep 10
open -a "Docker Desktop"

# 方案3：使用官方镜像源（如果网络允许）
# 删除镜像源配置
sudo rm /etc/docker/daemon.json
sudo systemctl restart docker

# 方案4：手动下载镜像
# 如果特定镜像无法下载，可以尝试其他标签
docker pull python:3.11-slim-bullseye
docker tag python:3.11-slim-bullseye python:3.11-slim

# 验证镜像拉取
docker pull python:3.11-slim
docker pull node:18-alpine
docker pull nginx:alpine
```

**macOS Docker Desktop特殊处理：**

```bash
# 检查Docker Desktop代理设置
docker system info | grep -i proxy

# 如果有代理配置导致问题，可以通过Docker Desktop GUI重置：
# 1. 打开Docker Desktop
# 2. 进入Settings > Resources > Proxies
# 3. 取消所有代理设置
# 4. 点击Apply & Restart

# 或者通过命令行重置Docker Desktop
osascript -e 'quit app "Docker Desktop"'
rm -rf ~/Library/Group\ Containers/group.com.docker/settings.json
open -a "Docker Desktop"
```

### 日志管理

#### 查看服务日志
```bash
# 查看所有服务日志
docker-compose -f docker-compose.prod.yml logs

# 查看特定服务日志
docker-compose -f docker-compose.prod.yml logs backend
docker-compose -f docker-compose.prod.yml logs frontend
docker-compose -f docker-compose.prod.yml logs mysql
docker-compose -f docker-compose.prod.yml logs redis

# 实时查看日志
docker-compose -f docker-compose.prod.yml logs -f backend

# 查看最近的日志
docker-compose -f docker-compose.prod.yml logs --tail=100 backend
```

#### 系统日志
```bash
# 查看系统日志
sudo journalctl -u docker
sudo journalctl -f

# 查看应用日志
tail -f logs/backend.log
tail -f logs/nginx/access.log
tail -f logs/nginx/error.log
```

#### 日志轮转
```bash
# 配置logrotate
sudo vim /etc/logrotate.d/wlweb

# 内容示例：
/path/to/wlweb/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
```

### 3. 容器调试

```bash
# 进入容器
docker-compose exec backend bash
docker-compose exec frontend sh

# 查看容器状态
docker-compose ps

# 重启特定服务
docker-compose restart backend
```

### 4. 完全重置

如果遇到严重问题，可以完全重置：

```bash
# 停止并删除所有容器
docker-compose down

# 删除所有镜像
docker rmi $(docker images -q)

# 清理系统
docker system prune -a

# 重新部署
./docker_deploy.sh deploy
```

### 性能优化

#### 容器资源优化
```yaml
# 在docker-compose.prod.yml中调整资源限制
deploy:
  resources:
    limits:
      memory: 2G
      cpus: '1.0'
    reservations:
      memory: 1G
      cpus: '0.5'
```

#### 数据库优化
```bash
# MySQL配置优化
vim mysql/my.cnf

[mysqld]
innodb_buffer_pool_size = 2G
max_connections = 500
innodb_log_file_size = 256M
query_cache_size = 128M
```

#### Nginx优化
```bash
# 编辑nginx配置
vim nginx/nginx.prod.conf

# 调整worker进程数
worker_processes auto;
worker_connections 1024;

# 启用gzip压缩
gzip on;
gzip_vary on;
gzip_min_length 1024;
```

#### Redis优化
```bash
# Redis配置优化
vim redis/redis.conf

maxmemory 1gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
```

## 安全建议

1. **定期更新镜像**：
   ```bash
   docker-compose pull
   ./docker_deploy.sh update
   ```

2. **使用非root用户**：
   - 脚本已配置非root用户运行

3. **网络安全**：
   - 生产环境使用防火墙
   - 配置HTTPS
   - 限制数据库访问

4. **数据安全**：
   - 定期备份数据
   - 加密敏感配置
   - 使用强密码

## 维护指南

### 定期维护任务

#### 1. 系统更新
```bash
# 更新系统包
sudo apt update && sudo apt upgrade -y

# 更新Docker
sudo apt update docker-ce docker-ce-cli containerd.io

# 重启系统（如需要）
sudo reboot
```

#### 2. 应用更新
```bash
# 更新应用代码
./scripts/production_deploy.sh update

# 或手动更新
git pull origin main
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d
```

#### 3. 定期清理
```bash
# 清理Docker资源（每周）
./scripts/production_deploy.sh cleanup

# 清理旧备份（每月）
./scripts/backup.sh cleanup

# 清理日志文件
find logs/ -name "*.log" -mtime +30 -delete
```

#### 4. 安全检查
```bash
# 检查系统安全更新
sudo apt list --upgradable | grep security

# 检查开放端口
nmap -sT -O localhost

# 检查失败登录
sudo grep "Failed password" /var/log/auth.log | tail -20
```

#### 5. 性能监控
```bash
# 定期运行性能检查
./scripts/monitor.sh check

# 生成月度报告
./scripts/monitor.sh report > reports/monthly_$(date +%Y%m).txt
```

### 自动化维护

设置crontab任务：

```bash
crontab -e

# 每日备份
0 2 * * * /path/to/wlweb/scripts/backup.sh backup daily

# 每周清理
0 3 * * 0 /path/to/wlweb/scripts/production_deploy.sh cleanup

# 每日监控检查
0 */6 * * * /path/to/wlweb/scripts/monitor.sh check

# SSL证书检查
0 1 * * * /path/to/wlweb/scripts/ssl_manager.sh status
```

## 联系支持

如果遇到问题，请：

1. 查看日志文件：`deploy.log`
2. 检查容器状态：`docker-compose ps`
3. 查看服务日志：`docker-compose logs`
4. 提交Issue时请包含错误日志和环境信息

---

**注意**：首次部署可能需要较长时间下载Docker镜像，请耐心等待。建议在网络良好的环境下进行部署。