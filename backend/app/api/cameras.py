import uuid

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models import Camera
from app.schemas import CameraCreate, CameraOut, CameraUpdate

router = APIRouter(prefix="/cameras", tags=["cameras"])


def _get(db: Session, camera_id: uuid.UUID) -> Camera:
    cam = db.get(Camera, camera_id)
    if cam is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Camera not found")
    return cam


@router.post("", response_model=CameraOut, status_code=status.HTTP_201_CREATED)
def create_camera(body: CameraCreate, db: Session = Depends(get_db)):
    cam = Camera(**body.model_dump())
    db.add(cam)
    db.commit()
    db.refresh(cam)
    return cam


@router.get("", response_model=list[CameraOut])
def list_cameras(db: Session = Depends(get_db)):
    return db.scalars(select(Camera).order_by(Camera.created_at)).all()


@router.get("/{camera_id}", response_model=CameraOut)
def get_camera(camera_id: uuid.UUID, db: Session = Depends(get_db)):
    return _get(db, camera_id)


@router.patch("/{camera_id}", response_model=CameraOut)
def update_camera(camera_id: uuid.UUID, body: CameraUpdate, db: Session = Depends(get_db)):
    cam = _get(db, camera_id)
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(cam, k, v)
    db.commit()
    db.refresh(cam)
    return cam


@router.delete("/{camera_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_camera(camera_id: uuid.UUID, db: Session = Depends(get_db)):
    db.delete(_get(db, camera_id))
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
