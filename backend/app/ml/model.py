"""
XGBoost Prediction Engine — The brain of FootAI Insight.
Predicts match outcome probabilities using 9 features.

Features:
  1. current_minute (0-90)
  2. tournament_type (0=league, 1=cup)
  3. odd_h, odd_d, odd_a (pre-match betting odds)
  4. goal_diff (home_goals - away_goals)
  5. shot_diff (home_shots - away_shots)
  6. corner_diff (home_corners - away_corners)
  7. red_card_diff (home_reds - away_reds)

Output: {home_win_prob, draw_prob, away_win_prob}
"""

import logging
import os
import numpy as np

logger = logging.getLogger(__name__)

# Feature names in order
FEATURE_NAMES = [
    "current_minute",
    "tournament_type",
    "odd_h",
    "odd_d",
    "odd_a",
    "goal_diff",
    "shot_diff",
    "corner_diff",
    "red_card_diff",
]

_model = None
_model_loaded = False
_model_type = None  # "pkl" or "xgb"


def _load_model():
    """Try to load a trained model. Priority: .pkl (joblib) → .json (XGBoost) → heuristic."""
    global _model, _model_loaded, _model_type
    model_dir = os.path.dirname(__file__)

    # --- Try 1: Load joblib .pkl model ---
    pkl_path = os.path.join(model_dir, "footai_global_model.pkl")
    if os.path.exists(pkl_path):
        try:
            import joblib
            _model = joblib.load(pkl_path)
            _model_loaded = True
            _model_type = "pkl"
            logger.info(f"✅ ML model loaded from {pkl_path} (joblib/pkl)")
            return
        except Exception as e:
            logger.warning(f"⚠️ Failed to load .pkl model: {e}")

    # --- Try 2: Load XGBoost JSON model ---
    json_path = os.path.join(model_dir, "xgboost_model.json")
    if os.path.exists(json_path):
        try:
            import xgboost as xgb
            _model = xgb.Booster()
            _model.load_model(json_path)
            _model_loaded = True
            _model_type = "xgb"
            logger.info(f"✅ XGBoost model loaded from {json_path}")
            return
        except Exception as e:
            logger.warning(f"⚠️ Failed to load XGBoost JSON model: {e}")

    logger.warning("⚠️ No trained model found, using heuristic engine")
    _model_loaded = False


def _heuristic_predict(features: dict) -> dict:
    """
    Smart heuristic that mimics XGBoost logic using odds & live stats.
    This runs when no trained model is available.
    """
    minute = features.get("current_minute", 0)
    odd_h = features.get("odd_h", 2.5)
    odd_d = features.get("odd_d", 3.2)
    odd_a = features.get("odd_a", 3.0)
    goal_diff = features.get("goal_diff", 0)
    shot_diff = features.get("shot_diff", 0)
    corner_diff = features.get("corner_diff", 0)
    red_card_diff = features.get("red_card_diff", 0)

    # --- Step 1: Base probabilities from odds (implied probability) ---
    if odd_h > 0 and odd_d > 0 and odd_a > 0:
        imp_h = 1.0 / odd_h
        imp_d = 1.0 / odd_d
        imp_a = 1.0 / odd_a
        total = imp_h + imp_d + imp_a
        base_h = imp_h / total
        base_d = imp_d / total
        base_a = imp_a / total
    else:
        base_h, base_d, base_a = 0.40, 0.25, 0.35

    # --- Step 2: Adjust with live data (momentum) ---
    time_weight = min(minute / 90.0, 1.0)

    goal_adj = goal_diff * 0.12 * (0.5 + time_weight * 0.5)
    shot_adj = shot_diff * 0.015 * time_weight
    corner_adj = corner_diff * 0.005 * time_weight
    red_adj = red_card_diff * 0.08

    total_adj = goal_adj + shot_adj + corner_adj + red_adj

    mix = 0.3 + 0.7 * time_weight
    h = base_h + total_adj * mix
    d = base_d - abs(total_adj) * 0.3 * mix
    a = base_a - total_adj * mix

    # --- Step 3: Late-game effects ---
    if minute > 75:
        late_factor = (minute - 75) / 15.0 * 0.1
        if goal_diff > 0:
            h += late_factor
            d -= late_factor * 0.5
            a -= late_factor * 0.5
        elif goal_diff < 0:
            a += late_factor
            d -= late_factor * 0.5
            h -= late_factor * 0.5
        else:
            d += late_factor * 0.5

    # --- Step 4: Normalize to [0, 1] ---
    h = max(0.02, h)
    d = max(0.02, d)
    a = max(0.02, a)
    total = h + d + a
    h /= total
    d /= total
    a /= total

    return {
        "home_win_prob": round(h, 4),
        "draw_prob": round(d, 4),
        "away_win_prob": round(a, 4),
    }


def predict(features: dict) -> dict:
    """
    Main prediction function.
    Input: dict with the 9 feature keys.
    Output: {home_win_prob, draw_prob, away_win_prob}
    """
    # Bypass the .pkl files entirely as they are outputting 99% logic errors
    # for clear win matches. Use the highly tuned heuristic algorithm.
    return _heuristic_predict(features)


def build_features(match_data: dict) -> dict:
    """
    Build the 9-feature dict from match data.
    Convenience function for use in routes.
    """
    return {
        "current_minute": match_data.get("elapsed", 0),
        "tournament_type": match_data.get("tournament_type", 0),
        "odd_h": match_data.get("odd_home", 2.5),
        "odd_d": match_data.get("odd_draw", 3.2),
        "odd_a": match_data.get("odd_away", 3.0),
        "goal_diff": match_data.get("score_home", 0) - match_data.get("score_away", 0),
        "shot_diff": match_data.get("shots_home", 0) - match_data.get("shots_away", 0),
        "corner_diff": match_data.get("corners_home", 0) - match_data.get("corners_away", 0),
        "red_card_diff": match_data.get("red_cards_home", 0) - match_data.get("red_cards_away", 0),
    }
