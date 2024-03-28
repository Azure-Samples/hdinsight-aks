# Predict house prices using Random Forest model

## Pre requisites
* Azure HDInsight on AKS Spark cluster. Learn how to create a cluster click [here](https://learn.microsoft.com/en-us/azure/hdinsight-aks/quickstart-create-cluster).

* Upload the sample dataset in the ADLS Gen2, primary storage account in a container. Learn how to upload data in the container [here](https://learn.microsoft.com/en-us/azure/data-factory/load-azure-data-lake-storage-gen2.)
* Navigate to the cluster overview page and open a python notebook in Jupyter.

## Enter the following code in the Jupyter notebook:

### Packages to be imported

```
import numpy as np
import pandas as pd # data processing
```

```
import matplotlib.pyplot as plt
import seaborn as sea
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import explained_variance_score
from sklearn.metrics import confusion_matrix

import os
print(os.listdir)
import warnings  
warnings.filterwarnings('ignore')

```
## Load the data from the storage account
```
df = pd.read_csv('abfss://<storage name>.dfs.core.windows.net/<container name>/<file name>', storage_options = {'connection_string': 'DefaultEndpointsProtocol=https;AccountName=<storage name>;AccountKey=<storage account key>;EndpointSuffix=core.windows.net'})

print(df)
```

## Checking for null values
`df.info()`

Since we do not have any null values, we will check for unique values in the dataset:

## Unique values present in each column
```
for value in df:
    print('For {},{} unique values present'.format(value,df[value].nunique()))
```

## Data visualization
```
plt.figure(figsize=(10,6))
sns.plotting_context('notebook',font_scale=1.2)
g = sns.pairplot(df[['sqft_lot','sqft_above','price','sqft_living','bedrooms','grade','yr_built','yr_renovated']]
                 ,hue='bedrooms',size=2)
g.set(xticklabels=[])
```
<img width="669" alt="image" src="https://github.com/apurbasroy/Azure-Samples/assets/42459865/ef3994d7-b6da-4572-8aba-2b3bd38f6212">

## From this plot it is clear for a linear regression for sqft_living & price,  next let us plot them in a joint plot to explore more.



```
sns.jointplot(x='sqft_lot',y='price',data=df,kind='reg')
sns.jointplot(x='sqft_above',y='price',data=df,kind='reg')
sns.jointplot(x='sqft_living',y='price',data=df,kind='reg')
sns.jointplot(x='yr_built',y='price',data=df,kind='reg')
```
![download](https://github.com/apurbasroy/Azure-Samples/assets/42459865/20cc13f5-4665-4e8f-a3e6-0e1b53ce2af9)

```
sns.jointplot(x='bedrooms',y='price',data=df,kind='scatter')
sns.jointplot(x='yr_renovated',y='price',data=df,kind='scatter')
sns.jointplot(x='grade',y='price',data=df,kind='scatter')
sns.jointplot(x='sqft_lot',y='sqft_above',data=df,kind='scatter')
```
![download](https://github.com/apurbasroy/Azure-Samples/assets/42459865/9f2aff0d-4e42-4237-ab00-e76d857bca6c)

## Heatmap to view the co relation between the variables

```
plt.figure(figsize=(15,10))
columns =['price','bedrooms','bathrooms','sqft_living','floors','grade','yr_built','condition']
sns.heatmap(dataset[columns].corr(),annot=True)

```
![download](https://github.com/apurbasroy/Azure-Samples/assets/42459865/ac6723e9-701c-41cd-a8fa-65ceb531c787)

## Start building the model using different regression models

```
X = dataset.iloc[:,1:].values
y = dataset.iloc[:,0].values

```
## Splitting the data into train,test data

```
X_train,X_test,y_train,y_test=train_test_split(X,y,test_size=0.3,random_state=0)

```
## Multiple Linear Regression:
### Fitting the train set to multiple linear regression and getting the score of the model

```
mlr = LinearRegression()
mlr.fit(X_train,y_train)
mlr_score = mlr.score(X_test,y_test)
pred_mlr = mlr.predict(X_test)
expl_mlr = explained_variance_score(pred_mlr,y_test)

```

## Decision Tree
```
tr_regressor = DecisionTreeRegressor(random_state=0)
tr_regressor.fit(X_train,y_train)
tr_regressor.score(X_test,y_test)
pred_tr = tr_regressor.predict(X_test)
decision_score=tr_regressor.score(X_test,y_test)
expl_tr = explained_variance_score(pred_tr,y_test)

```

## Random Forest Regression Model

```
rf_regressor = RandomForestRegressor(n_estimators=28,random_state=0)
rf_regressor.fit(X_train,y_train)
rf_regressor.score(X_test,y_test)
rf_pred =rf_regressor.predict(X_test)
rf_score=rf_regressor.score(X_test,y_test)
expl_rf = explained_variance_score(rf_pred,y_test)
```


### Calculating the model score for understanding how our model performed along with the explained variance score.
```
print("Multiple Linear Regression Model Score is ",round(mlr.score(X_test,y_test)*100))
print("Decision tree  Regression Model Score is ",round(tr_regressor.score(X_test,y_test)*100))
print("Random Forest Regression Model Score is ",round(rf_regressor.score(X_test,y_test)*100))
```
### Tabular pandas data frame, for clear comparison
```
models_score =pd.DataFrame({'Model':['Multiple Linear Regression','Decision Tree','Random forest Regression'],
                            'Score':[mlr_score,decision_score,rf_score],
                            'Explained Variance Score':[expl_mlr,expl_tr,expl_rf]
                           })
models_score.sort_values(by='Score',ascending=False)
```
<img width="710" alt="image" src="https://github.com/apurbasroy/Azure-Samples/assets/42459865/7a6e35f4-042c-45b4-b9f6-2ef08526e56c">
