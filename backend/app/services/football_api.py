"""
API-Football Service — fetches matches, live stats, and events.
Uses https://v3.football.api-sports.io
"""

import logging
from datetime import date
import httpx
from app.config import settings

logger = logging.getLogger(__name__)

# Status codes that mean a match is live
LIVE_STATUSES = {"1H", "HT", "2H", "ET", "P", "BT", "LIVE"}


class FootballApiService:
    """Client for API-Football v3."""

    def __init__(self):
        self.base_url = settings.api_football_base_url
        self.headers = {
            "x-apisports-key": settings.api_football_key,
        }

    async def _request(self, endpoint: str, params: dict = None) -> dict:
        """Make a GET request to API-Football."""
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(
                f"{self.base_url}/{endpoint}",
                headers=self.headers,
                params=params or {},
            )
            resp.raise_for_status()
            data = resp.json()
            return data

    async def fetch_today_matches(self, target_date: str = None) -> list[dict]:
        """
        Fetch all matches for today (or a given date).
        Returns list of match dicts.
        """
        if not target_date:
            target_date = date.today().isoformat()

        data = await self._request("fixtures", {"date": target_date})
        matches = []
        for item in data.get("response", []):
            fixture = item.get("fixture", {})
            league = item.get("league", {})

            # Only keep the leagues the app advertises (empty list = keep all).
            if settings.target_league_ids and league.get("id") not in settings.target_league_ids:
                continue

            teams = item.get("teams", {})
            goals = item.get("goals", {})
            status = fixture.get("status", {})

            matches.append({
                "fixture_id": fixture.get("id"),
                "league_name": league.get("name", ""),
                "league_id": league.get("id", 0),
                "league_logo": league.get("logo", ""),
                "country": league.get("country", ""),
                "home_team": teams.get("home", {}).get("name", ""),
                "away_team": teams.get("away", {}).get("name", ""),
                "home_logo": teams.get("home", {}).get("logo", ""),
                "away_logo": teams.get("away", {}).get("logo", ""),
                "status": status.get("short", "NS"),
                "elapsed": status.get("elapsed") or 0,
                "score_home": goals.get("home") or 0,
                "score_away": goals.get("away") or 0,
                "kick_off": fixture.get("date", ""),
                "tournament_type": 1 if league.get("type") == "Cup" else 0,
                "is_live": status.get("short", "") in LIVE_STATUSES,
            })
        logger.info(f"📡 Fetched {len(matches)} matches for {target_date}")
        return matches

    async def fetch_live_stats(self, fixture_id: int) -> dict:
        """
        Fetch live statistics for a specific match.
        Returns: {shots_home, shots_away, corners_home, corners_away, ...}
        """
        data = await self._request("fixtures/statistics", {"fixture": fixture_id})
        response = data.get("response", [])

        stats = {
            "shots_home": 0,
            "shots_away": 0,
            "corners_home": 0,
            "corners_away": 0,
            "red_cards_home": 0,
            "red_cards_away": 0,
            "extra": {},
        }

        if len(response) < 2:
            return stats

        for team_stats in response:
            is_home = response.index(team_stats) == 0
            prefix = "home" if is_home else "away"

            # Initialize dict for this team's extra stats
            stats["extra"][prefix] = {
                "possession": "0%",
                "fouls": 0,
                "yellow_cards": 0,
                "offsides": 0,
                "passes_pct": "0%",
                "expected_goals": "0.00",
            }

            for stat in team_stats.get("statistics", []):
                stat_type = stat.get("type", "")
                value = stat.get("value")
                if value is None:
                    value = 0

                # Core ML features
                if stat_type == "Total Shots":
                    stats[f"shots_{prefix}"] = int(value)
                elif stat_type == "Corner Kicks":
                    stats[f"corners_{prefix}"] = int(value)
                elif stat_type == "Red Cards":
                    stats[f"red_cards_{prefix}"] = int(value)

                # Advanced UI features
                elif stat_type == "Ball Possession":
                    stats["extra"][prefix]["possession"] = str(value)
                elif stat_type == "Fouls":
                    stats["extra"][prefix]["fouls"] = int(value)
                elif stat_type == "Yellow Cards":
                    stats["extra"][prefix]["yellow_cards"] = int(value)
                elif stat_type == "Offsides":
                    stats["extra"][prefix]["offsides"] = int(value)
                elif stat_type == "Passes %":
                    stats["extra"][prefix]["passes_pct"] = str(value)
                elif stat_type == "expected_goals":
                    stats["extra"][prefix]["expected_goals"] = str(value)

        return stats

    async def fetch_fixture_detail(self, fixture_id: int) -> dict | None:
        """Fetch a single fixture's current state."""
        data = await self._request("fixtures", {"id": fixture_id})
        response = data.get("response", [])
        if not response:
            return None

        item = response[0]
        fixture = item.get("fixture", {})
        teams = item.get("teams", {})
        goals = item.get("goals", {})
        status = fixture.get("status", {})

        return {
            "fixture_id": fixture.get("id"),
            "status": status.get("short", "NS"),
            "elapsed": status.get("elapsed") or 0,
            "score_home": goals.get("home") or 0,
            "score_away": goals.get("away") or 0,
            "is_live": status.get("short", "") in LIVE_STATUSES,
            "home_team": teams.get("home", {}).get("name", ""),
            "away_team": teams.get("away", {}).get("name", ""),
        }

    async def fetch_standings(self, league_id: int, season: int | None = None) -> list[dict]:
        """
        Fetch league standings. In the off-season the current season's table can
        be empty, so fall back to the previous season (which still has the final
        table) rather than showing nothing.
        """
        if season is None:
            season = settings.current_season
        result = await self._standings_for_season(league_id, season)
        if not result:
            result = await self._standings_for_season(league_id, season - 1)
        return result

    async def _standings_for_season(self, league_id: int, season: int) -> list[dict]:
        data = await self._request("standings", {
            "league": league_id,
            "season": season,
        })
        response = data.get("response", [])
        if not response:
            return []

        league_data = response[0].get("league", {})
        standings_groups = league_data.get("standings", [])
        if not standings_groups:
            return []

        result = []
        for group in standings_groups:
            for team in group:
                result.append({
                    "rank": team.get("rank", 0),
                    "team_name": team.get("team", {}).get("name", ""),
                    "team_logo": team.get("team", {}).get("logo", ""),
                    "points": team.get("points", 0),
                    "played": team.get("all", {}).get("played", 0),
                    "win": team.get("all", {}).get("win", 0),
                    "draw": team.get("all", {}).get("draw", 0),
                    "lose": team.get("all", {}).get("lose", 0),
                    "goals_for": team.get("all", {}).get("goals", {}).get("for", 0),
                    "goals_against": team.get("all", {}).get("goals", {}).get("against", 0),
                    "goal_diff": team.get("goalsDiff", 0),
                })
        return result


# Singleton
football_api = FootballApiService()
