Change Data Capture (CDC) is a technique you can use to track row-level changes in database tables in response to create, update, and delete operations. In this article, we use CDC Connectors for Apache Flink®, which offer a set of source connectors for Apache Flink. The connectors integrate Debezium® as the engine to capture the data changes.

Apache Flink supports to interpret Debezium JSON and Avro messages as INSERT/UPDATE/DELETE messages into Flink SQL system.

This support is useful in many cases to:
- Synchronize incremental data from databases to other systems
- Audit logs
- Build real-time materialized views on databases
- View temporal join changing history of a database table

Now, let us learn how to use Change Data Capture (CDC) of MySQL using Flink SQL. The MySQL CDC connector allows for reading snapshot data and incremental data from MySQL database.

## Prerequisites
•	Prepare MySQL(8.0) on Azure SQL Server 2012 <br>
•	Hilo Flink 1.16.0

## Flink MySQL CDC Connector

The MySQL CDC connector allows for reading snapshot data and incremental data from MySQL database. 

## Use SSH to use Flink SQL client
We have already covered this section in detail on how to use with Flink:
https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-web-ssh-on-portal-to-flink-sql

## Prepare table and enable CDC feature on MySQL
You can connect to the MySQL server with the following command shown below using MySQL command line client on Azure Cloud shell.

``` sql
-- MySQL
CREATE DATABASE mydb;
USE mydb;

CREATE TABLE orders (
  order_id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_date DATETIME NOT NULL,
  customer_name VARCHAR(255) NOT NULL,
  price DECIMAL(10, 5) NOT NULL,
  product_id INTEGER NOT NULL,
  order_status BOOLEAN NOT NULL -- Whether order has been placed
) AUTO_INCREMENT = 10001;

INSERT INTO orders
VALUES (default, '2020-07-30 10:08:22', 'Jark', 9999, 102, false),
       (default, '2020-07-30 10:11:09', 'Sally', 15.00, 105, false),
       (default, '2020-07-30 12:00:30', 'Edward', 25.25, 106, false);
```

## Download MySQL CDC connector on SSH

```
wget https://www.ververica.com/hubfs/JAR%20files/flink-sql-connector-mysql-cdc-2.4-SNAPSHOT.jar
```

## Add jar into sql-client.sh and connect to Flink SQL Client

```
bin/sql-client.sh -j flink-sql-connector-mysql-cdc-2.4-SNAPSHOT.jar
```

## Create Flink MySql cdc table on Flink SQL

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/63c7cb8c-f86c-4e58-bf73-3f0af3716030)

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/94af656a-f579-4851-a0b0-12fb2396d876)

## Make some changes on orders table

```sql
mysql> INSERT INTO orders
    -> VALUES (default, '2023-05-11 10:08:22', 'Mary', 50.50, 102, false),
    ->        (default, '2023-05-11 10:11:09', 'Lucy', 15.00, 105, false),
    ->        (default, '2023-05-11 12:00:30', 'Mike', 25.25, 106, false);
Query OK, 3 rows affected (0.23 sec)
Records: 3  Duplicates: 0  Warnings: 0
```

## Validation
Monitor the table on Flink SQL

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/17b8383a-eff2-427e-9f18-652e5d66fd42)




