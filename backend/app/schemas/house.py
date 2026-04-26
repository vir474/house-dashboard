from datetime import datetime

from pydantic import BaseModel


class HouseCreate(BaseModel):
    name: str
    year_built: int | None = None
    zip_code: str | None = None
    hvac_type: str | None = None
    roof_material: str | None = None
    has_fireplace: bool = False
    has_pool: bool = False
    has_basement: bool = False
    water_heater_age: int | None = None


class HouseRead(HouseCreate):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class TaskRead(BaseModel):
    id: int
    house_id: int
    name: str
    frequency: str
    season: str | None
    due_date: datetime | None
    last_completed: datetime | None
    next_due: datetime | None
    source: str
    reason: str | None
    is_dismissed: bool
    updated_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class CompleteTask(BaseModel):
    notes: str | None = None


class CompletionRead(BaseModel):
    id: int
    task_id: int
    completed_at: datetime
    notes: str | None

    class Config:
        from_attributes = True
