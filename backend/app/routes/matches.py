"""
Matches routes — today's matches, match details, live stats.
"""

import datetime
import logging
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.database import get_db
from app.models.match import Match
from app.services.cache_service import cache
from app.services.football_api import football_api
from app.config import settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/matches", tags=["Matches"])


@router.get("/today")
async def get_today_matches(db: AsyncSession = Depends(get_db)):
    """Get all matches for today, grouped by league."""
    # Check cache first
    cached = await cache.get("matches:today")
    if cached:
        return {"matches": cached, "demo": not settings.has_api_key}

    # Query DB
    today_start = datetime.datetime.utcnow().replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    today_end = today_start + datetime.timedelta(days=1)

    result = await db.execute(
        select(Match).where(
            Match.kick_off >= today_start,
            Match.kick_off < today_end,
        ).order_by(Match.kick_off)
    )
    matches = result.scalars().all()

    if not matches:
        # If no matches in DB, try fetching from API
        try:
            raw_matches = await football_api.fetch_today_matches()
            for m in raw_matches:
                existing = await db.execute(
                    select(Match).where(Match.fixture_id == m["fixture_id"])
                )
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
        except Exception:
            pass

    # Group by league
    leagues = {}
    for m in matches:
        league = m.league_name or "Other"
        if league not in leagues:
            leagues[league] = {
                "league_name": league,
                "league_logo": m.league_logo,
                "country": m.country,
                "matches": [],
            }
        leagues[league]["matches"].append(m.to_dict())

    data = list(leagues.values())
    await cache.set("matches:today", data, settings.matches_cache_ttl)
    return {"matches": data, "demo": not settings.has_api_key}


@router.get("/{match_id}")
async def get_match_detail(match_id: int, db: AsyncSession = Depends(get_db)):
    """Get details of a specific match."""
    result = await db.execute(select(Match).where(Match.id == match_id))
    match = result.scalars().first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    return match.to_dict()


@router.get("/{match_id}/live-stats")
async def get_live_stats(match_id: int, db: AsyncSession = Depends(get_db)):
    """Get live statistics for a specific match (from API-Football)."""
    result = await db.execute(select(Match).where(Match.id == match_id))
    match = result.scalars().first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    cache_key = f"live_stats:{match.fixture_id}"
    cached = await cache.get(cache_key)
    if cached:
        return cached

    try:
        stats = await football_api.fetch_live_stats(match.fixture_id)
        # Update match in DB
        match.shots_home = stats["shots_home"]
        match.shots_away = stats["shots_away"]
        match.corners_home = stats["corners_home"]
        match.corners_away = stats["corners_away"]
        match.red_cards_home = stats["red_cards_home"]
        match.red_cards_away = stats["red_cards_away"]

        # Also update status
        detail = await football_api.fetch_fixture_detail(match.fixture_id)
        if detail:
            match.status = detail["status"]
            match.elapsed = detail["elapsed"]
            match.score_home = detail["score_home"]
            match.score_away = detail["score_away"]
            match.is_live = detail["is_live"]

        await db.commit()
        await db.refresh(match)

        response = match.to_dict()
        await cache.set(cache_key, response, 60)  # Cache 1 minute
        return response
    except Exception as e:
        # On API failure (quota/timeout) serve the last-known DB data instead of
        # a 502, so the match screen still renders rather than showing an error.
        logger.warning(f"live-stats API failed for {match.fixture_id}, serving last-known: {e}")
        return match.to_dict()
