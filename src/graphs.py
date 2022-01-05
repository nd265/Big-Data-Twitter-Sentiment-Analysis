import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

most_active_users=pd.read_csv(r"/home/navya/Documents/csv files/users.csv",header=None)
most_active_users.columns=["name","tweets"]

y_pos=np.arange(len(most_active_users.name))

plt.bar(y_pos,most_active_users.tweets,align='center',color='GREEN')
plt.xticks(y_pos,most_active_users.name,rotation=20,fontsize=7)

plt.ylabel('tweets per 15 mins')
plt.xlabel('Users')
plt.title('Most active users')
plt.show()
'''

#most followers
most_followers=pd.read_csv(r"/home/navya/Documents/csv files/followers.csv",header=None)
most_followers.columns=["name","followers"]
y_pos=np.arange(len(most_followers.name))

plt.bar(y_pos,most_followers.followers,align='center')
plt.xticks(y_pos,most_followers.name,rotation=20,fontsize=7)

plt.ylabel('number of followers')
plt.xlabel('Users')
plt.title('Users with most followers')
plt.show()
'''

'''
#overall sentiment
sentiment_overall=pd.read_csv(r"/home/navya/Documents/csv files/count_sentiment.csv",header=None)
sentiment_overall.columns=['sentiment','tweets']
sentiment_data=sentiment_overall.sentiment
tweets_data=sentiment_overall.tweets
colors=['red','green','yellow']
explode=(0,0.1,0)
plt.pie(tweets_data,labels=sentiment_data,explode=explode,colors=colors,shadow=True,autopct='%1.1f%%')
plt.title('overall sentiments')
plt.show()
'''

'''

#sources for tweets
sources=pd.read_csv(r"/home/navya/Documents/csv files/sources.csv",header=None)
sources.columns=['source','number']
source_data=sources.source
number_data=sources.number
colors=['#1f77b4','#ff7f0e','#2ca02c']
explode=(0.1,0,0)
plt.pie(number_data,labels=source_data,explode=explode,colors=colors,shadow=True,autopct='%1.1f%%')
plt.title('sources for tweets')
plt.show()
'''
'''
#top 10 hashtags
top_hashtags=pd.read_csv(r"/home/navya/Documents/csv files/hashtags.csv",header=None)
top_hashtags.columns=["hashtag","number"]

y_pos=np.arange(len(top_hashtags.hashtag))

plt.bar(y_pos,top_hashtags.number,align='center',color='Red')
plt.xticks(y_pos,top_hashtags.hashtag,rotation=20,fontsize=7)

plt.ylabel('frequency')
plt.xlabel('hashtags')
plt.title('Top 10 hashtags')
plt.show()

#most retweeted users'''
'''
most_retweeted_users=pd.read_csv(r"/home/navya/Documents/csv files/most_retweeted.csv",header=None)
most_retweeted_users.columns=["name","retweet_frequency"]

y_pos=np.arange(len(most_retweeted_users.name))

plt.bar(y_pos,most_retweeted_users.retweet_frequency ,align='center')
plt.xticks(y_pos,most_retweeted_users.name,rotation=25,fontsize=7)

plt.ylabel('Retweet frequency')
plt.xlabel('Name of Users')
plt.title('Most retweeted users')
plt.show()
'''

'''
location_sentiment=pd.read_csv(r"/home/navya/Documents/csv files/location_sentiment_final.csv",header=None)
location_sentiment.columns=['location','sentiment']
x=location_sentiment.location
y=location_sentiment.sentiment
xticks=
plt.plot(y)
plt.xticks(range(len(x)),x)
plt.show()
'''
