from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from sqlalchemy import or_, func
from app.core.database import get_db
from app.models.terminal import Terminal, TerminalData
from app.models.user import User
from app.models.game_account import GameAccount, GameAssetRecord, GameInventoryRecord, GameLoginRecord
from app.models.account_asset import AccountAsset
from app.schemas.terminal import (
    TerminalCreate, TerminalUpdate, Terminal as TerminalSchema,
    TerminalHeartbeat, TerminalDataCreate, TerminalReportData,
    AccountInfoResponse, AccountResponse, LoginReportData, AssetsReportData, InventoryReportData
)
from app.api.deps import get_current_user
from app.api.open_api_deps import verify_user_credentials

router = APIRouter()

@router.get("/", response_model=List[TerminalSchema])
async def get_terminals(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    terminals = db.query(Terminal).offset(skip).limit(limit).all()
    
    # 基于数据上报时间判断在线状态（5分钟内有数据上报视为在线）
    five_minutes_ago = datetime.utcnow() - timedelta(minutes=5)
    
    for terminal in terminals:
        # 检查最近5分钟内是否有登录记录或资产记录上报
        recent_login = db.query(GameLoginRecord).filter(
            GameLoginRecord.terminal_id == terminal.terminal_id,
            GameLoginRecord.created_at >= five_minutes_ago
        ).first()
        
        recent_asset = db.query(GameAssetRecord).filter(
            GameAssetRecord.terminal_id == terminal.terminal_id,
            GameAssetRecord.created_at >= five_minutes_ago
        ).first()
        
        recent_inventory = db.query(GameInventoryRecord).filter(
            GameInventoryRecord.terminal_id == terminal.terminal_id,
            GameInventoryRecord.created_at >= five_minutes_ago
        ).first()
        
        # 如果有任何一种数据在5分钟内上报过，则认为在线
        if recent_login or recent_asset or recent_inventory:
            terminal.status = "online"
            # 更新最后心跳时间为最近的数据上报时间
            latest_time = None
            if recent_login:
                latest_time = recent_login.created_at
            if recent_asset and (not latest_time or recent_asset.created_at > latest_time):
                latest_time = recent_asset.created_at
            if recent_inventory and (not latest_time or recent_inventory.created_at > latest_time):
                latest_time = recent_inventory.created_at
            
            # 持久化更新到数据库
            if latest_time and terminal.last_heartbeat != latest_time:
                terminal.last_heartbeat = latest_time
                db.add(terminal)
        else:
            terminal.status = "offline"
    
    # 提交所有更改
    db.commit()
    
    return terminals

@router.post("/", response_model=TerminalSchema)
async def create_terminal(
    terminal: TerminalCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # 检查终端ID是否已存在
    db_terminal = db.query(Terminal).filter(Terminal.terminal_id == terminal.terminal_id).first()
    if db_terminal:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="终端ID已存在"
        )
    
    db_terminal = Terminal(**terminal.dict())
    db.add(db_terminal)
    db.commit()
    db.refresh(db_terminal)
    return db_terminal

@router.get("/{terminal_id}", response_model=TerminalSchema)
async def get_terminal(
    terminal_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    terminal = db.query(Terminal).filter(Terminal.id == terminal_id).first()
    if not terminal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="终端不存在"
        )
    return terminal

@router.put("/{terminal_id}", response_model=TerminalSchema)
async def update_terminal(
    terminal_id: int,
    terminal_update: TerminalUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    terminal = db.query(Terminal).filter(Terminal.id == terminal_id).first()
    if not terminal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="终端不存在"
        )
    
    update_data = terminal_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(terminal, field, value)
    
    db.commit()
    db.refresh(terminal)
    return terminal

@router.delete("/{terminal_id}")
async def delete_terminal(
    terminal_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    terminal = db.query(Terminal).filter(Terminal.id == terminal_id).first()
    if not terminal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="终端不存在"
        )
    
    db.delete(terminal)
    db.commit()
    return {"message": "终端删除成功"}

# 开放API端点
@router.post("/register")
async def register_terminal(
    terminal: TerminalCreate,
    db: Session = Depends(get_db)
):
    # 检查终端是否已存在
    db_terminal = db.query(Terminal).filter(Terminal.terminal_id == terminal.terminal_id).first()
    if db_terminal:
        # 更新现有终端信息
        db_terminal.name = terminal.name
        db_terminal.ip_address = terminal.ip_address
        db_terminal.config = terminal.config
        db_terminal.last_heartbeat = datetime.utcnow()
        db.commit()
        db.refresh(db_terminal)
        return {"message": "终端信息更新成功", "terminal_id": db_terminal.id}
    else:
        # 创建新终端
        db_terminal = Terminal(**terminal.dict())
        db_terminal.last_heartbeat = datetime.utcnow()
        db.add(db_terminal)
        db.commit()
        db.refresh(db_terminal)
        return {"message": "终端注册成功", "terminal_id": db_terminal.id}

@router.post("/{terminal_id}/heartbeat")
async def terminal_heartbeat(
    terminal_id: str,
    heartbeat: TerminalHeartbeat,
    db: Session = Depends(get_db)
):
    terminal = db.query(Terminal).filter(Terminal.terminal_id == terminal_id).first()
    if not terminal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="终端不存在"
        )
    
    terminal.status = heartbeat.status
    terminal.last_heartbeat = datetime.utcnow()
    if heartbeat.ip_address:
        terminal.ip_address = heartbeat.ip_address
    if heartbeat.config:
        terminal.config = heartbeat.config
    
    db.commit()
    return {"message": "心跳更新成功"}

@router.post("/{terminal_id}/data")
async def upload_terminal_data(
    terminal_id: str,
    data: TerminalDataCreate,
    db: Session = Depends(get_db)
):
    terminal = db.query(Terminal).filter(Terminal.terminal_id == terminal_id).first()
    if not terminal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="终端不存在"
        )
    
    terminal_data = TerminalData(
        terminal_id=terminal.id,
        data_type=data.data_type,
        data_content=data.data_content
    )
    db.add(terminal_data)
    db.commit()
    
    return {"message": "数据上传成功"}

@router.post("/report", status_code=status.HTTP_201_CREATED)
async def terminal_auto_report(
    report_data: TerminalReportData,
    db: Session = Depends(get_db)
):
    """
    终端自动上报接口
    用于终端首次运行时自动提交设备信息
    """
    # 数据校验
    if not report_data.terminal_id or len(report_data.terminal_id.strip()) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="终端ID不能为空"
        )
    
    if not report_data.imei or len(report_data.imei.strip()) < 15:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="IMEI号格式不正确，长度至少15位"
        )
    
    if not report_data.system_version or len(report_data.system_version.strip()) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="系统版本号不能为空"
        )
    
    # 检查终端是否已存在
    existing_terminal = db.query(Terminal).filter(
        Terminal.terminal_id == report_data.terminal_id
    ).first()
    
    if existing_terminal:
        # 更新现有终端信息
        existing_terminal.ip_address = report_data.ip_address
        existing_terminal.last_heartbeat = datetime.utcnow()
        existing_terminal.status = "online"
        
        # 更新配置信息
        config_data = {
            "system_version": report_data.system_version,
            "is_rooted": report_data.is_rooted,
            "imei": report_data.imei,
            "device_model": report_data.device_model,
            "device_brand": report_data.device_brand,
            "android_id": report_data.android_id,
            "last_report_time": datetime.utcnow().isoformat()
        }
        existing_terminal.config = config_data
        
        db.commit()
        
        # 记录上报数据
        terminal_data = TerminalData(
            terminal_id=existing_terminal.id,
            data_type="auto_report",
            data_content={
                "system_version": report_data.system_version,
                "is_rooted": report_data.is_rooted,
                "imei": report_data.imei,
                "ip_address": report_data.ip_address,
                "device_model": report_data.device_model,
                "device_brand": report_data.device_brand,
                "android_id": report_data.android_id,
                "report_type": "update"
            }
        )
        db.add(terminal_data)
        db.commit()
        
        return {
            "message": "终端信息更新成功",
            "terminal_id": report_data.terminal_id,
            "status": "updated"
        }
    else:
        # 创建新终端
        config_data = {
            "system_version": report_data.system_version,
            "is_rooted": report_data.is_rooted,
            "imei": report_data.imei,
            "device_model": report_data.device_model,
            "device_brand": report_data.device_brand,
            "android_id": report_data.android_id,
            "first_report_time": datetime.utcnow().isoformat()
        }
        
        new_terminal = Terminal(
            terminal_id=report_data.terminal_id,
            name=f"Terminal-{report_data.terminal_id[:8]}",
            description=f"自动注册终端 - {report_data.device_brand or 'Unknown'} {report_data.device_model or 'Device'}",
            status="online",
            ip_address=report_data.ip_address,
            config=config_data,
            last_heartbeat=datetime.utcnow()
        )
        
        db.add(new_terminal)
        db.commit()
        db.refresh(new_terminal)
        
        # 记录首次上报数据
        terminal_data = TerminalData(
            terminal_id=new_terminal.id,
            data_type="auto_report",
            data_content={
                "system_version": report_data.system_version,
                "is_rooted": report_data.is_rooted,
                "imei": report_data.imei,
                "ip_address": report_data.ip_address,
                "device_model": report_data.device_model,
                "device_brand": report_data.device_brand,
                "android_id": report_data.android_id,
                "report_type": "first_time"
            }
        )
        db.add(terminal_data)
        db.commit()
        
        return {
            "message": "终端注册成功",
            "terminal_id": report_data.terminal_id,
            "status": "created"
        }

@router.get("/{terminal_id}/account-info", response_model=AccountInfoResponse)
async def get_account_info(
    terminal_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_user_credentials)
):
    """
    获取登录账号信息接口
    动态返回账户信息：
    1. 如果终端已绑定账户，返回绑定的账户信息
    2. 如果终端未绑定账户，返回一个未绑定的账户
    """
    from app.models.account_asset import AccountAsset
    
    terminal = db.query(Terminal).filter(Terminal.terminal_id == terminal_id).first()
    if not terminal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="终端不存在"
        )
    
    # 检查该终端是否已绑定账户
    bound_account = db.query(AccountAsset).filter(AccountAsset.terminal_id == terminal.id).first()
    
    if bound_account:
        # 返回已绑定的账户信息
        return AccountInfoResponse(
            username=bound_account.character_name or bound_account.account,
            password="abc123456",
            region_info={
                "region_id": "server_01",
                "region_name": bound_account.server_name or "华东一区",
                "server_ip": "192.168.1.100",
                "server_port": 8080
            },
            account_status="active",
            last_login_time=datetime.utcnow().isoformat(),
            created_at=datetime.utcnow().isoformat(),
            updated_at=datetime.utcnow().isoformat()
        )
    else:
        # 查找一个未绑定的账户
        unbound_account = db.query(AccountAsset).filter(AccountAsset.terminal_id.is_(None)).first()
        
        if unbound_account:
            # 返回未绑定账户的信息（但不立即绑定）
            return AccountInfoResponse(
                username=unbound_account.character_name or unbound_account.account,
                password="abc123456",
                region_info={
                    "region_id": "server_01",
                    "region_name": unbound_account.server_name or "华东一区",
                    "server_ip": "192.168.1.100",
                    "server_port": 8080
                },
                account_status="active",
                last_login_time=datetime.utcnow().isoformat(),
                created_at=datetime.utcnow().isoformat(),
                updated_at=datetime.utcnow().isoformat()
            )
        else:
            # 没有可用的未绑定账户，返回默认信息
            return AccountInfoResponse(
                username=f"Player_{terminal_id[:6]}",
                password="abc123456",
                region_info={
                    "region_id": "server_01",
                    "region_name": "华东一区",
                    "server_ip": "192.168.1.100",
                    "server_port": 8080
                },
                account_status="active",
                last_login_time=datetime.utcnow().isoformat(),
                created_at=datetime.utcnow().isoformat(),
                updated_at=datetime.utcnow().isoformat()
            )

@router.get("/{terminal_id}/account", response_model=AccountResponse)
async def get_account(
    terminal_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_user_credentials)
):
    """
    获取登录账号信息接口（不包含account_id）
    动态返回账户信息：
    1. 如果终端已绑定账户，返回绑定的账户信息
    2. 如果终端未绑定账户，返回一个未绑定的账户
    """
    from app.models.account_asset import AccountAsset
    
    terminal = db.query(Terminal).filter(Terminal.terminal_id == terminal_id).first()
    if not terminal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="终端不存在"
        )
    
    # 检查该终端是否已绑定账户
    bound_account = db.query(AccountAsset).filter(AccountAsset.terminal_id == terminal.id).first()
    
    if bound_account:
        # 返回已绑定的账户信息
        return AccountResponse(
            username=bound_account.character_name or bound_account.account,
            level=bound_account.level or 1,
            server_name=bound_account.server_name or "默认服务器",
            last_login_time=datetime.utcnow().isoformat()
        )
    else:
        # 查找一个未绑定的账户
        unbound_account = db.query(AccountAsset).filter(AccountAsset.terminal_id.is_(None)).first()
        
        if unbound_account:
            # 返回未绑定账户的信息（但不立即绑定）
            return AccountResponse(
                username=unbound_account.character_name or unbound_account.account,
                level=unbound_account.level or 1,
                server_name=unbound_account.server_name or "默认服务器",
                last_login_time=datetime.utcnow().isoformat()
            )
        else:
            # 没有可用的未绑定账户，返回默认信息
            return AccountResponse(
                username=f"Player_{terminal_id[:6]}",
                level=1,
                server_name="默认服务器",
                last_login_time=datetime.utcnow().isoformat()
            )

@router.post("/{terminal_id}/login-report", status_code=status.HTTP_201_CREATED)
async def report_login(
    terminal_id: str,
    login_data: LoginReportData,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_user_credentials)
):
    """
    账户登录信息上报接口
    """
    terminal = db.query(Terminal).filter(Terminal.terminal_id == terminal_id).first()
    if not terminal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="终端不存在"
        )
    
    # 数据校验
    if not login_data.username or len(login_data.username.strip()) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户名不能为空"
        )
    
    # 转换登录时间
    login_time = None
    if hasattr(login_data, 'login_time') and login_data.login_time:
        try:
            if isinstance(login_data.login_time, str):
                login_time = datetime.fromisoformat(login_data.login_time.replace('Z', '+00:00'))
            else:
                login_time = login_data.login_time
        except ValueError:
            login_time = datetime.utcnow()
    else:
        login_time = datetime.utcnow()
    
    # 创建或更新游戏账户
    game_account = None
    if login_data.character_id:
        game_account = db.query(GameAccount).filter(
            GameAccount.account_id == login_data.character_id
        ).first()
        
        if not game_account:
            # 创建新的游戏账户
            game_account = GameAccount(
                account_id=login_data.character_id,
                username=login_data.username,
                server_name=login_data.game_server,
                last_terminal_id=terminal_id,
                last_login_time=login_time
            )
            db.add(game_account)
        else:
            # 更新现有账户信息
            game_account.username = login_data.username or game_account.username
            game_account.server_name = login_data.game_server or game_account.server_name
            game_account.last_terminal_id = terminal_id
            game_account.last_login_time = login_time
    
    # 记录登录记录
    login_record = GameLoginRecord(
        account_id=login_data.character_id,
        terminal_id=terminal_id,
        region_code=login_data.region_code,
        character_id=login_data.character_id,
        username=login_data.username,
        login_time=login_time,
        login_ip=login_data.login_ip,
        login_device=login_data.login_device,
        game_server=login_data.game_server,
        login_status='success'
    )
    db.add(login_record)
    
    # 记录原有的终端数据
    terminal_data = TerminalData(
        terminal_id=terminal.id,
        data_type="login_report",
        data_content={
            "username": login_data.username,
            "login_time": login_time.isoformat() if login_time else None,
            "login_ip": login_data.login_ip,
            "login_device": login_data.login_device,
            "game_server": login_data.game_server,
            "region_code": login_data.region_code,
            "character_id": login_data.character_id
        }
    )
    db.add(terminal_data)
    db.commit()
    
    return {
        "message": "登录信息上报成功",
        "terminal_id": terminal_id
    }

@router.post("/{terminal_id}/assets-report", status_code=status.HTTP_201_CREATED)
async def report_assets(
    terminal_id: str,
    assets_data: AssetsReportData,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_user_credentials)
):
    """
    资产信息上报接口
    """
    terminal = db.query(Terminal).filter(Terminal.terminal_id == terminal_id).first()
    if not terminal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="终端不存在"
        )
    
    # 数据校验
    if assets_data.gold < 0 or assets_data.diamond < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="资产数量不能为负数"
        )
    
    # 转换报告时间
    report_time = None
    if hasattr(assets_data, 'report_time') and assets_data.report_time:
        try:
            if isinstance(assets_data.report_time, str):
                report_time = datetime.fromisoformat(assets_data.report_time.replace('Z', '+00:00'))
            else:
                report_time = assets_data.report_time
        except ValueError:
            report_time = datetime.utcnow()
    else:
        report_time = datetime.utcnow()
    

    
    # 创建或更新游戏账户
    game_account = None
    if assets_data.character_id:
        game_account = db.query(GameAccount).filter(
            GameAccount.account_id == assets_data.character_id
        ).first()
        
        if not game_account:
            # 创建新的游戏账户
            game_account = GameAccount(
                account_id=assets_data.character_id,
                level=assets_data.level,
                last_terminal_id=terminal_id
            )
            db.add(game_account)
        else:
            # 更新现有账户信息
            if assets_data.level:
                game_account.level = assets_data.level
            game_account.last_terminal_id = terminal_id
    
    # 记录资产记录
    asset_record = GameAssetRecord(
        account_id=assets_data.character_id,
        terminal_id=terminal_id,
        region_code=assets_data.region_code,
        character_id=assets_data.character_id,
        gold=assets_data.gold,
        diamond=assets_data.diamond,
        energy=assets_data.energy,
        experience=assets_data.experience,
        level=assets_data.level,
        vip_level=assets_data.vip_level,
        report_time=report_time
    )
    db.add(asset_record)
    
    # 记录原有的终端数据
    terminal_data = TerminalData(
        terminal_id=terminal.id,
        data_type="assets_report",
        data_content={
            "gold": assets_data.gold,
            "diamond": assets_data.diamond,
            "energy": assets_data.energy,
            "experience": assets_data.experience,
            "level": assets_data.level,
            "vip_level": assets_data.vip_level,
            "report_time": report_time.isoformat() if report_time else None,
            "region_code": assets_data.region_code,
            "character_id": assets_data.character_id
        }
    )
    db.add(terminal_data)
    db.commit()
    
    return {
        "message": "资产信息上报成功"
    }

@router.post("/{terminal_id}/inventory-report", status_code=status.HTTP_201_CREATED)
async def report_inventory(
    terminal_id: str,
    inventory_data: InventoryReportData,
    db: Session = Depends(get_db),
    current_user: User = Depends(verify_user_credentials)
):
    """
    背包材料上报接口
    """
    terminal = db.query(Terminal).filter(Terminal.terminal_id == terminal_id).first()
    if not terminal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="终端不存在"
        )
    
    # 数据校验
    if not inventory_data.items or len(inventory_data.items) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="背包物品列表不能为空"
        )
    
    # 验证物品数据
    for item in inventory_data.items:
        if item.quantity < 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"物品 {item.item_name} 数量不能为负数"
            )
    

    
    # 转换报告时间
    report_time = None
    if hasattr(inventory_data, 'report_time') and inventory_data.report_time:
        try:
            if isinstance(inventory_data.report_time, str):
                report_time = datetime.fromisoformat(inventory_data.report_time.replace('Z', '+00:00'))
            else:
                report_time = inventory_data.report_time
        except ValueError:
            report_time = datetime.utcnow()
    else:
        report_time = datetime.utcnow()
    
    # 创建或更新游戏账户
    game_account = None
    if inventory_data.character_id:
        game_account = db.query(GameAccount).filter(
            GameAccount.account_id == inventory_data.character_id
        ).first()
        
        if not game_account:
            # 创建新的游戏账户
            game_account = GameAccount(
                account_id=inventory_data.character_id,
                last_terminal_id=terminal_id
            )
            db.add(game_account)
        else:
            # 更新现有账户信息
            game_account.last_terminal_id = terminal_id
    
    # 记录背包物品记录
    for item in inventory_data.items:
        inventory_record = GameInventoryRecord(
            account_id=inventory_data.character_id,
            terminal_id=terminal_id,
            region_code=inventory_data.region_code,
            character_id=inventory_data.character_id,
            item_id=item.item_id,
            item_name=item.item_name,
            item_type=item.item_type,
            quantity=item.quantity,
            quality=item.quality,
            description=item.description,
            report_time=report_time
        )
        db.add(inventory_record)
    
    # 记录原有的终端数据
    terminal_data = TerminalData(
        terminal_id=terminal.id,
        data_type="inventory_report",
        data_content={
            "items": [item.dict() for item in inventory_data.items],
            "report_time": inventory_data.report_time.isoformat() if isinstance(inventory_data.report_time, datetime) else inventory_data.report_time,
            "total_items": len(inventory_data.items),
            "region_code": inventory_data.region_code if hasattr(inventory_data, 'region_code') else None,
            "character_id": inventory_data.character_id if hasattr(inventory_data, 'character_id') else None
        }
    )
    db.add(terminal_data)
    db.commit()
    
    return {
        "message": "背包信息上报成功",
        "items_count": len(inventory_data.items)
    }