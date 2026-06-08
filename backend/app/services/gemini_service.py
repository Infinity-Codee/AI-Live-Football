"""
Google Gemini service — generates a short bilingual (Arabic + Turkish) tactical
analysis of a football match from its real live data. Used to enrich the AI
predictions with a human-readable explanation.

Numbers come from the ML/heuristic engine; this only adds the textual analysis.
"""

import asyncio
import json
import logging

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

_FINISHED = {"FT", "AET", "PEN"}
# Codes seen intermittently on the free tier under load — all worth retrying.
_TRANSIENT = {404, 429, 500, 502, 503, 504}


def _status_label(match) -> str:
    if match.is_live:
        return f"LIVE, minute {match.elapsed}"
    if match.status in _FINISHED:
        return "FINISHED (full time)"
    return "UPCOMING (not started)"


def _build_prompt(match) -> str:
    return (
        "You are a professional football analyst. Analyze the match below using "
        "ONLY the given data and respond with JSON ONLY.\n\n"
        f"League: {match.league_name}\n"
        f"Match: {match.home_team} (home) vs {match.away_team} (away)\n"
        f"Status: {_status_label(match)}\n"
        f"Score: {match.score_home} - {match.score_away}\n"
        f"Shots: {match.shots_home} - {match.shots_away}\n"
        f"Corners: {match.corners_home} - {match.corners_away}\n"
        f"Red cards: {match.red_cards_home} - {match.red_cards_away}\n\n"
        "Return JSON with exactly these keys:\n"
        '  "en": a concise 2-sentence tactical analysis in ENGLISH (who is on top, '
        "why, and the likely outcome),\n"
        '  "tr": the SAME analysis in TURKISH.\n'
        "Be specific to the numbers above. No markdown, JSON only."
    )


async def analyze_match(match) -> dict | None:
    """
    Return {"ar": "...", "tr": "..."} for the match, or None if Gemini is not
    configured or the request fails (caller then simply omits the analysis).
    """
    if not settings.has_gemini:
        return None

    body = {
        "contents": [{"parts": [{"text": _build_prompt(match)}]}],
        "generationConfig": {
            "responseMimeType": "application/json",
            "temperature": 0.4,
            "maxOutputTokens": 700,
            # gemini-2.5-flash is a "thinking" model; disable thinking so the
            # token budget goes to the answer (avoids truncated JSON) and it's fast.
            "thinkingConfig": {"thinkingBudget": 0},
        },
    }
    url = (
        f"{settings.gemini_base_url}/{settings.gemini_model}:generateContent"
        f"?key={settings.gemini_api_key}"
    )

    # The free tier intermittently returns 503/404 under load — retry with backoff.
    attempts = 4
    for attempt in range(attempts):
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                resp = await client.post(url, json=body)
            if resp.status_code in _TRANSIENT:
                logger.info(f"Gemini {resp.status_code} (transient), retry {attempt + 1}/{attempts}")
                await asyncio.sleep(1.2 * (attempt + 1))
                continue
            resp.raise_for_status()
            data = resp.json()
            text = data["candidates"][0]["content"]["parts"][0]["text"]
            parsed = json.loads(text)
            en = (parsed.get("en") or "").strip()
            tr = (parsed.get("tr") or "").strip()
            if en or tr:
                return {"en": en, "tr": tr}
            return None
        except Exception as e:
            logger.warning(f"Gemini analysis failed (attempt {attempt + 1}): {e}")
            await asyncio.sleep(1.0 * (attempt + 1))
    return None
