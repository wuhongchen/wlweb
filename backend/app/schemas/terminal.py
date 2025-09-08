from typing import Optional, Dict, Any
from pydantic import BaseModel
from app.models.terminal import TerminalStatus
from datetime import datetime

class TerminalBase(BaseModel):
    terminal_id: str
    name: str
    description: Optional[str] = None
    ip_address: Optional[str] = None
    config: Optional[Dict[str, Any]] = None

class TerminalCreate(TerminalBase):
    pass

class TerminalUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    status: Optional[TerminalStatus] = None
    ip_address: Optional[str] = None
    config: Optional[Dict[str, Any]] = None

class TerminalInDB(TerminalBase):
    id: int
    status: TerminalStatus
    last_heartbeat: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class Terminal(TerminalInDB):
    pass

class TerminalHeartbeat(BaseModel):
    status: TerminalStatus = TerminalStatus.online
    ip_address: Optional[str] = None
    config: Optional[Dict[str, Any]] = None

class TerminalDataCreate(BaseModel):
    data_type: str
    data_content: Dict[str, Any]

class TerminalReportData(BaseModel):
    """终端自动上报数据模型"""
    terminal_id: str
    system_version: str  # Android系统版本号
    is_rooted: bool      # 是否获取root权限
    imei: str           # 设备IMEI号
    ip_address: str     # 当前IP地址
    device_model: Optional[str] = None    # 设备型号（可选）
    device_brand: Optional[str] = None    # 设备品牌（可选）
    android_id: Optional[str] = None      # Android ID（可选）

class AccountInfoResponse(BaseModel):
    """账户信息响应模型"""
    username: str
    password: str
    region_info: Dict[str, Any]
    account_status: str
    last_login_time: str
    created_at: str
    updated_at: str

class AccountResponse(BaseModel):
    """账户信息响应模型（不包含account_id）"""
    username: str
    level: int
    server_name: str
    last_login_time: str

class LoginReportData(BaseModel):
    """账户登录信息上报模型"""
    terminal_id: int
    username: str
    login_time: str
    login_ip: str
    login_device: str
    game_server: str
    region_code: Optional[str] = None
    character_id: Optional[str] = None

class AssetsReportData(BaseModel):
    """资产信息上报模型"""
    terminal_id: int
    gold: int
    diamond: int
    energy: int
    experience: int
    level: int
    vip_level: int
    report_time: str
    region_code: Optional[str] = None
    character_id: Optional[str] = None

class InventoryItem(BaseModel):
    """背包物品模型"""
    item_id: str
    item_name: str
    item_type: str
    quantity: int
    quality: str
    description: Optional[str] = None

class InventoryReportData(BaseModel):
    """背包材料上报模型"""
    terminal_id: int
    items: list[InventoryItem]
    report_time: str
    region_code: Optional[str] = None
    character_id: Optional[str] = None