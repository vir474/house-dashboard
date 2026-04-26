from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import get_db
from app.models.house import Completion, Task
from app.schemas.house import CompleteTask, CompletionRead, TaskRead
from app.services.scheduler import compute_next_due

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.post("/{task_id}/complete", response_model=CompletionRead)
async def complete_task(task_id: int, payload: CompleteTask, db: AsyncSession = Depends(get_db)):
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    now = datetime.utcnow()
    completion = Completion(task_id=task_id, completed_at=now, notes=payload.notes)
    db.add(completion)

    task.last_completed = now
    task.next_due = compute_next_due(task.frequency, task.season, from_date=now)

    await db.commit()
    await db.refresh(completion)
    return completion


@router.patch("/{task_id}/dismiss", response_model=TaskRead)
async def dismiss_task(task_id: int, db: AsyncSession = Depends(get_db)):
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    task.is_dismissed = True
    await db.commit()
    await db.refresh(task)
    return task
