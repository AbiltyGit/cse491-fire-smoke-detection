import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class CameraBase(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    rtsp_url: str
    location: str | None = None
    conf_threshold: float = Field(0.45, ge=0, le=1)
    is_active: bool = True


class CameraCreate(CameraBase):
    pass


class CameraUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=120)
    rtsp_url: str | None = None
    location: str | None = None
    conf_threshold: float | None = Field(None, ge=0, le=1)
    is_active: bool | None = None


class CameraOut(CameraBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    created_at: datetime


class BoxIn(BaseModel):
    class_name: Literal["flame", "smoke"]
    confidence: float = Field(ge=0, le=1)
    x_min: float
    y_min: float
    x_max: float
    y_max: float


class BoxOut(BoxIn):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID


class EventCreate(BaseModel):
    camera_id: uuid.UUID
    frame_streak: int = Field(ge=1)
    snapshot_path: str | None = None
    boxes: list[BoxIn] = Field(min_length=1)


class EventOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    camera_id: uuid.UUID
    event_type: str
    max_confidence: float
    frame_streak: int
    snapshot_path: str | None
    detected_at: datetime
    boxes: list[BoxOut]
