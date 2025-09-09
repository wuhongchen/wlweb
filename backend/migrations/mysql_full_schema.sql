-- 游戏脚本中间件管理系统 - MySQL完整数据库架构
-- 创建时间: 2025-01-07
-- 数据库: wlweb_game_middleware

USE wlweb_game_middleware;

-- 用户表
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'user') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 终端设备表
CREATE TABLE terminals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    terminal_id VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    status ENUM('online', 'offline', 'maintenance') DEFAULT 'offline',
    ip_address VARCHAR(45),
    config JSON,
    description TEXT COMMENT '终端描述',
    last_heartbeat TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_terminal_id (terminal_id),
    INDEX idx_status (status),
    INDEX idx_last_heartbeat (last_heartbeat)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='终端设备表';

-- 任务表
CREATE TABLE tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    script_content TEXT NOT NULL,
    parameters JSON,
    status ENUM('pending', 'running', 'completed', 'failed') DEFAULT 'pending',
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_status (status),
    INDEX idx_created_by (created_by),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务表';

-- 任务执行记录表
CREATE TABLE task_executions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    terminal_id INT NOT NULL,
    result TEXT,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (terminal_id) REFERENCES terminals(id) ON DELETE CASCADE,
    INDEX idx_task_id (task_id),
    INDEX idx_terminal_id (terminal_id),
    INDEX idx_start_time (start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='任务执行记录表';

-- 终端数据表
CREATE TABLE terminal_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    terminal_id INT NOT NULL,
    data_type VARCHAR(50) NOT NULL,
    data_content JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (terminal_id) REFERENCES terminals(id) ON DELETE CASCADE,
    INDEX idx_terminal_id (terminal_id),
    INDEX idx_data_type (data_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='终端数据表';

-- 用户会话表
CREATE TABLE user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_session_token (session_token),
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户会话表';

-- 系统配置表
CREATE TABLE system_configs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    description VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_config_key (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';

-- 区域表
CREATE TABLE regions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    region_code VARCHAR(10) UNIQUE NOT NULL,
    region_name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_region_code (region_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='区域表';

-- 账号资产表
CREATE TABLE account_assets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account VARCHAR(100) NOT NULL COMMENT '账号',
    password TEXT NOT NULL COMMENT '密码',
    region_code VARCHAR(20) NOT NULL COMMENT '所属区域编码，如S110、S130等',
    terminal_id INT NULL COMMENT '绑定的终端ID',
    description TEXT NULL COMMENT '备注描述',
    server_name VARCHAR(100) NULL COMMENT '服务器名称',
    level INT NULL COMMENT '角色等级',
    character_name VARCHAR(100) NULL COMMENT '角色名称',
    character_id VARCHAR(100) NULL COMMENT '角色ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (terminal_id) REFERENCES terminals(id) ON DELETE SET NULL,
    INDEX idx_account (account),
    INDEX idx_region_code (region_code),
    INDEX idx_terminal_id (terminal_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='账号资产表';

-- 游戏账户信息表
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

-- 游戏资产记录表
CREATE TABLE game_asset_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id VARCHAR(100) NOT NULL COMMENT '账户ID',
    terminal_id VARCHAR(100) NOT NULL COMMENT '终端设备ID',
    region_code VARCHAR(20) COMMENT '区域编码',
    character_id VARCHAR(100) COMMENT '角色ID',
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
    INDEX idx_region_code (region_code),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (account_id) REFERENCES game_accounts(account_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='游戏资产记录表';

-- 游戏背包物品记录表
CREATE TABLE game_inventory_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id VARCHAR(100) NOT NULL COMMENT '账户ID',
    terminal_id VARCHAR(100) NOT NULL COMMENT '终端设备ID',
    region_code VARCHAR(20) COMMENT '区域编码',
    character_id VARCHAR(100) COMMENT '角色ID',
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
    INDEX idx_region_code (region_code),
    INDEX idx_item_type (item_type),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (account_id) REFERENCES game_accounts(account_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='游戏背包物品记录表';

-- 游戏登录记录表
CREATE TABLE game_login_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id VARCHAR(100) NOT NULL COMMENT '账户ID',
    terminal_id VARCHAR(100) NOT NULL COMMENT '终端设备ID',
    region_code VARCHAR(20) COMMENT '区域编码',
    character_id VARCHAR(100) COMMENT '角色ID',
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
    INDEX idx_region_code (region_code),
    INDEX idx_login_time (login_time),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (account_id) REFERENCES game_accounts(account_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='游戏登录记录表';

-- 插入默认数据

-- 插入默认管理员用户
-- 密码: admin123 (实际部署时应修改)
INSERT INTO users (username, email, password_hash, role) VALUES 
('admin', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6ukx/LBK2.', 'admin');

-- 插入示例终端
INSERT INTO terminals (terminal_id, name, status, ip_address) VALUES 
('TERM001', '测试终端1', 'offline', '192.168.1.100'),
('TERM002', '测试终端2', 'offline', '192.168.1.101');

-- 插入示例任务
INSERT INTO tasks (name, description, script_content, created_by) VALUES 
('系统信息收集', '收集终端系统基本信息', 'echo "System Info: $(uname -a)"', 1),
('磁盘空间检查', '检查磁盘使用情况', 'df -h', 1);

-- 插入默认区域数据
INSERT INTO regions (region_code, region_name, description) VALUES
('CN', '中国', '中国大陆地区'),
('US', '美国', '美国地区'),
('EU', '欧洲', '欧洲地区'),
('JP', '日本', '日本地区'),
('KR', '韩国', '韩国地区'),
('SEA', '东南亚', '东南亚地区');

-- 插入默认系统配置
INSERT INTO system_configs (config_key, config_value, description) VALUES
('default_region', 'CN', '默认区域设置'),
('max_accounts_per_region', '100', '每个区域最大账号数量'),
('region_auto_assign', 'true', '是否自动分配区域');

-- 创建完成提示
SELECT 'MySQL数据库结构创建完成！' AS message;