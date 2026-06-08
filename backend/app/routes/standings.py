"""
Standings routes — league tables.
"""

from fastapi import APIRouter, HTTPException
from app.services.cache_service import cache
from app.services.football_api import football_api
from app.mock_standings import get_mock_standings
from app.config import settings

router = APIRouter(prefix="/standings", tags=["Standings"])


@router.get("/{league_id}")
async def get_standings(league_id: int, season: int | None = None):
    """Get league standings (defaults to the current season)."""
    if season is None:
        season = settings.current_season

    # In demo mode (no API key) always serve the sample tables.
    if not settings.has_api_key:
        return {"standings": get_mock_standings(league_id), "demo": True}

    cache_key = f"standings:{league_id}:{season}"
    cached = await cache.get(cache_key)
    if cached:
        return {"standings": cached}

    try:
        standings = await football_api.fetch_standings(league_id, season)
        # Only cache real data — never cache an empty result (e.g. when the daily
        # API quota is temporarily exhausted) so the next request retries.
        if standings:
            await cache.set(cache_key, standings, 3600)  # Cache 1 hour
            return {"standings": standings}
        # Live fetch came back empty (quota exhausted, or off-season with no
        # table). Fall back to sample tables so the screen is never blank.
        mock = get_mock_standings(league_id)
        return {"standings": mock, "demo": True} if mock else {"standings": []}
    except HTTPException:
        raise
    except Exception as e:
        # On any API error, still try to serve sample tables rather than 502.
        mock = get_mock_standings(league_id)
        if mock:
            return {"standings": mock, "demo": True}
        raise HTTPException(status_code=502, detail=f"API error: {str(e)}")
