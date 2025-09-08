-- 为账号资产表添加游戏相关字段 (SQLite版本)
-- 创建时间: 2024-01-17

-- SQLite需要逐个添加列
ALTER TABLE account_assets ADD COLUMN server_name VARCHAR(100);
ALTER TABLE account_assets ADD COLUMN level INTEGER;
ALTER TABLE account_assets ADD COLUMN character_name VARCHAR(100);
ALTER TABLE account_assets ADD COLUMN character_id VARCHAR(100);

-- 添加索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_account_assets_server_name ON account_assets(server_name);
CREATE INDEX IF NOT EXISTS idx_account_assets_level ON account_assets(level);
CREATE INDEX IF NOT EXISTS idx_account_assets_character_name ON account_assets(character_name);
CREATE INDEX IF NOT EXISTS idx_account_assets_character_id ON account_assets(character_id);