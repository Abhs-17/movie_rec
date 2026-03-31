# 🎬 CineRec — Movie Recommendation System

A full-featured movie recommendation web app built with **Python + Flask + MySQL**.

---

## Project Structure

```
movie_rec/
├── app.py               ← Flask application (all routes & logic)
├── schema.sql           ← MySQL schema + seed data (17 movies, 8 directors, 14 genres)
├── requirements.txt
├── static/
│   ├── css/style.css    ← Cinematic dark theme
│   └── js/main.js
└── templates/
    ├── base.html        ← Shared layout + navbar
    ├── login.html
    ├── register.html
    ├── dashboard.html
    ├── movies.html
    ├── add_movie.html
    ├── movie_detail.html
    ├── recommend.html
    ├── directors.html
    ├── genres.html
    ├── platforms.html
    └── history.html
```

---

## Setup

### 1. Install Python dependencies
```bash
pip install -r requirements.txt
```

### 2. Set up MySQL database
```bash
mysql -u root -p < schema.sql
```
This creates the `movie_rec_db` database, all 8 tables, indexes, and seeds 17 sample movies.

### 3. Configure DB credentials
Open `app.py` and update the `DB_CONFIG` block at the top:
```python
DB_CONFIG = {
    'host':     'localhost',
    'user':     'root',
    'password': 'YOUR_MYSQL_PASSWORD',   # ← change this
    'database': 'movie_rec_db'
}
```

### 4. Run the app
```bash
python app.py
```
Visit → **http://127.0.0.1:5000**

---

## Default Login
| Username | Password  |
|----------|-----------|
| admin    | admin123  |

---

## Features

| Feature | Details |
|---------|---------|
| **Auth** | Register / Login / Logout with SHA-256 hashed passwords |
| **Dashboard** | Stats (movies, directors, genres), top-rated grid, recent recommendations |
| **Movie Catalog** | Grid view with poster, search by title, filter by genre |
| **Add Movie** | Title, year, rating, poster URL, trailer URL, director, genres (multi), platforms (multi) |
| **Movie Detail** | Full info, genre tags, streaming platform links, trailer button, similar movies |
| **Recommendation Engine** | Content-based filtering by shared genres (70%) + director match (30%), similarity score saved to DB |
| **Recommendation History** | Full log per user with movie poster, score, timestamp |
| **Directors** | Add directors, view movie count per director |
| **Genres** | Add genres, view movie count per genre |
| **Platforms** | Add streaming platforms with URLs |
| **Delete Movie** | Cascades to MOVIE_GENRE, MOVIE_PLATFORM, RECOMMENDATION |

---

## Database Schema (8 Tables)

```
USER              — Authentication
DIRECTOR          — Director info
MOVIE             — Core movie records (FK → DIRECTOR)
GENRE             — Genre categories
STREAMING_PLATFORM — Platform info
MOVIE_GENRE       — Junction: Movie ↔ Genre (M:N)
MOVIE_PLATFORM    — Junction: Movie ↔ Platform (M:N)
RECOMMENDATION    — Rec history per user with similarity score
```

---

## Recommendation Algorithm

Content-based filtering:
1. Find the seed movie by title search
2. Score all other movies:
   - **Genre match** × 0.7 — count of shared genres, normalized
   - **Director match** × 0.3 — 1 if same director, else 0
3. Sort by combined score descending, then by rating
4. Save each result to the `RECOMMENDATION` table
5. Return top 8 matches
