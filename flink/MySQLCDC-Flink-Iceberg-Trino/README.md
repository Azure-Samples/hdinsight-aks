# Real-Time Streaming of CDC Data from MySql to Apache Iceberg using Flink and Querying Iceberg Data with Trino

This sample demonstrates Real-Time streaming of CDC data from MySql to Apache Iceberg using Flink SQL Client for faster data analytics and machine learning workloads.

It will provide a comprehensive example of setting up a real-time streaming pipeline for CDC data synchronization. The integration of Flink, MySql CDC connectors, Iceberg, Azure Gen2 Storage, Hive Metastore, and Trino showcases the capabilities of modern data tools in handling dynamic data scenarios.

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/ba8385fe-458b-410b-9de2-e696f2815477)


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

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/79e4010b-72a2-4c9c-898e-bcc04cbc9095)


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
wget https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-flink-runtime-1.17/1.3.1/iceberg-flink-runtime-1.17-1.3.1.jar -P $FLINK_HOME/lib
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
   ![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/1f7216ac-8ba1-49a4-8308-075a1781592a)


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
   ![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/14899225-8c4e-4385-a938-0dd0cbbf0606)

   Then we can check the Flink mysql CDC tables contents on Flink SQL:
   ```
   select * from customers_source;
   ```
   ![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/f1d49cab-8753-474e-bb28-e3994eb3da9f)

## Creating Flink Table for Iceberg with Hive Metastore and Azure Gen2 Storage
We will now generate a Flink table for Iceberg, employing Hive Metastore as the catalog and Azure Gen2 Storage as the storage layer.

Please note that we should have downloaded the following dependencies used for adding Iceberg Catalog in previous section:
```
wget https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-flink-runtime-1.17/1.3.1/iceberg-flink-runtime-1.17-1.3.1.jar -P $FLINK_HOME/lib
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

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/56c8fa98-5267-49cd-8bfb-36ff41137530)
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/cba1dd82-793d-45ac-a24a-e648f4c88f4c)


2. Add dependencies to server classpah in current Flink SQL client
```
ADD JAR '/opt/flink-webssh/lib/iceberg-flink-runtime-1.17-1.3.1.jar';
ADD JAR '/opt/flink-webssh/lib/parquet-column-1.12.2.jar';
```

3. Create Database and use it
```
create database iceberg_cdc;
use iceberg_cdc;
```

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/4ae4f93b-de9f-43a2-86ac-b63c9bc4c997)
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/226d2f60-c851-4730-b3c5-ca9eb15602fc)

4. Now lets create the iceberg tables for the **customers** and **orders** as **customers_iceberg** and **orders_iceberg**:
```
CREATE TABLE customers_iceberg with ('format-version'='2') LIKE `default_catalog`.`default_database`.`customers_source` (EXCLUDING OPTIONS);
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/a322a743-84a8-4785-b1b0-d8f1aefe74bf)

```
CREATE TABLE orders_iceberg with ('format-version'='2') LIKE `default_catalog`.`default_database`.`orders_source` (EXCLUDING OPTIONS);
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/a784ba03-1dbb-4053-a75c-b93dc10c9555)

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
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/46def2cd-a26a-4ac7-9ef5-ff0c888ca1aa)

we are going to use INSERT INTO statement to UPSERT the streaming changes.
```
insert into customers_iceberg /*+ OPTIONS('upsert-enabled'='true','format-version'='2') */
select * from `default_catalog`.`default_database`.`customers_source` ;
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/fb311409-0f8b-43d7-a7bc-352f9dbc4b8a)

```
insert into orders_iceberg /*+ OPTIONS('upsert-enabled'='true','format-version'='2') */
select * from `default_catalog`.`default_database`.`orders_source` ;
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/35df8abf-8392-44e9-b77e-35d45d35d509)

Now these jobs are created and you can see the execution plan in Apache flink dashboard.
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/8e05e949-4cc6-4903-aebe-7cf25ae31ea7)

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/495299ee-65ed-4b67-b2e3-a22cf9efc5ed)

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
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/a14dc6b6-261d-4e99-8ad3-c9f0a177cdc3)

Here are are partitioning the table based on order_date and order_number

**Note:** In UPSERT mode, if the table is partitioned, the partition fields should be included in equality fields.

```
insert into customer_orders /*+ OPTIONS('upsert-enabled'='true','format-version'='2') */
select o.order_number , o.order_date, 
concat(c.first_name,' ',c.last_name) as purchaser, o.quantity, o.product_id 
from `default_catalog`.`default_database`.`orders_source` o 
join `default_catalog`.`default_database`.`customers_source` c on o.purchaser = c.id ;
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/2fab019e-0067-4890-896a-680ba7cea7d3)
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/fe08dad8-8faa-4f40-be16-092cd0b31f1d)


## Verification in Azure Gen2 Storage
Now we can see the tables that we creates and the data is stored in Azure Gen2 Storage.

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/bb14aae4-9d5a-4541-bd1c-04e174196b47)
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/aafeb080-0fa7-4e98-9261-732d61ef17a8)
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/bdaf2776-7da2-4527-99fe-a5c84ffda97d)
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/541b86c2-3e0b-467d-9bb0-9dccf38089b9)


## Querying Iceberg Data with Trino and Performing Inserts/Updates in MySQL
In this section, we will try to query these data using trino and try to insert and update the record in MySql

Firstly, please kindly follow the below document to congigure Iceberg catalog on Trino cluster of HDInsight on AKS:
https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-add-iceberg-catalog

Then we can see Iceberg tables in Trino (Here we use [Trino CLI](https://learn.microsoft.com/en-us/azure/hdinsight-aks/trino/trino-ui-command-line-interface) on local machine):
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/8e709214-296d-4cff-a45c-56622f2bbe00)

Now lets query orders_icerberg table
```
select * from ice.iceberg_cdc.orders_iceberg;

```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/0786dd6b-85c7-4602-998a-dc252823541e)

Now lets insert records in customers and orders table in MySql.
```
insert into customers (first_name,last_name,email) values ('pranav','sadagopan','ps@email.com') ;
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/e62f1bdd-a90b-4eb7-b7f0-fa78537d773f)

```
insert into orders (order_date,purchaser,quantity,product_id ) values ('2023-12-21', 1005, 10, 106) ;
insert into orders (order_date,purchaser,quantity,product_id ) values ('2023-12-21', 1005, 10, 106) ;
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/c524543f-0b53-475b-9afa-6f64825da934)


Now lets check the iceberg tables to see the inserted data.
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/f4af460b-0e1e-4928-941f-8a4303e4cbf5)
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/fdf03f4a-c3b5-4797-b192-1a11d9f7b59a)

Great, It captured the change and It inserted the new records in Iceberg tables.

Now lets try to update the records in MySQL:
```
mysql> update customers set email = 'example@email.com' where id = 1005 ;
mysql> update orders set quantity = 100 where purchaser = 1005 ;
```

Now lets check the iceberg tables to see the updated data.
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/00cec826-5b27-4f2a-b1dc-db1c1e086bb2)
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/82339b7b-36fd-4396-9056-31575fe2d6d9)


Great, It captured the change and It updates records in Iceberg tables.
Now lets see the enriched **customers_orders** table.
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/86a3f3e8-577d-4800-8461-f003ff7db13b)


## Exploring Metadata Queries
### History :
```
use ice.iceberg_cdc;
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/6c9685ef-4f7e-4f06-9ec9-5f62e3343fa5)


```
select * from "customer_orders$history";
```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/583c621f-bb85-4566-acf2-ec67b32a4fcc)


### Snapshot:
```
select * from "customer_orders$snapshots";

```
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/74bab7d3-b2da-4f30-8839-1a6d3b67a538)



## Conclusion
In wrapping up our journey through real-time data streaming, we combined Flink, MySQL CDC connectors, Iceberg, Azure Gen2 Storage, Hive Metastore, and Trino for a robust solution. Flink orchestrated a streaming pipeline to sync live data changes from MySQL to Iceberg, creating an efficient storage foundation. With a well-structured Iceberg table backed by Hive Metastore and Azure Gen2 Storage, our data management became seamless. Trino showcased its powers by smoothly querying Iceberg data, adding a layer of versatility. The Apache Flink dashboard provided insights into the streaming job efficiency. Lastly, our ability to insert and update MySQL records from Trino added interactivity, emphasizing the agility and power of modern data tools for responsive analytics.





   


