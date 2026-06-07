from datetime import date

from pydantic_settings import BaseSettings

# Placeholder values that mean "no real key configured yet".
_PLACEHOLDER_KEYS = {"", "YOUR_API_FOOTBALL_KEY_HERE", "YOUR_ODDS_API_KEY_HERE"}


class Settings(BaseSettings):
    # App
    app_name: str = "FootAI_Insight"
    debug: bool = True

    # Database
    # Default to a local async SQLite file so `uvicorn app.main:app` works out of
    # the box (matches the committed footai.db and the mobile localhost base URL).
    # docker-compose overrides this with the Postgres URL via the DATABASE_URL env.
    database_url: str = "sqlite+aiosqlite:///./footai.db"

    # Redis (Docker service)
    redis_url: str = "redis://redis:6379/0"

    # API-Football
    api_football_key: str = "YOUR_API_FOOTBALL_KEY_HERE"
    api_football_base_url: str = "https://v3.football.api-sports.io"

    # The Odds API
    odds_api_key: str = "YOUR_ODDS_API_KEY_HERE"
    odds_api_base_url: str = "https://api.the-odds-api.com/v4"

    # Credits
    initial_free_credits: int = 3
    credits_per_ad: int = 1
    credits_per_match: int = 1

    # Cache TTL (seconds)
    prediction_cache_ttl: int = 300
    matches_cache_ttl: int = 60

    # Data ingestion
    # League ids to fetch from the real API (empty list = no filter, fetch all).
    # Defaults to the leagues the app advertises in AppConstants.popularLeagues.
    target_league_ids: list[int] = [39, 140, 307, 203, 135, 78, 61, 2, 3]
    # How often the scheduler refreshes live matches. Kept gentle so the free
    # API tier (100 requests/day) is not exhausted.
    live_update_minutes: int = 10

    # ML
    # The shipped .pkl was bypassed because its class order produced wrong
    # results; the reliable odds+stats engine is used by default. Flip this to
    # True only after verifying the model's output mapping.
    use_ml_model: bool = False

    class Config:
        env_file = ".env"

    @property
    def has_api_key(self) -> bool:
        """True when a real API-Football key has been configured."""
        return self.api_football_key not in _PLACEHOLDER_KEYS

    @property
    def has_odds_key(self) -> bool:
        """True when a real Odds API key has been configured."""
        return self.odds_api_key not in _PLACEHOLDER_KEYS

    @property
    def current_season(self) -> int:
        """Starting year of the current football season (api-football convention)."""
        today = date.today()
        return today.year if today.month >= 7 else today.year - 1


settings = Settings()
