from datetime import timedelta
import logging
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import create_access_token, verify_password
from app.core.config import settings
from app.models.user import User
from app.schemas.auth import Token, UserLogin, LoginResponse, UserResponse

logger = logging.getLogger(__name__)

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")

@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户名或密码错误",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        subject=user.username, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }

@router.post("/login-json", response_model=LoginResponse)
async def login_json(
    user_login: UserLogin,
    db: Session = Depends(get_db)
):
    # 记录请求参数到日志
    logger.info(f"登录请求参数: username={user_login.username}, password_length={len(user_login.password) if user_login.password else 0}")
    logger.debug(f"登录请求详细参数: {user_login.dict()}")
    user = db.query(User).filter(User.username == user_login.username).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户不存在",
        )
    
    # 添加调试信息
    print(f"Debug: 用户名: {user_login.username}")
    print(f"Debug: 输入密码: {user_login.password}")
    print(f"Debug: 数据库密码哈希: {user.password_hash}")
    print(f"Debug: 密码哈希长度: {len(user.password_hash)}")
    
    try:
        password_valid = verify_password(user_login.password, user.password_hash)
        print(f"Debug: 密码验证结果: {password_valid}")
        if not password_valid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="密码错误",
            )
    except Exception as e:
        print(f"Debug: 密码验证异常: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"密码验证失败: {str(e)}",
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        subject=user.username, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "is_admin": user.role == "admin",
            "created_at": user.created_at,
            "updated_at": user.updated_at
        }
    }