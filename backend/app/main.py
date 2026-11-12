from fastapi import FastAPI

app = FastAPI(
    title="CSE 491 Fire & Smoke Detection API",
    version="0.1.0",
    description="Backend service for camera management, detection logging, and FCM alert dispatch.",
)


@app.get("/health", tags=["system"])
async def health_check():
    return {"status": "ok"}
