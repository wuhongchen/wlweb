#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自动化部署脚本
用于实现前后端项目的自动更新部署

功能特性：
1. 自动检测并处理端口占用问题
2. 支持前后端项目的自动构建和部署
3. 完善的错误处理机制
4. 部署状态监控和日志记录
"""

import os
import sys
import json
import time
import shutil
import signal
import logging
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass

# 配置类
@dataclass
class DeployConfig:
    """部署配置类"""
    project_root: str = ""
    frontend_port: int = 5175
    backend_port: int = 8001
    log_dir: str = "logs"
    health_check_timeout: int = 30
    health_check_interval: int = 2
    frontend_build_command: str = "npm run build"
    backend_start_command: str = "uvicorn app.main:app --host 0.0.0.0 --port 8001"
    
    def __post_init__(self):
        if not self.project_root:
            self.project_root = os.getcwd()

class DeploymentManager:
    """部署管理器主类"""
    
    def __init__(self, config: DeployConfig):
        self.config = config
        self.project_root = Path(config.project_root)
        self.log_dir = self.project_root / config.log_dir
        self.current_processes = {}
        
        # 确保目录存在
        self.log_dir.mkdir(exist_ok=True)
        
        # 设置日志
        self._setup_logging()
        
        # 注册信号处理
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _setup_logging(self):
        """设置日志记录"""
        log_file = self.log_dir / f"deploy_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file, encoding='utf-8'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        
        self.logger = logging.getLogger(__name__)
        self.logger.info(f"部署日志已初始化: {log_file}")
    
    def _signal_handler(self, signum, frame):
        """信号处理器"""
        self.logger.info(f"接收到信号 {signum}，正在清理资源...")
        self._cleanup_processes()
        sys.exit(0)
    
    def _cleanup_processes(self):
        """清理进程"""
        for name, process in self.current_processes.items():
            if process and process.poll() is None:
                self.logger.info(f"终止进程: {name}")
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
    
    def deploy(self, components: List[str] = None) -> bool:
        """执行部署
        
        Args:
            components: 要部署的组件列表，可选值: ['frontend', 'backend']
                       如果为None，则部署所有组件
        
        Returns:
            bool: 部署是否成功
        """
        if components is None:
            components = ['frontend', 'backend']
        
        self.logger.info(f"开始部署组件: {components}")
        
        try:
            # 1. 预检查
            if not self._pre_deployment_check():
                return False
            
            # 2. 停止现有服务
            self._stop_services()
            
            # 3. 部署各组件
            success = True
            for component in components:
                if component == 'frontend':
                    success &= self._deploy_frontend()
                elif component == 'backend':
                    success &= self._deploy_backend()
                else:
                    self.logger.warning(f"未知组件: {component}")
            
            if not success:
                self.logger.error("部署失败")
                return False
            
            # 4. 启动服务
            if not self._start_services():
                self.logger.error("服务启动失败")
                return False
            
            # 5. 健康检查
            if not self._health_check():
                self.logger.error("健康检查失败")
                return False
            
            self.logger.info("部署成功完成！")
            return True
            
        except Exception as e:
            self.logger.error(f"部署过程中发生异常: {e}")
            return False
    
    def _pre_deployment_check(self) -> bool:
        """部署前检查"""
        self.logger.info("执行部署前检查...")
        
        # 检查项目根目录
        if not self.project_root.exists():
            self.logger.error(f"项目根目录不存在: {self.project_root}")
            return False
        
        # 检查必要文件
        required_files = [
            'package.json',
            'backend/main.py',
            'backend/requirements.txt'
        ]
        
        for file_path in required_files:
            if not (self.project_root / file_path).exists():
                self.logger.error(f"必要文件不存在: {file_path}")
                return False
        
        self.logger.info("部署前检查通过")
        return True
    

    
    def _check_port_available(self, port: int) -> bool:
        """检查端口是否可用"""
        import socket
        
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                sock.settimeout(1)
                result = sock.connect_ex(('localhost', port))
                return result != 0
        except Exception:
            return False
    
    def _kill_process_on_port(self, port: int) -> bool:
        """杀死占用指定端口的进程"""
        try:
            # 查找占用端口的进程
            result = subprocess.run(
                ['lsof', '-ti', f':{port}'],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0 and result.stdout.strip():
                pids = result.stdout.strip().split('\n')
                for pid in pids:
                    if pid:
                        self.logger.info(f"终止占用端口 {port} 的进程 PID: {pid}")
                        subprocess.run(['kill', '-9', pid], check=False)
                
                # 等待进程终止
                time.sleep(2)
                return self._check_port_available(port)
            
            return True
            
        except Exception as e:
            self.logger.error(f"终止端口 {port} 上的进程失败: {e}")
            return False
    
    def _ensure_port_available(self, port: int, service_name: str) -> bool:
        """确保端口可用"""
        self.logger.info(f"检查 {service_name} 端口 {port} 可用性...")
        
        if self._check_port_available(port):
            self.logger.info(f"端口 {port} 可用")
            return True
        
        self.logger.warning(f"端口 {port} 被占用，尝试释放...")
        
        if self._kill_process_on_port(port):
            self.logger.info(f"端口 {port} 已释放")
            return True
        
        self.logger.error(f"无法释放端口 {port}")
        return False
    
    def _stop_services(self):
        """停止现有服务"""
        self.logger.info("停止现有服务...")
        
        # 停止前端服务
        if not self._ensure_port_available(self.config.frontend_port, "前端"):
            self.logger.warning(f"无法释放前端端口 {self.config.frontend_port}")
        
        # 停止后端服务
        if not self._ensure_port_available(self.config.backend_port, "后端"):
            self.logger.warning(f"无法释放后端端口 {self.config.backend_port}")
        
        # 清理当前进程
        self._cleanup_processes()
    
    def _deploy_frontend(self) -> bool:
        """部署前端"""
        self.logger.info("开始部署前端...")
        
        try:
            # 1. 安装依赖
            self.logger.info("安装前端依赖...")
            result = subprocess.run(
                ['npm', 'install'],
                cwd=self.project_root,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode != 0:
                self.logger.error(f"前端依赖安装失败: {result.stderr}")
                return False
            
            # 2. 构建前端
            self.logger.info("构建前端项目...")
            result = subprocess.run(
                ['npx', 'vite', 'build', '--mode', 'production'],
                cwd=self.project_root,
                capture_output=True,
                text=True,
                timeout=600,
                env={**os.environ, 'NODE_ENV': 'production'}
            )
            
            if result.returncode != 0:
                self.logger.error(f"前端构建失败: {result.stderr}")
                return False
            
            # 3. 检查构建结果
            dist_path = self.project_root / 'dist'
            if not dist_path.exists():
                self.logger.error("前端构建产物不存在")
                return False
            
            self.logger.info("前端部署完成")
            return True
            
        except subprocess.TimeoutExpired:
            self.logger.error("前端构建超时")
            return False
        except Exception as e:
            self.logger.error(f"前端部署失败: {e}")
            return False
    
    def _start_frontend(self) -> bool:
        """启动前端服务"""
        self.logger.info("启动前端服务...")
        
        try:
            # 确保端口可用
            if not self._ensure_port_available(self.config.frontend_port, "前端"):
                return False
            
            # 检查构建产物是否存在
            dist_path = self.project_root / 'dist'
            if not dist_path.exists():
                self.logger.error("前端构建产物不存在，请先构建前端")
                return False
            
            # 启动静态文件服务器
            process = subprocess.Popen(
                ['npx', 'vite', 'preview', '--port', str(self.config.frontend_port), '--host', '0.0.0.0'],
                cwd=self.project_root,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            self.current_processes['frontend'] = process
            
            # 等待服务启动
            for i in range(15):
                if self._check_port_available(self.config.frontend_port):
                    time.sleep(2)
                else:
                    self.logger.info(f"前端服务已启动在端口 {self.config.frontend_port}")
                    return True
            
            self.logger.error("前端服务启动超时")
            return False
            
        except Exception as e:
             self.logger.error(f"启动前端服务失败: {e}")
             return False
    
    def _deploy_backend(self) -> bool:
        """部署后端"""
        self.logger.info("开始部署后端...")
        
        try:
            backend_path = self.project_root / 'backend'
            
            # 1. 检查Python虚拟环境
            venv_path = backend_path / 'venv'
            if not venv_path.exists():
                self.logger.info("创建Python虚拟环境...")
                result = subprocess.run(
                    ['python3', '-m', 'venv', 'venv'],
                    cwd=backend_path,
                    capture_output=True,
                    text=True
                )
                
                if result.returncode != 0:
                    self.logger.error(f"创建虚拟环境失败: {result.stderr}")
                    return False
            
            # 2. 激活虚拟环境并安装依赖
            pip_path = venv_path / 'bin' / 'pip'
            if not pip_path.exists():
                self.logger.error("虚拟环境pip不存在")
                return False
            
            self.logger.info("安装后端依赖...")
            result = subprocess.run(
                [str(pip_path), 'install', '-r', 'requirements.txt'],
                cwd=backend_path,
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode != 0:
                self.logger.error(f"后端依赖安装失败: {result.stderr}")
                return False
            
            # 3. 检查数据库文件
            db_files = ['app.db', 'game_data.db', 'game_middleware.db']
            for db_file in db_files:
                db_path = backend_path / db_file
                if not db_path.exists():
                    self.logger.warning(f"数据库文件不存在: {db_file}")
            
            self.logger.info("后端部署完成")
            return True
            
        except subprocess.TimeoutExpired:
            self.logger.error("后端依赖安装超时")
            return False
        except Exception as e:
            self.logger.error(f"后端部署失败: {e}")
            return False
    
    def _start_backend(self) -> bool:
        """启动后端服务"""
        self.logger.info("启动后端服务...")
        
        try:
            backend_path = self.project_root / 'backend'
            python_path = backend_path / 'venv' / 'bin' / 'python'
            
            # 确保端口可用
            if not self._ensure_port_available(self.config.backend_port, "后端"):
                return False
            
            # 启动后端服务
            process = subprocess.Popen(
                [str(python_path), '-m', 'uvicorn', 'main:app', 
                 '--host', '0.0.0.0', '--port', str(self.config.backend_port), '--reload'],
                cwd=backend_path,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            self.current_processes['backend'] = process
            
            # 等待服务启动
            for i in range(15):
                if self._check_port_available(self.config.backend_port):
                    time.sleep(2)
                else:
                    self.logger.info(f"后端服务已启动在端口 {self.config.backend_port}")
                    return True
            
            self.logger.error("后端服务启动超时")
            return False
            
        except Exception as e:
            self.logger.error(f"启动后端服务失败: {e}")
            return False
    
    def _start_services(self) -> bool:
        """启动所有服务"""
        self.logger.info("启动服务...")
        
        # 启动后端服务
        if not self._start_backend():
            return False
        
        # 启动前端服务
        if not self._start_frontend():
            return False
        
        return True
    
    def _health_check(self) -> bool:
        """健康检查"""
        self.logger.info("执行健康检查...")
        
        import requests
        
        # 检查后端健康状态
        backend_url = f"http://localhost:{self.config.backend_port}"
        try:
            response = requests.get(f"{backend_url}/docs", timeout=5)
            if response.status_code == 200:
                self.logger.info("后端服务健康检查通过")
            else:
                self.logger.error(f"后端服务健康检查失败: {response.status_code}")
                return False
        except Exception as e:
            self.logger.error(f"后端服务健康检查异常: {e}")
            return False
        
        # 检查前端健康状态
        frontend_url = f"http://localhost:{self.config.frontend_port}"
        try:
            response = requests.get(frontend_url, timeout=5)
            if response.status_code == 200:
                self.logger.info("前端服务健康检查通过")
            else:
                self.logger.error(f"前端服务健康检查失败: {response.status_code}")
                return False
        except Exception as e:
            self.logger.error(f"前端服务健康检查异常: {e}")
            return False
        
        self.logger.info("所有服务健康检查通过")
        return True
    

    


    def deploy(self, components: list = None) -> bool:
        """执行部署"""
        if components is None:
            components = ['frontend', 'backend']
        
        self.logger.info(f"开始部署组件: {components}")
        
        try:
            # 预检查
            if not self._pre_deployment_check():
                return False
            
            # 停止服务
            self._stop_services()
            
            # 部署组件
            success = True
            if 'frontend' in components:
                if not self._deploy_frontend():
                    success = False
            
            if 'backend' in components and success:
                if not self._deploy_backend():
                    success = False
            
            if success:
                # 启动服务
                if self._start_services():
                    # 健康检查
                    if self._health_check():
                        self.logger.info("部署成功完成")
                        return True
                    else:
                        self.logger.error("健康检查失败")
                        success = False
                else:
                    self.logger.error("服务启动失败")
                    success = False
            
            if not success:
                self.logger.error("部署失败，请检查日志")
                return False
                
        except Exception as e:
            self.logger.error(f"部署过程中发生异常: {e}")
            return False
    
    def status(self):
        """检查服务状态"""
        print("检查服务状态...")
        
        # 检查端口占用
        frontend_port_used = not self._check_port_available(self.config.frontend_port)
        backend_port_used = not self._check_port_available(self.config.backend_port)
        
        print(f"前端端口 {self.config.frontend_port}: {'运行中' if frontend_port_used else '未使用'}")
        print(f"后端端口 {self.config.backend_port}: {'运行中' if backend_port_used else '未使用'}")
        
        if frontend_port_used and backend_port_used:
            # 执行健康检查
            if self._health_check():
                print("所有服务运行正常")
            else:
                print("服务运行异常")
        else:
            print("部分或全部服务未运行")


# 主函数
def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='自动化部署脚本')
    parser.add_argument('action', choices=['deploy', 'status', 'stop', 'start'],
                       help='执行的操作')
    parser.add_argument('--components', nargs='+', choices=['frontend', 'backend'],
                       help='要部署的组件 (默认: frontend backend)')
    parser.add_argument('--config', help='配置文件路径')
    
    args = parser.parse_args()
    
    # 创建部署管理器
    config = DeployConfig()
    if args.config:
        # 这里可以添加从配置文件加载的逻辑
        pass
    
    manager = DeploymentManager(config)
    
    try:
        if args.action == 'deploy':
            components = args.components or ['frontend', 'backend']
            success = manager.deploy(components)
            exit(0 if success else 1)
        
        elif args.action == 'status':
            manager.status()
        
        elif args.action == 'stop':
            manager._stop_services()
            print("服务已停止")
        
        elif args.action == 'start':
            if manager._start_services():
                print("服务启动成功")
            else:
                print("服务启动失败")
                exit(1)
        

    
    except KeyboardInterrupt:
        print("\n操作被用户中断")
        exit(1)
    except Exception as e:
        print(f"执行失败: {e}")
        exit(1)


if __name__ == '__main__':
    main()