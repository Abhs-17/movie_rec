from flask import Flask, render_template, request, redirect, url_for, session, jsonify, flash
import mysql.connector
import hashlib
import os
from datetime import datetime
from functools import wraps

app = Flask(__name__)
app.secret_key = 'movie_rec_secret_key_2025'

# ─── DB CONFIG ────────────────────────────────────────────────────────────────
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'Abhishek@2005',  # Updated to match MySQL root password
    'database': 'movie_rec_db'
}

def get_db():
    return mysql.connector.connect(**DB_CONFIG)

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

# ─── AUTH DECORATOR ───────────────────────────────────────────────────────────
def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated

def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        if session.get('role') != 'admin':
            flash('Admin access required.', 'error')
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return decorated

# ─── ROUTES ───────────────────────────────────────────────────────────────────

@app.route('/')
def index():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

# ── Auth ──────────────────────────────────────────────────────────────────────
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = hash_password(request.form['password'])
        db = get_db(); cur = db.cursor(dictionary=True)
        cur.execute("SELECT * FROM USER WHERE username=%s AND password_hash=%s", (username, password))
        user = cur.fetchone(); db.close()
        if user:
            session['user_id'] = user['user_id']
            session['username'] = user['username']
            session['role'] = user.get('role', 'user')
            return redirect(url_for('dashboard'))
        flash('Invalid credentials', 'error')
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username']
        email    = request.form['email']
        password = hash_password(request.form['password'])
        try:
            db = get_db(); cur = db.cursor()
            cur.execute("INSERT INTO USER (username,email,password_hash,role) VALUES (%s,%s,%s,%s)",
                        (username, email, password, 'user'))
            db.commit(); db.close()
            flash('Account created! Please log in.', 'success')
            return redirect(url_for('login'))
        except mysql.connector.IntegrityError:
            flash('Username or email already exists.', 'error')
    return render_template('register.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

# ── Dashboard ─────────────────────────────────────────────────────────────────
@app.route('/dashboard')
@login_required
def dashboard():
    db = get_db(); cur = db.cursor(dictionary=True)
    cur.execute("SELECT COUNT(*) AS c FROM MOVIE");         movie_count   = cur.fetchone()['c']
    cur.execute("SELECT COUNT(*) AS c FROM DIRECTOR");      dir_count     = cur.fetchone()['c']
    cur.execute("SELECT COUNT(*) AS c FROM GENRE");         genre_count   = cur.fetchone()['c']
    cur.execute("""
        SELECT M.title, R.similarity_score, R.recommended_at
        FROM RECOMMENDATION R JOIN MOVIE M ON R.movie_id=M.movie_id
        WHERE R.user_id=%s ORDER BY R.recommended_at DESC LIMIT 5
    """, (session['user_id'],))
    recent_recs = cur.fetchall()
    cur.execute("""
        SELECT M.movie_id, M.title, M.rating, M.poster_url, M.trailer_url,
               GROUP_CONCAT(G.genre_name SEPARATOR ', ') AS genres
        FROM MOVIE M LEFT JOIN MOVIE_GENRE MG ON M.movie_id=MG.movie_id
        LEFT JOIN GENRE G ON MG.genre_id=G.genre_id
        GROUP BY M.movie_id ORDER BY M.rating DESC LIMIT 6
    """)
    top_movies = cur.fetchall() 
    db.close()
    return render_template('dashboard.html',
                           movie_count=movie_count, dir_count=dir_count,
                           genre_count=genre_count, recent_recs=recent_recs,
                           top_movies=top_movies)

# ── Movies ────────────────────────────────────────────────────────────────────
@app.route('/movies')
@login_required
def movies():
    search = request.args.get('q', '')
    genre  = request.args.get('genre', '')
    db = get_db(); cur = db.cursor(dictionary=True)
    query = """
        SELECT M.movie_id, M.title, M.release_year, M.rating, M.poster_url, M.trailer_url,
               D.name AS director, GROUP_CONCAT(G.genre_name SEPARATOR ', ') AS genres
        FROM MOVIE M
        LEFT JOIN DIRECTOR D ON M.director_id=D.director_id
        LEFT JOIN MOVIE_GENRE MG ON M.movie_id=MG.movie_id
        LEFT JOIN GENRE G ON MG.genre_id=G.genre_id
        WHERE 1=1
    """
    params = []
    if search:
        query += " AND M.title LIKE %s"; params.append(f'%{search}%')
    if genre:
        query += " AND G.genre_name=%s"; params.append(genre)
    query += " GROUP BY M.movie_id ORDER BY M.rating DESC"
    cur.execute(query, params)
    movie_list = cur.fetchall()
    cur.execute("SELECT genre_name FROM GENRE ORDER BY genre_name")
    genres = [r['genre_name'] for r in cur.fetchall()]
    db.close()
    return render_template('movies.html', movies=movie_list, genres=genres, search=search, selected_genre=genre)

@app.route('/movies/add', methods=['GET', 'POST'])
@admin_required
def add_movie():
    db = get_db(); cur = db.cursor(dictionary=True)
    if request.method == 'POST':
        title       = request.form['title']
        year        = request.form.get('release_year') or None
        rating      = request.form.get('rating') or None
        poster_url  = request.form.get('poster_url') or None
        trailer_url = request.form.get('trailer_url') or None
        director_id = request.form.get('director_id') or None
        cur2 = db.cursor()
        try:
            cur2.execute("INSERT INTO MOVIE (title,release_year,rating,poster_url,trailer_url,director_id) VALUES (%s,%s,%s,%s,%s,%s)",
                         (title, year, rating, poster_url, trailer_url, director_id))
        except mysql.connector.IntegrityError:
            db.close()
            flash('Movie already exists for the selected release year.', 'error')
            return redirect(url_for('add_movie'))
        movie_id = cur2.lastrowid
        for gid in request.form.getlist('genres'):
            cur2.execute("INSERT IGNORE INTO MOVIE_GENRE VALUES (%s,%s)", (movie_id, gid))
        for pid in request.form.getlist('platforms'):
            cur2.execute("INSERT IGNORE INTO MOVIE_PLATFORM VALUES (%s,%s)", (movie_id, pid))
        db.commit(); db.close()
        flash('Movie added successfully!', 'success')
        return redirect(url_for('movies'))
    cur.execute("SELECT * FROM DIRECTOR ORDER BY name")
    directors = cur.fetchall()
    cur.execute("SELECT * FROM GENRE ORDER BY genre_name")
    genres = cur.fetchall()
    cur.execute("SELECT * FROM STREAMING_PLATFORM ORDER BY platform_name")
    platforms = cur.fetchall()
    db.close()
    return render_template('add_movie.html', directors=directors, genres=genres, platforms=platforms)

@app.route('/movies/<int:movie_id>')
@login_required
def movie_detail(movie_id):
    db = get_db(); cur = db.cursor(dictionary=True)
    cur.execute("""
        SELECT M.*, D.name AS director, D.nationality,
               (SELECT ROUND(AVG(R.rating), 1) FROM REVIEW R WHERE R.movie_id=M.movie_id) AS user_avg_rating,
               (SELECT COUNT(*) FROM REVIEW R WHERE R.movie_id=M.movie_id) AS user_review_count
        FROM MOVIE M LEFT JOIN DIRECTOR D ON M.director_id=D.director_id
        WHERE M.movie_id=%s
    """, (movie_id,))
    movie = cur.fetchone()
    if not movie: db.close(); return "Movie not found", 404
    cur.execute("""
        SELECT G.genre_name FROM GENRE G JOIN MOVIE_GENRE MG ON G.genre_id=MG.genre_id
        WHERE MG.movie_id=%s
    """, (movie_id,))
    movie['genres'] = [r['genre_name'] for r in cur.fetchall()]
    cur.execute("""
        SELECT SP.platform_name, SP.platform_url FROM STREAMING_PLATFORM SP
        JOIN MOVIE_PLATFORM MP ON SP.platform_id=MP.platform_id WHERE MP.movie_id=%s
    """, (movie_id,))
    movie['platforms'] = cur.fetchall()
    # recommendations
    cur.execute("""
        SELECT M2.movie_id, M2.title, M2.rating, M2.poster_url,
               GROUP_CONCAT(G.genre_name SEPARATOR ', ') AS genres,
               COUNT(DISTINCT MG2.genre_id) AS shared_genres
        FROM MOVIE M2
        JOIN MOVIE_GENRE MG2 ON M2.movie_id=MG2.movie_id
        JOIN GENRE G ON MG2.genre_id=G.genre_id
        WHERE MG2.genre_id IN (SELECT genre_id FROM MOVIE_GENRE WHERE movie_id=%s)
          AND M2.movie_id != %s
        GROUP BY M2.movie_id ORDER BY shared_genres DESC, M2.rating DESC LIMIT 4
    """, (movie_id, movie_id))
    similar = cur.fetchall()
    cur.execute("""
        SELECT R.rating, R.review_text, R.created_at, U.username
        FROM REVIEW R JOIN USER U ON R.user_id=U.user_id
        WHERE R.movie_id=%s
        ORDER BY R.created_at DESC
    """, (movie_id,))
    reviews = cur.fetchall()
    cur.execute("""
        SELECT rating, review_text
        FROM REVIEW
        WHERE movie_id=%s AND user_id=%s
    """, (movie_id, session['user_id']))
    my_review = cur.fetchone()
    db.close()
    return render_template('movie_detail.html', movie=movie, similar=similar, reviews=reviews, my_review=my_review)

@app.route('/movies/<int:movie_id>/review', methods=['POST'])
@login_required
def submit_review(movie_id):
    rating = request.form.get('rating', type=int)
    review_text = (request.form.get('review_text') or '').strip()
    if rating is None or rating < 1 or rating > 5:
        flash('Please select a rating between 1 and 5.', 'error')
        return redirect(url_for('movie_detail', movie_id=movie_id))

    db = get_db(); cur = db.cursor()
    cur.execute("""
        INSERT INTO REVIEW (user_id, movie_id, rating, review_text)
        VALUES (%s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
            rating=VALUES(rating),
            review_text=VALUES(review_text),
            created_at=CURRENT_TIMESTAMP
    """, (session['user_id'], movie_id, rating, review_text or None))
    db.commit(); db.close()
    flash('Your review has been saved.', 'success')
    return redirect(url_for('movie_detail', movie_id=movie_id))

@app.route('/movies/<int:movie_id>/delete', methods=['POST'])
@admin_required
def delete_movie(movie_id):
    db = get_db(); cur = db.cursor()
    cur.execute("DELETE FROM MOVIE WHERE movie_id=%s", (movie_id,))
    db.commit(); db.close()
    flash('Movie deleted.', 'success')
    return redirect(url_for('movies'))

# ── Recommendations ───────────────────────────────────────────────────────────
@app.route('/recommend', methods=['GET', 'POST'])
@login_required
def recommend():
    results = []
    query_title = ''
    if request.method == 'POST':
        query_title = request.form.get('title', '').strip()
        db = get_db(); cur = db.cursor(dictionary=True)
        cur.execute("""
            SELECT movie_id, director_id FROM MOVIE WHERE title LIKE %s LIMIT 1
        """, (f'%{query_title}%',))
        seed = cur.fetchone()
        if seed:
            cur.execute("""
                SELECT DISTINCT M.movie_id, M.title, M.release_year, M.rating, M.poster_url, M.trailer_url,
                       D.name AS director,
                       GROUP_CONCAT(DISTINCT G.genre_name SEPARATOR ', ') AS genres,
                       (
                         SELECT COUNT(*) FROM MOVIE_GENRE MG2
                         WHERE MG2.movie_id=M.movie_id
                           AND MG2.genre_id IN (SELECT genre_id FROM MOVIE_GENRE WHERE movie_id=%s)
                       ) AS genre_match,
                       IF(M.director_id=%s, 1, 0) AS dir_match
                FROM MOVIE M
                LEFT JOIN DIRECTOR D ON M.director_id=D.director_id
                LEFT JOIN MOVIE_GENRE MG ON M.movie_id=MG.movie_id
                LEFT JOIN GENRE G ON MG.genre_id=G.genre_id
                WHERE M.movie_id != %s
                GROUP BY M.movie_id
                HAVING genre_match > 0 OR dir_match = 1
                ORDER BY (genre_match * 0.7 + dir_match * 0.3) DESC, M.rating DESC
                LIMIT 8
            """, (seed['movie_id'], seed['director_id'], seed['movie_id']))
            results = cur.fetchall()
            # calculate similarity score & save
            for r in results:
                total = r['genre_match'] + r['dir_match']
                score = round(min(total / 5.0, 1.0), 2)
                r['similarity_score'] = score
                cur2 = db.cursor()
                cur2.execute("""
                    SELECT M2.movie_id, M2.title, M2.rating, M2.poster_url, M2.trailer_url,
                    VALUES (%s,%s,%s)
                """, (session['user_id'], r['movie_id'], score))
            db.commit()
        db.close()
    return render_template('recommend.html', results=results, query_title=query_title)

# ── Directors ─────────────────────────────────────────────────────────────────
@app.route('/directors', methods=['GET', 'POST'])
@admin_required
def directors():
    db = get_db(); cur = db.cursor(dictionary=True)
    if request.method == 'POST':
        name        = request.form['name']
        nationality = request.form.get('nationality') or None
        cur2 = db.cursor()
        cur2.execute("INSERT INTO DIRECTOR (name,nationality) VALUES (%s,%s)", (name, nationality))
        db.commit()
        flash('Director added!', 'success')
    cur.execute("""
        SELECT D.*, COUNT(M.movie_id) AS movie_count
        FROM DIRECTOR D LEFT JOIN MOVIE M ON D.director_id=M.director_id
        GROUP BY D.director_id ORDER BY D.name
    """)
    dir_list = cur.fetchall()
    db.close()
    return render_template('directors.html', directors=dir_list)

# ── Genres ────────────────────────────────────────────────────────────────────
@app.route('/genres', methods=['GET', 'POST'])
@admin_required
def genres():
    db = get_db(); cur = db.cursor(dictionary=True)
    if request.method == 'POST':
        genre_name = request.form['genre_name']
        cur2 = db.cursor()
        try:
            cur2.execute("INSERT INTO GENRE (genre_name) VALUES (%s)", (genre_name,))
            db.commit()
            flash('Genre added!', 'success')
        except mysql.connector.IntegrityError:
            flash('Genre already exists.', 'error')
    cur.execute("""
        SELECT G.*, COUNT(MG.movie_id) AS movie_count
        FROM GENRE G LEFT JOIN MOVIE_GENRE MG ON G.genre_id=MG.genre_id
        GROUP BY G.genre_id ORDER BY G.genre_name
    """)
    genre_list = cur.fetchall()
    db.close()
    return render_template('genres.html', genres=genre_list)

# ── Platforms ─────────────────────────────────────────────────────────────────
@app.route('/platforms', methods=['GET', 'POST'])
@admin_required
def platforms():
    db = get_db(); cur = db.cursor(dictionary=True)
    if request.method == 'POST':
        name = request.form['platform_name']
        url  = request.form.get('platform_url') or None
        cur2 = db.cursor()
        try:
            cur2.execute("INSERT INTO STREAMING_PLATFORM (platform_name,platform_url) VALUES (%s,%s)", (name, url))
            db.commit()
            flash('Platform added!', 'success')
        except mysql.connector.IntegrityError:
            flash('Platform already exists.', 'error')
    cur.execute("SELECT * FROM STREAMING_PLATFORM ORDER BY platform_name")
    platform_list = cur.fetchall()
    db.close()
    return render_template('platforms.html', platforms=platform_list)

# ── Recommendation History ────────────────────────────────────────────────────
@app.route('/history')
@login_required
def history():
    db = get_db(); cur = db.cursor(dictionary=True)
    cur.execute("""
        SELECT R.rec_id, R.similarity_score, R.recommended_at,
               M.title, M.poster_url, M.rating
        FROM RECOMMENDATION R JOIN MOVIE M ON R.movie_id=M.movie_id
        WHERE R.user_id=%s ORDER BY R.recommended_at DESC
    """, (session['user_id'],))
    recs = cur.fetchall()
    db.close()
    return render_template('history.html', recs=recs)

if __name__ == '__main__':
    app.run(debug=True)
