import asyncio
from app.ml.model import _heuristic_predict, build_features

features = build_features({
    "elapsed": 90,
    "tournament_type": 0,
    "odd_home": 0.0,
    "odd_draw": 0.0,
    "odd_away": 0.0,
    "score_home": 3,
    "score_away": 0,
})

print("With 0.0 odds (Heuristic):")
print(_heuristic_predict(features))

features_fixed = build_features({
    "elapsed": 90,
    "tournament_type": 0,
    "odd_home": 1.2,
    "odd_draw": 4.5,
    "odd_away": 12.0,
    "score_home": 3,
    "score_away": 0,
})

print("With realistic odds (Heuristic):")
print(_heuristic_predict(features_fixed))

features_prematch = build_features({
    "elapsed": 0,
    "tournament_type": 0,
    "odd_home": 1.5,
    "odd_draw": 4.0,
    "odd_away": 6.0,
    "score_home": 0,
    "score_away": 0,
})

print("Pre-match strong favorite (Heuristic):")
print(_heuristic_predict(features_prematch))
