"""
The Odds API Service — fetches pre-match betting odds.
Uses https://api.the-odds-api.com/v4
"""

import logging
import httpx
from app.config import settings

logger = logging.getLogger(__name__)


class OddsApiService:
    """Client for The Odds API v4."""

    def __init__(self):
        self.base_url = settings.odds_api_base_url
        self.api_key = settings.odds_api_key

    async def _fetch_sport_odds(self, sport_key: str) -> list[dict]:
        """Fetch odds for a specific The Odds API sport key."""
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                resp = await client.get(
                    f"{self.base_url}/sports/{sport_key}/odds",
                    params={
                        "apiKey": self.api_key,
                        "regions": "eu",
                        "markets": "h2h",
                        "oddsFormat": "decimal",
                    },
                )
                resp.raise_for_status()
                return resp.json()
        except Exception as e:
            logger.error(f"❌ Odds API error for {sport_key}: {e}")
            return []

    async def fetch_soccer_odds(self, sport: str | None = None) -> list[dict]:
        """
        Fetch upcoming odds.
        Default behavior is focused on EPL + La Liga since the app's
        Football API feed is currently filtered to those leagues.
        Returns list of dicts with home/draw/away odds.
        """
        if sport:
            sport_keys = [sport]
        else:
            sport_keys = ["soccer_epl", "soccer_spain_la_liga"]

        data: list[dict] = []
        for sport_key in sport_keys:
            payload = await self._fetch_sport_odds(sport_key)
            data.extend(payload)

        result = []
        for event in data:
            odds = self._extract_best_odds(event)
            if odds:
                result.append({
                    "home_team": event.get("home_team", ""),
                    "away_team": event.get("away_team", ""),
                    "commence_time": event.get("commence_time", ""),
                    "odd_home": odds["home"],
                    "odd_draw": odds["draw"],
                    "odd_away": odds["away"],
                })

        logger.info(f"📊 Fetched odds for {len(result)} events from {sport_keys}")
        return result

    def _extract_best_odds(self, event: dict) -> dict | None:
        """Extract the first available h2h odds from bookmakers."""
        bookmakers = event.get("bookmakers", [])
        if not bookmakers:
            return None

        for bm in bookmakers:
            markets = bm.get("markets", [])
            for market in markets:
                if market.get("key") != "h2h":
                    continue
                outcomes = market.get("outcomes", [])
                odds = {}
                for outcome in outcomes:
                    name = outcome.get("name", "")
                    price = outcome.get("price", 0)
                    if name == event.get("home_team"):
                        odds["home"] = price
                    elif name == event.get("away_team"):
                        odds["away"] = price
                    elif name == "Draw":
                        odds["draw"] = price
                if len(odds) == 3:
                    return odds
        return None

    def match_odds_to_teams(
        self, odds_list: list[dict], home_team: str, away_team: str
    ) -> dict | None:
        """
        Find the odds for a specific match by fuzzy team-name matching.
        Returns {odd_home, odd_draw, odd_away} or None.
        """
        home_lower = home_team.lower()
        away_lower = away_team.lower()

        for odds in odds_list:
            oh = odds["home_team"].lower()
            oa = odds["away_team"].lower()
            # Check if the names overlap
            if (home_lower in oh or oh in home_lower) and (
                away_lower in oa or oa in away_lower
            ):
                return {
                    "odd_home": odds["odd_home"],
                    "odd_draw": odds["odd_draw"],
                    "odd_away": odds["odd_away"],
                }
        return None


# Singleton
odds_api = OddsApiService()
