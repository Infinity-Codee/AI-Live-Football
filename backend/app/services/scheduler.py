"""
Scheduler — automated tasks for data sync.
- Daily: fetch all today's matches + odds
- Every 5 min: update live match stats
- Post-match: archive finished matches
"""

import logging
import datetime
from sqlalchemy import select, delete, or_, and_
from app.models.database import async_session
from app.models.match import Match
from app.services.football_api import football_api, LIVE_STATUSES
from app.services.odds_api import odds_api
from app.services.cache_service import cache

logger = logging.getLogger(__name__)

# Statuses that won't change again today — skip them in the live updater so we
# only re-poll matches that are live or could still go live.
_NO_POLL_STATUSES = ("FT", "AET", "PEN", "CANC", "ABD", "AWD", "WO", "PST", "TBD")


async def daily_sync():
    """
    Runs at 06:00 AM daily.
    Fetches all today's matches + their odds and stores in DB.
    """
    logger.info("🌅 Daily Sync started...")
    try:
        # 1. Fetch today's matches
        matches = await football_api.fetch_today_matches()
        logger.info(f"📡 Got {len(matches)} matches from API")

        # 2. Fetch odds for the day
        try:
            odds_list = await odds_api.fetch_soccer_odds()
        except Exception:
            odds_list = []
            logger.warning("⚠️ Could not fetch odds")

        # 3. Store in DB
        async with async_session() as db:
            for m in matches:
                result = await db.execute(
                    select(Match).where(Match.fixture_id == m["fixture_id"])
                )
                existing = result.scalars().first()

                # Match odds to teams
                matched_odds = odds_api.match_odds_to_teams(
                    odds_list, m["home_team"], m["away_team"]
                )

                if existing:
                    # Update existing match
                    existing.status = m["status"]
                    existing.elapsed = m["elapsed"]
                    existing.score_home = m["score_home"]
                    existing.score_away = m["score_away"]
                    existing.is_live = m["is_live"]
                    if matched_odds:
                        existing.odd_home = matched_odds["odd_home"]
                        existing.odd_draw = matched_odds["odd_draw"]
                        existing.odd_away = matched_odds["odd_away"]
                else:
                    # Create new match
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
                        odd_home=matched_odds["odd_home"] if matched_odds else 0,
                        odd_draw=matched_odds["odd_draw"] if matched_odds else 0,
                        odd_away=matched_odds["odd_away"] if matched_odds else 0,
                    )
                    db.add(match)

            # Once real fixtures are available, drop the sample/fallback rows so
            # real and demo matches never appear together in the app.
            if matches:
                from app.seed_mock_data import MOCK_MATCHES
                mock_ids = [mm["fixture_id"] for mm in MOCK_MATCHES]
                real_ids = {m["fixture_id"] for m in matches}
                stale_mock_ids = [mid for mid in mock_ids if mid not in real_ids]
                if stale_mock_ids:
                    await db.execute(
                        delete(Match).where(Match.fixture_id.in_(stale_mock_ids))
                    )
                    logger.info(f"🧹 Removed {len(stale_mock_ids)} sample rows (real fixtures available)")

            await db.commit()

        # Clear cache so new data is served
        await cache.delete("matches:today")
        logger.info("✅ Daily Sync completed!")
    except Exception as e:
        logger.error(f"❌ Daily Sync failed: {e}")


async def update_live_matches():
    """
    Runs on the live-update interval. Refreshes status/score/stats for matches
    that are live OR have just kicked off, so NS -> live -> FT transitions are
    picked up during the day (not only at the 06:00 daily sync). Without this, a
    match that starts after the daily sync would stay stuck on "not started".
    """
    logger.info("🔄 Updating live matches...")
    try:
        async with async_session() as db:
            now = datetime.datetime.utcnow()
            window_start = now - datetime.timedelta(hours=4)
            result = await db.execute(
                select(Match).where(
                    Match.status.notin_(_NO_POLL_STATUSES),
                    or_(
                        Match.is_live == True,  # noqa: E712
                        and_(Match.kick_off <= now, Match.kick_off >= window_start),
                    ),
                )
            )
            live_matches = result.scalars().all()

            for match in live_matches:
                try:
                    # Fetch latest detail
                    detail = await football_api.fetch_fixture_detail(match.fixture_id)
                    if detail:
                        match.status = detail["status"]
                        match.elapsed = detail["elapsed"]
                        match.score_home = detail["score_home"]
                        match.score_away = detail["score_away"]
                        match.is_live = detail["is_live"]

                        # If match ended, mark as not live
                        if detail["status"] in {"FT", "AET", "PEN"}:
                            match.is_live = False

                    # Only pull live stats for matches that are actually live now —
                    # keeps API usage bounded (just-kicked-off NS fixtures cost a
                    # single status call). Still guarded so a None result never
                    # zeroes existing values.
                    if match.is_live:
                        stats = await football_api.fetch_live_stats(match.fixture_id)
                        if stats:
                            match.shots_home = stats["shots_home"]
                            match.shots_away = stats["shots_away"]
                            match.corners_home = stats["corners_home"]
                            match.corners_away = stats["corners_away"]
                            match.red_cards_home = stats["red_cards_home"]
                            match.red_cards_away = stats["red_cards_away"]

                    # Invalidate cache for this match
                    await cache.delete(f"prediction:{match.fixture_id}")
                    await cache.delete(f"live_stats:{match.fixture_id}")

                except Exception as e:
                    logger.error(f"Error updating match {match.fixture_id}: {e}")

            await db.commit()

        # Also invalidate today's matches cache
        await cache.delete("matches:today")
        logger.info(f"✅ Updated {len(live_matches)} live matches")
    except Exception as e:
        logger.error(f"❌ Live update failed: {e}")
