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

    # Seed mock data if DB is empty
    try:
        from app.seed_mock_data import seed_mock_data
        await seed_mock_data()
    except Exception as e:
        logger.warning(f"⚠️ Mock data seeding skipped: {e}")

    # Connect to Redis (falls back to in-memory)
    await cache.connect(settings.redis_url)

    # Start scheduler for automated tasks (only if API keys are set)
    if settings.api_football_key != "YOUR_API_FOOTBALL_KEY_HERE":
        try:
            from apscheduler.schedulers.asyncio import AsyncIOScheduler
            from app.services.scheduler import daily_sync, update_live_matches

            scheduler = AsyncIOScheduler()
            scheduler.add_job(daily_sync, "cron", hour=6, minute=0)
            scheduler.add_job(update_live_matches, "interval", minutes=5)
            scheduler.start()
            logger.info("⏰ Scheduler started (daily sync + 5-min live update)")
        except Exception as e:
            logger.warning(f"⚠️ Scheduler not started: {e}")

        # Run initial sync
        try:
            from app.services.scheduler import daily_sync
            await daily_sync()
        except Exception:
            logger.warning("⚠️ Initial sync skipped (API key may not be set)")
    else:
        logger.info("📦 Running in mock/demo mode (no API keys configured)")

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

