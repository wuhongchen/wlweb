# 部署脚本使用说明

本项目提供了多个部署脚本，适用于不同的部署场景和需求。

## 📁 脚本文件说明

| 脚本文件 | 用途 | 适用场景 |
|---------|------|----------|
| `check_environment.sh` | 环境检查 | 部署前检查服务器环境 |
| `deploy_ubuntu.sh` | 完整部署 | 全新Ubuntu 22.04系统 |
| `quick_deploy.sh` | 快速部署 | 代码更新和重新部署 |
| `deploy.py` | Python部署工具 | 开发环境部署 |

## 🚀 使用流程

### 1. 环境检查（推荐第一步）

在部署前，建议先运行环境检查脚本：

```bash
./check_environment.sh
```

该脚本会检查：
- 操作系统版本和架构
- 系统资源（CPU、内存、磁盘）
- 网络连接
- 端口占用情况
- 权限设置
- 已安装的软件
- 安全配置

### 2. 完整部署（首次部署）

适用于全新的Ubuntu 22.04服务器：

```bash
sudo ./deploy_ubuntu.sh
```

该脚本会自动：
- 安装所有必需的系统依赖
- 配置数据库和缓存服务
- 安装前后端依赖
- 构建和部署应用
- 配置系统服务
- 设置防火墙和安全配置

### 3. 快速部署（更新部署）

适用于代码更新或重新部署：

```bash
sudo ./quick_deploy.sh
```

该脚本会：
- 检查系统依赖
- 更新代码
- 重新构建应用
- 重启服务

## 📋 部署前准备

### 系统要求
- **操作系统**: Ubuntu 22.04 64-bit
- **内存**: 4GB以上（推荐8GB）
- **CPU**: 2核心以上（推荐4核心）
- **存储**: 20GB以上可用空间
- **权限**: sudo/root访问权限

### 网络要求
- 稳定的互联网连接
- 能够访问包管理器源
- 以下端口可用：80, 8001, 3306, 6379

## 🔧 配置说明

### 环境变量配置

部署完成后，可以编辑 `.env` 文件来调整配置：

```bash
# 复制示例配置文件
cp .env.example .env

# 编辑配置
nano .env
```

主要配置项：
- 数据库连接信息
- Redis连接信息
- 应用密钥和安全设置
- CORS策略

### 端口配置

默认端口分配：
- **前端**: 80 (通过Nginx)
- **后端API**: 8001
- **MySQL**: 3306
- **Redis**: 6379

## 🔍 故障排除

### 常用检查命令

```bash
# 检查服务状态
sudo systemctl status wlweb-backend
sudo systemctl status nginx
sudo systemctl status mysql
sudo systemctl status redis-server

# 查看服务日志
sudo journalctl -u wlweb-backend -f
sudo tail -f /var/log/nginx/error.log

# 检查端口占用
sudo netstat -tlnp | grep :8001
sudo netstat -tlnp | grep :80

# 测试API连接
curl http://localhost:8001/health
curl http://localhost/
```

### 重新部署

如果部署失败，可以尝试：

```bash
# 1. 停止所有服务
sudo systemctl stop wlweb-backend
sudo systemctl stop nginx

# 2. 清理进程
sudo pkill -f "uvicorn.*app.main:app"
sudo pkill -f "node.*vite"

# 3. 重新运行部署
sudo ./deploy_ubuntu.sh
```

## 📚 详细文档

更详细的部署说明请参考：
- [完整部署指南](DEPLOYMENT_GUIDE.md)
- [项目README](README.md)
- [API文档](API_TEST_REPORT.md)

## 🆘 获取帮助

如果遇到问题：

1. 首先运行环境检查脚本
2. 查看相关日志文件
3. 参考故障排除章节
4. 查看详细部署指南
5. 提交Issue到项目仓库

## 📝 脚本更新

脚本会随项目更新，建议：
- 定期拉取最新代码
- 查看更新日志
- 测试新版本脚本

---

**注意**: 所有脚本都需要在项目根目录下运行，并确保有适当的权限。