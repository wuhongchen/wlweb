-- 添加region_code字段到game_login_records表（如果表存在）
ALTER TABLE game_login_records ADD COLUMN region_code VARCHAR(20);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_game_login_records_region_code ON game_login_records(region_code);