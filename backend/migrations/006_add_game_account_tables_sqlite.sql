-- 创建游戏账户信息表
CREATE TABLE game_accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id VARCHAR(100) NOT NULL UNIQUE, -- 账户ID，来自API上报
    username VARCHAR(100), -- 用户名
    level INTEGER, -- 等级
    server_name VARCHAR(100), -- 服务器名称
    last_terminal_id VARCHAR(100), -- 最后管理的终端设备ID
    last_login_time TIMESTAMP, -- 最后登录时间
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_game_accounts_account_id ON game_accounts(account_id);
CREATE INDEX idx_game_accounts_last_terminal_id ON game_accounts(last_terminal_id);

-- 创建游戏资产记录表
CREATE TABLE game_asset_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id VARCHAR(100) NOT NULL, -- 账户ID
    terminal_id VARCHAR(100) NOT NULL, -- 终端设备ID
    gold BIGINT, -- 金子数量
    diamond BIGINT, -- 元宝/钻石数量
    energy INTEGER, -- 体力值
    experience BIGINT, -- 经验值
    level INTEGER, -- 等级
    vip_level INTEGER, -- VIP等级
    report_time TIMESTAMP, -- 上报时间
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES game_accounts(account_id) ON DELETE CASCADE
);

CREATE INDEX idx_game_asset_records_account_id ON game_asset_records(account_id);
CREATE INDEX idx_game_asset_records_terminal_id ON game_asset_records(terminal_id);
CREATE INDEX idx_game_asset_records_created_at ON game_asset_records(created_at);

-- 创建游戏背包物品记录表
CREATE TABLE game_inventory_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id VARCHAR(100) NOT NULL, -- 账户ID
    terminal_id VARCHAR(100) NOT NULL, -- 终端设备ID
    item_id VARCHAR(100) NOT NULL, -- 物品ID
    item_name VARCHAR(200) NOT NULL, -- 物品名称
    item_type VARCHAR(50) NOT NULL, -- 物品类型
    quantity INTEGER NOT NULL, -- 数量
    quality VARCHAR(50), -- 品质
    description TEXT, -- 描述
    report_time TIMESTAMP, -- 上报时间
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES game_accounts(account_id) ON DELETE CASCADE
);

CREATE INDEX idx_game_inventory_records_account_id ON game_inventory_records(account_id);
CREATE INDEX idx_game_inventory_records_terminal_id ON game_inventory_records(terminal_id);
CREATE INDEX idx_game_inventory_records_item_type ON game_inventory_records(item_type);
CREATE INDEX idx_game_inventory_records_created_at ON game_inventory_records(created_at);

-- 创建游戏登录记录表
CREATE TABLE game_login_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id VARCHAR(100) NOT NULL, -- 账户ID
    terminal_id VARCHAR(100) NOT NULL, -- 终端设备ID
    username VARCHAR(100), -- 用户名
    login_time TIMESTAMP, -- 登录时间
    login_ip VARCHAR(45), -- 登录IP
    login_device VARCHAR(200), -- 登录设备
    game_server VARCHAR(100), -- 游戏服务器
    login_status VARCHAR(20), -- 登录状态
    server_info TEXT, -- 服务器信息 (JSON格式)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES game_accounts(account_id) ON DELETE CASCADE
);

CREATE INDEX idx_game_login_records_account_id ON game_login_records(account_id);
CREATE INDEX idx_game_login_records_terminal_id ON game_login_records(terminal_id);
CREATE INDEX idx_game_login_records_login_time ON game_login_records(login_time);
CREATE INDEX idx_game_login_records_created_at ON game_login_records(created_at);

-- 创建触发器来自动更新 updated_at 字段
CREATE TRIGGER update_game_accounts_updated_at
    AFTER UPDATE ON game_accounts
    FOR EACH ROW
BEGIN
    UPDATE game_accounts SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_game_asset_records_updated_at
    AFTER UPDATE ON game_asset_records
    FOR EACH ROW
BEGIN
    UPDATE game_asset_records SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_game_inventory_records_updated_at
    AFTER UPDATE ON game_inventory_records
    FOR EACH ROW
BEGIN
    UPDATE game_inventory_records SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_game_login_records_updated_at
    AFTER UPDATE ON game_login_records
    FOR EACH ROW
BEGIN
    UPDATE game_login_records SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;