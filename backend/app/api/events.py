import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models import Camera, DetectionBox, DetectionEvent
from app.schemas import EventCreate, EventOut

router = APIRouter(prefix="/events", tags=["events"])


@router.post("", response_model=EventOut, status_code=status.HTTP_201_CREATED)
def create_event(body: EventCreate, db: Session = Depends(get_db)):
    if db.get(Camera, body.camera_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Camera not found")
    classes = {b.class_name for b in body.boxes}
    event = DetectionEvent(
        camera_id=body.camera_id,
        event_type="both" if len(classes) > 1 else classes.pop(),
        max_confidence=max(b.confidence for b in body.boxes),
        frame_streak=body.frame_streak,
        snapshot_path=body.snapshot_path,
        boxes=[DetectionBox(**b.model_dump()) for b in body.boxes],
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return event


@router.get("", response_model=list[EventOut])
def list_events(
    camera_id: uuid.UUID | None = None,
    event_type: str | None = Query(None, pattern="^(flame|smoke|both)$"),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    q = select(DetectionEvent).order_by(DetectionEvent.detected_at.desc())
    if camera_id:
        q = q.where(DetectionEvent.camera_id == camera_id)
    if event_type:
        q = q.where(DetectionEvent.event_type == event_type)
    return db.scalars(q.limit(limit).offset(offset)).all()


@router.get("/{event_id}", response_model=EventOut)
def get_event(event_id: uuid.UUID, db: Session = Depends(get_db)):
    event = db.get(DetectionEvent, event_id)
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    return event
