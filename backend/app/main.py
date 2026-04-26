from fastapi import FastAPI

from app.api.routes import houses, tasks
from app.db.base import Base, engine

app = FastAPI(title="House Dashboard API")

app.include_router(houses.router)
app.include_router(tasks.router)


@app.on_event("startup")
async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


@app.get("/health")
async def health():
    return {"status": "ok"}
