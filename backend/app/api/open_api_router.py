from fastapi import APIRouter
from .endpoints import terminals

# 创建开放API路由器
open_api_router = APIRouter()

# 包含终端相关的开放API接口
open_api_router.include_router(
    terminals.router, 
    prefix="/terminals", 
    tags=["open-terminals"]
)