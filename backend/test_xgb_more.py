import asyncio
from app.ml.model import predict, build_features

features = build_features({
    "elapsed": 45,
    "tournament_type": 0,
    "odd_home": 2.5,
    "odd_draw": 3.0,
    "odd_away": 2.8,
    "score_home": 1,
    "score_away": 0,
})

print("Leading 1-0 at HT:")
print(predict(features))

features_2 = build_features({
    "elapsed": 80,
    "tournament_type": 0,
    "odd_home": 2.5,
    "odd_draw": 3.0,
    "odd_away": 2.8,
    "score_home": 0,
    "score_away": 2,
})

print("Losing 0-2 at 80 mins:")
print(predict(features_2))

features_3 = build_features({
    "elapsed": 0,
    "tournament_type": 0,
    "odd_home": 1.5,
    "odd_draw": 4.0,
    "odd_away": 6.0,
    "score_home": 0,
    "score_away": 0,
})

print("Pre-match, strong favorite:")
print(predict(features_3))
