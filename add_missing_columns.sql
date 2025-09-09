-- 为account_assets表添加缺失的字段
USE wlweb_game_middleware;

ALTER TABLE account_assets 
ADD COLUMN server_name VARCHAR(100) NULL COMMENT '服务器名称' AFTER description,
ADD COLUMN level INT NULL COMMENT '角色等级' AFTER server_name,
ADD COLUMN character_name VARCHAR(100) NULL COMMENT '角色名称' AFTER level,
ADD COLUMN character_id VARCHAR(100) NULL COMMENT '角色ID' AFTER character_name;

-- 验证表结构
DESCRIBE account_assets;

-- 查看现有数据
SELECT id, account, region_code, server_name, character_name, level FROM account_assets LIMIT 5;