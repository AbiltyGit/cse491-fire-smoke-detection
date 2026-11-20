from fastapi import FastAPI
from sqlalchemy import text

from app.api import cameras, events
from app.core.database import engine

app = FastAPI(
    title="CSE 491 Fire & Smoke Detection API",
    version="0.2.0",
    description="Backend service for camera management, detection logging, and FCM alert dispatch.",
)
app.include_router(cameras.router)
app.include_router(events.router)


@app.get("/health", tags=["system"])
def health_check():
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "ok", "database": "up"}
    except Exception:
        return {"status": "degraded", "database": "down"}
