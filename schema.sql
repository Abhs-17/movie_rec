-- ============================================================
-- Movie Recommendation System — DB Setup
-- Run: mysql -u root -p < schema.sql
-- ============================================================

DROP DATABASE IF EXISTS movie_rec_db;
CREATE DATABASE movie_rec_db;
USE movie_rec_db;

-- USER
CREATE TABLE IF NOT EXISTS USER (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    role          ENUM('admin', 'user') NOT NULL DEFAULT 'user',
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- DIRECTOR
CREATE TABLE IF NOT EXISTS DIRECTOR (
    director_id INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    nationality VARCHAR(50)
);

-- MOVIE
CREATE TABLE IF NOT EXISTS MOVIE (
    movie_id     INT AUTO_INCREMENT PRIMARY KEY,
    title        VARCHAR(200) NOT NULL,
    release_year SMALLINT,
    rating       FLOAT CHECK (rating BETWEEN 0 AND 10),
    poster_url   TEXT,
    trailer_url  TEXT,
    director_id  INT,
    UNIQUE KEY uq_movie_title_year (title, release_year),
    FOREIGN KEY (director_id) REFERENCES DIRECTOR(director_id) ON DELETE SET NULL
);
CREATE INDEX idx_movie_title ON MOVIE(title);

-- GENRE
CREATE TABLE IF NOT EXISTS GENRE (
    genre_id   INT AUTO_INCREMENT PRIMARY KEY,
    genre_name VARCHAR(50) NOT NULL UNIQUE
);

-- STREAMING_PLATFORM
CREATE TABLE IF NOT EXISTS STREAMING_PLATFORM (
    platform_id   INT AUTO_INCREMENT PRIMARY KEY,
    platform_name VARCHAR(100) NOT NULL UNIQUE,
    platform_url  TEXT
);

-- MOVIE_GENRE (junction)
CREATE TABLE IF NOT EXISTS MOVIE_GENRE (
    movie_id INT NOT NULL,
    genre_id INT NOT NULL,
    PRIMARY KEY (movie_id, genre_id),
    FOREIGN KEY (movie_id) REFERENCES MOVIE(movie_id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES GENRE(genre_id)  ON DELETE CASCADE
);

-- MOVIE_PLATFORM (junction)
CREATE TABLE IF NOT EXISTS MOVIE_PLATFORM (
    movie_id    INT NOT NULL,
    platform_id INT NOT NULL,
    PRIMARY KEY (movie_id, platform_id),
    FOREIGN KEY (movie_id)    REFERENCES MOVIE(movie_id)              ON DELETE CASCADE,
    FOREIGN KEY (platform_id) REFERENCES STREAMING_PLATFORM(platform_id) ON DELETE CASCADE
);

-- REVIEW (user-generated)
CREATE TABLE IF NOT EXISTS REVIEW (
    review_id    INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    movie_id     INT NOT NULL,
    rating       TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text  TEXT,
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_review_user_movie (user_id, movie_id),
    FOREIGN KEY (user_id)  REFERENCES USER(user_id)  ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES MOVIE(movie_id) ON DELETE CASCADE
);
CREATE INDEX idx_review_movie ON REVIEW(movie_id);

-- RECOMMENDATION
CREATE TABLE IF NOT EXISTS RECOMMENDATION (
    rec_id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id          INT NOT NULL,
    movie_id         INT NOT NULL,
    similarity_score FLOAT DEFAULT 0.0,
    recommended_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)  REFERENCES USER(user_id)  ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES MOVIE(movie_id) ON DELETE CASCADE
);
CREATE INDEX idx_rec_user ON RECOMMENDATION(user_id);

-- ============================================================
-- SEED DATA
-- ============================================================

-- Default admin user  (password: admin123)
INSERT IGNORE INTO USER (username, email, password_hash, role) VALUES
('admin','admin@movrec.com','240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9','admin');

-- Directors
INSERT IGNORE INTO DIRECTOR (name, nationality) VALUES
('Christopher Nolan',  'British-American'),
('Steven Spielberg',   'American'),
('Rajkumar Hirani',    'Indian'),
('James Cameron',      'Canadian'),
('Martin Scorsese',    'American'),
('David Fincher',      'American'),
('Denis Villeneuve',   'Canadian'),
('Quentin Tarantino',  'American');

-- Genres
INSERT IGNORE INTO GENRE (genre_name) VALUES
('Action'),('Adventure'),('Animation'),('Comedy'),('Crime'),
('Drama'),('Fantasy'),('Horror'),('Mystery'),('Romance'),
('Sci-Fi'),('Thriller'),('Biography'),('History');

-- Streaming Platforms
INSERT IGNORE INTO STREAMING_PLATFORM (platform_name, platform_url) VALUES
('Netflix',       'https://www.netflix.com'),
('Prime Video',   'https://www.primevideo.com'),
('Disney+',       'https://www.justwatch.com/us/provider/disney-plus'),
('HBO Max',       'https://www.max.com'),
('Apple TV+',     'https://tv.apple.com'),
('Hulu',          'https://www.justwatch.com/us/provider/hulu');

-- Movies
INSERT IGNORE INTO MOVIE (title, release_year, rating, poster_url, trailer_url, director_id) VALUES
('Inception',          2010, 8.8, 'https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg', 'https://www.youtube.com/watch?v=YoHD9XEInc0', 1),
('Interstellar',       2014, 8.6, 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg', 'https://www.youtube.com/watch?v=zSWdZVtXT7E', 1),
('The Dark Knight',    2008, 9.0, 'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg', 'https://www.youtube.com/watch?v=EXeTwQWrcwY', 1),
("Schindler's List",   1993, 9.0, 'https://image.tmdb.org/t/p/w500/sF1U4EUQS8YHUYjNl3pMGNIQyr0.jpg', 'https://www.youtube.com/watch?v=gG22XNhtnoY', 2),
('Jaws',               1975, 8.0, 'https://img.youtube.com/vi/U1fu_sA7XhE/hqdefault.jpg', 'https://www.youtube.com/watch?v=U1fu_sA7XhE', 2),
('3 Idiots',           2009, 8.4, 'https://image.tmdb.org/t/p/w500/66A9MqXOyVFCssoloscw79z8Tew.jpg', 'https://www.youtube.com/watch?v=xvszmNXdM4w', 3),
('PK',                 2014, 8.1, 'https://dummyimage.com/500x750/111/eee.jpg&text=PK+(2014)', 'https://www.youtube.com/watch?v=IjVMpFIRRW0', 3),
('Avatar',             2009, 7.9, 'https://image.tmdb.org/t/p/w500/jRXYjXNq0Cs2TcJjLkki24MLp7u.jpg', 'https://www.youtube.com/watch?v=5PSNL1qE6VY', 4),
('Titanic',            1997, 7.9, 'https://image.tmdb.org/t/p/w500/9xjZS2rlVxm8SFx8kPC3aIGCOYQ.jpg', 'https://www.youtube.com/watch?v=2e-eXJ6HgkQ', 4),
('Goodfellas',         1990, 8.7, 'https://image.tmdb.org/t/p/w500/aKuFiU82s5ISJpGZp7YkIr3kCUd.jpg', 'https://www.youtube.com/watch?v=qo5jJpHtI1Y', 5),
('The Departed',       2006, 8.5, 'https://image.tmdb.org/t/p/w500/nT97ifVT2J1yMQmeq20Qblg61T.jpg', 'https://www.youtube.com/watch?v=iojhR0PgrpE', 5),
('Fight Club',         1999, 8.8, 'https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg', 'https://www.youtube.com/watch?v=SUXWAEX2jlg', 6),
('Se7en',              1995, 8.6, 'https://image.tmdb.org/t/p/w500/69Sns8WoET6CfaYlIkHbla4l7nC.jpg', 'https://www.youtube.com/watch?v=znmZoVkCjpI', 6),
('Arrival',            2016, 7.9, 'https://image.tmdb.org/t/p/w500/x2FJsf1ElAgr63Y3PNPtJrcmpoe.jpg', 'https://www.youtube.com/watch?v=tFMo3UJ4B4g', 7),
('Dune',               2021, 8.0, 'https://image.tmdb.org/t/p/w500/d5NXSklXo0qyIYkgV94XAgMIckC.jpg', 'https://www.youtube.com/watch?v=8g18jFHCLXk', 7),
('Pulp Fiction',       1994, 8.9, 'https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg', 'https://www.youtube.com/watch?v=s7EdQ4FqbhY', 8),
('Django Unchained',   2012, 8.4, 'https://dummyimage.com/500x750/111/eee.jpg&text=Django+Unchained+(2012)', 'https://www.youtube.com/watch?v=eUdM9vrCbow', 8),
('The Prestige',       2006, 8.5, 'https://img.youtube.com/vi/o4gHCmTQDVI/hqdefault.jpg', 'https://www.youtube.com/watch?v=o4gHCmTQDVI', 1),
('Saving Private Ryan',1998, 8.6, 'https://image.tmdb.org/t/p/w500/uqx37cS8cpHg8U35f9U5IBlrCV3.jpg', 'https://www.youtube.com/watch?v=9CiW_DgxCnQ', 2),
('Munna Bhai M.B.B.S.',2003, 8.1, 'https://dummyimage.com/500x750/111/eee.jpg&text=Munna+Bhai+M.B.B.S.+(2003)', 'https://www.youtube.com/watch?v=6zvZQZxPf1A', 3),
('Shutter Island',     2010, 8.2, 'https://image.tmdb.org/t/p/w500/kve20tXwUZpu4GUX8l6X7Z4jmL6.jpg', 'https://www.youtube.com/watch?v=5iaYLCiq5RM', 5),
('Gone Girl',          2014, 8.1, 'https://img.youtube.com/vi/2-_-1nJf8Vg/hqdefault.jpg', 'https://www.youtube.com/watch?v=2-_-1nJf8Vg', 6),
('Blade Runner 2049',  2017, 8.0, 'https://image.tmdb.org/t/p/w500/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg', 'https://www.youtube.com/watch?v=gCcx85zbxz4', 7),
('Inglourious Basterds',2009,8.3, 'https://image.tmdb.org/t/p/w500/7sfbEnaARXDDhKm0CZ7D7uc2sbo.jpg', 'https://www.youtube.com/watch?v=KnrRy6kSFF0', 8),
('Catch Me If You Can',2002, 8.1, 'https://img.youtube.com/vi/71rDQ7z4eFg/hqdefault.jpg', 'https://www.youtube.com/watch?v=71rDQ7z4eFg', 2),
('The Martian',        2015, 8.0, 'https://img.youtube.com/vi/ej3ioOneTy8/hqdefault.jpg', 'https://www.youtube.com/watch?v=ej3ioOneTy8', 7),
('The Wolf of Wall Street', 2013, 8.2, 'https://image.tmdb.org/t/p/w500/sOxr33wnRuKazR9ClHek73T8qnK.jpg', 'https://www.youtube.com/watch?v=iszwuX1AK6A', 5);

-- Movie-Genre mappings
INSERT IGNORE INTO MOVIE_GENRE VALUES
(1,11),(1,8),(1,12),   -- Inception: Sci-Fi,Mystery,Thriller
(2,11),(2,6),(2,5),    -- Interstellar: Sci-Fi,Drama,Adventure
(3,1),(3,5),(3,12),    -- Dark Knight: Action,Crime,Thriller
(4,6),(4,13),(4,14),   -- Schindler's List: Drama,Biography,History
(5,1),(5,12),(5,8),    -- Jaws: Action,Thriller,Horror
(6,4),(6,6),           -- 3 Idiots: Comedy,Drama
(7,4),(7,6),(7,11),    -- PK: Comedy,Drama,Sci-Fi
(8,1),(8,2),(8,11),    -- Avatar: Action,Adventure,Sci-Fi
(9,6),(9,10),(9,9),    -- Titanic: Drama,Romance,Mystery
(10,5),(10,6),(10,12), -- Goodfellas: Crime,Drama,Thriller
(11,5),(11,6),(11,12), -- The Departed: Crime,Drama,Thriller
(12,6),(12,12),(12,9), -- Fight Club: Drama,Thriller,Mystery
(13,5),(13,6),(13,12), -- Se7en: Crime,Drama,Thriller
(14,6),(14,11),(14,12),-- Arrival: Drama,Sci-Fi,Thriller
(15,2),(15,11),(15,6), -- Dune: Adventure,Sci-Fi,Drama
(16,5),(16,12),(16,4), -- Pulp Fiction: Crime,Thriller,Comedy
(17,1),(17,5),(17,6),  -- Django: Action,Crime,Drama
(18,6),(18,9),(18,12), -- The Prestige: Drama,Mystery,Thriller
(19,1),(19,6),(19,14), -- Saving Private Ryan: Action,Drama,History
(20,4),(20,6),         -- Munna Bhai M.B.B.S.: Comedy,Drama
(21,9),(21,12),(21,6), -- Shutter Island: Mystery,Thriller,Drama
(22,9),(22,12),(22,6), -- Gone Girl: Mystery,Thriller,Drama
(23,11),(23,12),(23,6),-- Blade Runner 2049: Sci-Fi,Thriller,Drama
(24,5),(24,6),(24,2),  -- Inglourious Basterds: Crime,Drama,Adventure
(25,13),(25,5),(25,6), -- Catch Me If You Can: Biography,Crime,Drama
(26,11),(26,2),(26,6), -- The Martian: Sci-Fi,Adventure,Drama
(27,13),(27,5),(27,6); -- The Wolf of Wall Street: Biography,Crime,Drama

-- Movie-Platform mappings
INSERT IGNORE INTO MOVIE_PLATFORM VALUES
(1,2),(1,4),(2,2),(3,4),(3,1),(4,1),(5,6),(6,1),(7,1),(8,3),
(9,2),(10,1),(11,4),(12,1),(12,4),(13,1),(14,2),(15,1),(16,2),(17,1),
(18,1),(18,4),(19,1),(19,3),(20,1),(21,4),(22,1),(22,4),(23,4),(23,1),
(24,1),(24,2),(25,2),(26,3),(26,2),(27,1),(27,4);
