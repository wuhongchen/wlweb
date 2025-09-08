# API 地址配置指南

本文档说明如何配置前端应用与后端API的连接地址，以便根据不同环境动态调整API地址。

## 配置文件说明

项目使用环境变量配置API基础URL，通过以下文件进行管理：

### 1. 开发环境配置

文件：`.env.development`

```
# 开发环境配置
VITE_API_BASE_URL=http://localhost:8000
```

### 2. 生产环境配置

文件：`.env.production`

```
# 生产环境配置
VITE_API_BASE_URL=/api
```

## 前端API服务配置

在 `src/lib/api.ts` 文件中，我们使用环境变量配置API基础URL：

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

这段代码会根据 `API_BASE_URL` 是否以 `/api` 结尾来动态设置 `baseURL`：
- 如果以 `/api` 结尾（生产环境），则使用 `/api/v1`
- 如果不以 `/api` 结尾（开发环境），则使用 `http://localhost:8000/api/v1`

## Docker 配置

### 1. Dockerfile

在 `Dockerfile` 中，我们通过构建参数传递环境变量：

```dockerfile
# 构建参数
ARG VITE_API_BASE_URL=/api

# 设置环境变量
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}
```

### 2. docker-compose.yml

在 `docker-compose.yml` 中，我们为前端服务配置构建参数：

```yaml
frontend:
  build:
    context: .
    dockerfile: Dockerfile
    args:
      - VITE_API_BASE_URL=/api
```

## 自定义配置

### 本地开发

如果需要连接到不同的后端API地址，可以修改 `.env.development` 文件中的 `VITE_API_BASE_URL` 值。

### Docker部署

如果需要在Docker部署时使用不同的API地址，可以通过以下方式修改：

1. 修改 `docker-compose.yml` 文件中的构建参数：

```yaml
frontend:
  build:
    context: .
    dockerfile: Dockerfile
    args:
      - VITE_API_BASE_URL=http://api.example.com
```

2. 或者在构建时通过命令行传递参数：

```bash
docker-compose build --build-arg VITE_API_BASE_URL=http://api.example.com frontend
```

## 注意事项

1. 在生产环境中，通常使用相对路径 `/api` 作为API基础URL，这样可以通过Nginx代理将请求转发到后端服务。

2. 确保Nginx配置正确代理API请求，例如：

```nginx
location /api/ {
  proxy_pass http://backend:8000/;
  # 其他代理配置...
}
```

3. 如果API地址发生变化，需要重新构建前端应用以使新的配置生效。