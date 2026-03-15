"""
Mock Standings Data — For testing the app without an API-Football subscription.
Provides realistic league tables containing team logos and stats.
"""

MOCK_STANDINGS = {
    # Premier League
    39: [
        {"rank": 1, "team_name": "Liverpool", "team_logo": "https://media.api-sports.io/football/teams/40.png", "played": 28, "win": 19, "draw": 7, "lose": 2, "points": 64},
        {"rank": 2, "team_name": "Arsenal", "team_logo": "https://media.api-sports.io/football/teams/42.png", "played": 28, "win": 20, "draw": 4, "lose": 4, "points": 64},
        {"rank": 3, "team_name": "Manchester City", "team_logo": "https://media.api-sports.io/football/teams/50.png", "played": 28, "win": 19, "draw": 6, "lose": 3, "points": 63},
        {"rank": 4, "team_name": "Aston Villa", "team_logo": "https://media.api-sports.io/football/teams/66.png", "played": 29, "win": 17, "draw": 5, "lose": 7, "points": 56},
        {"rank": 5, "team_name": "Tottenham", "team_logo": "https://media.api-sports.io/football/teams/47.png", "played": 28, "win": 16, "draw": 5, "lose": 7, "points": 53},
        {"rank": 6, "team_name": "Manchester United", "team_logo": "https://media.api-sports.io/football/teams/33.png", "played": 28, "win": 15, "draw": 2, "lose": 11, "points": 47},
        {"rank": 7, "team_name": "West Ham", "team_logo": "https://media.api-sports.io/football/teams/48.png", "played": 29, "win": 12, "draw": 8, "lose": 9, "points": 44},
        {"rank": 8, "team_name": "Brighton", "team_logo": "https://media.api-sports.io/football/teams/51.png", "played": 28, "win": 11, "draw": 9, "lose": 8, "points": 42},
        {"rank": 9, "team_name": "Wolves", "team_logo": "https://media.api-sports.io/football/teams/39.png", "played": 28, "win": 12, "draw": 5, "lose": 11, "points": 41},
        {"rank": 10, "team_name": "Newcastle", "team_logo": "https://media.api-sports.io/football/teams/34.png", "played": 28, "win": 12, "draw": 4, "lose": 12, "points": 40},
        {"rank": 11, "team_name": "Chelsea", "team_logo": "https://media.api-sports.io/football/teams/49.png", "played": 27, "win": 11, "draw": 6, "lose": 10, "points": 39},
    ],
    # La Liga
    140: [
        {"rank": 1, "team_name": "Real Madrid", "team_logo": "https://media.api-sports.io/football/teams/541.png", "played": 29, "win": 22, "draw": 6, "lose": 1, "points": 72},
        {"rank": 2, "team_name": "Barcelona", "team_logo": "https://media.api-sports.io/football/teams/529.png", "played": 29, "win": 19, "draw": 7, "lose": 3, "points": 64},
        {"rank": 3, "team_name": "Girona", "team_logo": "https://media.api-sports.io/football/teams/547.png", "played": 29, "win": 19, "draw": 5, "lose": 5, "points": 62},
        {"rank": 4, "team_name": "Athletic Club", "team_logo": "https://media.api-sports.io/football/teams/531.png", "played": 29, "win": 16, "draw": 8, "lose": 5, "points": 56},
        {"rank": 5, "team_name": "Atletico Madrid", "team_logo": "https://media.api-sports.io/football/teams/530.png", "played": 29, "win": 17, "draw": 4, "lose": 8, "points": 55},
        {"rank": 6, "team_name": "Real Sociedad", "team_logo": "https://media.api-sports.io/football/teams/548.png", "played": 29, "win": 12, "draw": 10, "lose": 7, "points": 46},
    ],
    # Serie A
    135: [
        {"rank": 1, "team_name": "Inter Milan", "team_logo": "https://media.api-sports.io/football/teams/505.png", "played": 29, "win": 24, "draw": 4, "lose": 1, "points": 76},
        {"rank": 2, "team_name": "AC Milan", "team_logo": "https://media.api-sports.io/football/teams/489.png", "played": 29, "win": 19, "draw": 5, "lose": 5, "points": 62},
        {"rank": 3, "team_name": "Juventus", "team_logo": "https://media.api-sports.io/football/teams/496.png", "played": 29, "win": 17, "draw": 8, "lose": 4, "points": 59},
        {"rank": 4, "team_name": "Bologna", "team_logo": "https://media.api-sports.io/football/teams/500.png", "played": 29, "win": 15, "draw": 9, "lose": 5, "points": 54},
        {"rank": 5, "team_name": "AS Roma", "team_logo": "https://media.api-sports.io/football/teams/497.png", "played": 29, "win": 15, "draw": 6, "lose": 8, "points": 51},
        {"rank": 6, "team_name": "Atalanta", "team_logo": "https://media.api-sports.io/football/teams/499.png", "played": 28, "win": 14, "draw": 5, "lose": 9, "points": 47},
        {"rank": 7, "team_name": "Napoli", "team_logo": "https://media.api-sports.io/football/teams/492.png", "played": 29, "win": 12, "draw": 9, "lose": 8, "points": 45},
    ],
    # Bundesliga
    78: [
        {"rank": 1, "team_name": "Bayer Leverkusen", "team_logo": "https://media.api-sports.io/football/teams/168.png", "played": 26, "win": 22, "draw": 4, "lose": 0, "points": 70},
        {"rank": 2, "team_name": "Bayern Munich", "team_logo": "https://media.api-sports.io/football/teams/157.png", "played": 26, "win": 19, "draw": 3, "lose": 4, "points": 60},
        {"rank": 3, "team_name": "VfB Stuttgart", "team_logo": "https://media.api-sports.io/football/teams/172.png", "played": 26, "win": 18, "draw": 2, "lose": 6, "points": 56},
        {"rank": 4, "team_name": "Borussia Dortmund", "team_logo": "https://media.api-sports.io/football/teams/165.png", "played": 26, "win": 14, "draw": 8, "lose": 4, "points": 50},
        {"rank": 5, "team_name": "RB Leipzig", "team_logo": "https://media.api-sports.io/football/teams/173.png", "played": 26, "win": 15, "draw": 4, "lose": 7, "points": 49},
        {"rank": 6, "team_name": "Eintracht Frankfurt", "team_logo": "https://media.api-sports.io/football/teams/169.png", "played": 26, "win": 10, "draw": 10, "lose": 6, "points": 40},
    ],
    # Ligue 1
    61: [
        {"rank": 1, "team_name": "Paris SG", "team_logo": "https://media.api-sports.io/football/teams/85.png", "played": 26, "win": 17, "draw": 8, "lose": 1, "points": 59},
        {"rank": 2, "team_name": "Brest", "team_logo": "https://media.api-sports.io/football/teams/106.png", "played": 26, "win": 13, "draw": 8, "lose": 5, "points": 47},
        {"rank": 3, "team_name": "Monaco", "team_logo": "https://media.api-sports.io/football/teams/91.png", "played": 26, "win": 13, "draw": 7, "lose": 6, "points": 46},
    ],
    # Süper Lig
    203: [
        {"rank": 1, "team_name": "Galatasaray", "team_logo": "https://media.api-sports.io/football/teams/645.png", "played": 30, "win": 26, "draw": 3, "lose": 1, "points": 81},
        {"rank": 2, "team_name": "Fenerbahce", "team_logo": "https://media.api-sports.io/football/teams/646.png", "played": 30, "win": 25, "draw": 4, "lose": 1, "points": 79},
        {"rank": 3, "team_name": "Trabzonspor", "team_logo": "https://media.api-sports.io/football/teams/640.png", "played": 30, "win": 15, "draw": 4, "lose": 11, "points": 49},
        {"rank": 4, "team_name": "Besiktas", "team_logo": "https://media.api-sports.io/football/teams/549.png", "played": 30, "win": 14, "draw": 4, "lose": 12, "points": 46},
        {"rank": 5, "team_name": "Kasimpasa", "team_logo": "https://media.api-sports.io/football/teams/1020.png", "played": 30, "win": 13, "draw": 4, "lose": 13, "points": 43},
    ],
    # Roshn Saudi League
    307: [
        {"rank": 1, "team_name": "Al Hilal", "team_logo": "https://media.api-sports.io/football/teams/2962.png", "played": 25, "win": 23, "draw": 2, "lose": 0, "points": 71},
        {"rank": 2, "team_name": "Al Nassr", "team_logo": "https://media.api-sports.io/football/teams/2939.png", "played": 25, "win": 19, "draw": 2, "lose": 4, "points": 59},
        {"rank": 3, "team_name": "Al Ahli", "team_logo": "https://media.api-sports.io/football/teams/2933.png", "played": 25, "win": 14, "draw": 6, "lose": 5, "points": 48},
        {"rank": 4, "team_name": "Al Ittihad", "team_logo": "https://media.api-sports.io/football/teams/2975.png", "played": 25, "win": 14, "draw": 4, "lose": 7, "points": 46},
        {"rank": 5, "team_name": "Al Taawoun", "team_logo": "https://media.api-sports.io/football/teams/2969.png", "played": 25, "win": 12, "draw": 7, "lose": 6, "points": 43},
    ]
}

def get_mock_standings(league_id: int):
    """Returns mock standings for the given league, or an empty list if not supported."""
    return MOCK_STANDINGS.get(league_id, [])
