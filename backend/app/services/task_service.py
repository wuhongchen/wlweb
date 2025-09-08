from datetime import datetime, timedelta
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import and_, func
from app.models.task import Task, TaskExecution
from app.models.terminal import Terminal
from app.schemas.task import TaskCreate, TaskUpdate

class TaskService:
    @staticmethod
    def create_task(db: Session, task_data: TaskCreate, created_by: int) -> Task:
        """创建任务"""
        task = Task(**task_data.dict(), created_by=created_by)
        db.add(task)
        db.commit()
        db.refresh(task)
        return task
    
    @staticmethod
    def get_user_tasks(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[Task]:
        """获取用户创建的任务"""
        return db.query(Task).filter(
            Task.created_by == user_id
        ).offset(skip).limit(limit).all()
    
    @staticmethod
    def get_running_tasks(db: Session) -> List[Task]:
        """获取正在运行的任务"""
        return db.query(Task).filter(Task.status == "running").all()
    
    @staticmethod
    def execute_task(db: Session, task_id: int, terminal_id: int) -> TaskExecution:
        """执行任务"""
        # 检查任务是否存在
        task = db.query(Task).filter(Task.id == task_id).first()
        if not task:
            raise ValueError("任务不存在")
        
        # 检查终端是否存在且在线
        terminal = db.query(Terminal).filter(Terminal.id == terminal_id).first()
        if not terminal:
            raise ValueError("终端不存在")
        
        # 检查终端是否在线
        if terminal.status != "online":
            raise ValueError("终端不在线")
        
        # 创建执行记录
        execution = TaskExecution(
            task_id=task_id,
            terminal_id=terminal_id,
            start_time=datetime.utcnow()
        )
        db.add(execution)
        
        # 更新任务状态
        task.status = "running"
        task.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(execution)
        return execution
    
    @staticmethod
    def update_execution_result(db: Session, execution_id: int, result: str, 
                              success: bool = True) -> TaskExecution:
        """更新任务执行结果"""
        execution = db.query(TaskExecution).filter(TaskExecution.id == execution_id).first()
        if not execution:
            raise ValueError("执行记录不存在")
        
        execution.result = result
        execution.end_time = datetime.utcnow()
        
        # 更新任务状态
        task = db.query(Task).filter(Task.id == execution.task_id).first()
        if task:
            task.status = "completed" if success else "failed"
            task.updated_at = datetime.utcnow()
        
        db.commit()
        db.refresh(execution)
        return execution
    
    @staticmethod
    def get_task_executions(db: Session, task_id: int, limit: int = 50) -> List[TaskExecution]:
        """获取任务执行历史"""
        return db.query(TaskExecution).filter(
            TaskExecution.task_id == task_id
        ).order_by(TaskExecution.start_time.desc()).limit(limit).all()
    
    @staticmethod
    def get_terminal_executions(db: Session, terminal_id: int, limit: int = 50) -> List[TaskExecution]:
        """获取终端执行历史"""
        return db.query(TaskExecution).filter(
            TaskExecution.terminal_id == terminal_id
        ).order_by(TaskExecution.start_time.desc()).limit(limit).all()
    
    @staticmethod
    def get_execution_statistics(db: Session, days: int = 7) -> dict:
        """获取执行统计信息"""
        start_date = datetime.utcnow() - timedelta(days=days)
        
        # 总执行次数
        total_executions = db.query(TaskExecution).filter(
            TaskExecution.start_time >= start_date
        ).count()
        
        # 成功执行次数
        successful_executions = db.query(TaskExecution).filter(
            and_(
                TaskExecution.start_time >= start_date,
                TaskExecution.result.like('%success%')
            )
        ).count()
        
        # 平均执行时间
        avg_duration = db.query(
            func.avg(
                func.timestampdiff(
                    'SECOND',
                    TaskExecution.start_time,
                    TaskExecution.end_time
                )
            )
        ).filter(
            and_(
                TaskExecution.start_time >= start_date,
                TaskExecution.end_time.isnot(None)
            )
        ).scalar()
        
        success_rate = (successful_executions / total_executions * 100) if total_executions > 0 else 0
        
        return {
            "total_executions": total_executions,
            "successful_executions": successful_executions,
            "success_rate": round(success_rate, 2),
            "average_duration": round(avg_duration or 0, 2)
        }
    
    @staticmethod
    def cleanup_old_executions(db: Session, days: int = 90) -> int:
        """清理旧的执行记录"""
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        old_executions = db.query(TaskExecution).filter(
            TaskExecution.start_time < cutoff_date
        ).all()
        
        count = len(old_executions)
        for execution in old_executions:
            db.delete(execution)
        
        db.commit()
        return count