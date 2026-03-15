import datetime
from sqlalchemy import String, Integer, DateTime, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from app.models.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    device_id: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    credits: Mapped[int] = mapped_column(Integer, default=3)  # Start with 3 free credits
    total_ads_watched: Mapped[int] = mapped_column(Integer, default=0)
    is_pro: Mapped[bool] = mapped_column(Boolean, default=False)
    pro_expires_at: Mapped[datetime.datetime | None] = mapped_column(DateTime, nullable=True)
    rc_last_event_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
    rc_last_event_at: Mapped[datetime.datetime | None] = mapped_column(DateTime, nullable=True)

    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime, default=datetime.datetime.utcnow
    )
    last_active: Mapped[datetime.datetime] = mapped_column(
        DateTime, default=datetime.datetime.utcnow
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "device_id": self.device_id,
            "credits": self.credits,
            "total_ads_watched": self.total_ads_watched,
            "is_pro": self.is_pro,
            "pro_expires_at": self.pro_expires_at.isoformat() if self.pro_expires_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_active": self.last_active.isoformat() if self.last_active else None,
        }
