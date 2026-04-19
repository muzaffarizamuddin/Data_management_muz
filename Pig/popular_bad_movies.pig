ratings = LOAD '/user/maria_dev/ml-100k/u.data' AS 
(
	userID:int,
    movieID:int,
    rating:int,
    ratingTime:int
);

metadata = LOAD '/user/maria_dev/ml-100k/u.item' USING
	PigStorage('|') AS
(
	movieID:int,
    movieTitle:chararray,
    releaseDate:chararray,
    videoRelease:chararray,
    imdbLink:chararray
);

nameLookup = FOREACH metadata GENERATE movieID, movieTitle,
	ToUnixTime(ToDate(releaseDate, 'dd-MMM-yyyy')) as releaseTime;
--DUMP nameLookup;

ratingsByMovie = GROUP ratings by movieID;
--DUMP ratingsByMovie;

avgRatings = FOREACH ratingsByMovie GENERATE group AS movieID,
	AVG(ratings.rating) AS avgRating;
--DUMP avgRatings;

countRatings = FOREACH ratingsByMovie GENERATE group AS movieID,
	COUNT(ratings.rating) AS countRating;

bad_movies = FILTER avgRatings BY avgRating < 2.0;

--JOIN--
bad_movies_data = JOIN bad_movies BY movieID, nameLookup BY movieID, countRatings BY movieID;

--clean as joining produced a few movieID columns
bad_movies_clean = FOREACH bad_movies_data GENERATE 
    bad_movies::movieID, 
    movieTitle, 
    avgRating, 
    countRating;

--ORDER BY--
bad_movies_sorted = ORDER bad_movies_clean BY countRating DESC;

DUMP bad_movies_sorted;

STORE bad_movies_sorted INTO 'bad_movie_list';







