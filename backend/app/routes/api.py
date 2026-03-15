"""
Main API router — includes all sub-routers.
"""

from fastapi import APIRouter
from app.routes.matches import router as matches_router
from app.routes.predictions import router as predictions_router
from app.routes.wallet import router as wallet_router
from app.routes.billing import router as billing_router
from app.routes.events import router as events_router
from app.routes.standings import router as standings_router
from app.routes.mock import router as mock_router

router = APIRouter()

router.include_router(matches_router)
router.include_router(predictions_router)
router.include_router(wallet_router)
router.include_router(billing_router)
router.include_router(events_router)
router.include_router(standings_router)
router.include_router(mock_router)
