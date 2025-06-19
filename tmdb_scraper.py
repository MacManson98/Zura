import requests
import json
from pathlib import Path

# 🔑 Replace with your TMDB API key
API_KEY = '44bda25cf25ee68657a9007f51199091'
BASE_URL = 'https://api.themoviedb.org/3'
POSTER_BASE = 'https://image.tmdb.org/t/p/w500'

# 🎭 Genre mapping from TMDB IDs
GENRE_MAP = {
    28: "Action",
    12: "Adventure",
    16: "Animation",
    35: "Comedy",
    80: "Crime",
    99: "Documentary",
    18: "Drama",
    10751: "Family",
    14: "Fantasy",
    36: "History",
    27: "Horror",
    10402: "Music",
    9648: "Mystery",
    10749: "Romance",
    878: "Sci-Fi",
    10770: "TV Movie",
    53: "Thriller",
    10752: "War",
    37: "Western"
}

# 🧠 Tag inference
TAG_KEYWORDS = {
    "Mind-bending": ["dream", "reality", "illusion", "memory", "matrix", "twist"],
    "Feel-good": ["heartwarming", "feel good", "uplifting", "bond", "joyful"],
    "Emotional": ["moving", "tears", "loss", "journey", "inspire"],
    "Romantic": ["love", "romance", "relationship", "passion"],
    "Scary": ["terrifying", "haunted", "killer", "horror", "ghost"],
    "Based on a true story": ["true story", "biopic", "inspired"],
    "Artsy/Indie": ["indie", "festival", "arthouse"],
    "Epic": ["epic", "adventure", "grand", "heroic"],
    "Twisty": ["plot twist", "twist", "shock", "reveal"],
    "Action-packed": ["explosion", "battle", "war", "chase", "fight"]
}

def fetch_popular_movies(page=1):
    url = f"{BASE_URL}/movie/popular?api_key={API_KEY}&language=en-US&page={page}"
    response = requests.get(url)
    return response.json().get("results", [])

def extract_tags(title, overview):
    text = f"{title} {overview}".lower()
    tags = set()
    for tag, keywords in TAG_KEYWORDS.items():
        for keyword in keywords:
            if keyword in text:
                tags.add(tag)
    return list(tags)

def build_movie_object(entry):
    return {
        "title": entry["title"],
        "posterUrl": f"{POSTER_BASE}{entry['poster_path']}",
        "overview": entry["overview"],
        "cast": [],  # Can be expanded with additional TMDB calls
        "genres": [GENRE_MAP.get(genre_id, "Unknown") for genre_id in entry["genre_ids"]],
        "tags": extract_tags(entry["title"], entry["overview"])
    }

def save_movies_to_json(movies, path="assets/movies.json"):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(movies, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    all_movies = []
    for page in range(1, 4):  # 🔁 Grab 3 pages (~60 movies)
        print(f"Fetching page {page}...")
        results = fetch_popular_movies(page)
        for movie in results:
            if movie.get("poster_path") and movie.get("overview"):
                all_movies.append(build_movie_object(movie))

    save_movies_to_json(all_movies)
    print(f"✅ Saved {len(all_movies)} movies to assets/movies.json")
