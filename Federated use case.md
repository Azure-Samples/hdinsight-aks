# Analyzing NYC Trip data using Trino in HDInsight on AKS

This demo showcases how you can use federated capability of Trino in HDInsight on AKS to analyze NYC Trip data

## Pre-requisites

* Trino cluster with HDInsight on AKS
* ADLS Gen2 storage and user-assigned managed identity (MSI)
* Azure Postgres or Azure SQL Database

## Scenario

For this scenario, we are going to cover the following path:
1. Take data from NYC Trip offical site, for this demostration, we will download one month data from [NYC site](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
2. Land the data ADLS Gen2 and expose it as Hive table in Trino.
3. Prepare zone data and land in Azure postgres or SQL Databse
4. Run Trino query on two data source hive and SQL databse

## Demo steps

### Step 1: Create a Trino cluster with HDInsight on AKS with hive catalog
 
* Create a [Trino cluster with HDInsight on AKS](/azure/hdinsight/kafka/apache-kafka-get-started).
For this demo purpose, 
Hive catalog name is "hive-catalog"
Cluster name - testcluster

* Add Azure postgres sql database as catalog in the ewnly created cluster

  [Configure a catalog](https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-add-catalogs)
  [Refer connector properties for Postgres SQL](https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-connectors)

For connection URL, get this from Azure Postgres SQL Databse from Azure portal

For this demo purpose,
Catalog name:  "pg"

### Step 2: Prepare the data in ADLS Gen2
* Download the NYC data for any month. For this demo, we have downloaded October 2022 data as parquet file

* Create ADLS Gen2 storage "sampleteststorage" with container as "nycdata"
   * Create directory as "year=2022"/"month=10' in container "nycdata"
   * Copy/Upload the downloaded trip data to the new created directory in sampleteststorage
   * Provide "Sotrage Blob Owner" permission to the MSI assocaited to with Trino cluster to the "sampleteststorageaccount"

### Step 3: Create schema and table in hive catalog pointing to the data in ADLS Gen2

* Use [Webssh/Trino CLI or DBeaver](https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-ui-web-ssh) to connect to Trino cluster and run the following queries

  CREATE SCHEMA "hive-catalog".nycdata;

  CREATE TABLE "hive-catalog".nycdata.yellow_trip (
	 VendorID bigint
	,tpep_pickup_datetime timestamp(3)
	,tpep_dropoff_datetime timestamp(3)
	,passenger_count double
	,trip_distance double
	,RatecodeID double
	,store_and_fwd_flag varchar
	,PULocationID bigint
	,DOLocationID bigint
	,payment_type bigint
	,fare_amount double
	,extra double
	,mta_tax double
	,tip_amount double
	,tolls_amount double
	,improvement_surcharge double
	,total_amount double
	,congestion_surcharge double
	,airport_fee double
	,year varchar
	,month varchar
) WITH (external_location = 'abfss://nycdata@sampleteststorage.dfs.core.windows.net/tripdata', partitioned_by = ARRAY['year', 'month'], format = 'parquet');

-- As we have create a partition hence, need to sync the parititon to metastore
call system.sync_partition_metadata('"hive-catalog".nycdata', '"hive-catalog".nycdata.yellow_trip', 'ADD', false);

### Prepare Zone data and copy to Azure postgres database

*  Download the NYC data for any month. For this demo, we have downloaded October 2022 data as parquet file
*  ![image](https://github.com/Azure-Samples/hdinsight-aks/assets/109063956/26896aa8-f554-4c51-99a1-f01d4687a387)

*  Delete the first column from the downloaded csv file as it denotes column header

*  Create directory as "zone" in container "nycdata" in stroage account "sampleteststorage" 
  	* Copy/Upload the downloaded zone data to the "zone" directory

*  Create table metadata in "hive-catalog" and copy the data in postgres database

  	CREATE TABLE "hive-catalog".nycdata.zones (
	 LocationID varchar
	,borough varchar
	,Zone varchar
	,service_zone varchar
	) WITH (external_location = 'abfss://nycdata@sampleteststorage.dfs.core.windows.net/zone/', format = 'csv');

	-- Copy the data to Postgres databse
	CREATE SCHEMA pg.nycdata;
	CREATE TABLE pg.nycdata.zones 
	AS SELECT 
	cast(locationid as bigint) locationid
	,borough
	,Zone
	,service_zone
	FROM "hive-catalog".nycdata.zones;

### Federation in Trino

* Join the table in two catalog "hive-catalog" and "pg" and

	 select
		z.zone,
		avg(fare_amount) as avg_fare,
		sum(passenger_count) as total_passengers
	from
		"hive-catalog".nycdata.yellow_trip y
	Inner join pg.nycdata.zones  z
		on
		y.PULocationID= cast(z.locationid as bigint)
	Group by
		z.zone
		having
		sum(passenger_count) > 100000
	Order by total_passengers asc;

![image](https://github.com/Azure-Samples/hdinsight-aks/assets/109063956/ea01953d-8526-454b-accd-9cf02eb38212)

