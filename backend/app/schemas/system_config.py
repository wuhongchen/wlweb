from typing import Optional
from pydantic import BaseModel
from datetime import datetime

# 系统配置相关模式
class SystemConfigBase(BaseModel):
    config_key: str
    config_value: str
    description: Optional[str] = None
    is_active: bool = True

class SystemConfigCreate(SystemConfigBase):
    pass

class SystemConfigUpdate(BaseModel):
    config_key: Optional[str] = None
    config_value: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None

class SystemConfigInDB(SystemConfigBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class SystemConfig(SystemConfigInDB):
    pass

# 区域相关模式
class RegionBase(BaseModel):
    region_code: str
    region_name: str
    description: Optional[str] = None
    is_active: bool = True

class RegionCreate(RegionBase):
    pass

class RegionUpdate(BaseModel):
    region_code: Optional[str] = None
    region_name: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None

class RegionInDB(RegionBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class Region(RegionInDB):
    pass