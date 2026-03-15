import asyncio
import logging
from app.config import settings
from app.services.football_api import football_api

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_stats():
    # Looking at the logs, 1379268 or 1391096 were updated
    fixture_id = 1391096
    
    print(f"Fetching raw data for {fixture_id}...")
    data = await football_api._request("fixtures/statistics", {"fixture": fixture_id})
    print("RAW DATA:")
    import json
    print(json.dumps(data, indent=2))

    print("\nPARSED DATA:")
    stats = await football_api.fetch_live_stats(fixture_id)
    print(json.dumps(stats, indent=2))

if __name__ == "__main__":
    asyncio.run(test_stats())
