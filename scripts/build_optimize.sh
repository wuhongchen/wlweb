#!/bin/bash

# Docker镜像构建优化脚本
# 用于优化构建过程，减少构建时间和镜像大小

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置变量
PROJECT_NAME="wlweb"
REGISTRY=""
TAG="latest"
ENVIRONMENT="production"
BUILD_CACHE=true
PUSH_IMAGES=false
CLEANUP_OLD=true
PARALLEL_BUILD=true

# 显示帮助信息
show_help() {
    cat << EOF
Docker镜像构建优化脚本

用法: $0 [选项]

选项:
  -e, --env ENV          设置环境 (development|production) [默认: production]
  -t, --tag TAG          设置镜像标签 [默认: latest]
  -r, --registry REG     设置镜像仓库地址
  --no-cache             禁用构建缓存
  --push                 构建后推送镜像到仓库
  --no-cleanup           不清理旧镜像
  --no-parallel          禁用并行构建
  -h, --help             显示此帮助信息

示例:
  $0                                    # 使用默认设置构建
  $0 -e development -t dev              # 构建开发环境镜像
  $0 -t v1.0.0 --push                  # 构建并推送v1.0.0版本
  $0 -r registry.example.com --push    # 推送到私有仓库
EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        --no-cache)
            BUILD_CACHE=false
            shift
            ;;
        --push)
            PUSH_IMAGES=true
            shift
            ;;
        --no-cleanup)
            CLEANUP_OLD=false
            shift
            ;;
        --no-parallel)
            PARALLEL_BUILD=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 验证环境参数
if [[ "$ENVIRONMENT" != "development" && "$ENVIRONMENT" != "production" ]]; then
    log_error "无效的环境: $ENVIRONMENT (必须是 development 或 production)"
    exit 1
fi

# 设置镜像名称
if [[ -n "$REGISTRY" ]]; then
    BACKEND_IMAGE="$REGISTRY/${PROJECT_NAME}-backend:$TAG"
    FRONTEND_IMAGE="$REGISTRY/${PROJECT_NAME}-frontend:$TAG"
else
    BACKEND_IMAGE="${PROJECT_NAME}-backend:$TAG"
    FRONTEND_IMAGE="${PROJECT_NAME}-frontend:$TAG"
fi

# 检查Docker是否运行
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker未运行或无权限访问"
        exit 1
    fi
}

# 检查必要文件
check_files() {
    local missing_files=()
    
    if [[ "$ENVIRONMENT" == "production" ]]; then
        [[ ! -f "backend/Dockerfile.prod" ]] && missing_files+=("backend/Dockerfile.prod")
        [[ ! -f "Dockerfile.prod" ]] && missing_files+=("Dockerfile.prod")
        [[ ! -f "docker-compose.prod.yml" ]] && missing_files+=("docker-compose.prod.yml")
    else
        [[ ! -f "backend/Dockerfile" ]] && missing_files+=("backend/Dockerfile")
        [[ ! -f "Dockerfile" ]] && missing_files+=("Dockerfile")
        [[ ! -f "docker-compose.yml" ]] && missing_files+=("docker-compose.yml")
    fi
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "缺少必要文件:"
        printf '  - %s\n' "${missing_files[@]}"
        exit 1
    fi
}

# 清理旧镜像
cleanup_old_images() {
    if [[ "$CLEANUP_OLD" == "true" ]]; then
        log_info "清理旧的未使用镜像..."
        
        # 清理悬空镜像
        docker image prune -f >/dev/null 2>&1 || true
        
        # 清理旧版本镜像（保留最新3个版本）
        local old_backend_images=$(docker images "${PROJECT_NAME}-backend" --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" | tail -n +2 | sort -k2 -r | tail -n +4 | awk '{print $1}')
        local old_frontend_images=$(docker images "${PROJECT_NAME}-frontend" --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" | tail -n +2 | sort -k2 -r | tail -n +4 | awk '{print $1}')
        
        if [[ -n "$old_backend_images" ]]; then
            echo "$old_backend_images" | xargs -r docker rmi >/dev/null 2>&1 || true
        fi
        
        if [[ -n "$old_frontend_images" ]]; then
            echo "$old_frontend_images" | xargs -r docker rmi >/dev/null 2>&1 || true
        fi
        
        log_success "清理完成"
    fi
}

# 构建后端镜像
build_backend() {
    log_info "构建后端镜像: $BACKEND_IMAGE"
    
    local dockerfile="backend/Dockerfile"
    if [[ "$ENVIRONMENT" == "production" ]]; then
        dockerfile="backend/Dockerfile.prod"
    fi
    
    local build_args=()
    build_args+=("--file" "$dockerfile")
    build_args+=("--tag" "$BACKEND_IMAGE")
    
    if [[ "$BUILD_CACHE" == "false" ]]; then
        build_args+=("--no-cache")
    fi
    
    # 添加构建参数
    build_args+=("--build-arg" "BUILDKIT_INLINE_CACHE=1")
    build_args+=("--build-arg" "ENVIRONMENT=$ENVIRONMENT")
    
    # 使用BuildKit进行优化构建
    DOCKER_BUILDKIT=1 docker build "${build_args[@]}" backend/
    
    if [[ $? -eq 0 ]]; then
        log_success "后端镜像构建完成"
    else
        log_error "后端镜像构建失败"
        return 1
    fi
}

# 构建前端镜像
build_frontend() {
    log_info "构建前端镜像: $FRONTEND_IMAGE"
    
    local dockerfile="Dockerfile"
    if [[ "$ENVIRONMENT" == "production" ]]; then
        dockerfile="Dockerfile.prod"
    fi
    
    local build_args=()
    build_args+=("--file" "$dockerfile")
    build_args+=("--tag" "$FRONTEND_IMAGE")
    
    if [[ "$BUILD_CACHE" == "false" ]]; then
        build_args+=("--no-cache")
    fi
    
    # 添加构建参数
    build_args+=("--build-arg" "BUILDKIT_INLINE_CACHE=1")
    build_args+=("--build-arg" "ENVIRONMENT=$ENVIRONMENT")
    
    # 使用BuildKit进行优化构建
    DOCKER_BUILDKIT=1 docker build "${build_args[@]}" .
    
    if [[ $? -eq 0 ]]; then
        log_success "前端镜像构建完成"
    else
        log_error "前端镜像构建失败"
        return 1
    fi
}

# 并行构建
build_parallel() {
    log_info "开始并行构建镜像..."
    
    # 启动后端构建
    build_backend &
    local backend_pid=$!
    
    # 启动前端构建
    build_frontend &
    local frontend_pid=$!
    
    # 等待构建完成
    local backend_result=0
    local frontend_result=0
    
    wait $backend_pid || backend_result=$?
    wait $frontend_pid || frontend_result=$?
    
    if [[ $backend_result -ne 0 || $frontend_result -ne 0 ]]; then
        log_error "镜像构建失败"
        return 1
    fi
    
    log_success "所有镜像构建完成"
}

# 串行构建
build_sequential() {
    log_info "开始串行构建镜像..."
    
    build_backend || return 1
    build_frontend || return 1
    
    log_success "所有镜像构建完成"
}

# 推送镜像
push_images() {
    if [[ "$PUSH_IMAGES" == "true" ]]; then
        if [[ -z "$REGISTRY" ]]; then
            log_warning "未指定仓库地址，跳过推送"
            return 0
        fi
        
        log_info "推送镜像到仓库..."
        
        docker push "$BACKEND_IMAGE" || {
            log_error "后端镜像推送失败"
            return 1
        }
        
        docker push "$FRONTEND_IMAGE" || {
            log_error "前端镜像推送失败"
            return 1
        }
        
        log_success "镜像推送完成"
    fi
}

# 显示镜像信息
show_image_info() {
    log_info "镜像构建信息:"
    echo "  环境: $ENVIRONMENT"
    echo "  标签: $TAG"
    echo "  后端镜像: $BACKEND_IMAGE"
    echo "  前端镜像: $FRONTEND_IMAGE"
    
    if [[ -n "$REGISTRY" ]]; then
        echo "  仓库: $REGISTRY"
    fi
    
    echo
    
    # 显示镜像大小
    log_info "镜像大小:"
    docker images | grep -E "${PROJECT_NAME}-(backend|frontend)" | grep "$TAG" || true
}

# 主函数
main() {
    log_info "开始Docker镜像构建优化流程"
    
    # 检查环境
    check_docker
    check_files
    
    # 清理旧镜像
    cleanup_old_images
    
    # 构建镜像
    if [[ "$PARALLEL_BUILD" == "true" ]]; then
        build_parallel || exit 1
    else
        build_sequential || exit 1
    fi
    
    # 推送镜像
    push_images || exit 1
    
    # 显示信息
    show_image_info
    
    log_success "Docker镜像构建优化完成！"
}

# 执行主函数
main "$@"