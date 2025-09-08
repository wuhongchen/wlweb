-- 创建游戏账户信息表
CREATE TABLE game_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id VARCHAR(100) NOT NULL UNIQUE COMMENT '账户ID，来自API上报',
    username VARCHAR(100) COMMENT '用户名',
    level INT COMMENT '等级',
    server_name VARCHAR(100) COMMENT '服务器名称',
    last_terminal_id VARCHAR(100) COMMENT '最后管理的终端设备ID',
    last_login_time TIMESTAMP NULL COMMENT '最后登录时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_account_id (account_id),
    INDEX idx_last_terminal_id (last_terminal_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='游戏账户信息表';

-- 创建游戏资产记录表
CREATE TABLE game_asset_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id VARCHAR(100) NOT NULL COMMENT '账户ID',
    terminal_id VARCHAR(100) NOT NULL COMMENT '终端设备ID',
    gold BIGINT COMMENT '金子数量',
    diamond BIGINT COMMENT '元宝/钻石数量',
    energy INT COMMENT '体力值',
    experience BIGINT COMMENT '经验值',
    level INT COMMENT '等级',
    vip_level INT COMMENT 'VIP等级',
    report_time TIMESTAMP NULL COMMENT '上报时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_account_id (account_id),
    INDEX idx_terminal_id (terminal_id),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (account_id) REFERENCES game_accounts(account_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='游戏资产记录表';

-- 创建游戏背包物品记录表
CREATE TABLE game_inventory_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id VARCHAR(100) NOT NULL COMMENT '账户ID',
    terminal_id VARCHAR(100) NOT NULL COMMENT '终端设备ID',
    item_id VARCHAR(100) NOT NULL COMMENT '物品ID',
    item_name VARCHAR(200) NOT NULL COMMENT '物品名称',
    item_type VARCHAR(50) NOT NULL COMMENT '物品类型',
    quantity INT NOT NULL COMMENT '数量',
    quality VARCHAR(50) COMMENT '品质',
    description TEXT COMMENT '描述',
    report_time TIMESTAMP NULL COMMENT '上报时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_account_id (account_id),
    INDEX idx_terminal_id (terminal_id),
    INDEX idx_item_type (item_type),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (account_id) REFERENCES game_accounts(account_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='游戏背包物品记录表';

-- 创建游戏登录记录表
CREATE TABLE game_login_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id VARCHAR(100) NOT NULL COMMENT '账户ID',
    terminal_id VARCHAR(100) NOT NULL COMMENT '终端设备ID',
    username VARCHAR(100) COMMENT '用户名',
    login_time TIMESTAMP NULL COMMENT '登录时间',
    login_ip VARCHAR(45) COMMENT '登录IP',
    login_device VARCHAR(200) COMMENT '登录设备',
    game_server VARCHAR(100) COMMENT '游戏服务器',
    login_status VARCHAR(20) COMMENT '登录状态',
    server_info JSON COMMENT '服务器信息',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_account_id (account_id),
    INDEX idx_terminal_id (terminal_id),
    INDEX idx_login_time (login_time),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (account_id) REFERENCES game_accounts(account_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='游戏登录记录表';