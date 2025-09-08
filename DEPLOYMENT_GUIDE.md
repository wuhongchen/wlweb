# 游戏脚本中间件管理系统 - Ubuntu 22.04 部署指南

本指南提供了在 Ubuntu 22.04 64-bit 系统上部署游戏脚本中间件管理系统的详细说明。

## 📋 目录

- [系统要求](#系统要求)
- [部署方式](#部署方式)
- [完整部署](#完整部署)
- [快速部署](#快速部署)
- [手动部署](#手动部署)
- [配置说明](#配置说明)
- [服务管理](#服务管理)
- [故障排除](#故障排除)
- [维护指南](#维护指南)
- [安全建议](#安全建议)

## 🖥️ 系统要求

### 硬件要求
- **CPU**: 2核心以上
- **内存**: 4GB以上（推荐8GB）
- **存储**: 20GB以上可用空间
- **网络**: 稳定的互联网连接

### 软件要求
- **操作系统**: Ubuntu 22.04 64-bit
- **权限**: sudo/root 访问权限
- **端口**: 80, 8001, 3306, 6379 端口可用

## 🚀 部署方式

### 方式一：完整自动部署（推荐）

适用于全新的 Ubuntu 22.04 系统，会自动安装所有依赖。

```bash
# 1. 克隆项目
git clone https://github.com/wuhongchen/wlweb.git
cd wlweb

# 2. 给脚本执行权限
chmod +x deploy_ubuntu.sh

# 3. 运行部署脚本
sudo ./deploy_ubuntu.sh
```

### 方式二：快速部署

适用于已经配置好基础环境的服务器，用于代码更新和重新部署。

```bash
# 1. 进入项目目录
cd wlweb

# 2. 运行快速部署
sudo ./quick_deploy.sh
```

### 方式三：Docker 部署

```bash
# 1. 安装 Docker 和 Docker Compose
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 文件，修改必要的配置

# 3. 启动服务
docker-compose up -d
```

## 📦 完整部署

### 部署脚本功能

`deploy_ubuntu.sh` 脚本会自动执行以下操作：

1. **系统检查和更新**
   - 检查 Ubuntu 版本
   - 更新系统包
   - 安装基础工具

2. **环境安装**
   - Node.js 18.x
   - Python 3.11
   - MySQL 8.0
   - Redis 7.x
   - Nginx

3. **项目配置**
   - 创建系统用户
   - 安装项目依赖
   - 配置环境变量
   - 初始化数据库

4. **服务配置**
   - 创建 systemd 服务
   - 配置 Nginx 反向代理
   - 设置防火墙规则

5. **启动和验证**
   - 启动所有服务
   - 执行健康检查
   - 显示部署信息

### 部署过程

```bash
# 完整部署过程大约需要 10-20 分钟
sudo ./deploy_ubuntu.sh
```

部署完成后，你将看到类似以下的输出：

```
===========================================
         部署成功完成！
===========================================

访问地址:
  前端: http://192.168.1.100:80
  后端 API: http://192.168.1.100:8001

服务管理命令:
  启动后端: systemctl start wlweb-backend
  停止后端: systemctl stop wlweb-backend
  重启后端: systemctl restart wlweb-backend
  查看状态: systemctl status wlweb-backend
  查看日志: journalctl -u wlweb-backend -f
```

## ⚡ 快速部署

### 使用场景

- 代码更新后重新部署
- 依赖包更新
- 配置文件修改后重启

### 快速部署步骤

```bash
# 1. 停止服务
sudo systemctl stop wlweb-backend

# 2. 更新代码（如果使用 Git）
git pull origin main

# 3. 运行快速部署
sudo ./quick_deploy.sh
```

## 🔧 手动部署

如果自动部署脚本遇到问题，可以按照以下步骤手动部署：

### 1. 安装系统依赖

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础工具
sudo apt install -y curl wget git unzip software-properties-common

# 安装 Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 安装 Python 3.11
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

# 安装 MySQL
sudo apt install -y mysql-server mysql-client

# 安装 Redis
sudo apt install -y redis-server

# 安装 Nginx
sudo apt install -y nginx
```

### 2. 配置数据库

```bash
# 启动 MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# 配置 MySQL（设置root密码为 root123）
sudo mysql_secure_installation

# 创建数据库和用户
sudo mysql -u root -p
```

```sql
CREATE DATABASE wlweb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'wlweb'@'localhost' IDENTIFIED BY 'wlweb123';
GRANT ALL PRIVILEGES ON wlweb.* TO 'wlweb'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. 配置项目

```bash
# 创建用户
sudo useradd -r -s /bin/bash -d /home/wlweb -m wlweb

# 设置项目权限
sudo chown -R wlweb:wlweb /path/to/wlweb

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件

# 安装前端依赖
sudo -u wlweb npm install
sudo -u wlweb npm run build

# 安装后端依赖
cd backend
sudo -u wlweb python3.11 -m venv venv
sudo -u wlweb bash -c "source venv/bin/activate && pip install -r requirements.txt"
```

### 4. 配置服务

```bash
# 创建 systemd 服务文件
sudo tee /etc/systemd/system/wlweb-backend.service > /dev/null <<EOF
[Unit]
Description=WLWeb Backend Service
After=network.target mysql.service redis-server.service
Requires=mysql.service redis-server.service

[Service]
Type=simple
User=wlweb
Group=wlweb
WorkingDirectory=/path/to/wlweb/backend
Environment=PATH=/path/to/wlweb/backend/venv/bin
EnvironmentFile=/path/to/wlweb/.env
ExecStart=/path/to/wlweb/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8001
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable wlweb-backend
sudo systemctl start wlweb-backend
```

### 5. 配置 Nginx

```bash
# 复制 Nginx 配置
sudo cp nginx.conf /etc/nginx/sites-available/wlweb

# 修改配置文件中的路径
sudo sed -i 's|/app/dist|/path/to/wlweb/dist|g' /etc/nginx/sites-available/wlweb

# 启用站点
sudo ln -s /etc/nginx/sites-available/wlweb /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 测试并重启 Nginx
sudo nginx -t
sudo systemctl restart nginx
```

## ⚙️ 配置说明

### 环境变量配置

编辑 `.env` 文件：

```bash
# 数据库配置
MYSQL_ROOT_PASSWORD=root123
MYSQL_DATABASE=wlweb
MYSQL_USER=wlweb
MYSQL_PASSWORD=wlweb123
DATABASE_URL=mysql+pymysql://wlweb:wlweb123@localhost:3306/wlweb

# Redis配置
REDIS_URL=redis://localhost:6379/0

# 安全配置
SECRET_KEY=your-secret-key-change-in-production
DEBUG=false

# CORS配置
CORS_ORIGINS=http://localhost:80,http://your-domain.com

# 应用配置
APP_NAME=游戏脚本中间件管理系统
APP_VERSION=1.0.0
```

### 端口配置

- **前端**: 80 (Nginx)
- **后端**: 8001
- **MySQL**: 3306
- **Redis**: 6379

### Nginx 配置

主要配置项：
- 静态文件服务
- API 反向代理
- Gzip 压缩
- 安全头设置

## 🔄 服务管理

### 后端服务管理

```bash
# 启动服务
sudo systemctl start wlweb-backend

# 停止服务
sudo systemctl stop wlweb-backend

# 重启服务
sudo systemctl restart wlweb-backend

# 查看状态
sudo systemctl status wlweb-backend

# 查看日志
sudo journalctl -u wlweb-backend -f

# 查看最近的错误日志
sudo journalctl -u wlweb-backend --since "1 hour ago" -p err
```

### 数据库管理

```bash
# 连接数据库
mysql -u wlweb -p wlweb

# 备份数据库
mysqldump -u wlweb -p wlweb > backup_$(date +%Y%m%d_%H%M%S).sql

# 恢复数据库
mysql -u wlweb -p wlweb < backup_file.sql
```

### Nginx 管理

```bash
# 测试配置
sudo nginx -t

# 重新加载配置
sudo systemctl reload nginx

# 重启 Nginx
sudo systemctl restart nginx

# 查看访问日志
sudo tail -f /var/log/nginx/access.log

# 查看错误日志
sudo tail -f /var/log/nginx/error.log
```

## 🔍 故障排除

### 常见问题

#### 1. 后端服务启动失败

```bash
# 查看详细错误信息
sudo journalctl -u wlweb-backend --no-pager -l

# 检查端口占用
sudo netstat -tlnp | grep :8001

# 手动启动测试
cd /path/to/wlweb/backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8001
```

#### 2. 数据库连接失败

```bash
# 检查 MySQL 状态
sudo systemctl status mysql

# 测试数据库连接
mysql -u wlweb -p -h localhost wlweb

# 检查数据库配置
cat .env | grep DATABASE
```

#### 3. 前端无法访问

```bash
# 检查 Nginx 状态
sudo systemctl status nginx

# 检查 Nginx 配置
sudo nginx -t

# 检查端口监听
sudo netstat -tlnp | grep :80

# 查看 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log
```

#### 4. 权限问题

```bash
# 修复项目目录权限
sudo chown -R wlweb:wlweb /path/to/wlweb
sudo chmod -R 755 /path/to/wlweb

# 修复日志目录权限
sudo mkdir -p /var/log/wlweb
sudo chown wlweb:wlweb /var/log/wlweb
```

### 日志分析

#### 系统日志
```bash
# 查看系统日志
sudo journalctl --since "1 hour ago"

# 查看特定服务日志
sudo journalctl -u wlweb-backend --since "1 hour ago"

# 实时查看日志
sudo journalctl -u wlweb-backend -f
```

#### 应用日志
```bash
# 后端应用日志
tail -f /path/to/wlweb/logs/deploy_*.log

# Nginx 访问日志
sudo tail -f /var/log/nginx/access.log

# Nginx 错误日志
sudo tail -f /var/log/nginx/error.log
```

## 🔧 维护指南

### 定期维护任务

#### 1. 系统更新
```bash
# 每月执行一次
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
```

#### 2. 日志清理
```bash
# 清理系统日志（保留最近30天）
sudo journalctl --vacuum-time=30d

# 清理应用日志
find /path/to/wlweb/logs -name "*.log" -mtime +30 -delete
```

#### 3. 数据库维护
```bash
# 数据库备份（建议每日执行）
mysqldump -u wlweb -p wlweb > /backup/wlweb_$(date +%Y%m%d).sql

# 清理旧备份（保留最近7天）
find /backup -name "wlweb_*.sql" -mtime +7 -delete
```

#### 4. 性能监控
```bash
# 检查系统资源使用
top
htop
df -h
free -h

# 检查服务状态
sudo systemctl status wlweb-backend mysql redis-server nginx

# 检查网络连接
sudo netstat -tlnp
```

### 更新部署

#### 代码更新
```bash
# 1. 备份当前版本
cp -r /path/to/wlweb /backup/wlweb_$(date +%Y%m%d)

# 2. 拉取最新代码
cd /path/to/wlweb
git pull origin main

# 3. 运行快速部署
sudo ./quick_deploy.sh
```

#### 依赖更新
```bash
# 更新前端依赖
cd /path/to/wlweb
sudo -u wlweb npm update
sudo -u wlweb npm run build

# 更新后端依赖
cd /path/to/wlweb/backend
sudo -u wlweb bash -c "source venv/bin/activate && pip install --upgrade -r requirements.txt"

# 重启服务
sudo systemctl restart wlweb-backend
```

## 🔒 安全建议

### 1. 防火墙配置
```bash
# 配置 UFW 防火墙
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443  # 如果使用 HTTPS
```

### 2. SSL/TLS 配置
```bash
# 安装 Certbot
sudo apt install -y certbot python3-certbot-nginx

# 获取 SSL 证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo crontab -e
# 添加：0 12 * * * /usr/bin/certbot renew --quiet
```

### 3. 数据库安全
```bash
# 运行 MySQL 安全脚本
sudo mysql_secure_installation

# 限制数据库访问
# 编辑 /etc/mysql/mysql.conf.d/mysqld.cnf
# 添加：bind-address = 127.0.0.1
```

### 4. 系统安全
```bash
# 禁用 root SSH 登录
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# 配置自动安全更新
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 5. 应用安全
- 定期更新 SECRET_KEY
- 使用强密码
- 启用 HTTPS
- 配置适当的 CORS 策略
- 定期备份数据

## 📞 技术支持

如果在部署过程中遇到问题，请：

1. 查看相关日志文件
2. 检查系统资源使用情况
3. 确认网络连接正常
4. 参考故障排除章节
5. 提交 Issue 到项目仓库

## 📝 更新日志

- **v1.0.0** - 初始版本，支持 Ubuntu 22.04 自动部署
- 后续版本更新将在此记录

---

**注意**: 本指南基于 Ubuntu 22.04 64-bit 系统编写，其他版本可能需要适当调整。