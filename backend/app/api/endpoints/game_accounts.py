from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc
from app.core.database import get_db
from app.models.game_account import GameAccount, GameAssetRecord, GameInventoryRecord, GameLoginRecord
from app.models.user import User
from app.api.deps import get_current_user
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

router = APIRouter()

# 响应模型
class GameAccountResponse(BaseModel):
    id: int
    account_id: str
    level: Optional[int]
    last_terminal_id: Optional[str]
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class GameLoginRecordResponse(BaseModel):
    id: int
    account_id: str
    terminal_id: str
    region_code: Optional[str]
    login_time: datetime
    created_at: datetime
    
    class Config:
        from_attributes = True

class GameAssetRecordResponse(BaseModel):
    id: int
    account_id: str
    terminal_id: str
    gold: Optional[int]
    diamond: Optional[int]
    energy: Optional[int]
    experience: Optional[int]
    level: Optional[int]
    vip_level: Optional[int]
    report_time: datetime
    created_at: datetime
    
    class Config:
        from_attributes = True

class GameInventoryRecordResponse(BaseModel):
    id: int
    account_id: str
    terminal_id: str
    item_name: str
    item_type: Optional[str]
    quantity: int
    report_time: datetime
    created_at: datetime
    
    class Config:
        from_attributes = True

@router.get("/", response_model=List[GameAccountResponse])
async def get_game_accounts(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    获取游戏账户列表
    """
    accounts = db.query(GameAccount).order_by(desc(GameAccount.updated_at)).offset(skip).limit(limit).all()
    return accounts

@router.get("/{account_id}", response_model=GameAccountResponse)
async def get_game_account(
    account_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    获取指定游戏账户信息
    """
    account = db.query(GameAccount).filter(GameAccount.account_id == account_id).first()
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="游戏账户不存在"
        )
    return account

@router.get("/{account_id}/login-records", response_model=List[GameLoginRecordResponse])
async def get_login_records(
    account_id: str,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    获取指定账户的登录记录
    """
    # 验证账户存在
    account = db.query(GameAccount).filter(GameAccount.account_id == account_id).first()
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="游戏账户不存在"
        )
    
    records = db.query(GameLoginRecord).filter(
        GameLoginRecord.account_id == account_id
    ).order_by(desc(GameLoginRecord.login_time)).offset(skip).limit(limit).all()
    
    return records

@router.get("/{account_id}/asset-records", response_model=List[GameAssetRecordResponse])
async def get_asset_records(
    account_id: str,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    获取指定账户的资产记录
    """
    # 验证账户存在
    account = db.query(GameAccount).filter(GameAccount.account_id == account_id).first()
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="游戏账户不存在"
        )
    
    records = db.query(GameAssetRecord).filter(
        GameAssetRecord.account_id == account_id
    ).order_by(desc(GameAssetRecord.report_time)).offset(skip).limit(limit).all()
    
    return records

@router.get("/{account_id}/inventory-records", response_model=List[GameInventoryRecordResponse])
async def get_inventory_records(
    account_id: str,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    获取指定账户的背包记录
    """
    # 验证账户存在
    account = db.query(GameAccount).filter(GameAccount.account_id == account_id).first()
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="游戏账户不存在"
        )
    
    records = db.query(GameInventoryRecord).filter(
        GameInventoryRecord.account_id == account_id
    ).order_by(desc(GameInventoryRecord.report_time)).offset(skip).limit(limit).all()
    
    return records

@router.get("/{account_id}/latest-assets", response_model=GameAssetRecordResponse)
async def get_latest_assets(
    account_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    获取指定账户的最新资产记录
    """
    # 验证账户存在
    account = db.query(GameAccount).filter(GameAccount.account_id == account_id).first()
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="游戏账户不存在"
        )
    
    latest_record = db.query(GameAssetRecord).filter(
        GameAssetRecord.account_id == account_id
    ).order_by(desc(GameAssetRecord.report_time)).first()
    
    if not latest_record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="该账户暂无资产记录"
        )
    
    return latest_record

@router.get("/{account_id}/latest-inventory")
async def get_latest_inventory(
    account_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    获取指定账户的最新背包物品汇总
    """
    # 验证账户存在
    account = db.query(GameAccount).filter(GameAccount.account_id == account_id).first()
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="游戏账户不存在"
        )
    
    # 获取最新的上报时间
    latest_time = db.query(GameInventoryRecord.report_time).filter(
        GameInventoryRecord.account_id == account_id
    ).order_by(desc(GameInventoryRecord.report_time)).first()
    
    if not latest_time:
        return {
            "account_id": account_id,
            "items": [],
            "report_time": None
        }
    
    # 获取最新时间的所有物品记录
    latest_records = db.query(GameInventoryRecord).filter(
        GameInventoryRecord.account_id == account_id,
        GameInventoryRecord.report_time == latest_time[0]
    ).all()
    
    items = [{
        "item_name": record.item_name,
        "item_type": record.item_type,
        "quantity": record.quantity
    } for record in latest_records]
    
    return {
        "account_id": account_id,
        "items": items,
        "report_time": latest_time[0],
        "total_items": len(items)
    }