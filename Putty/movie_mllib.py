from pyspark.sql import SparkSession
from pyspark.ml.recommendation import ALS
from pyspark.sql import Row
from pyspark.sql.functions import lit

#Load up movie ID -> movie name dict
def loadMovieNames():
    movieNames = {}
    with open("ml-100k/u.item") as f:
        for line in f:
            fields = line.split('|')
            movieNames[int(fields[0])] = fields[1].decode('ascii','ignore')
    return movieNames

#Convert u.data lines into (userID, movieID, rating) rows

def parseInput(line):
    fields = line.value.split()
    return Row(userID = int(fields[0]), movieID = int(fields[1]), rating = float(fields[2]))

if __name__ == "__main__":
    #Create a Spark Session (the config bit is only for Windows!)
    spark = SparkSession.builder.appName("MovieRecs").getOrCreate()

    #This line in neccesary on HDP 2.6.5
    spark.conf.set("spark.sql.crossJoin.enabled", "true")

    #Load up our movie ID -> name dictionary
    movieNames = loadMovieNames()

    #Get raw data
    lines = spark.read.text("hdfs:///user/maria_dev/ml-100k/u_edited.data").rdd

    #Convert it to RDD of row objects with (userID, movieID, rating)
    ratingsRDD = lines.map(parseInput)

    #Convert to a dataframe and cache it
    ratings = spark.createDataFrame(ratingsRDD).cache()

    #create an ALS collaborative filtering model from complete dataset
    als = ALS(maxIter=5, regParam=0.01, userCol="userID", itemCol="movieID", ratingCol="rating")
    model = als.fit(ratings)

    print("\nRatings for user ID 0:")
    userRatings = ratings.filter("userID = 0")
    for rating in userRatings.collect():
        print movieNames[rating['movieID']], rating['rating']

    print("\nTop 20 recommendation:")
    #Find movies rated more than 100 times
    ratingCounts = ratings.groupBy("movieID").count().filter("count > 100")
    #Construct a test data frame for user 0, for every movie rated more than 100 times
    popularMovies = ratingCounts.select("movieID").withColumn('userID', lit(0))

    #Run our model on that list of popular movies for user ID 0
    recommendations = model.transform(popularMovies)

    #get the top 20 with the highest predicted ratings
    topRecommendations = recommendations.sort(recommendations.prediction.desc()).take(20)

    for recommendation in topRecommendations:
        print(movieNames[recommendation['movieID']], recommendation['prediction'])

    spark.stop()

