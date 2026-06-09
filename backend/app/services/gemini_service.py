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


def _build_prompt(match, prediction=None) -> str:
    lines = [
        "You are a professional football analyst. Using ONLY the data below, write a "
        "grounded analysis and respond with JSON ONLY.",
        "",
        f"League: {match.league_name}",
        f"Match: {match.home_team} (home) vs {match.away_team} (away)",
        f"Status: {_status_label(match)}",
        f"Score: {match.score_home} - {match.score_away}",
    ]

    has_stats = any([
        match.shots_home, match.shots_away, match.corners_home,
        match.corners_away, match.red_cards_home, match.red_cards_away,
    ])
    if has_stats:
        lines.append(f"Shots: {match.shots_home} - {match.shots_away}")
        lines.append(f"Corners: {match.corners_home} - {match.corners_away}")
        lines.append(f"Red cards: {match.red_cards_home} - {match.red_cards_away}")
        extra = match.extra_stats or {}
        home_x, away_x = extra.get("home") or {}, extra.get("away") or {}
        if home_x.get("possession") or away_x.get("possession"):
            lines.append(
                f"Possession: {home_x.get('possession', '-')} - {away_x.get('possession', '-')}"
            )
    else:
        lines.append("Detailed stats (shots/corners) are NOT available for this match.")

    if match.odd_home and match.odd_home > 0:
        lines.append(
            f"Pre-match odds: home {match.odd_home}, draw {match.odd_draw}, away {match.odd_away}"
        )

    if prediction:
        lines.append(
            "Our AI model's prediction — "
            f"home win {prediction['home_win_prob'] * 100:.0f}%, "
            f"draw {prediction['draw_prob'] * 100:.0f}%, "
            f"away win {prediction['away_win_prob'] * 100:.0f}%."
        )

    lines.append("")
    lines.append(
        "Return JSON with exactly these keys:\n"
        '  "en": 2 concise sentences in ENGLISH — state who is favoured and WHY '
        "(grounded in the score, game state, and the model's prediction), then the "
        "likely outcome. If detailed stats are unavailable, reason from the score and "
        "game state and do NOT invent stats.\n"
        '  "tr": the SAME analysis in TURKISH.\n'
        "Be specific and consistent with the model's prediction. No markdown, JSON only."
    )
    return "\n".join(lines)


async def analyze_match(match, prediction=None) -> dict | None:
    """
    Return {"en": "...", "tr": "..."} for the match, or None if Gemini is not
    configured or the request fails (caller then simply omits the analysis).
    The optional `prediction` (model probabilities) grounds the narrative.
    """
    if not settings.has_gemini:
        return None

    body = {
        "contents": [{"parts": [{"text": _build_prompt(match, prediction)}]}],
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

    # The free tier occasionally returns a transient 503/404 — one quick retry
    # catches most blips while keeping the total well under the client's timeout
    # (worst case ~2x12s + 1.5s ≈ 25s, vs the app's 40s analysis budget).
    attempts = 2
    for attempt in range(attempts):
        try:
            async with httpx.AsyncClient(timeout=12) as client:
                resp = await client.post(url, json=body)
            if resp.status_code in _TRANSIENT:
                logger.info(f"Gemini {resp.status_code} (transient), retry {attempt + 1}/{attempts}")
                await asyncio.sleep(1.5)
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
            await asyncio.sleep(1.5)
    return None
