from sqlalchemy import Column, Integer, String, DateTime, Enum, JSON, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum

class TerminalStatus(str, enum.Enum):
    online = "online"
    offline = "offline"
    error = "error"

class Terminal(Base):
    __tablename__ = "terminals"
    
    id = Column(Integer, primary_key=True, index=True)
    terminal_id = Column(String(100), unique=True, index=True, nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    status = Column(Enum(TerminalStatus), default=TerminalStatus.offline)
    ip_address = Column(String(45))
    config = Column(JSON)
    last_heartbeat = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # 关联关系
    account_assets = relationship("AccountAsset", back_populates="terminal")

class TerminalData(Base):
    __tablename__ = "terminal_data"
    
    id = Column(Integer, primary_key=True, index=True)
    terminal_id = Column(Integer, nullable=False, index=True)
    data_type = Column(String(50), nullable=False, index=True)
    data_content = Column(JSON, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)