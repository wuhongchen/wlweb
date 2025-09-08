# WLWeb 后端API服务

一个基于 FastAPI 的游戏脚本中间件管理系统后端API服务，提供完整的RESTful API接口用于管理游戏终端设备、执行脚本任务和监控系统状态。

## 技术栈

### 核心框架
- **FastAPI** - 现代、快速的 Python Web 框架
- **SQLAlchemy** - Python SQL 工具包和 ORM
- **Pydantic** - 数据验证和设置管理
- **Alembic** - 数据库迁移工具
- **JWT** - JSON Web Token 认证

### 数据库
- **MySQL 8.0** - 关系型数据库

### 部署
- **Python 3.8+** - 运行环境
- **Uvicorn** - ASGI 服务器

## 功能特性

### 用户管理
- 用户登录/登出
- JWT 令牌认证
- 角色权限控制（管理员/普通用户）

### 终端设备管理
- 终端设备注册和管理
- 实时状态监控
- 心跳检测
- 设备信息查看和编辑

### 任务管理
- 脚本任务创建和编辑
- 任务执行和调度
- 执行历史记录
- 任务状态监控

### 数据统计
- 系统概览数据
- 终端设备统计
- 任务执行统计
- 实时数据查询

### 系统设置
- 用户信息管理
- 密码修改
- 系统配置（管理员）
- 数据清理工具

## 项目结构

```
wlweb/
├── backend/                 # FastAPI 后端核心
│   ├── app/
│   │   ├── api/            # API 路由模块
│   │   │   ├── endpoints/  # 具体接口实现
│   │   │   └── deps.py     # 依赖注入
│   │   ├── core/           # 核心配置
│   │   │   ├── config.py   # 应用配置
│   │   │   ├── database.py # 数据库连接
│   │   │   └── security.py # 安全认证
│   │   ├── models/         # SQLAlchemy 数据模型
│   │   ├── schemas/        # Pydantic 数据模式
│   │   ├── services/       # 业务逻辑服务
│   │   ├── utils/          # 工具函数
│   │   └── main.py         # FastAPI 应用入口
│   ├── migrations/         # Alembic 数据库迁移
│   ├── logs/              # 应用日志目录
│   └── requirements.txt    # Python 依赖包
├── deploy.sh              # 自动化部署脚本
├── .env                   # 环境变量配置
└── README.md              # 项目文档
```

## 快速开始

### 环境要求

- **Python 3.8+** - 推荐使用 Python 3.9 或更高版本
- **MySQL 8.0+** - 数据库服务
- **pip** - Python 包管理器

### 一键部署（推荐）

使用提供的自动化部署脚本，可以快速完成环境检测、依赖安装和服务启动：

```bash
# 克隆项目
git clone <repository-url>
cd wlweb

# 一键部署
./deploy.sh start
```

部署脚本功能：
- ✅ Python 环境检测（3.8+）
- ✅ 自动创建虚拟环境
- ✅ 安装项目依赖
- ✅ 配置文件检查和创建
- ✅ MySQL 连接测试
- ✅ 服务启动和健康检查

### 手动部署

如果需要手动控制部署过程：

1. **环境准备**
   ```bash
   # 创建虚拟环境
   python3 -m venv venv
   source venv/bin/activate
   
   # 安装依赖
   pip install -r backend/requirements.txt
   ```

2. **配置环境变量**
   ```bash
   # 复制并编辑配置文件
   cp .env.example .env
   # 修改数据库连接、JWT密钥等配置
   ```

3. **数据库初始化**
   ```bash
   # 运行数据库迁移
   cd backend
   alembic upgrade head
   ```

4. **启动服务**
   ```bash
   # 启动API服务
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```



## 服务管理

使用部署脚本可以方便地管理服务：

```bash
# 启动服务
./deploy.sh start

# 停止服务
./deploy.sh stop

# 重启服务
./deploy.sh restart

# 查看服务状态
./deploy.sh status

# 查看实时日志
./deploy.sh logs
```

## API 接口文档

服务启动后，可以通过以下地址访问：

- **API 服务**: http://localhost:8000
- **交互式文档**: http://localhost:8000/docs
- **ReDoc 文档**: http://localhost:8000/redoc
- **健康检查**: http://localhost:8000/health

### 主要接口模块

#### 认证接口
- `POST /auth/login` - 用户登录
- `POST /auth/logout` - 用户登出
- `GET /auth/me` - 获取当前用户信息

#### 用户管理
- `GET /users/` - 获取用户列表
- `POST /users/` - 创建新用户
- `GET /users/{user_id}` - 获取用户详情
- `PUT /users/{user_id}` - 更新用户信息
- `DELETE /users/{user_id}` - 删除用户

#### 终端设备管理
- `GET /terminals/` - 获取终端列表
- `POST /terminals/` - 注册新终端
- `GET /terminals/{terminal_id}` - 获取终端详情
- `PUT /terminals/{terminal_id}` - 更新终端信息
- `POST /terminals/{terminal_id}/heartbeat` - 终端心跳

#### 任务管理
- `GET /tasks/` - 获取任务列表
- `POST /tasks/` - 创建新任务
- `GET /tasks/{task_id}` - 获取任务详情
- `PUT /tasks/{task_id}` - 更新任务
- `POST /tasks/{task_id}/execute` - 执行任务

#### 数据统计
- `GET /stats/overview` - 系统概览统计
- `GET /stats/terminals` - 终端统计数据
- `GET /stats/tasks` - 任务统计数据

## 配置说明

### 环境变量配置 (.env)

```bash
# 数据库配置
MYSQL_SERVER=localhost
MYSQL_PORT=3306
MYSQL_USER=wlweb
MYSQL_PASSWORD=wlweb123
MYSQL_DB=wlweb

# JWT 配置
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 应用配置
DEBUG=false
BACKEND_CORS_ORIGINS=*
```

### 依赖包说明

核心依赖包及其作用：

- `fastapi==0.104.1` - Web 框架
- `uvicorn[standard]==0.24.0` - ASGI 服务器
- `sqlalchemy==2.0.23` - ORM 框架
- `alembic==1.12.1` - 数据库迁移
- `pymysql==1.1.0` - MySQL 驱动
- `python-jose[cryptography]==3.3.0` - JWT 处理
- `passlib[bcrypt]==1.7.4` - 密码加密
- `python-multipart==0.0.6` - 文件上传支持
- `pydantic==2.5.0` - 数据验证
- `pydantic-settings==2.1.0` - 配置管理
- `python-dotenv==1.0.0` - 环境变量加载
- `cryptography==41.0.7` - 加密库

## 开发指南

### 添加新的API接口

1. 在 `backend/app/schemas/` 中定义数据模式
2. 在 `backend/app/models/` 中定义数据模型
3. 在 `backend/app/services/` 中实现业务逻辑
4. 在 `backend/app/api/endpoints/` 中创建路由
5. 在 `backend/app/api/api.py` 中注册路由

### 数据库迁移

```bash
# 生成迁移文件
alembic revision --autogenerate -m "描述变更内容"

# 执行迁移
alembic upgrade head

# 回滚迁移
alembic downgrade -1
```

### 日志查看

应用日志存储在 `backend/logs/` 目录：

```bash
# 查看实时日志
tail -f backend/logs/app.log

# 或使用部署脚本
./deploy.sh logs
```

## 性能优化

### 生产环境建议

1. **数据库优化**
   - 配置适当的连接池大小
   - 添加必要的数据库索引
   - 定期优化数据库表

2. **应用优化**
   - 使用 Gunicorn 作为生产服务器
   - 配置适当的工作进程数
   - 启用 Gzip 压缩

3. **安全配置**
   - 修改默认的 JWT 密钥
   - 配置 HTTPS
   - 限制 CORS 来源
   - 定期更新依赖包

## 故障排除

### 常见问题

1. **服务启动失败**
   - 检查 Python 版本是否满足要求
   - 确认 MySQL 服务正在运行
   - 检查端口 8000 是否被占用

2. **数据库连接失败**
   - 验证 .env 文件中的数据库配置
   - 确认 MySQL 用户权限
   - 检查网络连接

3. **API 请求失败**
   - 检查 CORS 配置
   - 验证 JWT 令牌
   - 查看应用日志

### 获取帮助

如果遇到问题，可以：

1. 查看应用日志：`./deploy.sh logs`
2. 检查服务状态：`./deploy.sh status`
3. 查看 API 文档：http://localhost:8000/docs

## 许可证

本项目采用 MIT 许可证。详情请参阅 LICENSE 文件。