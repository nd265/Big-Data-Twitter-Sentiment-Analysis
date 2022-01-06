# Big-Data-Twitter-Sentiment-Analysis
Twitter Sentiment analysis on FIFA World Cup using Hadoop frameworks | Mini project during Internship at Birlasoft Pvt Ltd, India 2018

### Workflow
This is the workflow of the project
![**Workflow diagram**](https://github.com/nd265/Big-Data-Twitter-Sentiment-Analysis/blob/main/data/assets/workflow_diagram.png?raw=true)

### Report
The report can be found [here](https://github.com/nd265/Big-Data-Twitter-Sentiment-Analysis/blob/main/report/Report.pdf)

### Usage and Installations

Here I have used Hadoop and its ecosystem to store and process real time Twitter data on FIFA World Cup 2018. I have used Apache FLUME to configure with Twitter API keys and fetch live streaming tweets. FLUME can be configured to fetch required keywords from twitter and the keywords I used were 'World Cup', 'FIFA', 'Messi'
FLUME saves all the tweets in HDFS (Hadoop Distributed File System) in JSON format. HIVE, which is a Hadoop Data Warehouse tool is used to create a table on top of the JSON tweets fetched by FLUME using JSON SerDe (Serializer and Deserializer, which tell Hive how it should translate the data Hive readable format) and Hive queries are used to pre-process and analyse the tweets.

In order to fetch the live streamed tweets, you need to have Consumer Key (API Key) and Consumer Secret (API Secret), Access Token and Access Token Secret. The steps to create these can be found [here](https://developer.twitter.com/en/docs/authentication/oauth-2-0/bearer-tokens)

After generation of Twitter API tokens and keys:

  1) Install and Configure Flume
  2) Download the flume-sources-1.0-SNAPSHOT.jar
  3) Copy the jars to Flume Plugin Directories
  4) Add the JAR to Flume class path in the configuration file
  5) Update the file `flume.conf` ([reference file](https://github.com/nd265/Big-Data-Twitter-Sentiment-Analysis/blob/main/data/assets/flume.conf)) with key and secure tokens to access Twitter API
  6) Specify some keywords as `source.Twitter.keywords=FIFA, World Cup, Messi`
  7) Specify HDFS storage location path in `flume.conf`
  8) Create HDFS directories as configured in `flume.conf` and give full permissions to FLUME in order to write tweets in that location.

  9) Start the FLUME agent manually or like in the [code](https://github.com/nd265/Big-Data-Twitter-Sentiment-Analysis/blob/main/src/sentiment_analysis.hql)
  10) Once the tweets are stored in the mentioned directory, use Hive to build a table on top of it and start running the queries in `sentiment_analysis.hql`

  11) Once, all the analysis is done, store the results in csv format from Hive tables and visualize your results using Python
To generate graphs, execute the python file `graphs.py` in the 'src' folder

Unfortunately, I could not upload the Twitter data here as during my internship I was not able to take a copy of the large amount of data from the machine due to company's privacy policies.
