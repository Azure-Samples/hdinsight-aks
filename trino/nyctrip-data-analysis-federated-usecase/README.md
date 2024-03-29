# Analyzing NYC Taxi Trip data - Trino with HDInsight on AKS

This demo showcases how you can use federated capability of Trino with HDInsight on AKS to analyze NYC Taxi Trip data.

## Pre-requisites

* Trino cluster with HDInsight on AKS
* ADLS Gen2 storage
* User-assigned managed identity (MSI)
* Azure Database for PostgresSQL

## Scenario

For this scenario, we are going to cover the following path:
1. Take NYC taxi data from the official source.
2. Land the data in ADLS Gen 2 and expose it as a Hive table in Trino.
3. Prepare zone data and land in Azure Database for PostgresSQL.
4. Run a federated query on two data sources ADLS Gen2 and Azure Database for PostgresSQL.

## Demo steps

### Step 1: Create a Trino cluster with HDInsight on AKS with hive catalog enabled
 
* Create a [Trino cluster with HDInsight on AKS](/azure/hdinsight-aks/trino/trino-create-cluster).
  For this demo purpose, we have created the following cluster:
    * Cluster name - `testcluster`
    * Hive catalog name - `hive-catalog`

* Create [Azure Database for PostgresSQL server](/azure/postgresql/flexible-server/quickstart-create-server-portal#create-an-azure-database-for-postgresql-server) and a database in the server.
  For this demo purpose, we have created the following database:
    * Server - `constospostgres`
    * Database - `tutorialdb`

  ![image](https://github.com/Azure-Samples/hdinsight-aks/assets/109063956/0ccd1c5d-5f9b-4b47-8651-97a9afa3f53c)

* Configure the postgres database as catalog in the Trino cluster.
  Refer the following documentation:

  * [Configure a catalog](https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-add-catalogs)
  * [Connector properties for Postgres SQL](/azure/hdinsight-aks/trino/trino-connectors)

  For connection URL, get it from the Azure portal.

  For this demo purpose, we have used the following catalog name:
  * Catalog name - `pg`

  Sample ARM template snippet for adding Azure Database for PostgresSQL as catalog in Trino. Refer the properties under `serviceConfigsProfiles`.

  ```json
	"properties": {
        "clusterType": "Trino",
       
            "secretsProfile": {
                "keyVaultResourceId": "/subscriptions/d66b1168-d835-4066-8c45-7d2ed713c082/resourceGroups/AJSandbox/providers/Microsoft.KeyVault/vaults/ajhilokeyvault",
                "secrets": [
                    {
                        "referenceName": "demokeyvaultsecret",
                        "type": "Secret",
                        "keyVaultObjectName": "demokeyvaultsecret"
                    }
                ]
            },
            "serviceConfigsProfiles": [
                {
                    "serviceName": "trino",
                    "configs": [
                   
                        {
                            "component": "catalogs",
                            "files": [
                                {
                                    "fileName": "hive-catalog.properties",
                                    "values": {
                                        "connector.name": "hive",
                                        "hive.allow-drop-table": "true",
                                        "hive.metastore": "hdi"
                                    }
                                },
                                {
                                    "fileName": "pg.properties",
                                    "values": {
                                        "connection-password": "${SECRET_REF:demokeyvaultsecret}",
                                        "connection-url": "jdbc:postgresql://constospostgres.postgres.database.azure.com:5432/tutorialdb?sslmode=require",
                                        "connection-user": "<admin-user-name>",
                                        "connector.name": "postgresql"
                                    }
                                }
                            ]
                        }
                    ]
                }
            ],
            
        }
     
	 ```

### Step 2: Prepare the data in ADLS Gen2

* Download the NYC yellow taxi trip data for any month from [here](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page). For this demo, we have downloaded October 2022 data as parquet file.

* Create ADLS Gen2 storage `sampleteststorage` with container as `nycdata`.
   * Create directory as `tripdata/year=2022/month=10` in container `nycdata`.
   * Copy/Upload the downloaded trip data to the newly created directory in the `sampleteststorage`.
   * Provide "Storage Blob Data Owner" permission to the MSI assocaited with your Trino cluster in the storage `sampleteststorageaccount`.
 
     ![image](https://github.com/Azure-Samples/hdinsight-aks/assets/109063956/b397b799-055a-4d85-bff3-3743824ce04b)

### Step 3: Create schema and table in hive catalog pointing to the data stored in ADLS Gen2 (sampleteststorage)

* Use [Webssh/Trino CLI or DBeaver](/azure/hdinsight-aks/trino/trino-ui-web-ssh) to connect to your Trino cluster and run the following queries:
  
  ```sql 

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
	```

	Since we have created a partition hence, need to sync the parititon to the hive metastore. Run the following command.

	```call system.sync_partition_metadata('"hive-catalog".nycdata', '"hive-catalog".nycdata.yellow_trip', 'ADD', false);```

### Step 4: Prepare Zone data and copy to the Azure Database for PostgresSQL

* Download the zone data from [here](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) and delete the first column from the downloaded csv file as it denotes column header.

   ![image](https://github.com/Azure-Samples/hdinsight-aks/assets/109063956/26896aa8-f554-4c51-99a1-f01d4687a387)

* Create a directory as `zone` in the container `nycdata` in the storage account `sampleteststorage`.
  
    * Copy/Upload the downloaded csv data to the `zone` directory.

      ![image](https://github.com/Azure-Samples/hdinsight-aks/assets/109063956/1da037a8-3b94-43be-8de9-55a04c574b49) 

*  Create a reference table in "hive-catalog" and copy the data to postgres database table.

  	```sql

   	CREATE TABLE "hive-catalog".nycdata.zones (
	 LocationID varchar
	,borough varchar
	,Zone varchar
	,service_zone varchar
	) WITH (external_location = 'abfss://nycdata@sampleteststorage.dfs.core.windows.net/zone/', format = 'csv');

	-- Copy the data to Postgres database

	CREATE SCHEMA pg.nycdata;
	CREATE TABLE pg.nycdata.zones 
	AS SELECT 
	cast(locationid as bigint) locationid
	,borough
	,Zone
	,service_zone
	FROM "hive-catalog".nycdata.zones;
	```
   
### Step 5: Federation in Trino with HDInsight on AKS

* Join the tables in two catalog "hive-catalog" and "pg" to experience the federated capaibility of Trino.

  Sample federated query: The following query gives avg fare amount and corresponding passengers count based on zones.

	``` sql
	SELECT
		z.zone,
		avg(fare_amount) as avg_fare,
		sum(passenger_count) as total_passengers
	FROM
		"hive-catalog".nycdata.yellow_trip y
	INNER JOIN pg.nycdata.zones  z
		on
		y.PULocationID= cast(z.locationid as bigint)
	GROUP BY
		z.zone
	HAVING
		sum(passenger_count) > 100000
	ORDER BY
 		total_passengers asc;
 	```

  	![image](https://github.com/Azure-Samples/hdinsight-aks/assets/109063956/ea01953d-8526-454b-accd-9cf02eb38212)

