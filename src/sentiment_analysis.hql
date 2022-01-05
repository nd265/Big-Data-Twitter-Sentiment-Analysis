-- author: Navya Dahiya
-- last updated: 10 July, 2018

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
      location :string
      >
   
)
    ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
    WITH SERDEPROPERTIES ("ignore.malformed.json" = "true")
    LOCATION '/project/db/RAW_TWEETS'
    ROW FORMAT SERDE 'com.cloudera.hive.serde.JsonSerDe';

flume-ng agent -n TwitterAgent -f /opt/apache-flume-1.6.0-bin/conf/flume.conf

LOAD DATA inpath '/twitter/tweets/water' overwrite INTO TABLE raw_tweets;

CREATE TABLE dictionary(
    word STRING,
    rating INT) 
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t';

LOAD DATA LOCAL inpath '/home/navya/Downloads/afinn165.txt' overwrite INTO TABLE dictionary;

CREATE VIEW filter_tweets AS
    SELECT
        id,
        source,
        text,
        `user`.screen_name,
        `user`.name,  
        `user`.statuses_count,
        `user`.friends_count,
        `user`.followers_count,
        `user`.location,
        retweeted_status,
        entities.hashtags,entities.user_mentions
   FROM 
        raw_tweets;


-- number of tows:1026


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

970

#CREATE VIEW splitted_words as select *,split(text,' ') as words from remove_spam;

#CREATE VIEW tweet_word as select id,screen_name,name ,word from splitted_words LATERAL VIEW explode(words) w as word;

---remove non english words
#CREATE VIEW clean_tweet_word as select * from tweet_word where regexp_replace(tweet_word.word,'[^a-zA-Z0-9]+', '')!='';

#CREATE VIEW clean_tweet_words as select * from remove_spam where regexp_replace(remove_spam.text,'[^a-zA-Z0-9]+', '')!='';

#CREATE VIEW remove_non_english_text as select * from remove_spam where regexp_replace(remove_spam.text,'[^a-zA-Z0-9]+', '')!='';

#CREATE VIEW remove_non_english_locations as select * from remove_spam where regexp_replace(remove_spam.`user`.location,'[^a-zA-Z0-9]+', '')!='';


CREATE VIEW cleaned_tweets as select * from remove_spam where regexp_replace(remove_spam.location,'[^a-zA-Z0-9]+', '')!='' AND regexp_replace(remove_spam.location,'[^a-zA-Z0-9]+', '')!='';


#CREATE VIEW clean_tweet_word2 as select id,name,word from clean_tweet_word;

hive> set mapreduce.map.memory.mb=4096;

hive >set mapreduce.map.java.opts=-Xmx3600M;


CREATE VIEW sentiment2 as select ctw.id,ctw.word,ctw.name,dictionary.rating from clean_tweet_word ctw LEFT OUTER JOIN dictionary ON(ctw.word =dictionary.word);

select id,name,rating from sentiment2 group by(name);

CREATE sentiment_analysis as select name,avg(rating) as rating from sentiment2 group by name oder by(rating) desc;

----top 10 hashtags:
CREATE VIEW hash_tags as select ht,count(ht) as countht from cleaned_tweets lateral VIEW explode(hashtags.text) dummy as ht group by ht order by countht desc limit 10;
 
--top 5 locations of tweet users;
CREATE VIEW top_locations as select location, count(location) as cnt from cleaned_tweets group by(location) order by(cnt) desc limit 5;

--top 10 users with most tweets--most active users
CREATE VIEW top_users as select screen_name,count(id) as cnt_id from cleaned_tweets group by screen_name having screen_name IS NOT NULL order by (cnt_id) desc limit 10;


--extract the sources:
CREATE VIEW sources_tweet as select screen_name, substr(source,instr(source,">"),instr(source,"</a>")-instr(source,">")) as source from cleaned_tweets;

--top sources used by the users
CREATE VIEW top_sources as select source,count(source) as cnt_source from sources_tweet group by(source) order by cnt_source desc limit 3;

--top 10 users with most followers
CREATE VIEW max_followers as select screen_name,followers_count from cleaned_tweets order by followers_count desc limit 10;


--top 10 whose posts are most retweeetd 
CREATE VIEW most_retweeted_people as select retweeted_status.`user`.screen_name,count(retweeted_status.`user`.screen_name) as cnt_screen_name from cleaned_tweets group by(retweeted_status.`user`.screen_name) order by cnt_screen_name desc limit 10;

--location and sources
CREATE VIEW location_source as select sources_tweet.source,cleaned_tweets.location from sources_tweet inner join cleaned_tweets on sources_tweet.screen_name=cleaned_tweets.screen_name;

set hive.cli.print.header=true;

insert overwrite directory '/project/output/most_retweeted_people' row format delimited fields terminated by ','  select * from most_retweeted_people;

insert overwrite directory '/project/output/max_followers' row format delimited fields terminated by ','  select * from max_followers;

insert overwrite directory '/project/output/top_sources' row format delimited fields terminated by ','  select * from top_sources;

insert overwrite directory '/project/output/top_locations' row format delimited fields terminated by ',' select * from top_locations; 

insert overwrite directory '/project/output/hashtags' row format delimited fields terminated by ','  select * from hash_tags;

CREATE VIEW split_words as select screen_name as screen_name,split(text, ' ') as words from cleaned_tweets;

CREATE TABLE tweet_word as select id as id, word from split_words lateral VIEW explode(words) w as word;

CREATE VIEW word_rating as select tweet_word.screen_name,tweet_word.word,dictionary.rating from tweet_word inner join dictionary on (tweet_word.word=dictionary.word);

CREATE VIEW sentiment as select screen_name,avg(rating) as rating from word_rating group by(word_rating.screen_name) order by rating desc;



CREATE VIEW count_sentiment as select count(screen_name>0.0) as positive,count(screen_name<0.0) as negative, count(screen_name=0) as neutral from sentiment;

 insert overwrite directory '/project/output/count_sentiment' row format delimited fields terminated by ','  select * from count_sentiment;




CREATE VIEW location_sentiment as select location,rating from cleaned_tweets left outer join sentiment on cleaned_tweets.screen_name=sentiment.screen_name group by(location) having location is not null;




