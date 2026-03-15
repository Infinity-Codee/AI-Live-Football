from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # App
    app_name: str = "FootAI_Insight"
    debug: bool = True

    # Database (PostgreSQL in Docker)
    database_url: str = "postgresql+asyncpg://footai:footai_pass@postgres:5432/footai_db"

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

    class Config:
        env_file = ".env"


settings = Settings()
