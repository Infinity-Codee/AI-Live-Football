import datetime
from sqlalchemy import String, Integer, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.models.database import Base


class CreditTransaction(Base):
    __tablename__ = "credit_transactions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), index=True)
    match_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("matches.id"), nullable=True
    )

    # +1 = ad reward, -1 = match unlock
    amount: Mapped[int] = mapped_column(Integer, default=0)

    # "ad_reward" or "match_unlock"
    type: Mapped[str] = mapped_column(String(50), default="")

    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime, default=datetime.datetime.utcnow
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "match_id": self.match_id,
            "amount": self.amount,
            "type": self.type,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
