from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.models.system_config import SystemConfig, Region
from app.schemas.system_config import (
    SystemConfigCreate, SystemConfigUpdate, SystemConfig as SystemConfigSchema,
    RegionCreate, RegionUpdate, Region as RegionSchema
)
from app.api.deps import get_current_user

router = APIRouter()

# 系统配置相关接口
@router.get("/configs", response_model=List[SystemConfigSchema])
async def get_system_configs(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取系统配置列表"""
    configs = db.query(SystemConfig).offset(skip).limit(limit).all()
    return configs

@router.post("/configs", response_model=SystemConfigSchema)
async def create_system_config(
    config: SystemConfigCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """创建系统配置"""
    # 检查配置键是否已存在
    db_config = db.query(SystemConfig).filter(SystemConfig.config_key == config.config_key).first()
    if db_config:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="配置键已存在"
        )
    
    db_config = SystemConfig(**config.dict())
    db.add(db_config)
    db.commit()
    db.refresh(db_config)
    return db_config

@router.get("/configs/{config_id}", response_model=SystemConfigSchema)
async def get_system_config(
    config_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取单个系统配置"""
    config = db.query(SystemConfig).filter(SystemConfig.id == config_id).first()
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="配置不存在"
        )
    return config

@router.put("/configs/{config_id}", response_model=SystemConfigSchema)
async def update_system_config(
    config_id: int,
    config_update: SystemConfigUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """更新系统配置"""
    config = db.query(SystemConfig).filter(SystemConfig.id == config_id).first()
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="配置不存在"
        )
    
    update_data = config_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(config, field, value)
    
    db.commit()
    db.refresh(config)
    return config

@router.delete("/configs/{config_id}")
async def delete_system_config(
    config_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """删除系统配置"""
    config = db.query(SystemConfig).filter(SystemConfig.id == config_id).first()
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="配置不存在"
        )
    
    db.delete(config)
    db.commit()
    return {"message": "配置删除成功"}

# 区域管理相关接口
@router.get("/regions", response_model=List[RegionSchema])
async def get_regions(
    skip: int = 0,
    limit: int = 100,
    active_only: bool = True,
    db: Session = Depends(get_db)
):
    """获取区域列表"""
    query = db.query(Region)
    if active_only:
        query = query.filter(Region.is_active == True)
    regions = query.offset(skip).limit(limit).all()
    return regions

@router.post("/regions", response_model=RegionSchema)
async def create_region(
    region: RegionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """创建区域"""
    # 检查区域代码是否已存在
    db_region = db.query(Region).filter(Region.region_code == region.region_code).first()
    if db_region:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="区域代码已存在"
        )
    
    db_region = Region(**region.dict())
    db.add(db_region)
    db.commit()
    db.refresh(db_region)
    return db_region

@router.get("/regions/{region_id}", response_model=RegionSchema)
async def get_region(
    region_id: int,
    db: Session = Depends(get_db)
):
    """获取单个区域"""
    region = db.query(Region).filter(Region.id == region_id).first()
    if not region:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="区域不存在"
        )
    return region

@router.put("/regions/{region_id}", response_model=RegionSchema)
async def update_region(
    region_id: int,
    region_update: RegionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """更新区域"""
    region = db.query(Region).filter(Region.id == region_id).first()
    if not region:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="区域不存在"
        )
    
    update_data = region_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(region, field, value)
    
    db.commit()
    db.refresh(region)
    return region

@router.delete("/regions/{region_id}")
async def delete_region(
    region_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """删除区域"""
    region = db.query(Region).filter(Region.id == region_id).first()
    if not region:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="区域不存在"
        )
    
    db.delete(region)
    db.commit()
    return {"message": "区域删除成功"}