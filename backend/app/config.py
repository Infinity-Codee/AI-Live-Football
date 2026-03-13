from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "LiveFootballAIDetection"
    debug: bool = True
    database_url: str = "sqlite:///./app.db"

    class Config:
        env_file = ".env"


settings = Settings()
