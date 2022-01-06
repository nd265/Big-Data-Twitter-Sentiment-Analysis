#  author: Navya Dahiya
#  created: July, 2018
#  TODO: convert it into a function

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def main():

    #top 10 hashtags
    top_hashtags=pd.read_csv("results/hashtags.csv",header=None)
    top_hashtags.columns=["hashtag","number"]
    y_pos=np.arange(len(top_hashtags.hashtag))
    plt.bar(y_pos,top_hashtags.number,align='center',color='Red')
    plt.xticks(y_pos,top_hashtags.hashtag,rotation=20,fontsize=7)
    plt.ylabel('frequency')
    plt.xlabel('hashtags')
    plt.title('Top 10 hashtags')
    plt.savefig("results/hashtags.png", dpi=200, bbox_inches='tight')
    plt.close()

    # most active users
    most_active_users=pd.read_csv("results/users.csv",header=None)
    most_active_users.columns=["name","tweets"]
    y_pos=np.arange(len(most_active_users.name))
    plt.bar(y_pos,most_active_users.tweets,align='center',color='GREEN')
    plt.xticks(y_pos,most_active_users.name,rotation=20,fontsize=7)
    plt.ylabel('tweets per 15 mins')
    plt.xlabel('Users')
    plt.title('Most active users')
    plt.savefig("results/active_users.png", dpi=200, bbox_inches='tight')
    plt.close()

   #sources for tweets
    sources=pd.read_csv("results/top_sources.csv",header=None)
    sources.columns=['source','number']
    source_data=sources.source
    number_data=sources.number
    colors=['#1f77b4','#ff7f0e','#2ca02c']
    explode=(0.1,0,0)
    plt.pie(number_data,labels=source_data,explode=explode,colors=colors,shadow=True,autopct='%1.1f%%')
    plt.title('sources for tweets')
    plt.savefig("results/sources.png", dpi=200, bbox_inches='tight')
    plt.close()

    #most followers
    most_followers=pd.read_csv("results/max_followers.csv",header=None)
    most_followers.columns=["name","followers"]
    y_pos=np.arange(len(most_followers.name))
    plt.bar(y_pos,most_followers.followers,align='center')
    plt.xticks(y_pos,most_followers.name,rotation=20,fontsize=7)
    plt.ylabel('number of followers')
    plt.xlabel('Users')
    plt.title('Users with most followers')
    plt.savefig("results/max_followers.png", dpi=200, bbox_inches='tight')
    plt.close()

    # most retweeted users
    most_retweeted_users=pd.read_csv("results/most_retweeted.csv",header=None)
    most_retweeted_users.columns=["name","retweet_frequency"]
    y_pos=np.arange(len(most_retweeted_users.name))
    plt.bar(y_pos,most_retweeted_users.retweet_frequency ,align='center')
    plt.xticks(y_pos,most_retweeted_users.name,rotation=25,fontsize=7)
    plt.ylabel('Retweet frequency')
    plt.xlabel('Name of Users')
    plt.title('Most retweeted users')
    plt.savefig("results/most_retweeted.png", dpi=200, bbox_inches='tight')
    plt.close()
   
    #overall sentiment
    sentiment_overall=pd.read_csv("../results/count_sentiment.csv",header=None)
    sentiment_overall.columns=['sentiment','tweets']
    sentiment_data=sentiment_overall.sentiment
    tweets_data=sentiment_overall.tweets
    colors=['red','green','yellow']
    explode=(0,0.1,0)
    plt.pie(tweets_data,labels=sentiment_data,explode=explode,colors=colors,shadow=True,autopct='%1.1f%%')
    plt.title('overall sentiments')
    plt.savefig("../results/heheh.png", dpi=200, bbox_inches='tight')
    plt.close()
   
    #location wise average sentiment
    df=pd.read_csv("results/location_sentiment_final.csv",header=None)
    print(df)
    df.columns=['location','sentiment']
    extract the last word after space 
    df['location']=df['location'].str.split(' ').str[-1]		
    filename='../data/country_list.txt'
    f=open(filename,"r") 
    country=[line.decode("utf-16be","ignore").replace("\r\n", "").encode("utf-8","ignore") for line in f]
    uper_country= map(lambda x:x.upper(),country)
    uper_country2=map(lambda y:y.strip(),uper_country)
    df_obj = df.select_dtypes(['object'])
    df[df_obj.columns] = df_obj.apply(lambda x: x.str.strip().str.upper())
    df3=df[df['location'].isin(uper_country2)]
    df3=df3.groupby('location')['sentiment'].mean().reset_index()
    
    #remove the 1st row as it is blank 
    df3=df3.iloc[1:]
    xs=df3.location
    ys=df3.sentiment
    pos_df3=ys.copy()
    neg_df3=ys.copy()
    plt.xlabel('location')
    plt.xticks(rotation=90)
    plt.ylabel('Average sentiment value')
    plt.plot(xs,ys,color='red')
    plt.savefig("../results/navya.png", dpi=200, bbox_inches='tight')
    plt.close()

   
if __name__ == "__main__":
    main()