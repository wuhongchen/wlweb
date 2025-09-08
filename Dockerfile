# 多阶段构建
# 第一阶段：构建前端
FROM node:18-alpine as frontend-builder

WORKDIR /app

# 复制前端依赖文件
COPY package*.json ./
RUN npm ci --only=production

# 复制前端源码并构建
COPY . .
RUN npm run build

# 第二阶段：生产环境
FROM nginx:alpine

# 复制构建好的前端文件
COPY --from=frontend-builder /app/dist /usr/share/nginx/html

# 复制nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 暴露端口
EXPOSE 80

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]