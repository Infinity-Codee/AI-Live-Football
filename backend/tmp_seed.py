import asyncio
import logging
from app.config import settings
from app.services.football_api import football_api
from app.models.database import get_db, async_session
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.match import Match
from sqlalchemy import select
import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def fetch_real_matches():
    logger.info(f"Using Football API Key: {settings.api_football_key[:5]}...")
    async with async_session() as db:
        today_start = datetime.datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        today_end = today_start + datetime.timedelta(days=1)
        
        try:
            logger.info("Fetching real matches from API...")
            raw_matches = await football_api.fetch_today_matches()
            logger.info(f"API Returned {len(raw_matches)} matches after filtering.")
            
            for m in raw_matches:
                existing = await db.execute(select(Match).where(Match.fixture_id == m["fixture_id"]))
                if not existing.scalars().first():
                    match = Match(
                        fixture_id=m["fixture_id"],
                        league_name=m["league_name"],
                        league_id=m["league_id"],
                        league_logo=m["league_logo"],
                        country=m["country"],
                        home_team=m["home_team"],
                        away_team=m["away_team"],
                        home_logo=m["home_logo"],
                        away_logo=m["away_logo"],
                        status=m["status"],
                        elapsed=m["elapsed"],
                        score_home=m["score_home"],
                        score_away=m["score_away"],
                        kick_off=datetime.datetime.fromisoformat(
                            m["kick_off"].replace("Z", "+00:00")
                        ).replace(tzinfo=None) if m["kick_off"] else datetime.datetime.utcnow(),
                        tournament_type=m["tournament_type"],
                        is_live=m["is_live"],
                    )
                    db.add(match)
            await db.commit()
            
            result = await db.execute(
                select(Match).where(
                    Match.kick_off >= today_start,
                    Match.kick_off < today_end,
                ).order_by(Match.kick_off)
            )
            matches = result.scalars().all()
            logger.info(f"Successfully saved {len(matches)} real matches to PostgreSQL!")
            
        except Exception as e:
            logger.error(f"Failed to fetch matches: {e}")

if __name__ == "__main__":
    asyncio.run(fetch_real_matches())
