from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text, BigInteger, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base

class GameAccount(Base):
    """游戏账户信息表"""
    __tablename__ = "game_accounts"
    
    id = Column(Integer, primary_key=True, index=True)
    account_id = Column(String(100), unique=True, nullable=False, index=True, comment="账户ID，来自API上报")
    username = Column(String(100), nullable=True, comment="用户名")
    level = Column(Integer, nullable=True, comment="等级")
    server_name = Column(String(100), nullable=True, comment="服务器名称")
    last_terminal_id = Column(String(100), nullable=True, index=True, comment="最后管理的终端设备ID")
    last_login_time = Column(DateTime(timezone=True), nullable=True, comment="最后登录时间")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # 关联关系
    asset_records = relationship("GameAssetRecord", back_populates="account")
    inventory_records = relationship("GameInventoryRecord", back_populates="account")

class GameAssetRecord(Base):
    """游戏资产记录表"""
    __tablename__ = "game_asset_records"
    
    id = Column(Integer, primary_key=True, index=True)
    account_id = Column(String(100), ForeignKey("game_accounts.account_id"), nullable=True, index=True, comment="账户ID")
    terminal_id = Column(String(100), nullable=False, index=True, comment="终端设备ID")
    region_code = Column(String(20), nullable=True, comment="游戏区域代码")
    character_id = Column(String(100), nullable=True, comment="角色ID")
    gold = Column(BigInteger, nullable=True, comment="金子数量")
    diamond = Column(BigInteger, nullable=True, comment="元宝/钻石数量")
    energy = Column(Integer, nullable=True, comment="体力值")
    experience = Column(BigInteger, nullable=True, comment="经验值")
    level = Column(Integer, nullable=True, comment="等级")
    vip_level = Column(Integer, nullable=True, comment="VIP等级")
    report_time = Column(DateTime(timezone=True), nullable=True, comment="上报时间")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 关联关系
    account = relationship("GameAccount", back_populates="asset_records")

class GameInventoryRecord(Base):
    """游戏背包物品记录表"""
    __tablename__ = "game_inventory_records"
    
    id = Column(Integer, primary_key=True, index=True)
    account_id = Column(String(100), ForeignKey("game_accounts.account_id"), nullable=True, index=True, comment="账户ID")
    terminal_id = Column(String(100), nullable=False, index=True, comment="终端设备ID")
    region_code = Column(String(20), nullable=True, comment="游戏区域代码")
    character_id = Column(String(100), nullable=True, comment="角色ID")
    item_id = Column(String(100), nullable=False, comment="物品ID")
    item_name = Column(String(200), nullable=False, comment="物品名称")
    item_type = Column(String(50), nullable=False, comment="物品类型")
    quantity = Column(Integer, nullable=False, comment="数量")
    quality = Column(String(50), nullable=True, comment="品质")
    description = Column(Text, nullable=True, comment="描述")
    report_time = Column(DateTime(timezone=True), nullable=True, comment="上报时间")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 关联关系
    account = relationship("GameAccount", back_populates="inventory_records")

class GameLoginRecord(Base):
    """游戏登录记录表"""
    __tablename__ = "game_login_records"
    
    id = Column(Integer, primary_key=True, index=True)
    account_id = Column(String(100), ForeignKey("game_accounts.account_id"), nullable=True, index=True, comment="账户ID")
    terminal_id = Column(String(100), nullable=False, index=True, comment="终端设备ID")
    region_code = Column(String(20), nullable=True, comment="游戏区域代码")
    character_id = Column(String(100), nullable=True, comment="角色ID")
    username = Column(String(100), nullable=True, comment="用户名")
    login_time = Column(DateTime(timezone=True), nullable=True, comment="登录时间")
    login_ip = Column(String(45), nullable=True, comment="登录IP")
    login_device = Column(String(200), nullable=True, comment="登录设备")
    game_server = Column(String(100), nullable=True, comment="游戏服务器")
    login_status = Column(String(20), nullable=True, comment="登录状态")
    server_info = Column(JSON, nullable=True, comment="服务器信息")
    created_at = Column(DateTime(timezone=True), server_default=func.now())