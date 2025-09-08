from datetime import datetime, timedelta
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.models.terminal import Terminal, TerminalData
from app.schemas.terminal import TerminalCreate, TerminalUpdate

class TerminalService:
    @staticmethod
    def get_online_terminals(db: Session, heartbeat_timeout: int = 5) -> List[Terminal]:
        """获取在线终端列表"""
        cutoff_time = datetime.utcnow() - timedelta(minutes=heartbeat_timeout)
        return db.query(Terminal).filter(
            and_(
                Terminal.status == "online",
                Terminal.last_heartbeat >= cutoff_time
            )
        ).all()
    
    @staticmethod
    def get_offline_terminals(db: Session, heartbeat_timeout: int = 5) -> List[Terminal]:
        """获取离线终端列表"""
        cutoff_time = datetime.utcnow() - timedelta(minutes=heartbeat_timeout)
        return db.query(Terminal).filter(
            Terminal.last_heartbeat < cutoff_time
        ).all()
    
    @staticmethod
    def update_terminal_status(db: Session, terminal_id: str, status: str) -> Optional[Terminal]:
        """更新终端状态"""
        terminal = db.query(Terminal).filter(Terminal.terminal_id == terminal_id).first()
        if terminal:
            terminal.status = status
            terminal.last_heartbeat = datetime.utcnow()
            db.commit()
            db.refresh(terminal)
        return terminal
    
    @staticmethod
    def register_or_update_terminal(db: Session, terminal_data: TerminalCreate) -> Terminal:
        """注册或更新终端"""
        existing_terminal = db.query(Terminal).filter(
            Terminal.terminal_id == terminal_data.terminal_id
        ).first()
        
        if existing_terminal:
            # 更新现有终端
            for field, value in terminal_data.dict().items():
                setattr(existing_terminal, field, value)
            existing_terminal.last_heartbeat = datetime.utcnow()
            db.commit()
            db.refresh(existing_terminal)
            return existing_terminal
        else:
            # 创建新终端
            new_terminal = Terminal(**terminal_data.dict())
            new_terminal.last_heartbeat = datetime.utcnow()
            db.add(new_terminal)
            db.commit()
            db.refresh(new_terminal)
            return new_terminal
    
    @staticmethod
    def get_terminal_data(db: Session, terminal_id: int, data_type: Optional[str] = None, 
                         limit: int = 100) -> List[TerminalData]:
        """获取终端数据"""
        query = db.query(TerminalData).filter(TerminalData.terminal_id == terminal_id)
        
        if data_type:
            query = query.filter(TerminalData.data_type == data_type)
        
        return query.order_by(TerminalData.created_at.desc()).limit(limit).all()
    
    @staticmethod
    def cleanup_old_data(db: Session, days: int = 30) -> int:
        """清理旧数据"""
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        old_data = db.query(TerminalData).filter(
            TerminalData.created_at < cutoff_date
        ).all()
        
        count = len(old_data)
        for data in old_data:
            db.delete(data)
        
        db.commit()
        return count
    
    @staticmethod
    def get_terminal_statistics(db: Session) -> dict:
        """获取终端统计信息"""
        total_terminals = db.query(Terminal).count()
        online_terminals = len(TerminalService.get_online_terminals(db))
        offline_terminals = total_terminals - online_terminals
        
        return {
            "total": total_terminals,
            "online": online_terminals,
            "offline": offline_terminals,
            "online_rate": (online_terminals / total_terminals * 100) if total_terminals > 0 else 0
        }