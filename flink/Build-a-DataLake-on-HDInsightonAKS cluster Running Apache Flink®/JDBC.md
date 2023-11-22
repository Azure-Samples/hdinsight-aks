
This example creates an Azure SQL Server table using JDBC SQL Connector on FLINK SQL.

## JDBC SQL Connector on Flink
The JDBC connector allows for reading data from and writing data into any relational databases with a JDBC driver. This document describes how to setup the JDBC connector to run SQL queries against relational databases.

The JDBC sink operate in upsert mode for exchange UPDATE/DELETE messages with the external system if a primary key is defined on the DDL, otherwise, it operates in append mode and doesn’t support to consume UPDATE/DELETE messages.

## Prerequisites
- Prepare SQL Server Database on Azure SQL Server 2012
- HDInsight Flink 1.16.0 on AKS

## Download required jar on webssh

```
wget https://repo1.maven.org/maven2/org/apache/flink/flink-connector-jdbc/3.1.0-1.16/flink-connector-jdbc-3.1.0-1.16.jar
wget https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/12.4.0.jre11/mssql-jdbc-12.4.0.jre11.jar
```

```
user@sshnode-0 [ ~ ]$ ls -l *.jar
-rw-rw-r-- 1 user user  264302 Apr 13 14:05 flink-connector-jdbc-3.1.0-1.16.jar
-rw-rw-r-- 1 user user 1183551 Jul 31 21:08 mssql-jdbc-12.4.0.jre11.jar
```

## Create SQL Server table on Flink SQL

-- on webssh
```
bin/sql-client.sh -j flink-connector-jdbc-3.1.0-1.16.jar -j mssql-jdbc-12.4.0.jre11.jar
```

-- on Flink SQL
``` SQL
CREATE CATALOG myhive WITH (
    'type' = 'hive'
);

USE CATALOG myhive;


CREATE TABLE roles_sqlserver (
  `ROLE_ID` BIGINT,
  `CREATE_TIME` INT,
  `OWNER_NAME` STRING,
  `ROLE_NAME` STRING,
  PRIMARY KEY (ROLE_ID) NOT ENFORCED
) WITH (
  'connector' = 'jdbc',
  'url' = 'jdbc:sqlserver://cicihdionakssqlserver.database.windows.net:1433;database=hivedb',
  'table-name' = 'dbo.roles',
  'driver' = 'com.microsoft.sqlserver.jdbc.SQLServerDriver',
  'username' = '<username>',
  'password' = '<Password>'
);

select * from roles_sqlserver;

Flink SQL> insert into roles_sqlserver values(3,1692769800,'read','read');
[INFO] Submitting SQL update statement to the cluster...
[INFO] SQL update statement has been successfully submitted to the cluster:
Job ID: b2094a64342edbb2f746e3663be43b33


Flink SQL> insert into roles_sqlserver values(4,1692769800,'write','write');
[INFO] Submitting SQL update statement to the cluster...
[INFO] SQL update statement has been successfully submitted to the cluster:
Job ID: f114e829b24874d0517689a037944f0f


Flink SQL> select * from roles_sqlserver;
+----+----------------------+-------------+--------------------------------+--------------------------------+
| op |              ROLE_ID | CREATE_TIME |                     OWNER_NAME |                      ROLE_NAME |
+----+----------------------+-------------+--------------------------------+--------------------------------+
| +I |                    1 |  1692769677 |                          admin |                          admin |
| +I |                    2 |  1692769677 |                         public |                         public |
| +I |                    3 |  1692769800 |                           read |                           read |
| +I |                    4 |  1692769800 |                          write |                          write |
+----+----------------------+-------------+--------------------------------+--------------------------------+
Received a total of 4 rows

Flink SQL> delete from roles_sqlserver where ROLE_ID=3;
[ERROR] Could not execute SQL statement. Reason:
org.apache.flink.table.api.TableException: Unsupported query: delete from roles_sqlserver where ROLE_ID=3;

Flink SQL> update roles_sqlserver set OWNER_NAME = 'read-only' where OWNER_NAME = 'read';
[ERROR] Could not execute SQL statement. Reason:
org.apache.flink.table.api.TableException: Unsupported query: update roles_sqlserver set OWNER_NAME = 'read-only' where OWNER_NAME = 'read';

```
