from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
from app.core.database import get_db
from app.models.task import Task, TaskExecution
from app.models.terminal import Terminal
from app.models.user import User
from app.schemas.task import (
    TaskCreate, TaskUpdate, Task as TaskSchema,
    TaskExecutionCreate, TaskExecutionUpdate
)
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/", response_model=List[TaskSchema])
async def get_tasks(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    tasks = db.query(Task).offset(skip).limit(limit).all()
    return tasks

@router.post("/", response_model=TaskSchema)
async def create_task(
    task: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_task = Task(
        **task.dict(),
        created_by=current_user.id
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

@router.get("/{task_id}", response_model=TaskSchema)
async def get_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="任务不存在"
        )
    return task

@router.put("/{task_id}", response_model=TaskSchema)
async def update_task(
    task_id: int,
    task_update: TaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="任务不存在"
        )
    
    update_data = task_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(task, field, value)
    
    db.commit()
    db.refresh(task)
    return task

@router.delete("/{task_id}")
async def delete_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="任务不存在"
        )
    
    db.delete(task)
    db.commit()
    return {"message": "任务删除成功"}

@router.post("/{task_id}/execute")
async def execute_task(
    task_id: int,
    execution: TaskExecutionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="任务不存在"
        )
    
    # 检查终端是否存在
    terminal = db.query(Terminal).filter(Terminal.id == execution.terminal_id).first()
    if not terminal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="终端不存在"
        )
    
    # 创建任务执行记录
    task_execution = TaskExecution(
        task_id=task_id,
        terminal_id=execution.terminal_id,
        start_time=datetime.utcnow()
    )
    db.add(task_execution)
    
    # 更新任务状态
    task.status = "running"
    
    db.commit()
    db.refresh(task_execution)
    
    return {"message": "任务执行已启动", "execution_id": task_execution.id}

@router.put("/executions/{execution_id}")
async def update_task_execution(
    execution_id: int,
    execution_update: TaskExecutionUpdate,
    db: Session = Depends(get_db)
):
    execution = db.query(TaskExecution).filter(TaskExecution.id == execution_id).first()
    if not execution:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="任务执行记录不存在"
        )
    
    update_data = execution_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(execution, field, value)
    
    # 如果任务完成，更新完成时间
    if execution_update.result and not execution.end_time:
        execution.end_time = datetime.utcnow()
        
        # 更新任务状态
        task = db.query(Task).filter(Task.id == execution.task_id).first()
        if task:
            task.status = "completed" if "success" in execution_update.result.lower() else "failed"
    
    db.commit()
    db.refresh(execution)
    
    return {"message": "任务执行状态更新成功"}

@router.get("/{task_id}/executions")
async def get_task_executions(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="任务不存在"
        )
    
    executions = db.query(TaskExecution).filter(TaskExecution.task_id == task_id).all()
    return executions