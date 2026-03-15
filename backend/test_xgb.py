import asyncio
from app.ml.model import predict, build_features

features = build_features({
    "elapsed": 90,
    "tournament_type": 0,
    "odd_home": 0.0,
    "odd_draw": 0.0,
    "odd_away": 0.0,
    "score_home": 3,
    "score_away": 0,
})

print("With 0.0 odds:")
print(predict(features))

features_fixed = build_features({
    "elapsed": 90,
    "tournament_type": 0,
    "odd_home": 1.2,
    "odd_draw": 4.5,
    "odd_away": 12.0,
    "score_home": 3,
    "score_away": 0,
})

print("With realistic odds:")
print(predict(features_fixed))

features_default = build_features({
    "elapsed": 90,
    "tournament_type": 0,
    "odd_home": 2.5,
    "odd_draw": 3.2,
    "odd_away": 3.0,
    "score_home": 3,
    "score_away": 0,
})

print("With default (2.5) odds:")
print(predict(features_default))
