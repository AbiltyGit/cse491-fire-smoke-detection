import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

_id = lambda: mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)  # noqa: E731
_now = lambda: mapped_column(DateTime(timezone=True), server_default=func.now())  # noqa: E731


class User(Base):
    __tablename__ = "users"
    id: Mapped[uuid.UUID] = _id()
    full_name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(255), unique=True)
    role: Mapped[str] = mapped_column(String(50), default="operator")
    created_at: Mapped[datetime] = _now()


class UserDevice(Base):
    __tablename__ = "user_devices"
    id: Mapped[uuid.UUID] = _id()
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    fcm_token: Mapped[str] = mapped_column(Text, unique=True)
    platform: Mapped[str] = mapped_column(String(20))
    registered_at: Mapped[datetime] = _now()


class Camera(Base):
    __tablename__ = "cameras"
    id: Mapped[uuid.UUID] = _id()
    name: Mapped[str] = mapped_column(String(120))
    rtsp_url: Mapped[str] = mapped_column(Text)
    location: Mapped[str | None] = mapped_column(String(255))
    conf_threshold: Mapped[float] = mapped_column(Float, default=0.45)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = _now()


class DetectionEvent(Base):
    __tablename__ = "detection_events"
    id: Mapped[uuid.UUID] = _id()
    camera_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("cameras.id", ondelete="CASCADE"))
    event_type: Mapped[str] = mapped_column(String(20))
    max_confidence: Mapped[float] = mapped_column(Float)
    frame_streak: Mapped[int] = mapped_column(Integer)
    snapshot_path: Mapped[str | None] = mapped_column(Text)
    detected_at: Mapped[datetime] = _now()
    boxes: Mapped[list["DetectionBox"]] = relationship(
        cascade="all, delete-orphan", lazy="selectin"
    )


class DetectionBox(Base):
    __tablename__ = "detection_boxes"
    id: Mapped[uuid.UUID] = _id()
    event_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("detection_events.id", ondelete="CASCADE"))
    class_name: Mapped[str] = mapped_column(String(20))
    confidence: Mapped[float] = mapped_column(Float)
    x_min: Mapped[float] = mapped_column(Float)
    y_min: Mapped[float] = mapped_column(Float)
    x_max: Mapped[float] = mapped_column(Float)
    y_max: Mapped[float] = mapped_column(Float)


class NotificationLog(Base):
    __tablename__ = "notification_logs"
    id: Mapped[uuid.UUID] = _id()
    event_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("detection_events.id", ondelete="CASCADE"))
    device_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("user_devices.id", ondelete="CASCADE"))
    fcm_message_id: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(30), default="sent")
    sent_at: Mapped[datetime] = _now()
    acknowledged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
