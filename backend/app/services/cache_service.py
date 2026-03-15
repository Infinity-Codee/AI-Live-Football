"""
Cache Service — Redis with in-memory fallback.
Stores prediction results for 5 minutes to serve thousands of users
from one API-Football call.
"""

import json
import time
import logging
from typing import Any

logger = logging.getLogger(__name__)

# ── In-memory fallback cache ────────────────────────────────────────
_memory_cache: dict[str, tuple[Any, float]] = {}


class CacheService:
    """Unified cache: tries Redis first, falls back to dict."""

    def __init__(self):
        self._redis = None

    async def connect(self, redis_url: str):
        """Try to connect to Redis. If it fails, use memory cache."""
        try:
            import redis.asyncio as aioredis
            self._redis = aioredis.from_url(redis_url, decode_responses=True)
            await self._redis.ping()
            logger.info("✅ Redis connected")
        except Exception as e:
            logger.warning(f"⚠️ Redis unavailable ({e}), using in-memory cache")
            self._redis = None

    async def get(self, key: str) -> Any | None:
        """Get cached value by key."""
        # Try Redis first
        if self._redis:
            try:
                val = await self._redis.get(key)
                if val:
                    return json.loads(val)
            except Exception:
                pass

        # Fallback: in-memory
        if key in _memory_cache:
            value, expire_at = _memory_cache[key]
            if time.time() < expire_at:
                return value
            else:
                del _memory_cache[key]
        return None

    async def set(self, key: str, value: Any, ttl: int = 300):
        """Set cached value with TTL (default 5 minutes)."""
        # Try Redis
        if self._redis:
            try:
                await self._redis.set(key, json.dumps(value), ex=ttl)
                return
            except Exception:
                pass

        # Fallback: in-memory
        _memory_cache[key] = (value, time.time() + ttl)

    async def delete(self, key: str):
        """Invalidate a cached key."""
        if self._redis:
            try:
                await self._redis.delete(key)
            except Exception:
                pass
        _memory_cache.pop(key, None)

    async def clear_pattern(self, pattern: str):
        """Clear all keys matching pattern (Redis only)."""
        if self._redis:
            try:
                keys = []
                async for key in self._redis.scan_iter(match=pattern):
                    keys.append(key)
                if keys:
                    await self._redis.delete(*keys)
            except Exception:
                pass


# Singleton
cache = CacheService()
