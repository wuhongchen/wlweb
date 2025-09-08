from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.api.router import api_router
from app.api.open_api_router import open_api_router
from app.core.config import settings

app = FastAPI(
    title="游戏脚本中间件管理系统",
    description="Game Script Middleware Management System API",
    version="1.0.0",
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    default_response_class=JSONResponse
)

# 设置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 添加UTF-8编码中间件
@app.middleware("http")
async def add_charset_header(request, call_next):
    response = await call_next(request)
    if response.headers.get("content-type", "").startswith("application/json"):
        response.headers["content-type"] = "application/json; charset=utf-8"
    return response

# 包含API路由
app.include_router(api_router, prefix=settings.API_V1_STR)

# 包含开放API路由（无需认证）
app.include_router(open_api_router, prefix="/open-api/v1")

@app.get("/")
async def root():
    return {"message": "游戏脚本中间件管理系统 API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)