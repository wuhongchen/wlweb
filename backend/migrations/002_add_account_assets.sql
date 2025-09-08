-- 账号资产管理模块 - 数据库迁移
-- 创建时间: 2024-01-16

-- 账号资产表
CREATE TABLE account_assets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account VARCHAR(100) NOT NULL COMMENT '账号',
    password TEXT NOT NULL COMMENT '密码',
    region_code VARCHAR(20) NOT NULL COMMENT '所属区域编码，如S110、S130等',
    terminal_id INT NULL COMMENT '绑定的终端ID',
    description TEXT NULL COMMENT '备注描述',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (terminal_id) REFERENCES terminals(id) ON DELETE SET NULL,
    INDEX idx_account (account),
    INDEX idx_region_code (region_code),
    INDEX idx_terminal_id (terminal_id),
    INDEX idx_created_at (created_at)
);