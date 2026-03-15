"""
Prediction routes — live predictions and pre-match analysis.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.database import get_db
from app.models.match import Match
from app.models.prediction import Prediction
from app.services.cache_service import cache
from app.services.football_api import football_api
from app.services.odds_api import odds_api
from app.ml.model import predict, build_features
from app.config import settings

router = APIRouter(prefix="/predictions", tags=["Predictions"])


@router.get("/{match_id}/pre-match")
async def get_pre_match_prediction(match_id: int, db: AsyncSession = Depends(get_db)):
    """
    Free pre-match prediction based on odds only.
    Available before the match starts.
    """
    result = await db.execute(select(Match).where(Match.id == match_id))
    match = result.scalars().first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    # Build features with only pre-match data (no live stats)
    features = {
        "current_minute": 0,
        "tournament_type": match.tournament_type,
        "odd_h": match.odd_home or 2.5,
        "odd_d": match.odd_draw or 3.2,
        "odd_a": match.odd_away or 3.0,
        "goal_diff": 0,
        "shot_diff": 0,
        "corner_diff": 0,
        "red_card_diff": 0,
    }

    prediction = predict(features)
    return {
        "match_id": match_id,
        "type": "pre_match",
        "minute": 0,
        **prediction,
        "home_team": match.home_team,
        "away_team": match.away_team,
    }


@router.get("/{match_id}")
async def get_live_prediction(match_id: int, db: AsyncSession = Depends(get_db)):
    """
    Live prediction — requires credit.
    Results are cached for 5 minutes (saves API budget).
    """
    result = await db.execute(select(Match).where(Match.id == match_id))
    match = result.scalars().first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    # Check cache first (saves API calls for all subsequent users)
    cache_key = f"prediction:{match.fixture_id}"
    cached = await cache.get(cache_key)
    if cached:
        return cached

    # Fetch latest live stats from API-Football
    try:
        stats = await football_api.fetch_live_stats(match.fixture_id)
        detail = await football_api.fetch_fixture_detail(match.fixture_id)

        if detail:
            match.status = detail["status"]
            match.elapsed = detail["elapsed"]
            match.score_home = detail["score_home"]
            match.score_away = detail["score_away"]
            match.is_live = detail["is_live"]

        # Fetch latest live odds and align them via fuzzy search
        live_odds = await odds_api.fetch_soccer_odds()
        matched_odds = odds_api.match_odds_to_teams(live_odds, match.home_team, match.away_team)
        if matched_odds:
            match.odd_home = matched_odds["odd_home"]
            match.odd_draw = matched_odds["odd_draw"]
            match.odd_away = matched_odds["odd_away"]

        match.shots_home = stats["shots_home"]
        match.shots_away = stats["shots_away"]
        match.corners_home = stats["corners_home"]
        match.corners_away = stats["corners_away"]
        match.red_cards_home = stats["red_cards_home"]
        match.red_cards_away = stats["red_cards_away"]
        match.extra_stats = stats.get("extra", {})
        await db.commit()
    except Exception:
        pass  # Use existing DB data if API fails

    # Handle time edge cases for the ML model
    elapsed_for_model = match.elapsed or 0
    if match.status == "ET":
        elapsed_for_model = 0
    elif elapsed_for_model > 90:
        elapsed_for_model = 90

    # Build features from latest data
    features = build_features({
        "elapsed": elapsed_for_model,
        "tournament_type": match.tournament_type,
        "odd_home": match.odd_home,
        "odd_draw": match.odd_draw,
        "odd_away": match.odd_away,
        "score_home": match.score_home,
        "score_away": match.score_away,
        "shots_home": match.shots_home,
        "shots_away": match.shots_away,
        "corners_home": match.corners_home,
        "corners_away": match.corners_away,
        "red_cards_home": match.red_cards_home,
        "red_cards_away": match.red_cards_away,
    })

    # Get prediction
    prediction_result = predict(features)

    # Save to DB
    pred = Prediction(
        match_id=match.id,
        minute=match.elapsed,
        home_win_prob=prediction_result["home_win_prob"],
        draw_prob=prediction_result["draw_prob"],
        away_win_prob=prediction_result["away_win_prob"],
        shot_diff=features["shot_diff"],
        corner_diff=features["corner_diff"],
        goal_diff=features["goal_diff"],
        red_card_diff=features["red_card_diff"],
    )
    db.add(pred)
    await db.commit()

    response = {
        "match_id": match_id,
        "type": "live",
        "minute": match.elapsed,
        **prediction_result,
        "home_team": match.home_team,
        "away_team": match.away_team,
        "score": f"{match.score_home} - {match.score_away}",
        "stats": {
            "shots_home": match.shots_home,
            "shots_away": match.shots_away,
            "corners_home": match.corners_home,
            "corners_away": match.corners_away,
            "red_cards_home": match.red_cards_home,
            "red_cards_away": match.red_cards_away,
            "extra": match.extra_stats or {},
        },
    }

    # Cache for 5 minutes
    await cache.set(cache_key, response, settings.prediction_cache_ttl)
    return response


@router.get("/{match_id}/history")
async def get_prediction_history(match_id: int, db: AsyncSession = Depends(get_db)):
    """
    Get all predictions made for a match (momentum timeline).
    Used to draw the momentum chart in the app.
    """
    result = await db.execute(
        select(Prediction)
        .where(Prediction.match_id == match_id)
        .order_by(Prediction.minute)
    )
    predictions = result.scalars().all()
    return {
        "match_id": match_id,
        "history": [p.to_dict() for p in predictions],
    }
