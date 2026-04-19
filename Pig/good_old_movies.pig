ratings = LOAD '/user/maria_dev/ml-100k/u.data' AS 
(
	userID:int,
    movieID:int,
    rating:int,
    ratingTime:int
);

--DUMP ratings;

metadata = LOAD '/user/maria_dev/ml-100k/u.item' USING
	PigStorage('|') AS
(
	movieID:int,
    movieTitle:chararray,
    releaseDate:chararray,
    videoRelease:chararray,
    imdbLink:chararray
);
--DUMP metadata;

nameLookup = FOREACH metadata GENERATE movieID, movieTitle,
	ToUnixTime(ToDate(releaseDate, 'dd-MMM-yyyy')) as releaseTime;
--DUMP nameLookup;

ratingsByMovie = GROUP ratings by movieID;
--DUMP ratingsByMovie;

avgRatings = FOREACH ratingsByMovie GENERATE group AS movieID,
	AVG(ratings.rating) AS avgRating;
--DUMP avgRatings;

--DESCRIBE ratings;
--DESCRIBE ratingsByMovie;
--DESCRIBE avgRatings


five_star_movies = FILTER avgRatings BY avgRating > 4.0;

--DUMP five_star_movies;
--JOIN--

five_star_movies_data = JOIN five_star_movies BY movieID, nameLookup BY movieID;
--DESCRIBE five_star_movies_data;
--DUMP five_star_movies_data;

--ORDER BY--
oldest_five_star_movie = ORDER five_star_movies_data BY
	nameLookup::releaseTime;

DUMP oldest_five_star_movie










