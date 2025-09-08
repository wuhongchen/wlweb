from typing import Optional
from pydantic import BaseModel, Field
from datetime import datetime
from app.models.terminal import TerminalStatus

class AccountAssetBase(BaseModel):
    account: str = Field(..., min_length=1, max_length=100, description="账号")
    password: str = Field(..., min_length=1, description="密码")
    region_code: str = Field(..., min_length=1, max_length=20, description="所属区域编码，如S110、S130等")
    terminal_id: Optional[int] = Field(None, description="绑定的终端ID")
    description: Optional[str] = Field(None, description="备注描述")
    # 新增游戏相关字段
    server_name: Optional[str] = Field(None, max_length=100, description="服务器名称")
    level: Optional[int] = Field(None, description="角色等级")
    character_name: Optional[str] = Field(None, max_length=100, description="角色名称")
    character_id: Optional[str] = Field(None, max_length=100, description="角色ID")

class AccountAssetCreate(AccountAssetBase):
    pass

class AccountAssetUpdate(BaseModel):
    account: Optional[str] = Field(None, min_length=1, max_length=100, description="账号")
    password: Optional[str] = Field(None, min_length=1, description="密码")
    region_code: Optional[str] = Field(None, min_length=1, max_length=20, description="所属区域编码")
    terminal_id: Optional[int] = Field(None, description="绑定的终端ID")
    description: Optional[str] = Field(None, description="备注描述")
    # 新增游戏相关字段
    server_name: Optional[str] = Field(None, max_length=100, description="服务器名称")
    level: Optional[int] = Field(None, description="角色等级")
    character_name: Optional[str] = Field(None, max_length=100, description="角色名称")
    character_id: Optional[str] = Field(None, max_length=100, description="角色ID")

class AccountAssetInDB(AccountAssetBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class AccountAsset(AccountAssetInDB):
    pass

class TerminalInfo(BaseModel):
    """终端信息响应模型"""
    id: int
    terminal_id: int
    name: str
    status: TerminalStatus
    
    class Config:
        from_attributes = True

class AccountAssetWithTerminal(AccountAsset):
    terminal: Optional[TerminalInfo] = None