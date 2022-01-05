-- author: Navya Dahiya
-- last updated: 10 July, 2018

-- add the jar below to allow Hive to parse json data stored by Flume in HDFS
add jar /opt/apache-hive-2.1.0-bin/lib/Hive-JSON-Serde/json-serde/target/json-serde-1.3.9-SNAPSHOT-jar-with-dependencies.jar 

CREATE DATABASE twitter_tweets;
USE twitter_tweets;

CREATE EXTERNAL TABLE raw_tweets (
   id BIGINT,
   created_at STRING,
   source STRING,
   favorited BOOLEAN,
   retweet_count INT,
   retweeted_status STRUCT<
      text:STRING,
      `user`:STRUCT<screen_name:STRING,name:STRING>>,
   entities STRUCT<
      urls:ARRAY<STRUCT<expanded_url:STRING>>,
      user_mentions:ARRAY<STRUCT<screen_name:STRING,name:STRING>>,
      hashtags:ARRAY<STRUCT<text:STRING>>>,
   text STRING,
   `user` STRUCT<
      screen_name:STRING,
      name:STRING,
      friends_count:INT,
      followers_count:INT,
      statuses_count:INT,
      verified:BOOLEAN,
      location :STRING
      >
   
)
    ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
    WITH SERDEPROPERTIES ("ignore.malformed.json" = "true")
    LOCATION '/project/db/RAW_TWEETS'
    ROW FORMAT SERDE 'com.cloudera.hive.serde.JsonSerDe';

-- start the flume agent
flume-ng agent -n TwitterAgent -f /opt/apache-flume-1.6.0-bin/conf/flume.conf

-- load tweets into Hive
LOAD DATA inpath '/twitter/tweets' overwrite INTO TABLE raw_tweets;

-- create table to store AFINN 165 dictionary woth sentiment valences
CREATE TABLE dictionary(
    word STRING,
    rating INT) 
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t';

-- load AFINN dictionary to the Hive table 
LOAD DATA LOCAL inpath '../data/afinn165.txt' overwrite INTO TABLE dictionary;

-- Extract and keep only those columns essential for analysis
CREATE VIEW filter_tweets AS
    SELECT
        id,
        source,
        text,
        `user`.screen_name AS screen_name,
        `user`.name AS name,  
        `user`.statuses_count AS statuses_count,
        `user`.friends_count AS friends_count,
        `user`.followers_count AS followers_count,
        `user`.location AS location,
        retweeted_status,
        entities.hashtags as hashtags,
        entities.user_mentions as user_mentions
   FROM 
        raw_tweets;

-- Identify and remove spam users based on the following conditions:
-- 1) who follow more people but are followed by less people (friends_count/followers_count), 
-- 2) who tweet short length messages
-- 3) who use a lot of hashtags

CREATE VIEW remove_spam AS
    SELECT * 
        FROM filter_tweets 
            WHERE 
                statuses_count > 50 
                AND
                    friends_count/followers_count > 0.01 
                AND
                    length(text) > 10 
                AND
                    size(hashtags) < 10;

CREATE VIEW cleaned_tweets AS 
    SELECT * 
    FROM remove_spam 
    WHERE 
        regexp_replace(remove_spam.text,'[^a-zA-Z0-9]+', '')!='' 
        AND 
        regexp_replace(remove_spam.location,'[^a-zA-Z0-9]+', '')!='';


set mapreduce.map.memory.mb=4096;

set mapreduce.map.java.opts=-Xmx3600M;



----top 10 hashtags:
CREATE VIEW hash_tags AS 
    SELECT 
        ht,
        count(ht) AS countht 
            FROM cleaned_tweets 
                lateral VIEW explode(hashtags.text) dummy AS ht 
                GROUP BY ht 
                ORDER BY countht DESC 
                LIMIT 10;
 
--top 5 locations of tweet users;
CREATE VIEW top_locations AS 
    SELECT 
        location, 
        count(location) AS cnt 
            FROM cleaned_tweets 
            GROUP BY(location) 
            ORDER BY(cnt) DESC 
            LIMIT 5;

--top 10 most active users
CREATE VIEW top_users AS 
    SELECT 
        screen_name,
        count(id) AS cnt_id 
            FROM cleaned_tweets 
            GROUP BY screen_name 
            HAVING screen_name IS NOT NULL 
            ORDER BY (cnt_id) DESC 
            LIMIT 10;


--extract the sources:
CREATE VIEW sources_tweet AS 
    SELECT 
        screen_name, 
        substr(source,instr(source,">"),instr(source,"</a>")-instr(source,">")) AS source 
            FROM cleaned_tweets;

--top sources used by the users
CREATE VIEW top_sources AS 
    SELECT 
        source,
        count(source) AS cnt_source 
            FROM sources_tweet 
            GROUP BY(source) 
            ORDER BY cnt_source DESC 
            LIMIT 3;

--top 10 users with most followers
CREATE VIEW max_followers AS 
    SELECT 
        screen_name,
        followers_count 
            FROM cleaned_tweets 
            ORDER BY followers_count DESC 
            LIMIT 10;


--top 10 whose posts are most retweeetd 
CREATE VIEW most_retweeted_people AS 
    SELECT 
        retweeted_status.screen_name,
        count(retweeted_status.screen_name) AS cnt_screen_name 
            FROM cleaned_tweets 
            GROUP BY(retweeted_status.screen_name) 
            ORDER BY cnt_screen_name DESC 
            LIMIT 10;

--location and sources
CREATE VIEW location_source AS 
    SELECT 
        sources_tweet.source,
        cleaned_tweets.location 
            FROM sources_tweet 
            INNER JOIN cleaned_tweets 
            ON 
            sources_tweet.screen_name=cleaned_tweets.screen_name;

set hive.cli.print.header=true;


-- split the tweets into single words as comma separated values in array format in the row
CREATE VIEW split_words AS 
    SELECT 
        screen_name AS screen_name,
        split(text, ' ') AS words 
            FROM cleaned_tweets;

-- split each word inside the array as a new row using the built in UDTF 'explode' and create a row per word
-- Also, convert the word to lowercase for comparison with word in 'dictionary' table
CREATE TABLE tweet_word AS 
    SELECT 
        id AS id, 
        lower(word) FROM split_words 
            lateral VIEW explode(words) w AS word;

-- join tables 'tweet_word' and 'dictionary' to map the sentiment valences from the words in dictionary to the tweet
CREATE VIEW word_rating AS 
    SELECT 
        tweet_word.screen_name,
        tweet_word.word,
        dictionary.rating 
            FROM tweet_word 
            INNER JOIN dictionary 
            ON 
            (tweet_word.word=dictionary.word);

-- sentiment per user
CREATE VIEW sentiment AS 
    SELECT 
        screen_name,
        avg(rating) AS rating 
            FROM word_rating 
            GROUP BY(word_rating.screen_name) 
            ORDER BY rating DESC;


-- overall sentiment for all users
CREATE VIEW count_sentiment AS 
    SELECT 
        count(screen_name>0.0) AS positive,
        count(screen_name<0.0) AS negative, 
        count(screen_name=0) AS neutral 
            FROM sentiment;


-- avg sentiment per country
CREATE VIEW location_sentiment AS 
    SELECT 
        location,
        rating 
            FROM cleaned_tweets 
            LEFT OUTER JOIN sentiment 
            ON cleaned_tweets.screen_name=sentiment.screen_name 
            GROUP BY(location) 
            HAVING location IS NOT NULL;


--save all results views as csv files
INSERT overwrite directory '../results/most_retweeted_people' ROW format delimited fields terminated BY ','  SELECT * FROM most_retweeted_people;

INSERT overwrite directory '../results/max_followers' ROW format delimited fields terminated BY ','  SELECT * FROM max_followers;

INSERT overwrite directory '../results/top_sources' ROW format delimited fields terminated BY ','  SELECT * FROM top_sources;

INSERT overwrite directory '../results/top_locations' ROW format delimited fields terminated BY ',' SELECT * FROM top_locations; 

INSERT overwrite directory '../results/hashtags' ROW format delimited fields terminated BY ','  SELECT * FROM hash_tags;

INSERT overwrite directory '../results/users' ROW format delimited fields terminated BY ','  SELECT * FROM top_users;

INSERT overwrite directory '../results/count_sentiment' ROW format delimited fields terminated BY ','  SELECT * FROM count_sentiment;

INSERT overwrite directory '../results/location_sentiment_final' ROW format delimited fields terminated BY ','  SELECT * FROM location_sentiment;


