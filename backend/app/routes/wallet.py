"""
Wallet routes — credit management, ad rewards, and spending.
"""

import datetime
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.database import get_db
from app.models.user import User
from app.models.credit_transaction import CreditTransaction
from app.config import settings

router = APIRouter(prefix="/wallet", tags=["Wallet"])


class RegisterRequest(BaseModel):
    device_id: str


class SpendRequest(BaseModel):
    device_id: str
    match_id: int


class RewardRequest(BaseModel):
    device_id: str


@router.post("/register")
async def register_device(req: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """Register a new device. Gives initial free credits."""
    result = await db.execute(select(User).where(User.device_id == req.device_id))
    user = result.scalars().first()

    if user:
        # Already registered
        return {
            "status": "existing",
            "credits": user.credits,
            "device_id": user.device_id,
            "is_pro": user.is_pro,
        }

    # Create new user
    user = User(
        device_id=req.device_id,
        credits=settings.initial_free_credits,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    return {
        "status": "new",
        "credits": user.credits,
        "device_id": user.device_id,
        "is_pro": user.is_pro,
    }


@router.get("/balance")
async def get_balance(device_id: str, db: AsyncSession = Depends(get_db)):
    """Get current credit balance."""
    result = await db.execute(select(User).where(User.device_id == device_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found. Register first.")

    return {
        "credits": user.credits,
        "total_ads_watched": user.total_ads_watched,
        "is_pro": user.is_pro,
        "pro_expires_at": user.pro_expires_at.isoformat() if user.pro_expires_at else None,
    }


@router.post("/reward")
async def add_reward(req: RewardRequest, db: AsyncSession = Depends(get_db)):
    """Add 1 credit after watching a rewarded ad."""
    result = await db.execute(select(User).where(User.device_id == req.device_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.credits += settings.credits_per_ad
    user.total_ads_watched += 1
    user.last_active = datetime.datetime.utcnow()

    # Log transaction
    txn = CreditTransaction(
        user_id=user.id,
        amount=settings.credits_per_ad,
        type="ad_reward",
    )
    db.add(txn)
    await db.commit()

    return {
        "credits": user.credits,
        "message": f"+{settings.credits_per_ad} credit added!",
    }


@router.post("/spend")
async def spend_credit(req: SpendRequest, db: AsyncSession = Depends(get_db)):
    """Spend 1 credit to unlock a match's live predictions."""
    result = await db.execute(select(User).where(User.device_id == req.device_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if already unlocked this match
    existing_spend = await db.execute(
        select(CreditTransaction).where(
            CreditTransaction.user_id == user.id,
            CreditTransaction.match_id == req.match_id,
            CreditTransaction.type == "match_unlock",
        )
    )
    if existing_spend.scalars().first():
        return {"credits": user.credits, "message": "Match already unlocked!"}

    # Check balance
    if user.credits < settings.credits_per_match:
        raise HTTPException(
            status_code=402, detail="Not enough credits. Watch an ad to earn more!"
        )

    user.credits -= settings.credits_per_match
    user.last_active = datetime.datetime.utcnow()

    txn = CreditTransaction(
        user_id=user.id,
        match_id=req.match_id,
        amount=-settings.credits_per_match,
        type="match_unlock",
    )
    db.add(txn)
    await db.commit()

    return {
        "credits": user.credits,
        "message": "Match unlocked! Enjoy the AI predictions.",
    }


@router.get("/transactions")
async def get_transactions(
    device_id: str, limit: int = 10, db: AsyncSession = Depends(get_db)
):
    """Get recent credit transactions."""
    result = await db.execute(select(User).where(User.device_id == device_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    txn_result = await db.execute(
        select(CreditTransaction)
        .where(CreditTransaction.user_id == user.id)
        .order_by(desc(CreditTransaction.created_at))
        .limit(limit)
    )
    transactions = txn_result.scalars().all()

    return {
        "transactions": [t.to_dict() for t in transactions],
        "credits": user.credits,
    }
