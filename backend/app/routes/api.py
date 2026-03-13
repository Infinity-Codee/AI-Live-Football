from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def health_check():
    return {"status": "ok"}


@router.get("/matches")
async def get_matches():
    return {
        "matches": [
            {
                "id": 1,
                "home": "Real Madrid",
                "away": "Barcelona",
                "status": "live",
            }
        ]
    }
