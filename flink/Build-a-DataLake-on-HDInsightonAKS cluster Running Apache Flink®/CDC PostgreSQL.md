This example demonstrates how to monitor changes on PostgreSQL table using Flink-SQL CDC. 

Change Data Capture (CDC) is a technique you can use to track row-level changes in database tables in response to create, update, and delete operations. In this article, we use CDC Connectors for Apache Flink®, which offer a set of source connectors for Apache Flink. The connectors integrate Debezium® as the engine to capture the data changes.

Flink supports to interpret Debezium JSON and Avro messages as INSERT/UPDATE/DELETE messages into Apache Flink SQL system.

This support is useful in many cases to:

.Synchronize incremental data from databases to other systems <br>
.Audit logs  <br>
.Build real-time materialized views on databases  <br>
.View temporal join changing history of a database table  <br>

## Prerequisites

. Azure PostgresSQL flexible server Version 14.7  <br>
. HDInsight Flink 1.16.0 on AKS  <br>
. Linux virtual Machine to use PostgreSQL client  <br>
. Add the NSG rule that allows inbound and outbound connections on port 5432 in HDInsight on AKS pool subnet.  <br>

## Flink PostgreSQL CDC connector 

The PostgreSQL CDC connector allows for reading snapshot data and incremental data from PostgreSQL database.

## Prepare PostgreSQL table & Client

Using a Linux virtual machine, install PostgreSQL client using below commands

```
sudo apt-get update
sudo apt-get install postgresql-client
```

Install the certificate to connect to PostgreSQL server using SSL
```
wget --no-check-certificate https://dl.cacerts.digicert.com/DigiCertGlobalRootCA.crt.pem
```

Connect to the server (replace host, username and database name accordingly)

```
psql --host=flinkpostgres.postgres.database.azure.com --port=5432 --username=admin --dbname=postgres --set=sslmode=require --set=sslrootcert=DigiCertGlobalRootCA.crt.pem
```

After connecting to the database successfully, create a sample table
``` SQL
CREATE TABLE shipments (
    shipment_id SERIAL NOT NULL PRIMARY KEY,
    order_id SERIAL NOT NULL,
    origin VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    is_arrived BOOLEAN NOT NULL
  );
  ALTER SEQUENCE public.shipments_shipment_id_seq RESTART WITH 1001;
  ALTER TABLE public.shipments REPLICA IDENTITY FULL;
  INSERT INTO shipments
  VALUES (default,10001,'Beijing','Shanghai',false),
     (default,10002,'Hangzhou','Shanghai',false),
     (default,10003,'Shanghai','Hangzhou',false);
```

To enable CDC on PostgreSQL database, you're required to make the following changes.<br>
WAL level must be changed to logical. This value can be changed in server parameters section on Azure portal.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/f9b77d67-4055-40f7-84ca-ec3db3f872ec)

User accessing the table must have 'REPLICATION' role added <br>
``` SQL
ALTER USER <username> WITH REPLICATION;
```

## Create Apache Flink PostgreSQL CDC table

download  Flink PostgreSQL CDC jar <br>
```
wget https://repo1.maven.org/maven2/com/ververica/flink-sql-connector-postgres-cdc/2.4.2/flink-sql-connector-postgres-cdc-2.4.2.jar
```

webssh to enter Flink SQL <br>
```
/opt/flink-webssh/bin/sql-client.sh -j /opt/flink-sql-connector-postgres-cdc-2.4.2.jar
```

Create table on Flink SQL <br>
``` SQL
CREATE TABLE shipments (
   shipment_id INT,
   order_id INT,
   origin STRING,
   destination STRING,
   is_arrived BOOLEAN,
   PRIMARY KEY (shipment_id) NOT ENFORCED
 ) WITH (
   'connector' = 'postgres-cdc',
   'hostname' = 'flinkpostgres.postgres.database.azure.com',
   'port' = '5432',
   'username' = 'username',
   'password' = 'admin',
   'database-name' = 'postgres',
   'schema-name' = 'public',
   'table-name' = 'shipments',
   'decoding.plugin.name' = 'pgoutput'
 );
```

**Validation**
``` SQL
select * from shipments;
```

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/dc5e1c12-2ea5-4bbf-8e75-3ebeeb097b58)

## Clean up resource


