Change Data Capture (CDC) is a technique you can use to track row-level changes in database tables in response to create, update, and delete operations. In this article, we use CDC Connectors for Apache Flink®, which offer a set of source connectors for Apache Flink. The connectors integrate Debezium® as the engine to capture the data changes.

Apache Flink supports to interpret Debezium JSON and Avro messages as INSERT/UPDATE/DELETE messages into Flink SQL system.

This support is useful in many cases to:
- Synchronize incremental data from databases to other systems
- Audit logs
- Build real-time materialized views on databases
- View temporal join changing history of a database table

Now, let us learn how to use Change Data Capture (CDC) of SQL Server using Flink SQL. The SQLServer CDC connector allows for reading snapshot data and incremental data from SQLServer database.

## Prerequisites
- Prepare Azure SQL Server 2012 <br>
- HDInsight Flink 1.16.0 on AKS

## SQLServer CDC Connector
The SQLServer CDC connector is a Flink Source connector, which reads database snapshot first and then continues to read change events with exactly once processing even failures happen. This example uses Flink CDC to create a SQLServerCDC table on FLINK SQL

## Use SSH to use Flink SQL client
We have already covered this section in detail on how to use with Flink:
https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-web-ssh-on-portal-to-flink-sql

## Prepare table and enable CDC feature on SQL Server SQLDB
Let us prepare a table and enable the CDC, You can refer the detailed steps listed on SQL Documentation:
https://learn.microsoft.com/en-us/sql/relational-databases/track-changes/enable-and-disable-change-data-capture-sql-server?view=sql-server-ver16

**Create a database**
```sql
CREATE DATABASE inventory;
GO
```
**Enable CDC on the SQL Server database**
```sql
USE inventory;
EXEC sys.sp_cdc_enable_db;  
GO
```

**Verify that the user has access to the CDC table**
```sql
USE inventory
GO
EXEC sys.sp_cdc_help_change_data_capture
GO
```

**Note**
The query returns configuration information for each table in the database (enabled for CDC). If the result is empty, verify that the user has privileges to access both the capture instance as well as the CDC tables.

**Create and populate our products using a single insert with many rows**
```sql
CREATE TABLE products (
id INTEGER IDENTITY(101,1) NOT NULL PRIMARY KEY,
name VARCHAR(255) NOT NULL,
description VARCHAR(512),
weight FLOAT
);

INSERT INTO products(name,description,weight)
VALUES ('scooter','Small 2-wheel scooter',3.14);
INSERT INTO products(name,description,weight)
VALUES ('car battery','12V car battery',8.1);
INSERT INTO products(name,description,weight)
VALUES ('12-pack drill bits','12-pack of drill bits with sizes ranging from #40 to #3',0.8);
INSERT INTO products(name,description,weight)
VALUES ('hammer','12oz carpenter''s hammer',0.75);
INSERT INTO products(name,description,weight)
VALUES ('hammer','14oz carpenter''s hammer',0.875);
INSERT INTO products(name,description,weight)
VALUES ('hammer','16oz carpenter''s hammer',1.0);
INSERT INTO products(name,description,weight)
VALUES ('rocks','box of assorted rocks',5.3);
INSERT INTO products(name,description,weight)
VALUES ('jacket','water resistent black wind breaker',0.1);
INSERT INTO products(name,description,weight)
VALUES ('spare tire','24 inch spare tire',22.2);

EXEC sys.sp_cdc_enable_table @source_schema = 'dbo', @source_name = 'products', @role_name = NULL, @supports_net_changes = 0;

-- Creating simple orders on SQL Table

CREATE TABLE orders (
id INTEGER IDENTITY(10001,1) NOT NULL PRIMARY KEY,
order_date DATE NOT NULL,
purchaser INTEGER NOT NULL,
quantity INTEGER NOT NULL,
product_id INTEGER NOT NULL,
FOREIGN KEY (product_id) REFERENCES products(id)
);

INSERT INTO orders(order_date,purchaser,quantity,product_id)
VALUES ('16-JAN-2016', 1001, 1, 102);
INSERT INTO orders(order_date,purchaser,quantity,product_id)
VALUES ('17-JAN-2016', 1002, 2, 105);
INSERT INTO orders(order_date,purchaser,quantity,product_id)
VALUES ('19-FEB-2016', 1002, 2, 106);
INSERT INTO orders(order_date,purchaser,quantity,product_id)
VALUES ('21-FEB-2016', 1003, 1, 107);

EXEC sys.sp_cdc_enable_table @source_schema = 'dbo', @source_name = 'orders', @role_name = NULL, @supports_net_changes = 0;
GO
```

## Download SQLServer CDC connector on SSH
```
wget https://repo1.maven.org/maven2/com/ververica/flink-sql-connector-sqlserver-cdc/2.4.1/flink-sql-connector-sqlserver-cdc-2.4.1.jar
```

## Add jar into sql-client.sh and connect to Flink SQL Client
```
bin/sql-client.sh -j flink-sql-connector-sqlserver-cdc-2.4.1.jar
```

## Create SQLServer CDC table
```sql
SET 'sql-client.execution.result-mode' = 'tableau';

CREATE TABLE orders (
    id INT,
    order_date DATE,
    purchaser INT,
    quantity INT,
    product_id INT,
    PRIMARY KEY (id) NOT ENFORCED
) WITH (
    'connector' = 'sqlserver-cdc',
    'hostname' = '<updatehostname>.database.windows.net', //update with the host name
    'port' = '1433',
    'username' = '<update-username>', //update with the user name
    'password' = '<update-password>', //update with the password
    'database-name' = 'inventory',
    'table-name' = 'dbo.orders'
);

select * from orders;
```

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/e2ffcd49-3e7c-412e-9801-26caaff2e744)

## Perform changes on table from SQLServer side
![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/64aa7833-4228-4b81-beed-6718e5cbd626)

## Validation
Monitor the table on Flink SQL

![image](https://github.com/Guodong-Wang-prog/hdinsight-aks/assets/60081730/24960b71-5a84-4198-987b-3089f05d26b9)

## Reference
https://ververica.github.io/flink-cdc-connectors/master/content/connectors/sqlserver-cdc.html
