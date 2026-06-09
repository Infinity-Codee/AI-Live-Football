import datetime
from sqlalchemy import String, Integer, Float, DateTime, Boolean, JSON
from sqlalchemy.orm import Mapped, mapped_column
from app.models.database import Base


class Match(Base):
    __tablename__ = "matches"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    fixture_id: Mapped[int] = mapped_column(Integer, unique=True, index=True)

    # League info
    league_name: Mapped[str] = mapped_column(String(200), default="")
    league_id: Mapped[int] = mapped_column(Integer, default=0)
    league_logo: Mapped[str] = mapped_column(String(500), default="")
    country: Mapped[str] = mapped_column(String(100), default="")

    # Teams
    home_team: Mapped[str] = mapped_column(String(200), default="")
    away_team: Mapped[str] = mapped_column(String(200), default="")
    home_logo: Mapped[str] = mapped_column(String(500), default="")
    away_logo: Mapped[str] = mapped_column(String(500), default="")

    # Status: NS (not started), 1H, HT, 2H, FT, etc.
    status: Mapped[str] = mapped_column(String(10), default="NS")
    elapsed: Mapped[int] = mapped_column(Integer, default=0)

    # Score
    score_home: Mapped[int] = mapped_column(Integer, default=0)
    score_away: Mapped[int] = mapped_column(Integer, default=0)

    # Kick-off time (UTC)
    kick_off: Mapped[datetime.datetime] = mapped_column(
        DateTime, default=datetime.datetime.utcnow
    )

    # Odds (pre-match)
    odd_home: Mapped[float] = mapped_column(Float, default=0.0)
    odd_draw: Mapped[float] = mapped_column(Float, default=0.0)
    odd_away: Mapped[float] = mapped_column(Float, default=0.0)

    # Tournament type: 0 = league, 1 = cup
    tournament_type: Mapped[int] = mapped_column(Integer, default=0)

    # Live stats (updated during match)
    shots_home: Mapped[int] = mapped_column(Integer, default=0)
    shots_away: Mapped[int] = mapped_column(Integer, default=0)
    corners_home: Mapped[int] = mapped_column(Integer, default=0)
    corners_away: Mapped[int] = mapped_column(Integer, default=0)
    red_cards_home: Mapped[int] = mapped_column(Integer, default=0)
    red_cards_away: Mapped[int] = mapped_column(Integer, default=0)

    # Is it currently live?
    is_live: Mapped[bool] = mapped_column(Boolean, default=False)

    # Extra metrics (Possession, Fouls, Yellow Cards, Offsides, etc.)
    extra_stats: Mapped[dict] = mapped_column(JSON, default=dict)

    created_at: Mapped[datetime.datetime] = mapped_column(
        DateTime, default=datetime.datetime.utcnow
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "fixture_id": self.fixture_id,
            "league_name": self.league_name,
            "league_id": self.league_id,
            "league_logo": self.league_logo,
            "country": self.country,
            "home_team": self.home_team,
            "away_team": self.away_team,
            "home_logo": self.home_logo,
            "away_logo": self.away_logo,
            "status": self.status,
            "elapsed": self.elapsed,
            "score_home": self.score_home,
            "score_away": self.score_away,
            # Stamp the stored (naive UTC) kick-off with an explicit UTC marker so
            # clients parse it as UTC and convert to local time correctly. Without
            # the marker the app reads UTC as local and shows times 3h early.
            "kick_off": self.kick_off.replace(tzinfo=datetime.timezone.utc).isoformat() if self.kick_off else None,
            "odd_home": self.odd_home,
            "odd_draw": self.odd_draw,
            "odd_away": self.odd_away,
            "tournament_type": self.tournament_type,
            "shots_home": self.shots_home,
            "shots_away": self.shots_away,
            "corners_home": self.corners_home,
            "corners_away": self.corners_away,
            "red_cards_home": self.red_cards_home,
            "red_cards_away": self.red_cards_away,
            "extra_stats": self.extra_stats or {},
            "is_live": self.is_live,
        }
