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
('Quentin Tarantino',  'American'),
('Nitesh Tiwari',      'Indian'),
('S. S. Rajamouli',    'Indian'),
('Lokesh Kanagaraj',   'Indian'),
('Jeethu Joseph',      'Indian'),
('Prashanth Neel',     'Indian'),
('Francis Ford Coppola','American'),
('Frank Darabont',     'American'),
('Lana Wachowski',     'American'),
('Ridley Scott',       'British'),
('Bong Joon-ho',       'South Korean'),
('Damien Chazelle',    'American'),
('George Miller',      'Australian'),
('Peter Jackson',      'New Zealander'),
('Robert Zemeckis',    'American'),
('Todd Phillips',      'American'),
('Jonathan Demme',     'American'),
('Hayao Miyazaki',     'Japanese'),
('Lee Unkrich',        'American'),
('Makoto Shinkai',     'Japanese'),
('Wes Anderson',       'American'),
('Joseph Kosinski',    'American'),
('Matt Reeves',        'American'),
('Joel Coen',          'American');

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
('The Wolf of Wall Street', 2013, 8.2, 'https://image.tmdb.org/t/p/w500/sOxr33wnRuKazR9ClHek73T8qnK.jpg', 'https://www.youtube.com/watch?v=iszwuX1AK6A', 5),
('Dangal',             2016, 8.3, 'https://dummyimage.com/500x750/111/eee.jpg&text=Dangal+(2016)', 'https://www.youtube.com/watch?v=x_7YlGv9u1g', 9),
('RRR',                2022, 7.8, 'https://dummyimage.com/500x750/111/eee.jpg&text=RRR+(2022)', 'https://www.youtube.com/watch?v=NgBoMJy386M', 10),
('Vikram',             2022, 8.3, 'https://dummyimage.com/500x750/111/eee.jpg&text=Vikram+(2022)', 'https://www.youtube.com/watch?v=OKBMCL-frPU', 11),
('Drishyam',           2013, 8.2, 'https://dummyimage.com/500x750/111/eee.jpg&text=Drishyam+(2013)', 'https://www.youtube.com/watch?v=AuuX2j14NBg', 12),
('KGF: Chapter 1',     2018, 8.2, 'https://dummyimage.com/500x750/111/eee.jpg&text=KGF+Chapter+1+(2018)', 'https://www.youtube.com/watch?v=cn8mueJ9wKk', 13),
('The Godfather',      1972, 9.2, 'https://dummyimage.com/500x750/111/eee.jpg&text=The+Godfather+(1972)', 'https://www.youtube.com/watch?v=sY1S34973zA', 14),
('The Shawshank Redemption', 1994, 9.3, 'https://dummyimage.com/500x750/111/eee.jpg&text=The+Shawshank+Redemption+(1994)', 'https://www.youtube.com/watch?v=6hB3S9bIaco', 15),
('The Matrix',         1999, 8.7, 'https://dummyimage.com/500x750/111/eee.jpg&text=The+Matrix+(1999)', 'https://www.youtube.com/watch?v=m8e-FF8MsqU', 16),
('Gladiator',          2000, 8.5, 'https://dummyimage.com/500x750/111/eee.jpg&text=Gladiator+(2000)', 'https://www.youtube.com/watch?v=P5ieIbInFpg', 17),
('Parasite',           2019, 8.5, 'https://dummyimage.com/500x750/111/eee.jpg&text=Parasite+(2019)', 'https://www.youtube.com/watch?v=5xH0HfJHsaY', 18),
('Whiplash',           2014, 8.5, 'https://dummyimage.com/500x750/111/eee.jpg&text=Whiplash+(2014)', 'https://www.youtube.com/watch?v=7d_jQycdQGo', 19),
('Mad Max: Fury Road', 2015, 8.1, 'https://dummyimage.com/500x750/111/eee.jpg&text=Mad+Max+Fury+Road+(2015)', 'https://www.youtube.com/watch?v=hEJnMQG9ev8', 20),
('The Lord of the Rings: The Fellowship of the Ring', 2001, 8.8, 'https://dummyimage.com/500x750/111/eee.jpg&text=LOTR+Fellowship+(2001)', 'https://www.youtube.com/watch?v=V75dMMIW2B4', 21),
('Forrest Gump',       1994, 8.8, 'https://dummyimage.com/500x750/111/eee.jpg&text=Forrest+Gump+(1994)', 'https://www.youtube.com/watch?v=bLvqoHBptjg', 22),
('Joker',              2019, 8.4, 'https://dummyimage.com/500x750/111/eee.jpg&text=Joker+(2019)', 'https://www.youtube.com/watch?v=zAGVQLHvwOY', 23),
('The Silence of the Lambs', 1991, 8.6, 'https://dummyimage.com/500x750/111/eee.jpg&text=Silence+of+the+Lambs+(1991)', 'https://www.youtube.com/watch?v=W6Mm8Sbe__o', 24),
('Spirited Away',      2001, 8.6, 'https://dummyimage.com/500x750/111/eee.jpg&text=Spirited+Away+(2001)', 'https://www.youtube.com/watch?v=ByXuk9QqQkk', 25),
('Coco',               2017, 8.4, 'https://dummyimage.com/500x750/111/eee.jpg&text=Coco+(2017)', 'https://www.youtube.com/watch?v=xlnPHQ3TLX8', 26),
('Your Name',          2016, 8.4, 'https://dummyimage.com/500x750/111/eee.jpg&text=Your+Name+(2016)', 'https://www.youtube.com/watch?v=xU47nhruN-Q', 27),
('The Social Network', 2010, 7.8, 'https://dummyimage.com/500x750/111/eee.jpg&text=The+Social+Network+(2010)', 'https://www.youtube.com/watch?v=lB95KLmpLR4', 6),
('Prisoners',          2013, 8.1, 'https://dummyimage.com/500x750/111/eee.jpg&text=Prisoners+(2013)', 'https://www.youtube.com/watch?v=bpXfcTF6iVk', 7),
('Zodiac',             2007, 7.7, 'https://dummyimage.com/500x750/111/eee.jpg&text=Zodiac+(2007)', 'https://www.youtube.com/watch?v=yNncHPl1UXg', 6),
('The Grand Budapest Hotel', 2014, 8.1, 'https://dummyimage.com/500x750/111/eee.jpg&text=Grand+Budapest+Hotel+(2014)', 'https://www.youtube.com/watch?v=1Fg5iWmQjwk', 30),
('Oppenheimer',        2023, 8.4, 'https://dummyimage.com/500x750/111/eee.jpg&text=Oppenheimer+(2023)', 'https://www.youtube.com/watch?v=uYPbbksJxIg', 1),
('Avatar: The Way of Water', 2022, 7.6, 'https://dummyimage.com/500x750/111/eee.jpg&text=Avatar+Way+of+Water+(2022)', 'https://www.youtube.com/watch?v=d9MyW72ELq0', 4),
('Top Gun: Maverick',  2022, 8.2, 'https://dummyimage.com/500x750/111/eee.jpg&text=Top+Gun+Maverick+(2022)', 'https://www.youtube.com/watch?v=giXco2jaZ_4', 31),
('The Batman',         2022, 7.8, 'https://dummyimage.com/500x750/111/eee.jpg&text=The+Batman+(2022)', 'https://www.youtube.com/watch?v=mqqft2x_Aa4', 32),
('No Country for Old Men', 2007, 8.2, 'https://dummyimage.com/500x750/111/eee.jpg&text=No+Country+for+Old+Men+(2007)', 'https://www.youtube.com/watch?v=38A__WT3-o0', 33),
('La La Land',         2016, 8.0, 'https://dummyimage.com/500x750/111/eee.jpg&text=La+La+Land+(2016)', 'https://www.youtube.com/watch?v=0pdqf4P9MB8', 19),
('Blade Runner',       1982, 8.1, 'https://dummyimage.com/500x750/111/eee.jpg&text=Blade+Runner+(1982)', 'https://www.youtube.com/watch?v=eogpIG53Cis', 17);

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
(27,13),(27,5),(27,6), -- The Wolf of Wall Street: Biography,Crime,Drama
(28,6),(28,13),(28,14),-- Dangal: Drama,Biography,History
(29,1),(29,2),(29,6),  -- RRR: Action,Adventure,Drama
(30,1),(30,5),(30,12), -- Vikram: Action,Crime,Thriller
(31,6),(31,9),(31,12), -- Drishyam: Drama,Mystery,Thriller
(32,1),(32,5),(32,6),  -- KGF: Chapter 1: Action,Crime,Drama
(33,5),(33,6),         -- The Godfather: Crime,Drama
(34,5),(34,6),         -- The Shawshank Redemption: Crime,Drama
(35,1),(35,11),        -- The Matrix: Action,Sci-Fi
(36,1),(36,2),(36,6),  -- Gladiator: Action,Adventure,Drama
(37,5),(37,6),(37,12), -- Parasite: Crime,Drama,Thriller
(38,6),                -- Whiplash: Drama
(39,1),(39,2),(39,11), -- Mad Max: Fury Road: Action,Adventure,Sci-Fi
(40,2),(40,7),(40,6),  -- LOTR Fellowship: Adventure,Fantasy,Drama
(41,6),(41,10),        -- Forrest Gump: Drama,Romance
(42,5),(42,6),(42,12), -- Joker: Crime,Drama,Thriller
(43,5),(43,6),(43,12), -- The Silence of the Lambs: Crime,Drama,Thriller
(44,3),(44,2),(44,7),  -- Spirited Away: Animation,Adventure,Fantasy
(45,3),(45,2),(45,7),  -- Coco: Animation,Adventure,Fantasy
(46,3),(46,10),(46,7), -- Your Name: Animation,Romance,Fantasy
(47,6),(47,13),        -- The Social Network: Drama,Biography
(48,5),(48,6),(48,9),  -- Prisoners: Crime,Drama,Mystery
(49,5),(49,6),(49,9),  -- Zodiac: Crime,Drama,Mystery
(50,4),(50,5),(50,2),  -- The Grand Budapest Hotel: Comedy,Crime,Adventure
(51,6),(51,13),(51,14),-- Oppenheimer: Drama,Biography,History
(52,1),(52,2),(52,11), -- Avatar: The Way of Water: Action,Adventure,Sci-Fi
(53,1),(53,6),         -- Top Gun: Maverick: Action,Drama
(54,1),(54,5),(54,9),  -- The Batman: Action,Crime,Mystery
(55,5),(55,6),(55,12), -- No Country for Old Men: Crime,Drama,Thriller
(56,4),(56,6),(56,10), -- La La Land: Comedy,Drama,Romance
(57,11),(57,12),(57,6);-- Blade Runner: Sci-Fi,Thriller,Drama

-- Movie-Platform mappings
INSERT IGNORE INTO MOVIE_PLATFORM VALUES
(1,2),(1,4),(2,2),(3,4),(3,1),(4,1),(5,6),(6,1),(7,1),(8,3),
(9,2),(10,1),(11,4),(12,1),(12,4),(13,1),(14,2),(15,1),(16,2),(17,1),
(18,1),(18,4),(19,1),(19,3),(20,1),(21,4),(22,1),(22,4),(23,4),(23,1),
(24,1),(24,2),(25,2),(26,3),(26,2),(27,1),(27,4),
(28,2),(28,1),(29,2),(29,1),(30,1),(30,2),(31,2),(31,1),(32,1),(32,2),
(33,1),(33,2),(34,1),(34,2),(35,1),(35,4),(36,1),(36,2),(37,1),(37,4),
(38,1),(38,4),(39,1),(39,4),(40,1),(40,2),(41,1),(41,2),(42,1),(42,4),
(43,1),(43,4),(44,1),(44,3),(45,1),(45,3),(46,1),(46,3),(47,1),(47,4),
(48,1),(48,4),(49,1),(49,4),(50,1),(50,2),(51,1),(51,4),(52,3),(52,1),
(53,1),(53,2),(54,1),(54,4),(55,1),(55,4),(56,1),(56,2),(57,1),(57,4);
