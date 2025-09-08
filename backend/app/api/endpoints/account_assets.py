from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, joinedload
from app.core.database import get_db
from app.models.account_asset import AccountAsset
from app.models.terminal import Terminal
from app.models.user import User
from app.schemas.account_asset import (
    AccountAssetCreate, AccountAssetUpdate, AccountAsset as AccountAssetSchema,
    AccountAssetWithTerminal
)
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/", response_model=List[AccountAssetWithTerminal])
async def get_account_assets(
    skip: int = 0,
    limit: int = 100,
    region_code: Optional[str] = Query(None, description="按区域编码筛选"),
    terminal_id: Optional[int] = Query(None, description="按终端ID筛选"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取账号资产列表"""
    query = db.query(AccountAsset).options(joinedload(AccountAsset.terminal))
    
    if region_code:
        query = query.filter(AccountAsset.region_code == region_code)
    if terminal_id:
        query = query.filter(AccountAsset.terminal_id == terminal_id)
    
    account_assets = query.offset(skip).limit(limit).all()
    
    # 转换为包含终端信息的响应格式
    result = []
    for asset in account_assets:
        asset_dict = {
            "id": asset.id,
            "account": asset.account,
            "password": asset.password,
            "region_code": asset.region_code,
            "terminal_id": asset.terminal_id,
            "description": asset.description,
            "server_name": asset.server_name,
            "level": asset.level,
            "character_name": asset.character_name,
            "character_id": asset.character_id,
            "created_at": asset.created_at,
            "updated_at": asset.updated_at,
            "terminal": {
                "id": asset.terminal.id,
                "terminal_id": asset.terminal.id,
                "name": asset.terminal.name,
                "status": asset.terminal.status
            } if asset.terminal else None
        }
        result.append(asset_dict)
    
    return result

@router.post("/", response_model=AccountAssetSchema)
async def create_account_asset(
    account_asset: AccountAssetCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """创建账号资产"""
    # 检查终端是否存在（如果指定了终端ID）
    if account_asset.terminal_id:
        terminal = db.query(Terminal).filter(Terminal.id == account_asset.terminal_id).first()
        if not terminal:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="指定的终端不存在"
            )
    
    # 检查账号是否已存在
    existing_asset = db.query(AccountAsset).filter(
        AccountAsset.account == account_asset.account,
        AccountAsset.region_code == account_asset.region_code
    ).first()
    if existing_asset:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="该区域下的账号已存在"
        )
    
    db_account_asset = AccountAsset(**account_asset.dict())
    db.add(db_account_asset)
    db.commit()
    db.refresh(db_account_asset)
    return db_account_asset

@router.get("/{asset_id}", response_model=AccountAssetWithTerminal)
async def get_account_asset(
    asset_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取单个账号资产"""
    account_asset = db.query(AccountAsset).options(joinedload(AccountAsset.terminal)).filter(AccountAsset.id == asset_id).first()
    if not account_asset:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="账号资产不存在"
        )
    
    # 转换为包含终端信息的响应格式
    result = {
        "id": account_asset.id,
        "account": account_asset.account,
        "password": account_asset.password,
        "region_code": account_asset.region_code,
        "terminal_id": account_asset.terminal_id,
        "description": account_asset.description,
        "server_name": account_asset.server_name,
        "level": account_asset.level,
        "character_name": account_asset.character_name,
        "character_id": account_asset.character_id,
        "created_at": account_asset.created_at,
        "updated_at": account_asset.updated_at,
        "terminal": {
            "id": account_asset.terminal.id,
            "terminal_id": account_asset.terminal.id,
            "name": account_asset.terminal.name,
            "status": account_asset.terminal.status
        } if account_asset.terminal else None
    }
    
    return result

@router.put("/{asset_id}", response_model=AccountAssetSchema)
async def update_account_asset(
    asset_id: int,
    account_asset_update: AccountAssetUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """更新账号资产"""
    db_account_asset = db.query(AccountAsset).filter(AccountAsset.id == asset_id).first()
    if not db_account_asset:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="账号资产不存在"
        )
    
    # 检查终端是否存在（如果更新了终端ID）
    if account_asset_update.terminal_id is not None:
        if account_asset_update.terminal_id > 0:  # 0表示解除绑定
            terminal = db.query(Terminal).filter(Terminal.id == account_asset_update.terminal_id).first()
            if not terminal:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="指定的终端不存在"
                )
    
    # 检查账号唯一性（如果更新了账号或区域）
    if account_asset_update.account or account_asset_update.region_code:
        new_account = account_asset_update.account or db_account_asset.account
        new_region = account_asset_update.region_code or db_account_asset.region_code
        
        existing_asset = db.query(AccountAsset).filter(
            AccountAsset.account == new_account,
            AccountAsset.region_code == new_region,
            AccountAsset.id != asset_id
        ).first()
        if existing_asset:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="该区域下的账号已存在"
            )
    
    # 更新字段
    update_data = account_asset_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_account_asset, field, value)
    
    db.commit()
    db.refresh(db_account_asset)
    return db_account_asset

@router.delete("/{asset_id}")
async def delete_account_asset(
    asset_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """删除账号资产"""
    db_account_asset = db.query(AccountAsset).filter(AccountAsset.id == asset_id).first()
    if not db_account_asset:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="账号资产不存在"
        )
    
    db.delete(db_account_asset)
    db.commit()
    return {"message": "账号资产删除成功"}

@router.get("/regions/list")
async def get_regions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取所有区域编码列表"""
    regions = db.query(AccountAsset.region_code).distinct().all()
    return [region[0] for region in regions]