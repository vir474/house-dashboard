from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class House(Base):
    __tablename__ = "houses"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    year_built: Mapped[int | None] = mapped_column(Integer, nullable=True)
    zip_code: Mapped[str | None] = mapped_column(String(10), nullable=True)
    hvac_type: Mapped[str | None] = mapped_column(String(50), nullable=True)  # central, heat_pump, none
    roof_material: Mapped[str | None] = mapped_column(String(50), nullable=True)  # asphalt, metal, tile
    has_fireplace: Mapped[bool] = mapped_column(Boolean, default=False)
    has_pool: Mapped[bool] = mapped_column(Boolean, default=False)
    has_basement: Mapped[bool] = mapped_column(Boolean, default=False)
    water_heater_age: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    tasks: Mapped[list["Task"]] = relationship("Task", back_populates="house", cascade="all, delete-orphan")


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    house_id: Mapped[int] = mapped_column(Integer, ForeignKey("houses.id"))
    name: Mapped[str] = mapped_column(String(200))
    frequency: Mapped[str] = mapped_column(String(50))  # weekly, monthly, quarterly, annually, twice_yearly
    season: Mapped[str | None] = mapped_column(String(20), nullable=True)  # spring, summer, fall, winter
    due_date: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    last_completed: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    next_due: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    source: Mapped[str] = mapped_column(String(20), default="rule")  # rule, llm, manual
    reason: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_dismissed: Mapped[bool] = mapped_column(Boolean, default=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    house: Mapped["House"] = relationship("House", back_populates="tasks")
    completions: Mapped[list["Completion"]] = relationship("Completion", back_populates="task", cascade="all, delete-orphan")


class Completion(Base):
    __tablename__ = "completions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    task_id: Mapped[int] = mapped_column(Integer, ForeignKey("tasks.id"))
    completed_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    notes: Mapped[str | None] = mapped_column(String(500), nullable=True)

    task: Mapped["Task"] = relationship("Task", back_populates="completions")
