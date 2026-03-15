"""
Events routes — lightweight monetization analytics intake.
"""

import logging
from typing import Any

from fastapi import APIRouter
from pydantic import BaseModel, Field

router = APIRouter(prefix="/events", tags=["Events"])
logger = logging.getLogger(__name__)


class MonetizationEventRequest(BaseModel):
    device_id: str
    event_name: str
    properties: dict[str, Any] = Field(default_factory=dict)


@router.post("/monetization")
async def monetization_event(req: MonetizationEventRequest):
    logger.info(
        "monetization_event | device_id=%s | event=%s | properties=%s",
        req.device_id,
        req.event_name,
        req.properties,
    )
    return {"status": "ok"}
