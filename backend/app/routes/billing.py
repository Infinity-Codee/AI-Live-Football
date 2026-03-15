"""
Billing routes — entitlements and RevenueCat webhook bridge.
"""

import datetime
from typing import Any

from fastapi import APIRouter, Body, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.database import get_db
from app.models.user import User

router = APIRouter(prefix="/billing", tags=["Billing"])


class EntitlementSyncRequest(BaseModel):
    device_id: str
    is_pro: bool = False
    source: str = "client"
    pro_expires_at: str | None = None


def _parse_iso_datetime(value: str | None) -> datetime.datetime | None:
    if not value:
        return None
    try:
        return datetime.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def _now_utc() -> datetime.datetime:
    return datetime.datetime.now(datetime.timezone.utc)


@router.get("/entitlements")
async def get_entitlements(device_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.device_id == device_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    is_pro = bool(user.is_pro)
    if user.pro_expires_at:
        expiry = user.pro_expires_at
        if expiry.tzinfo is None:
            expiry = expiry.replace(tzinfo=datetime.timezone.utc)
        if expiry <= _now_utc():
            is_pro = False

    if is_pro != user.is_pro:
        user.is_pro = is_pro
        await db.commit()

    return {
        "device_id": user.device_id,
        "is_pro": is_pro,
        "pro_expires_at": user.pro_expires_at.isoformat() if user.pro_expires_at else None,
    }


@router.post("/entitlements/sync")
async def sync_entitlements(req: EntitlementSyncRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.device_id == req.device_id))
    user = result.scalars().first()

    if not user:
        user = User(device_id=req.device_id, credits=settings.initial_free_credits)
        db.add(user)
        await db.flush()

    expires_at = _parse_iso_datetime(req.pro_expires_at)
    if expires_at and expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=datetime.timezone.utc)
    is_pro = req.is_pro
    if expires_at and expires_at <= _now_utc():
        is_pro = False

    user.is_pro = is_pro
    user.pro_expires_at = expires_at
    user.last_active = datetime.datetime.utcnow()
    user.rc_last_event_type = f"sync:{req.source}"
    user.rc_last_event_at = datetime.datetime.utcnow()
    await db.commit()

    return {
        "status": "ok",
        "device_id": user.device_id,
        "is_pro": user.is_pro,
        "pro_expires_at": user.pro_expires_at.isoformat() if user.pro_expires_at else None,
    }


@router.post("/webhooks/revenuecat")
async def revenuecat_webhook(
    payload: dict[str, Any] = Body(default_factory=dict),
    db: AsyncSession = Depends(get_db),
):
    event = payload.get("event") or {}
    app_user_id = event.get("app_user_id")
    event_type = str(event.get("type") or "").upper()
    entitlement_ids = event.get("entitlement_ids") or []
    expiration_ms = event.get("expiration_at_ms")

    if not app_user_id:
        return {"status": "ignored", "reason": "missing_app_user_id"}

    result = await db.execute(select(User).where(User.device_id == app_user_id))
    user = result.scalars().first()
    if not user:
        user = User(device_id=app_user_id, credits=settings.initial_free_credits)
        db.add(user)
        await db.flush()

    expires_at = None
    if expiration_ms is not None:
        try:
            expires_at = datetime.datetime.fromtimestamp(
                int(expiration_ms) / 1000, tz=datetime.timezone.utc
            )
        except Exception:
            expires_at = None

    has_pro_entitlement = "pro" in entitlement_ids
    if event_type in {"EXPIRATION", "SUBSCRIPTION_PAUSED"}:
        is_pro = False
    elif has_pro_entitlement:
        is_pro = True
    else:
        is_pro = user.is_pro

    if expires_at and expires_at <= _now_utc():
        is_pro = False

    user.is_pro = is_pro
    user.pro_expires_at = expires_at
    user.last_active = datetime.datetime.utcnow()
    user.rc_last_event_type = event_type or "UNKNOWN"
    user.rc_last_event_at = datetime.datetime.utcnow()
    await db.commit()

    return {
        "status": "processed",
        "device_id": user.device_id,
        "event_type": event_type,
        "is_pro": user.is_pro,
    }
