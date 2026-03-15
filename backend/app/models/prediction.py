import datetime
from sqlalchemy import Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.models.database import Base


class Prediction(Base):
    __tablename__ = "predictions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    match_id: Mapped[int] = mapped_column(Integer, ForeignKey("matches.id"), index=True)

    # At which minute was this prediction made
    minute: Mapped[int] = mapped_column(Integer, default=0)

    # Probabilities
    home_win_prob: Mapped[float] = mapped_column(Float, default=0.0)
    draw_prob: Mapped[float] = mapped_column(Float, default=0.0)
    away_win_prob: Mapped[float] = mapped_column(Float, default=0.0)

    # Input features snapshot
    shot_diff: Mapped[float] = mapped_column(Float, default=0.0)
    corner_diff: Mapped[float] = mapped_column(Float, default=0.0)
    goal_diff: Mapped[float] = mapped_column(Float, default=0.0)
    red_card_diff: Mapped[float] = mapped_column(Float, default=0.0)

    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime, default=datetime.datetime.utcnow
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "match_id": self.match_id,
            "minute": self.minute,
            "home_win_prob": round(self.home_win_prob, 4),
            "draw_prob": round(self.draw_prob, 4),
            "away_win_prob": round(self.away_win_prob, 4),
            "shot_diff": self.shot_diff,
            "corner_diff": self.corner_diff,
            "goal_diff": self.goal_diff,
            "red_card_diff": self.red_card_diff,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
