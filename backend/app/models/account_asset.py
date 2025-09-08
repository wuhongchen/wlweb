from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base

class AccountAsset(Base):
    __tablename__ = "account_assets"
    
    id = Column(Integer, primary_key=True, index=True)
    account = Column(String(100), nullable=False, index=True, comment="账号")
    password = Column(Text, nullable=False, comment="密码")
    region_code = Column(String(20), nullable=False, index=True, comment="所属区域编码，如S110、S130等")
    terminal_id = Column(Integer, ForeignKey("terminals.id"), nullable=True, index=True, comment="绑定的终端ID")
    description = Column(Text, nullable=True, comment="备注描述")
    # 新增游戏相关字段
    server_name = Column(String(100), nullable=True, comment="服务器名称")
    level = Column(Integer, nullable=True, comment="角色等级")
    character_name = Column(String(100), nullable=True, comment="角色名称")
    character_id = Column(String(100), nullable=True, comment="角色ID")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # 关联关系
    terminal = relationship("Terminal", back_populates="account_assets")