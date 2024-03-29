# Azure HDInsight on AKS Spark integration with Azure HDInsight HBase  

HDI on AKS comes with the following workloads – Flink, Trino and Spark. It is important for users to access HBase from Spark for point-to-point queries. 
This tutorial shows how to connect to HDInsight HBase from an Azure HDInsight on AKS Spark cluster. The key steps involved in connecting between Spark and HBase are as follows. 


*   Create Azure HDInsight HBase cluster

*   Create Azure HDInsight on AKS Spark cluster 

*   Connect from Azure HDInsight HBase to Azure HDInsight on AKS Spark (both clusters should be kept in same region)

*   Read and Write from HDInsight on AKS Spark cluster to Azure HDInsight HBase cluster


1.Create an Azure HDInsight HBase cluster

2.Create Azure HDInsight on AKS Spark cluster 

a) Connect from Azure HDInsight HBase to Azure HDInsight on AKS Spark	Update the hbase-site.xml in HDI on AKS Spark cluster 

   i)Login to the Azure HDInsight Hbase cluster head node and download the hbase-site.xml file from /etc/hbase/conf via WinSCP 

![image](https://github.com/apurbasroy/Azure-Samples/assets/42459865/32cfaa1a-df8e-4c13-9901-ce7b9478a1cb)

![image](https://github.com/apurbasroy/Azure-Samples/assets/42459865/da51ff41-e12e-4402-99c9-44658a5e4728)
 

ii) We need to add the path to the spark-hbase connector jar while launching the spark-shell  

 

b) Spark-HBase connector configuration and setup   

### Client-side (Spark cluster) configuration:   

i)Create a new folder and download the spark-hbase connector jars   

ii)Login to WebSSH pod of HDI on Spark cluster  

iii)Navigate to the directory cd /home/(user) 

iv)Type : 

```
wget https://archive.apache.org/dist/hbase/2.4.11/hbase-2.4.11-client-bin.tar.gz 

tar -xvf hbase-2.4.11-client-bin.tar.gz
```

v)Create a new directory named connector in a preferred directory for e.g.: mkdir /home/(user)/connector  

vi)Execute the below commands from the new folder created.   
            
~~~
wget https://hdiconfigactions.blob.core.windows.net/spark-hbase-connector/Spark-331-HBase-2411/hbase-spark-1.0.1-SNAPSHOT_spark_331_hbase_2411.jar   
wget  https://hdiconfigactions.blob.core.windows.net/spark-hbase-connector/Spark-331-HBase-2411/hbase-spark-protocol-1.0.1-SNAPSHOT_spark_331_hbase_2411.jar
wget https://hdiconfigactions.blob.core.windows.net/spark-hbase-connector/Spark-331-HBase-2411/hbase-spark-protocol-shaded-1.0.1-SNAPSHOT_spark_331_hbase_2411.jar
~~~

 

 

**Note:** After these commands you will see 3 jars in the folder created */home/(user)/connector*

 

 
## Server-side (HBase cluster region servers) configuration:   

### It requires additional jars on the HBase server side to make the connection success. You need to add a few jars in the HBase region servers CLASSPATH.  For this you can download the jars and keep it in the lib folder ( /usr/hdp/5.*/hbase/lib)   

  

a) Login to SSH from the HBase Head node.  

b)Download connector and Scala jars to HBase region servers `$HBASE_HOME/lib`   


```
cd $HBASE_HOME/lib
wget https://hdiconfigactions.blob.core.windows.net/spark-hbase-connector/Spark-331-HBase-2411/hbase-spark-1.0.1-SNAPSHOT_spark_331_hbase_2411.jar     
wget  https://hdiconfigactions.blob.core.windows.net/spark-hbase-connector/Spark-331-HBase-2411/hbase-spark-protocol-1.0.1-SNAPSHOT_spark_331_hbase_2411.jar
wget  https://hdiconfigactions.blob.core.windows.net/spark-hbase-connector/Spark-331-HBase-2411/hbase-spark-protocol-shaded-1.0.1-SNAPSHOT_spark_331_hbase_2411.jar 
wget https://repo1.maven.org/maven2/org/scala-lang/scala-library/2.12.10/scala-library-2.12.10.jar  
```
   

  
## Read and Write from HDInsight on AKS Spark cluster to Azure HDInsight HBase cluster  

### Steps to read Hbase table using spark shell:  

i)Open the AKS spark shell.  

A screenshot of a computer 

 ii)Type: 

```
  spark-shell --jars "/home/{user}/connector/*,/home/{user}/hbase-2.4.11-client/lib/shaded-clients/*"
```
 
iii)Import the required classes:  

```
import org.apache.hadoop.hbase.spark.HBaseContext
import org.apache.hadoop.hbase.HBaseConfiguration  
```

### To create an instance of HBase configuration:  

IV)Type:

```
val conf = HBaseConfiguration.create()  
conf.add(“HBase”,“”) conf.add("hbase.zookeeper.quorum","value") 
conf.add("hbase.zookeeper.property.clientPort","2181") 
conf.add("zookeeper.znode.parent","hbase-unsecure") 
```
### Create a new HBase context based on the same config files:  

```
new HBaseContext(spark.sparkContext, conf)  
```
### Create a dataframe specifying the schema of df:  

```
val hbaseDF = (spark.read.format(“org.apache.hadoop.hbase.spark”)  

    			.option(“hbase.columns.mapping”,  

     			 rowKey STRING : key,”+  

                 “firstName String Name: First, lastName String Name: Last” +  

                 “country STRING Address:Country, state STRING Address :State”  

          		 )  

     			  .option(“hbase.table”, “Person”)  

        		 ).load()  
```
  

### Read schema of the dataframe: 

`hbaseDF.schema`

### Read the dataframe:

`
hbaseDF.show()` 

### Write data in Hbase via spark shell  

### Create the the catalog  

```
val catalog = a“““{  

|”table”:{“namespace”:“default”, “name”:“spark-hbase-demo”},  

|“rowkey”:“key”  

|“columns”:{  

|“id”:{“col”:“key”, “type”:“int”}  

|“name”:{“cf”:“cf”, “col”:“name”, “type”:“string”  

|}  

|}”””.stripMargin  

```

### Create a dataframe with some dummy records  

`val df =sql(“select id”, ‘myline_’ ||id name from range(10”))`

### Write the dataframe into hbase  

`spark.use.hbasecontext”,false.save()lecatalog.tableCatalog->catalog, HBaseTableCatalog.newTable ->“5”)).format(“org.apace.hadoop.hbase.spark”).option(hbase.sp)`
  

### Login to the hbase shell in HBase cluster.    

  `$hbase shell`

### Read the newly created dataframe:  

  `scan ‘spark-hbase-demo’`





### Apache Spark-HBase connector tuneable configurations   

There are several tuneable in the Apache HBase-Spark connector, for example:   

hbase.spark.query.batchsize - Set the maximum number of values to return for each call to next() in scan.   

hbase.spark.query.cachedrows - The number of rows for caching that will be passed to scan.   

Details of the available configurations are [here](https://github.com/apache/hbase-connectors/blob/master/spark/hbase-spark/src/main/scala/org/apache/hadoop/hbase/spark/datasources/HBaseSparkConf.scala).

  

 
