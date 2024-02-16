# Real-Time Streaming of CDC Data from MySql to Apache Iceberg using Flink and Querying Iceberg Data with Trino

This sample demonstrates Real-Time streaming of CDC data from MySql to Apache Iceberg using Flink SQL Client for faster data analytics and machine learning workloads.

It will provide a comprehensive example of setting up a real-time streaming pipeline for CDC data synchronization. The integration of Flink, MySql CDC connectors, Iceberg, Azure Gen2 Storage, Hive Metastore, and Trino showcases the capabilities of modern data tools in handling dynamic data scenarios.

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/891576a8-e569-4558-b802-3d114529ef38)

## What is Apache Iceberg ?

[Apache Iceberg](https://github.com/apache/iceberg) is an **open-source framework** for organizing large-scale data in data lakes, offering seamless **schema evolution** and **transactional writes**. It ensures consistency with snapshot isolation, supports efficient metadata management, and enables **time travel** for historical data analysis. Iceberg is compatible with various storage systems, providing flexibility for diverse data lake environments.

## Prerequisites
- Azure Database for MySQL - Flexible Server instance: https://learn.microsoft.com/en-us/azure/mysql/flexible-server/quickstart-create-server-portal
- Flink cluster on HDInisisht on AKS: https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-create-cluster-portal
- Trino cluster on HDInsight on AKS: https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-create-cluster

## MySQL source database and tables preparation and overview
Connect to Azure MySQL server, Run the following commands to create "Inventory" database, create tables "customers" and "orders", and insert some sample data to "customers" and "orders":
```
# Create the database that we'll use to populate data and watch the effect in the binlog
CREATE DATABASE inventory;
GRANT ALL PRIVILEGES ON inventory.* TO 'mysqluser'@'%';

# Switch to this database
USE inventory;

# Create some customers ...
CREATE TABLE customers (
  id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE KEY
) AUTO_INCREMENT=1001;


INSERT INTO customers
VALUES (default,"Sally","Thomas","sally.thomas@acme.com"),
       (default,"George","Bailey","gbailey@foobar.com"),
       (default,"Edward","Walker","ed@walker.com"),
       (default,"Anne","Kretchmar","annek@noanswer.org");

# Create some very simple orders
CREATE TABLE orders (
  order_number INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_date DATE NOT NULL,
  purchaser INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  FOREIGN KEY order_customer (purchaser) REFERENCES customers(id),
  FOREIGN KEY ordered_product (product_id) REFERENCES products(id)
) AUTO_INCREMENT = 10001;

INSERT INTO orders
VALUES (default, '2016-01-16', 1001, 1, 102),
       (default, '2016-01-17', 1002, 2, 105),
       (default, '2016-02-19', 1002, 2, 106),
       (default, '2016-02-21', 1003, 1, 107);
```
Here in the demo we are going to use customers and orders tables for data processing and streaming.

**Note**:
Please change the following MySQL configurations which are necessary for the compability with Flink CDC tables we will craete later on:
- Set binlog_row_image=FULL
- Set require_secure_transport=ON

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/88109ac3-39da-4e63-9080-7bf890fe8627)

## Setting up Flink CDC Connectors for MySQL: Creating Tables for Change Data Capture (CDC)
We are going to use mysql-cdc connector to capture the changes from mysql.

The MySQL CDC connector allows for reading snapshot data and incremental data from MySQL database.

### Steps to create tables for MySQL CDC
1. Go to webssh and download below jar for MySQL CDC connector:
  ```
  wget https://www.ververica.com/hubfs/JAR%20files/flink-sql-connector-mysql-cdc-2.4-SNAPSHOT.jar
  ```

**Note:**
Please kindly also downloaded the following dependencies used for adding Iceberg Catalog, which will be used later on in the same Flink SQL client:
```
wget https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-flink-runtime-1.16/1.3.0/iceberg-flink-runtime-1.16-1.3.0.jar -P $FLINK_HOME/lib
wget https://repo1.maven.org/maven2/org/apache/parquet/parquet-column/1.12.2/parquet-column-1.12.2.jar -P $FLINK_HOME/lib
```

2. Start the Apache Flink SQL Client with the following command:
   ```
   bin/sql-client.sh -j flink-sql-connector-mysql-cdc-2.4-SNAPSHOT.jar
   ```
3. Create the flink cdc table for both **customers** and **orders** table as **customers_source** and **orders_source**
   ```
   CREATE TABLE customers_source (
	 `id` int NOT NULL,
	 first_name STRING,
	 last_name STRING,
	 email STRING,
	 PRIMARY KEY (`id`) NOT ENFORCED
	 ) WITH (
	 'connector' = 'mysql-cdc',
	 'hostname' = 'guodong-mysqlsingleserver.mysql.database.azure.com',
	 'port' = '3306',
	 'username' = 'guodong',
	 'password' = 'xxx!',
	 'database-name' = 'inventory',
	 'table-name' = 'customers'
	 );
   ```
   ![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/e3de72c6-00d5-4db9-a4d2-dba4b68e589a)

   ```
   CREATE TABLE orders_source (
	`order_number` int NOT NULL,
	 order_date date NOT NULL,
	 purchaser int NOT NULL,
	 quantity int NOT NULL,
	 product_id int,
	 PRIMARY KEY(`order_number`) NOT ENFORCED
	 )WITH (
	 'connector' = 'mysql-cdc',
	 'hostname' = 'guodong-mysqlsingleserver.mysql.database.azure.com',
	 'port' = '3306',
	 'username' = 'guodong',
	 'password' = 'xxx',
	 'database-name' = 'inventory',
	 'table-name' = 'orders'
   );

   ```
   ![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/cf31baca-7f8f-4efe-a79a-3686b316bfea)

   Then we can check the Flink mysql CDC tables contents on Flink SQL:
   ```
   select * from customers_source;
   ```
   ![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/779418fe-d45a-4eb8-810f-4623d9d8be72)

## Creating Flink Table for Iceberg with Hive Metastore and Azure Gen2 Storage
We will now generate a Flink table for Iceberg, employing Hive Metastore as the catalog and Azure Gen2 Storage as the storage layer.

Please note that we should have downloaded the following dependencies used for adding Iceberg Catalog in previous section:
```
wget https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-flink-runtime-1.16/1.3.0/iceberg-flink-runtime-1.16-1.3.0.jar -P $FLINK_HOME/lib
wget https://repo1.maven.org/maven2/org/apache/parquet/parquet-column/1.12.2/parquet-column-1.12.2.jar -P $FLINK_HOME/lib
```

In the same FLink SQL Client, we can create Iceberg catalog and Iceberg tables managed in Hive catalog with the followinig steps:
1. Create iceberg catalog and use it:
   ```
   CREATE CATALOG iceberg_catalog WITH (
   'type'='iceberg',
   'catalog-type'='hive',
   'uri'='thrift://hive-metastore:9083',
   'clients'='5',
   'property-version'='1',
   'warehouse'='abfs://iceberg@guodongwangstore.dfs.core.windows.net/ieberg-output');
   
   USE CATALOG iceberg_catalog;
   ```
 

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/3ee72cf7-0bc4-4d10-ae2c-1a997754d1f1)

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/7d46d001-81cf-4d38-8bbc-88b0f82d13a6)

2. Add dependencies to server classpah in current Flink SQL client
```
ADD JAR '/opt/flink-webssh/lib/iceberg-flink-runtime-1.16-1.3.0.jar';
ADD JAR '/opt/flink-webssh/lib/parquet-column-1.12.2.jar';
```

3. Create Database and use it
```
create database iceberg_cdc;
use iceberg_cdc;
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/9b242109-62a0-4a98-8631-6749b072f358)

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/7e4c9bba-4947-4196-9b93-a12438cf30a3)

4. Now lets create the iceberg tables for the **customers** and **orders** as **customers_iceberg** and **orders_iceberg**:
```
CREATE TABLE customers_iceberg with ('format-version'='2') LIKE `default_catalog`.`default_database`.`customers_source` (EXCLUDING OPTIONS);
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/bb99ea61-b99c-4c63-9c24-b5dfed984c78)
```
CREATE TABLE orders_iceberg with ('format-version'='2') LIKE `default_catalog`.`default_database`.`orders_source` (EXCLUDING OPTIONS);
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/8fb8f8ef-6c66-4e95-9708-75cea2fa2076)

**Note:**
Creating table with ('format-version'='2') is necessary, otherwise we will face the following error message when inserting data to iceberg tables:

```
024-02-12 09:22:40.141 [] IcebergFilesCommitter -> Sink: IcebergSink iceberg_catalog.default.customers_iceberg (1/1)#15 WARN  flink apache.flink.runtime.taskmanager.Task 1091 IcebergFilesCommitter -> Sink: IcebergSink iceberg_catalog.default.customers_iceberg (1/1)#15 (4f3216c39a864538cdc2ec966591ccb3_e883208d19e3c34f8aaf2a3168a63337_0_15) switched from INITIALIZING to FAILED with failure cause: java.lang.IllegalArgumentException: Cannot write delete files in a v1 table
```

Here we do not need to specify the schema as we are using the **CREATE TABLE LIKE** to create a table with the same schema as source tables.

## Initiating Streaming Pipeline for MySQL to Iceberg Sync with Flink
Now we are going to start the streaming pipeline to sync the streaming data changes from MySql to Iceberg.

First we need to set the **checkpointing interval** in current Flink SQL client:
```
set 'execution.checkpointing.interval'='3000' ;
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/6f92b82d-1a34-4877-9129-15fb13105dd0)

we are going to use INSERT INTO statement to UPSERT the streaming changes.
```
insert into customers_iceberg /*+ OPTIONS('upsert-enabled'='true','format-version'='2') */
select * from `default_catalog`.`default_database`.`customers_source` ;
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/8b0a973c-8cae-4e30-8b88-eab167480869)


```
insert into orders_iceberg /*+ OPTIONS('upsert-enabled'='true','format-version'='2') */
select * from `default_catalog`.`default_database`.`orders_source` ;
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/57de6e3d-640d-406e-8fd1-76f998a32b49)

Now these jobs are created and you can see the execution plan in Apache flink dashboard.
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/16a2de21-e3e3-4da7-9c45-3f613ab39a15)

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/5e1d4639-f2d0-4641-b81b-c9884c38194c)

Now lets try to join **orders_source** and **customers_source** to create a table **customer_orders** to store the enriched the data.
```
create table customer_orders (
`order_number` int NOT NULL,
order_date  date NOT NULL,
purchaser VARCHAR NOT NULL,
quantity int NOT NULL,
product_id  int,
PRIMARY KEY(`order_number`,order_date) NOT ENFORCED
)
PARTITIONED by (order_date)
with ('format-version'='2');
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/500a442c-2b26-4557-b690-6f1499ce19be)

Here are are partitioning the table based on order_date and order_number

**Note:** In UPSERT mode, if the table is partitioned, the partition fields should be included in equality fields.

```
insert into customer_orders /*+ OPTIONS('upsert-enabled'='true','format-version'='2') */
select o.order_number , o.order_date, 
concat(c.first_name,' ',c.last_name) as purchaser, o.quantity, o.product_id 
from `default_catalog`.`default_database`.`orders_source` o 
join `default_catalog`.`default_database`.`customers_source` c on o.purchaser = c.id ;
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/1772ae3b-4b08-44b2-8ace-44813620a88a)

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/19ce4e19-c17f-4dd8-89cb-6a1ba1b7bf04)


## Verification in Azure Gen2 Storage
Now we can see the tables that we creates and the data is stored in Azure Gen2 Storage.

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/dc6bf782-c0e0-4471-b3ca-f9132f962b40)

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/6d6410d1-b253-435a-8773-cca24b8c9657)

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/89fc98bc-9581-44ca-a684-080b1b13f778)

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/513d9443-28fb-4a6c-b5f1-c6306392c699)

## Querying Iceberg Data with Trino and Performing Inserts/Updates in MySQL
In this section, we will try to query these data using trino and try to insert and update the record in MySql

Firstly, please kindly follow the below document to congigure Iceberg catalog on Trino cluster of HDInsight on AKS:
https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-add-iceberg-catalog

Then we can see Iceberg tables in Trino (Here we use [Trino CLI](https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-ui-command-line-interface) on local machine):
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/9b02f65f-1111-4bfc-9fac-76b95f66c8fd)

Now lets query orders_icerberg table
```
select * from ice.iceberg_cdc.orders_iceberg;

```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/eaffafa1-04eb-40d3-bcda-6357005a52b6)

Now lets insert records in customers and orders table in MySql.
```
insert into customers (first_name,last_name,email) values ('pranav','sadagopan','ps@email.com') ;
```

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/cb8328d3-4709-4fd7-9732-789c11e0d445)

```
insert into orders (order_date,purchaser,quantity,product_id ) values ('2023-12-21', 1005, 10, 106) ;
insert into orders (order_date,purchaser,quantity,product_id ) values ('2023-12-21', 1005, 10, 106) ;
```

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/be227b98-b7da-416b-a19e-5ac120ab8220)

Now lets check the iceberg tables to see the inserted data.
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/f1cb4234-3ad5-4adc-b2a1-4de25ad398ee)
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/bb2f6fa7-dcc5-4f97-9412-96d5e7718c48)

Great, It captured the change and It inserted the new records in Iceberg tables.

Now lets try to update the records in MySQL:
```
mysql> update customers set email = 'example@email.com' where id = 1005 ;
mysql> update orders set quantity = 100 where purchaser = 1005 ;
```

Now lets check the iceberg tables to see the updated data.
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/c4dd9dd2-89ab-4a48-a503-865d2f70a03f)
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/562a56b5-882c-4977-ad78-d88213ed0bb1)

Great, It captured the change and It updates records in Iceberg tables.
Now lets see the enriched **customers_orders** table.
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/a6e97c4d-5cef-46cf-bf8b-5b26391487a7)

## Exploring Metadata Queries
### History :
```
use ice.iceberg_cdc;
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/056c5278-1249-4891-9aab-7c407470953c)

```
select * from "customer_orders$history";
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/1fbf7a77-24bd-4f0d-a3cc-916d210dc7c9)

### Snapshot:
```
select * from "customer_orders$snapshots";

```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/1f0e8f5c-1a46-4925-b5b1-1aa23102397b)


## Conclusion
In wrapping up our journey through real-time data streaming, we combined Flink, MySQL CDC connectors, Iceberg, Azure Gen2 Storage, Hive Metastore, and Trino for a robust solution. Flink orchestrated a streaming pipeline to sync live data changes from MySQL to Iceberg, creating an efficient storage foundation. With a well-structured Iceberg table backed by Hive Metastore and Azure Gen2 Storage, our data management became seamless. Trino showcased its powers by smoothly querying Iceberg data, adding a layer of versatility. The Apache Flink dashboard provided insights into the streaming job efficiency. Lastly, our ability to insert and update MySQL records from Trino added interactivity, emphasizing the agility and power of modern data tools for responsive analytics.





   


