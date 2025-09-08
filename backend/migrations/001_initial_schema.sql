-- 游戏脚本中间件管理系统 - 初始数据库架构
-- 创建时间: 2024-01-15

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
);

-- 终端设备表
CREATE TABLE terminals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    terminal_id VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    status ENUM('online', 'offline', 'maintenance') DEFAULT 'offline',
    ip_address VARCHAR(45),
    config JSON,
    last_heartbeat TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_terminal_id (terminal_id),
    INDEX idx_status (status),
    INDEX idx_last_heartbeat (last_heartbeat)
);

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
);

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
);

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
);

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
);

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