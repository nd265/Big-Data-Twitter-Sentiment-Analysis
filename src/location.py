import pandas as pd
import codecs
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
df=pd.read_csv(r"/home/navya/Documents/csv files/location_sentiment_final.csv",header=None)

df.columns=['location','sentiment']
print df
print '----------------------'
#extract the last word after space 
df['location']=df['location'].str.split(' ').str[-1]		
print df

print '==========================='
filename='/home/navya/Downloads/country_list.txt'
f=open(filename,"r") 
country=[line.decode("utf-16be","ignore").replace("\r\n", "").encode("utf-8","ignore") for line in f]
	
print type(country)

uper_country= map(lambda x:x.upper(),country)


uper_country2=map(lambda y:y.strip(),uper_country)

print type(uper_country2)
print '-----------------------'

print uper_country2

df_obj = df.select_dtypes(['object'])
df[df_obj.columns] = df_obj.apply(lambda x: x.str.strip().str.upper())

#print df

df3=df[df['location'].isin(uper_country2)]
print df3



df3=df3.groupby('location')['sentiment'].mean().reset_index()
#remove the 1st row as it is blank 
df3=df3.iloc[1:]


print df3	


xs=df3.location
ys=df3.sentiment
pos_df3=ys.copy()
neg_df3=ys.copy()
plt.xlabel('location')
plt.xticks(rotation=90)
plt.ylabel('Average sentiment value')
plt.plot(xs,ys,color='red')

plt.show()
