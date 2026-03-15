from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase
from app.config import settings

engine = create_async_engine(settings.database_url, echo=settings.debug)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncSession:
    """Dependency: yields an async database session."""
    async with async_session() as session:
        yield session


async def init_db():
    """Create all tables on startup."""
    async with engine.begin() as conn:
        from app.models.match import Match  # noqa: F401
        from app.models.prediction import Prediction  # noqa: F401
        from app.models.user import User  # noqa: F401
        from app.models.credit_transaction import CreditTransaction  # noqa: F401
        await conn.run_sync(Base.metadata.create_all)
