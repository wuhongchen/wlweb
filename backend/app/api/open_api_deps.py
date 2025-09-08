from typing import Optional
from fastapi import Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.account_asset import AccountAsset
from app.models.user import User
from app.core.security import verify_password
import base64


def verify_user_credentials(
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db)
) -> User:
    """
    验证开放API接口的用户认证（使用用户管理系统账户）
    
    使用Basic Auth格式: Authorization: Basic base64(username:password)
    账户和密码来自users表中的数据，实现数据隔离
    
    Args:
        authorization: HTTP Authorization头
        db: 数据库会话
        
    Returns:
        User: 验证成功的用户对象
        
    Raises:
        HTTPException: 认证失败时抛出401错误
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无效的认证凭据",
        headers={"WWW-Authenticate": "Basic"},
    )
    
    if not authorization:
        raise credentials_exception
    
    # 检查是否为Basic Auth格式
    if not authorization.startswith("Basic "):
        raise credentials_exception
    
    try:
        # 解码Base64编码的凭据
        encoded_credentials = authorization.split(" ")[1]
        decoded_credentials = base64.b64decode(encoded_credentials).decode("utf-8")
        
        # 分离用户名和密码
        if ":" not in decoded_credentials:
            raise credentials_exception
            
        username, password = decoded_credentials.split(":", 1)
        
        if not username or not password:
            raise credentials_exception
            
    except (IndexError, ValueError, UnicodeDecodeError):
        raise credentials_exception
    
    # 在数据库中验证用户名和密码
    user = db.query(User).filter(User.username == username).first()
    
    if not user or not verify_password(password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户名或密码错误"
        )
    
    return user


def verify_account_credentials(
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db)
) -> AccountAsset:
    """
    验证开放API接口的账户密码认证（兼容性保留）
    
    使用Basic Auth格式: Authorization: Basic base64(account:password)
    账户和密码来自account_assets表中的数据
    
    Args:
        authorization: HTTP Authorization头
        db: 数据库会话
        
    Returns:
        AccountAsset: 验证成功的账户资产对象
        
    Raises:
        HTTPException: 认证失败时抛出401错误
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无效的认证凭据",
        headers={"WWW-Authenticate": "Basic"},
    )
    
    if not authorization:
        raise credentials_exception
    
    # 检查是否为Basic Auth格式
    if not authorization.startswith("Basic "):
        raise credentials_exception
    
    try:
        # 解码Base64编码的凭据
        encoded_credentials = authorization.split(" ")[1]
        decoded_credentials = base64.b64decode(encoded_credentials).decode("utf-8")
        
        # 分离账户和密码
        if ":" not in decoded_credentials:
            raise credentials_exception
            
        account, password = decoded_credentials.split(":", 1)
        
        if not account or not password:
            raise credentials_exception
            
    except (IndexError, ValueError, UnicodeDecodeError):
        raise credentials_exception
    
    # 在数据库中验证账户和密码
    account_asset = db.query(AccountAsset).filter(
        AccountAsset.account == account,
        AccountAsset.password == password
    ).first()
    
    if not account_asset:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="账户或密码错误"
        )
    
    return account_asset


def get_account_by_region(
    region_code: str,
    account_asset: AccountAsset = Depends(verify_account_credentials)
) -> AccountAsset:
    """
    根据区域代码验证账户权限
    
    Args:
        region_code: 区域代码
        account_asset: 已验证的账户资产对象
        
    Returns:
        AccountAsset: 验证成功的账户资产对象
        
    Raises:
        HTTPException: 区域权限验证失败时抛出403错误
    """
    if account_asset.region_code != region_code:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"账户无权限访问区域 {region_code}"
        )
    
    return account_asset