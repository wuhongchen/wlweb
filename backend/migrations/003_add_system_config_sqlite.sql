-- 创建系统配置表
CREATE TABLE system_configs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    description VARCHAR(255),
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_system_configs_key ON system_configs(config_key);

-- 创建区域表
CREATE TABLE regions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    region_code VARCHAR(10) UNIQUE NOT NULL,
    region_name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_regions_code ON regions(region_code);

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