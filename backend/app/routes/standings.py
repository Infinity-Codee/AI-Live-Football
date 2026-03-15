"""
Standings routes — league tables.
"""

from fastapi import APIRouter, HTTPException
from app.services.cache_service import cache
from app.services.football_api import football_api
from app.mock_standings import get_mock_standings

router = APIRouter(prefix="/standings", tags=["Standings"])


@router.get("/{league_id}")
async def get_standings(league_id: int, season: int = 2024):
    """Get league standings."""
    cache_key = f"standings:{league_id}:{season}"
    cached = await cache.get(cache_key)
    if cached:
        return {"standings": cached}

    try:
        standings = await football_api.fetch_standings(league_id, season)
        if not standings:
            # Fallback to mock data for demonstration
            standings = get_mock_standings(league_id)
            if not standings:
                raise HTTPException(status_code=404, detail="No standings found")

        await cache.set(cache_key, standings, 3600)  # Cache 1 hour
        return {"standings": standings}
    except HTTPException:
        raise
    except Exception as e:
        # Fallback to mock data if API limits hit or other errors
        standings = get_mock_standings(league_id)
        if standings:
            return {"standings": standings}
        raise HTTPException(status_code=502, detail=f"API error: {str(e)}")
