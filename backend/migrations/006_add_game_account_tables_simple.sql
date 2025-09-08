-- 创建游戏账户表
CREATE TABLE IF NOT EXISTS game_accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id VARCHAR(100) NOT NULL UNIQUE,
    level INTEGER,
    last_terminal_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建游戏资产记录表
CREATE TABLE IF NOT EXISTS game_asset_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id VARCHAR(100) NOT NULL,
    terminal_id VARCHAR(50) NOT NULL,
    gold INTEGER,
    diamond INTEGER,
    energy INTEGER,
    experience INTEGER,
    level INTEGER,
    vip_level INTEGER,
    report_time TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES game_accounts(account_id)
);

-- 创建游戏背包记录表
CREATE TABLE IF NOT EXISTS game_inventory_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id VARCHAR(100) NOT NULL,
    terminal_id VARCHAR(50) NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    item_type VARCHAR(50),
    quantity INTEGER NOT NULL DEFAULT 0,
    report_time TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES game_accounts(account_id)
);

-- 创建游戏登录记录表
CREATE TABLE IF NOT EXISTS game_login_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id VARCHAR(100) NOT NULL,
    terminal_id VARCHAR(50) NOT NULL,
    region_code VARCHAR(20),
    login_time TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES game_accounts(account_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_game_accounts_account_id ON game_accounts(account_id);
CREATE INDEX IF NOT EXISTS idx_game_asset_records_account_id ON game_asset_records(account_id);
CREATE INDEX IF NOT EXISTS idx_game_asset_records_report_time ON game_asset_records(report_time);
CREATE INDEX IF NOT EXISTS idx_game_inventory_records_account_id ON game_inventory_records(account_id);
CREATE INDEX IF NOT EXISTS idx_game_inventory_records_report_time ON game_inventory_records(report_time);
CREATE INDEX IF NOT EXISTS idx_game_login_records_account_id ON game_login_records(account_id);
CREATE INDEX IF NOT EXISTS idx_game_login_records_login_time ON game_login_records(login_time);