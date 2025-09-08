# 自动化部署脚本使用说明

## 概述

本自动化部署脚本 `deploy.py` 专为前后端分离项目设计，提供完整的自动化部署解决方案。脚本采用模块化设计，具备端口管理、构建部署、错误处理、状态监控和回滚机制等功能。

## 功能特性

### 🚀 核心功能
- **自动端口检测与处理**: 智能检测端口占用，自动终止冲突进程
- **前后端自动构建**: 支持 Vue.js 前端和 FastAPI 后端的自动构建部署
- **完善错误处理**: 全流程错误捕获和处理机制
- **实时状态监控**: 部署过程状态监控和健康检查
- **智能回滚机制**: 部署失败时自动回滚到上一个稳定版本
- **备份管理**: 自动创建备份并管理备份生命周期
- **详细日志记录**: 完整的操作日志和错误追踪

### 🛠️ 技术特点
- 模块化设计，易于维护和扩展
- 支持命令行参数，操作灵活
- 跨平台兼容（macOS/Linux）
- 安全的进程管理和资源清理

## 系统要求

### 环境依赖
- Python 3.8+
- Node.js 16+
- npm 或 yarn
- Git

### Python 依赖包
```bash
pip install requests psutil
```

## 项目结构要求

脚本适用于以下项目结构：
```
project-root/
├── frontend/          # 前端项目目录
│   ├── package.json
│   ├── src/
│   └── ...
├── backend/           # 后端项目目录
│   ├── requirements.txt
│   ├── app/
│   └── ...
├── deploy.py          # 部署脚本
└── README_DEPLOY.md   # 本说明文档
```

## 使用方法

### 基本命令

#### 1. 完整部署（前端+后端）
```bash
python deploy.py deploy
```

#### 2. 部署指定组件
```bash
# 仅部署前端
python deploy.py deploy --components frontend

# 仅部署后端
python deploy.py deploy --components backend

# 部署前端和后端
python deploy.py deploy --components frontend backend
```

#### 3. 服务管理
```bash
# 检查服务状态
python deploy.py status

# 启动服务
python deploy.py start

# 停止服务
python deploy.py stop
```

#### 4. 备份管理
```bash
# 列出所有备份
python deploy.py list-backups

# 回滚到指定备份
python deploy.py rollback --backup-id <backup_id>
```

### 高级用法

#### 自定义配置
```bash
# 使用自定义配置文件
python deploy.py deploy --config /path/to/config.json
```

## 配置说明

### 默认配置
```python
class DeployConfig:
    project_root: str = "/current/directory"
    frontend_port: int = 5174
    backend_port: int = 8001
    backup_dir: str = "backups"
    log_dir: str = "logs"
    max_backups: int = 5
    health_check_timeout: int = 30
    health_check_interval: int = 2
```

### 配置项说明
- `project_root`: 项目根目录路径
- `frontend_port`: 前端服务端口
- `backend_port`: 后端服务端口
- `backup_dir`: 备份文件存储目录
- `log_dir`: 日志文件存储目录
- `max_backups`: 最大备份保留数量
- `health_check_timeout`: 健康检查超时时间（秒）
- `health_check_interval`: 健康检查间隔时间（秒）

## 部署流程

### 完整部署流程
1. **预检查**: 验证项目结构和依赖
2. **创建备份**: 备份当前版本的前后端文件
3. **停止服务**: 安全停止正在运行的服务
4. **端口处理**: 检测并释放占用的端口
5. **构建部署**: 执行前后端构建和部署
6. **启动服务**: 启动新版本的服务
7. **健康检查**: 验证服务运行状态
8. **清理备份**: 清理过期的备份文件

### 错误处理机制
- 任何步骤失败时自动触发回滚
- 详细的错误日志记录
- 安全的资源清理
- 用户友好的错误提示

## 日志管理

### 日志文件位置
- 部署日志: `logs/deploy_YYYYMMDD_HHMMSS.log`
- 错误日志: 包含在部署日志中

### 日志级别
- `INFO`: 正常操作信息
- `WARNING`: 警告信息
- `ERROR`: 错误信息
- `DEBUG`: 调试信息（开发模式）

## 备份管理

### 备份策略
- 每次部署前自动创建备份
- 备份包含前后端完整文件
- 自动清理超过保留数量的旧备份
- 备份信息以 JSON 格式存储

### 备份结构
```
backups/
├── backup_20240115_143022/
│   ├── backup_info.json
│   ├── frontend/
│   └── backend/
└── backup_20240115_150315/
    ├── backup_info.json
    ├── frontend/
    └── backend/
```

## 故障排除

### 常见问题

#### 1. 端口占用问题
```bash
# 手动检查端口占用
lsof -i :5174
lsof -i :8001

# 手动终止进程
kill -9 <PID>
```

#### 2. 权限问题
```bash
# 确保脚本有执行权限
chmod +x deploy.py

# 确保目录有写权限
chmod 755 .
```

#### 3. 依赖问题
```bash
# 检查 Python 依赖
pip list | grep -E "requests|psutil"

# 检查 Node.js 版本
node --version
npm --version
```

#### 4. 服务启动失败
- 检查日志文件获取详细错误信息
- 验证项目配置文件
- 确认数据库连接（后端）
- 检查环境变量配置

### 紧急恢复

如果部署完全失败且自动回滚也失败：

1. **手动停止所有服务**
```bash
python deploy.py stop
```

2. **查看可用备份**
```bash
python deploy.py list-backups
```

3. **手动回滚**
```bash
python deploy.py rollback --backup-id <最新备份ID>
```

4. **如果回滚失败，手动恢复**
```bash
# 从备份目录手动复制文件
cp -r backups/<backup_id>/frontend/* frontend/
cp -r backups/<backup_id>/backend/* backend/
```

## 最佳实践

### 部署前准备
1. 确保代码已提交到版本控制系统
2. 在测试环境验证部署流程
3. 检查系统资源（磁盘空间、内存）
4. 备份重要数据

### 生产环境建议
1. 在低峰期执行部署
2. 准备回滚计划
3. 监控服务状态
4. 保留足够的备份
5. 定期清理日志文件

### 安全注意事项
1. 不要在脚本中硬编码敏感信息
2. 确保备份目录的访问权限
3. 定期更新依赖包
4. 监控异常访问

## 扩展开发

### 添加新的部署组件
1. 在 `DeployConfig` 中添加配置项
2. 实现对应的 `_deploy_<component>` 方法
3. 在 `deploy` 方法中添加组件处理逻辑
4. 更新命令行参数解析

### 自定义健康检查
```python
def _custom_health_check(self) -> bool:
    # 实现自定义健康检查逻辑
    pass
```

### 集成外部监控
```python
def _send_notification(self, message: str):
    # 集成钉钉、企业微信等通知
    pass
```

## 版本历史

- **v1.0.0**: 初始版本，包含基本部署功能
- 支持前后端自动部署
- 实现备份和回滚机制
- 添加健康检查和监控

## 技术支持

如遇到问题，请：
1. 查看日志文件获取详细错误信息
2. 参考本文档的故障排除部分
3. 检查项目配置和环境依赖
4. 联系开发团队获取支持

---

**注意**: 请在使用前仔细阅读本文档，确保理解各项功能和操作流程。建议在测试环境充分验证后再在生产环境使用。