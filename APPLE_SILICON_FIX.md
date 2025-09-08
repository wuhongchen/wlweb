# Apple Silicon Mac Docker 兼容性修复

## 问题描述

在 Apple Silicon (M1/M2/M3) Mac 上运行 Docker 部署时，可能会遇到以下错误：

```
Error: Cannot find module @rollup/rollup-linux-arm64-musl
```

这是因为 Node.js 容器在 ARM64 架构上运行时，某些 npm 包的预编译二进制文件不兼容导致的。

## 解决方案

我们已经在 `docker-compose.yml` 文件中添加了 `platform: linux/amd64` 配置，强制容器使用 x86_64 架构运行，确保兼容性。

### 修改内容

1. **移除过时的 version 字段**
   - 删除了 `docker-compose.yml` 开头的 `version: '3.8'` 字段
   - 避免 Docker Compose 产生过时警告

2. **添加平台架构配置**
   - 为 `frontend` 服务添加 `platform: linux/amd64`
   - 为 `backend` 服务添加 `platform: linux/amd64`
   - 确保在 Apple Silicon Mac 上使用 x86_64 架构

3. **修复前端构建问题**
   - 在前端 Dockerfile 中添加依赖清理和重新安装步骤
   - 解决 rollup 模块的 npm bug 问题

4. **修复后端启动问题**
   - 修正后端 Dockerfile 中的启动命令：`uvicorn main:app` 而不是 `uvicorn app.main:app`
   - 修复环境变量名称：`BACKEND_CORS_ORIGINS` 而不是 `CORS_ORIGINS`
   - 添加缺失的依赖：`email-validator==2.1.0`
   - 修改健康检查命令：使用 Python 而不是 curl

## 重新部署

修复完成后，请按以下步骤重新部署：

### 1. 清理现有容器和镜像

```bash
# 停止所有服务
docker-compose down

# 删除相关镜像（强制重新构建）
docker rmi wlweb-frontend wlweb-backend 2>/dev/null || true

# 清理构建缓存
docker builder prune -f
```

### 2. 重新部署

```bash
# 使用部署脚本
./docker_deploy.sh deploy

# 或者手动部署
docker-compose up --build -d
```

### 3. 验证部署

```bash
# 检查服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 测试前端访问
curl http://localhost

# 测试后端API
curl http://localhost:8000/health
```

## 性能说明

- 使用 `linux/amd64` 平台在 Apple Silicon Mac 上会通过 Rosetta 2 模拟运行
- 性能可能略有下降，但确保了兼容性
- 对于生产环境，建议在 x86_64 服务器上部署以获得最佳性能

## API 地址配置问题

**问题**: 前端代码中的 API 地址可能指向错误的链接和端口，导致无法正确连接后端服务。

**解决方案**: 使用环境变量配置 API 地址，使其可以根据 Docker 生成的地址动态修改。详细配置方法请参考 [API 地址配置指南](./API_CONFIG_GUIDE.md)。

主要修改包括：

1. 创建环境变量配置文件：
   ```
   # .env.development（开发环境）
   VITE_API_BASE_URL=http://localhost:8000
   
   # .env.production（生产环境）
   VITE_API_BASE_URL=/api
   ```

2. 修改前端 API 服务文件，使用环境变量：
   ```typescript
   // API基础配置
   const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000'
   
   // 创建axios实例
   const api: AxiosInstance = axios.create({
     baseURL: API_BASE_URL.endsWith('/api') ? `${API_BASE_URL}/v1` : `${API_BASE_URL}/api/v1`,
     timeout: 10000,
     headers: {
       'Content-Type': 'application/json',
     },
   })
   ```

3. 在 Docker 构建配置中传递环境变量：
   ```dockerfile
   # Dockerfile
   ARG VITE_API_BASE_URL=/api
   ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}
   ```

   ```yaml
   # docker-compose.yml
   frontend:
     build:
       context: .
       dockerfile: Dockerfile
       args:
         - VITE_API_BASE_URL=/api
   ```

## 故障排除

### 如果仍然遇到构建错误

1. **清理 Docker 环境**
   ```bash
   docker system prune -a -f
   docker volume prune -f
   ```

2. **检查 Docker Desktop 设置**
   - 确保 Docker Desktop 已启用 "Use Rosetta for x86/amd64 emulation on Apple Silicon"
   - 重启 Docker Desktop

3. **增加资源分配**
   - 在 Docker Desktop 设置中增加 CPU 和内存分配
   - 推荐：CPU 4核，内存 8GB

### 如果需要原生 ARM64 支持

可以尝试以下方法（实验性）：

1. **修改 package.json**
   ```json
   {
     "scripts": {
       "build": "npm rebuild && vite build"
     }
   }
   ```

2. **使用多阶段构建优化**
   - 在构建阶段清理 node_modules
   - 重新安装依赖

## 联系支持

如果问题仍然存在，请提供以下信息：

- macOS 版本
- Docker Desktop 版本
- 芯片型号 (M1/M2/M3)
- 完整的错误日志

---

*最后更新：2024年*