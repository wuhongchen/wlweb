from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta
from app.core.database import get_db
from app.models.user import User
from app.models.terminal import Terminal
from app.models.task import Task, TaskExecution
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/dashboard")
async def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # 获取基础统计数据
    total_users = db.query(User).count()
    total_terminals = db.query(Terminal).count()
    total_tasks = db.query(Task).count()
    
    # 在线终端数量
    online_terminals = db.query(Terminal).filter(
        Terminal.status == "online",
        Terminal.last_heartbeat >= datetime.utcnow() - timedelta(minutes=5)
    ).count()
    
    # 今日任务执行数量
    today = datetime.utcnow().date()
    today_executions = db.query(TaskExecution).filter(
        func.date(TaskExecution.start_time) == today
    ).count()
    
    # 任务状态分布
    task_status_stats = db.query(
        Task.status,
        func.count(Task.id).label('count')
    ).group_by(Task.status).all()
    
    task_status_distribution = {status: count for status, count in task_status_stats}
    
    # 最近7天的任务执行趋势
    seven_days_ago = datetime.utcnow() - timedelta(days=7)
    daily_executions = db.query(
        func.date(TaskExecution.start_time).label('date'),
        func.count(TaskExecution.id).label('count')
    ).filter(
        TaskExecution.start_time >= seven_days_ago
    ).group_by(
        func.date(TaskExecution.start_time)
    ).all()
    
    execution_trend = [
        {"date": str(date), "count": count}
        for date, count in daily_executions
    ]
    
    return {
        "total_users": total_users,
        "total_terminals": total_terminals,
        "total_tasks": total_tasks,
        "online_terminals": online_terminals,
        "today_executions": today_executions,
        "task_status_distribution": task_status_distribution,
        "execution_trend": execution_trend
    }

@router.get("/terminals")
async def get_terminal_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # 终端状态分布
    terminal_status_stats = db.query(
        Terminal.status,
        func.count(Terminal.id).label('count')
    ).group_by(Terminal.status).all()
    
    status_distribution = {status: count for status, count in terminal_status_stats}
    
    # 最活跃的终端
    active_terminals = db.query(
        Terminal.terminal_id,
        Terminal.name,
        func.count(TaskExecution.id).label('execution_count')
    ).join(
        TaskExecution, Terminal.id == TaskExecution.terminal_id
    ).group_by(
        Terminal.id, Terminal.terminal_id, Terminal.name
    ).order_by(
        func.count(TaskExecution.id).desc()
    ).limit(10).all()
    
    top_terminals = [
        {
            "terminal_id": terminal_id,
            "name": name,
            "execution_count": execution_count
        }
        for terminal_id, name, execution_count in active_terminals
    ]
    
    return {
        "status_distribution": status_distribution,
        "top_terminals": top_terminals
    }

@router.get("/tasks")
async def get_task_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # 任务执行成功率
    total_executions = db.query(TaskExecution).count()
    successful_executions = db.query(TaskExecution).filter(
        TaskExecution.result.like('%success%')
    ).count()
    
    success_rate = (successful_executions / total_executions * 100) if total_executions > 0 else 0
    
    # 平均执行时间
    avg_execution_time = db.query(
        func.avg(
            func.timestampdiff(
                'SECOND',
                TaskExecution.start_time,
                TaskExecution.end_time
            )
        )
    ).filter(
        TaskExecution.end_time.isnot(None)
    ).scalar()
    
    # 最常执行的任务
    popular_tasks = db.query(
        Task.name,
        func.count(TaskExecution.id).label('execution_count')
    ).join(
        TaskExecution, Task.id == TaskExecution.task_id
    ).group_by(
        Task.id, Task.name
    ).order_by(
        func.count(TaskExecution.id).desc()
    ).limit(10).all()
    
    top_tasks = [
        {
            "name": name,
            "execution_count": execution_count
        }
        for name, execution_count in popular_tasks
    ]
    
    return {
        "total_executions": total_executions,
        "success_rate": round(success_rate, 2),
        "avg_execution_time": round(avg_execution_time or 0, 2),
        "top_tasks": top_tasks
    }