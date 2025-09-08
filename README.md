# 游戏脚本中间件管理系统

一个基于 Vue 3 + FastAPI 的游戏脚本中间件管理系统，用于管理游戏终端设备、执行脚本任务和监控系统状态。

## 技术栈

### 前端
- **Vue 3** - 渐进式 JavaScript 框架
- **TypeScript** - 类型安全的 JavaScript 超集
- **Vite** - 快速的前端构建工具
- **Tailwind CSS** - 实用优先的 CSS 框架
- **Vue Router** - Vue.js 官方路由管理器

### 后端
- **FastAPI** - 现代、快速的 Python Web 框架
- **SQLAlchemy** - Python SQL 工具包和 ORM
- **Pydantic** - 数据验证和设置管理
- **Alembic** - 数据库迁移工具
- **JWT** - JSON Web Token 认证

### 数据库
- **MySQL 8.0** - 关系型数据库
- **Redis** - 内存数据结构存储

### 部署
- **Docker** - 容器化部署
- **Docker Compose** - 多容器应用编排
- **Nginx** - Web 服务器和反向代理

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
- 系统概览仪表板
- 终端设备统计
- 任务执行统计
- 实时数据展示

### 系统设置
- 用户信息管理
- 密码修改
- 系统配置（管理员）
- 数据清理工具

## 项目结构

```
wlweb/
├── backend/                 # FastAPI 后端
│   ├── app/
│   │   ├── api/            # API 路由
│   │   ├── core/           # 核心配置
│   │   ├── models/         # 数据模型
│   │   ├── schemas/        # Pydantic 模式
│   │   ├── services/       # 业务逻辑
│   │   ├── utils/          # 工具函数
│   │   └── main.py         # 应用入口
│   ├── migrations/         # 数据库迁移
│   ├── requirements.txt    # Python 依赖
│   ├── Dockerfile         # 生产环境镜像
│   └── Dockerfile.dev     # 开发环境镜像
├── src/                    # Vue 前端
│   ├── components/         # 组件
│   ├── composables/        # 组合式函数
│   ├── lib/               # 工具库
│   ├── pages/             # 页面组件
│   ├── router/            # 路由配置
│   └── main.ts            # 应用入口
├── docker-compose.yml      # 生产环境编排
├── docker-compose.dev.yml  # 开发环境编排
├── nginx.conf             # Nginx 配置
├── .env.example           # 环境变量模板
└── README.md              # 项目文档
```

## 快速开始

### 环境要求

- Docker 20.10+
- Docker Compose 2.0+
- Node.js 18+ (开发环境)
- Python 3.11+ (开发环境)

### 生产环境部署

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd wlweb
   ```

2. **配置环境变量**
   ```bash
   cp .env.example .env
   # 编辑 .env 文件，修改数据库密码、JWT密钥等配置
   ```

3. **启动服务**
   ```bash
   docker-compose up -d
   ```

4. **访问应用**
   - 前端: http://localhost
   - 后端API: http://localhost:8000
   - API文档: http://localhost:8000/docs

### 开发环境设置

1. **启动数据库服务**
   ```bash
   docker-compose -f docker-compose.dev.yml up mysql redis -d
   ```

2. **后端开发**
   ```bash
   cd backend
   pip install -r requirements.txt
   uvicorn app.main:app --reload --port 8001
   ```

3. **前端开发**
   ```bash
   npm install
   npm run dev
   ```

## API 接口

### 认证接口
- `POST /auth/login` - 用户登录
- `POST /auth/logout` - 用户登出
- `GET /auth/me` - 获取当前用户信息

### 用户管理
- `GET /users` - 获取用户列表
- `POST /users` - 创建用户
- `PUT /users/{user_id}` - 更新用户
- `DELETE /users/{user_id}` - 删除用户

### 终端管理
- `GET /terminals` - 获取终端列表
- `POST /terminals` - 创建终端
- `GET /terminals/{terminal_id}` - 获取终端详情
- `PUT /terminals/{terminal_id}` - 更新终端
- `DELETE /terminals/{terminal_id}` - 删除终端

### 任务管理
- `GET /tasks` - 获取任务列表
- `POST /tasks` - 创建任务
- `GET /tasks/{task_id}` - 获取任务详情
- `PUT /tasks/{task_id}` - 更新任务
- `DELETE /tasks/{task_id}` - 删除任务
- `POST /tasks/{task_id}/execute` - 执行任务

### 对外开放接口
- `POST /external/terminals/register` - 终端注册
- `POST /external/terminals/heartbeat` - 终端心跳
- `POST /external/terminals/data` - 终端数据上报
- `GET /external/tasks/{terminal_id}` - 获取终端任务
- `POST /external/tasks/result` - 任务结果上报

## 数据库设计

### 主要数据表

- **users** - 用户表
- **user_sessions** - 用户会话表
- **terminals** - 终端设备表
- **terminal_data** - 终端数据表
- **tasks** - 任务表
- **task_executions** - 任务执行记录表

详细的数据库结构请参考 `backend/migrations/001_initial_schema.sql`

## 配置说明

### 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `MYSQL_ROOT_PASSWORD` | MySQL root 密码 | `root123` |
| `MYSQL_DATABASE` | 数据库名 | `wlweb` |
| `MYSQL_USER` | 数据库用户 | `wlweb` |
| `MYSQL_PASSWORD` | 数据库密码 | `wlweb123` |
| `SECRET_KEY` | JWT 密钥 | - |
| `DEBUG` | 调试模式 | `false` |
| `CORS_ORIGINS` | 跨域允许源 | - |

### 系统配置

- **最大终端连接数**: 100
- **任务执行超时**: 300秒
- **数据保留天数**: 30天
- **自动数据清理**: 启用

## 开发指南

### 代码规范

- **前端**: 使用 ESLint + Prettier
- **后端**: 使用 Black + Flake8
- **提交**: 使用 Conventional Commits

### 测试

```bash
# 后端测试
cd backend
pytest

# 前端测试
npm run test
```

### 构建

```bash
# 前端构建
npm run build

# Docker 镜像构建
docker-compose build
```

## 部署指南

### 生产环境部署

1. 确保服务器安装了 Docker 和 Docker Compose
2. 配置环境变量和安全设置
3. 使用 `docker-compose up -d` 启动服务
4. 配置反向代理和 SSL 证书
5. 设置监控和日志收集

### 安全建议

- 修改默认密码和密钥
- 启用 HTTPS
- 配置防火墙规则
- 定期更新依赖包
- 备份数据库

## 故障排除

### 常见问题

1. **数据库连接失败**
   - 检查数据库服务是否启动
   - 验证连接配置和密码

2. **前端无法访问后端**
   - 检查 CORS 配置
   - 验证 API 地址配置

3. **Docker 容器启动失败**
   - 查看容器日志: `docker-compose logs`
   - 检查端口占用情况

### 日志查看

```bash
# 查看所有服务日志
docker-compose logs

# 查看特定服务日志
docker-compose logs backend
docker-compose logs frontend
```

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 许可证

MIT License

## 联系方式

如有问题或建议，请提交 Issue 或联系开发团