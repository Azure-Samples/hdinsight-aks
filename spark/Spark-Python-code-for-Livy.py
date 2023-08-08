%livy.pyspark
import pandas as pd
import matplotlib.pyplot as plt
data1 = [22,40,10,50,70]
s1 = pd.Series(data1)   #One-dimensional ndarray with axis labels (including time series).

data2 = data1
index = ['John','sam','anna','smith','ben']
s2 = pd.Series(data2,index=index)

data3 = {'John':22, 'sam':40, 'anna':10,'smith':50,'ben':70}
s3 = pd.Series(data3)

s3['jp'] = 32     #insert a new row

s3['John'] = 88

names = ['John','sam','anna','smith','ben']
ages = [10,40,50,48,70]
name_series = pd.Series(names)
age_series = pd.Series(ages)

data_dict = {'name':name_series, 'age':age_series}
dframe = pd.DataFrame(data_dict)   #create a pandas DataFrame from dictionary

dframe['age_plus_five'] = dframe['age'] + 5   #create a new column
dframe.pop('age_plus_five')
#dframe.pop('age')

salary = [1000,6000,4000,8000,10000]
salary_series = pd.Series(salary)
new_data_dict = {'name':name_series, 'age':age_series,'salary':salary_series}
new_dframe = pd.DataFrame(new_data_dict)
new_dframe['average_salary'] = new_dframe['age']*90

new_dframe.index = new_dframe['name']
print(new_dframe.loc['sam'])