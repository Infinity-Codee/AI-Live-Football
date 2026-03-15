"""
Mock routes — manual triggers for seeding and testing the ML model.
"""

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.database import get_db
from app.models.match import Match
from app.ml.model import predict, build_features
from app.seed_mock_data import seed_mock_data

router = APIRouter(prefix="/mock", tags=["Mock / Testing"])


@router.get("/seed")
async def trigger_seed():
    """Manually trigger mock data seeding."""
    seeded = await seed_mock_data()
    if seeded:
        return {"status": "success", "message": "Mock data seeded successfully"}
    return {"status": "skipped", "message": "Database already has data"}


@router.get("/test-model")
async def test_model_all(db: AsyncSession = Depends(get_db)):
    """Run ML predictions on all matches in the database."""
    result = await db.execute(select(Match).order_by(Match.id))
    matches = result.scalars().all()

    predictions = []
    for match in matches:
        features = build_features({
            "elapsed": match.elapsed,
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

        pred = predict(features)

        predictions.append({
            "match_id": match.id,
            "home_team": match.home_team,
            "away_team": match.away_team,
            "score": f"{match.score_home} - {match.score_away}",
            "status": match.status,
            "minute": match.elapsed,
            "features": features,
            **pred,
        })

    return {
        "total_matches": len(predictions),
        "predictions": predictions,
    }
