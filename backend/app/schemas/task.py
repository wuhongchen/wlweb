from typing import Optional, Dict, Any
from pydantic import BaseModel
from app.models.task import TaskStatus
from datetime import datetime

class TaskBase(BaseModel):
    name: str
    description: Optional[str] = None
    parameters: Optional[Dict[str, Any]] = None

class TaskCreate(TaskBase):
    pass

class TaskUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    parameters: Optional[Dict[str, Any]] = None
    status: Optional[TaskStatus] = None

class TaskInDB(TaskBase):
    id: int
    status: TaskStatus
    created_by: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class Task(TaskInDB):
    pass

class TaskExecutionCreate(BaseModel):
    task_id: int
    terminal_id: int

class TaskExecutionUpdate(BaseModel):
    status: Optional[TaskStatus] = None
    result: Optional[Dict[str, Any]] = None