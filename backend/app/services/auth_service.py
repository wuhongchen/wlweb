from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.core.security import verify_password, create_access_token
from app.models.user import User
from app.models.session import UserSession
from app.core.config import settings
import secrets

class AuthService:
    @staticmethod
    def authenticate_user(db: Session, username: str, password: str) -> User:
        """验证用户凭据"""
        user = db.query(User).filter(User.username == username).first()
        if not user:
            return None
        if not verify_password(password, user.password_hash):
            return None
        return user
    
    @staticmethod
    def create_user_session(db: Session, user: User) -> dict:
        """创建用户会话"""
        # 生成访问令牌
        access_token = create_access_token(
            data={"sub": user.username},
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        
        # 生成会话令牌
        session_token = secrets.token_urlsafe(32)
        
        # 创建会话记录
        user_session = UserSession(
            user_id=user.id,
            session_token=session_token,
            expires_at=datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        
        db.add(user_session)
        db.commit()
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "session_token": session_token,
            "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        }
    
    @staticmethod
    def revoke_user_session(db: Session, session_token: str) -> bool:
        """撤销用户会话"""
        session = db.query(UserSession).filter(
            UserSession.session_token == session_token
        ).first()
        
        if session:
            db.delete(session)
            db.commit()
            return True
        return False
    
    @staticmethod
    def cleanup_expired_sessions(db: Session):
        """清理过期会话"""
        expired_sessions = db.query(UserSession).filter(
            UserSession.expires_at < datetime.utcnow()
        ).all()
        
        for session in expired_sessions:
            db.delete(session)
        
        db.commit()
        return len(expired_sessions)