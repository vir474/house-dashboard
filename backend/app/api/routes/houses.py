from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import get_db
from app.models.house import House, Task
from app.schemas.house import HouseCreate, HouseRead, TaskRead
from app.services.ollama import suggest_tasks
from app.services.rules import generate_tasks_from_rules
from app.services.scheduler import compute_next_due

router = APIRouter(prefix="/houses", tags=["houses"])


@router.post("/", response_model=HouseRead)
async def create_house(payload: HouseCreate, db: AsyncSession = Depends(get_db)):
    house = House(**payload.model_dump())
    db.add(house)
    await db.commit()
    await db.refresh(house)

    # Auto-generate tasks from rules
    rule_tasks = generate_tasks_from_rules(house)
    for t in rule_tasks:
        task = Task(
            house_id=house.id,
            name=t["name"],
            frequency=t["frequency"],
            season=t.get("season"),
            source=t["source"],
            next_due=compute_next_due(t["frequency"], t.get("season")),
        )
        db.add(task)

    await db.commit()
    return house


@router.get("/{house_id}", response_model=HouseRead)
async def get_house(house_id: int, db: AsyncSession = Depends(get_db)):
    house = await db.get(House, house_id)
    if not house:
        raise HTTPException(status_code=404, detail="House not found")
    return house


@router.get("/{house_id}/tasks", response_model=list[TaskRead])
async def get_tasks(house_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Task).where(Task.house_id == house_id, Task.is_dismissed == False)
    )
    return result.scalars().all()


@router.post("/{house_id}/tasks/suggest", response_model=list[TaskRead])
async def suggest_and_save(house_id: int, db: AsyncSession = Depends(get_db)):
    """Call Ollama to generate contextual task suggestions and save them."""
    house = await db.get(House, house_id)
    if not house:
        raise HTTPException(status_code=404, detail="House not found")

    suggestions = await suggest_tasks(house)
    saved = []
    for s in suggestions:
        task = Task(
            house_id=house.id,
            name=s["name"],
            frequency=s.get("frequency", "annually"),
            season=s.get("season"),
            source="llm",
            reason=s.get("reason"),
            next_due=compute_next_due(s.get("frequency", "annually"), s.get("season")),
        )
        db.add(task)
        saved.append(task)

    await db.commit()
    for t in saved:
        await db.refresh(t)
    return saved
