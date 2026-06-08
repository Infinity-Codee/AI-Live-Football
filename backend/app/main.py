"""
FootAI Insight — FastAPI Backend
Main application entry point.
"""

import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routes.api import router as api_router
from app.models.database import init_db
from app.services.cache_service import cache

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown events."""
    # --- STARTUP ---
    logger.info("🚀 Starting FootAI Insight Backend...")

    # Initialize database tables
    await init_db()
    logger.info("✅ Database initialized")

    # Connect to Redis (falls back to in-memory)
    await cache.connect(settings.redis_url)

    if settings.has_api_key:
        # ── LIVE mode: a real API key is configured ──────────────────────
        logger.info("🟢 LIVE mode — using the real API-Football feed")
        try:
            from apscheduler.schedulers.asyncio import AsyncIOScheduler
            from app.services.scheduler import daily_sync, update_live_matches

            scheduler = AsyncIOScheduler()
            scheduler.add_job(daily_sync, "cron", hour=6, minute=0)
            scheduler.add_job(
                update_live_matches, "interval", minutes=settings.live_update_minutes
            )
            scheduler.start()
            logger.info(
                f"⏰ Scheduler started (daily sync + {settings.live_update_minutes}-min live update)"
            )
        except Exception as e:
            logger.warning(f"⚠️ Scheduler not started: {e}")

        # Run an initial sync so today's real matches are available immediately
        try:
            from app.services.scheduler import daily_sync
            await daily_sync()
        except Exception as e:
            logger.warning(f"⚠️ Initial sync failed: {e}")

        # Safety net: if no real matches could be fetched (daily API quota
        # exhausted, or genuinely no fixtures today), seed sample matches so the
        # app is never empty. Real matches replace these on the next sync.
        try:
            from sqlalchemy import select, func
            from app.models.match import Match
            from app.models.database import async_session
            from app.seed_mock_data import seed_mock_data, MOCK_MATCHES
            mock_ids = [m["fixture_id"] for m in MOCK_MATCHES]
            async with async_session() as db:
                real_count = (await db.execute(
                    select(func.count(Match.id)).where(Match.fixture_id.notin_(mock_ids))
                )).scalar() or 0
            if real_count == 0:
                # No real fixtures (off-season / quota exhausted). Seed FRESH
                # sample data — force=True replaces any stale/degraded mock rows
                # so the app always shows a clean, populated demo set. Real
                # matches replace these on the next successful sync.
                await seed_mock_data(force=True)
                logger.info("📦 No real matches available — refreshed clean sample data as a fallback")
        except Exception as e:
            logger.warning(f"⚠️ Fallback seed failed: {e}")
    else:
        # ── DEMO mode: no key → seed sample matches so the app is browsable ─
        logger.info("📦 DEMO mode (no API key) — serving clearly-labelled sample data")
        try:
            from app.seed_mock_data import seed_mock_data
            await seed_mock_data()
        except Exception as e:
            logger.warning(f"⚠️ Mock data seeding skipped: {e}")

    yield

    # --- SHUTDOWN ---
    logger.info("👋 Shutting down FootAI Insight Backend...")


app = FastAPI(
    title="FootAI Insight API",
    description="AI-Powered Football Match Analysis — Live predictions every 5 minutes",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS — allow all origins during development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api")


@app.get("/")
async def root():
    return {
        "app": "FootAI Insight",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs",
    }


@app.get("/health")
async def health():
    return {"status": "healthy"}

