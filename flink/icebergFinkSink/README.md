**This demo will use a java-faker library to generate Streaming Lord of the Rings data using Flink’s native support
for rich functions, and then sink the stream data into an Iceberg table on HDInsight on AKS running Flink cluster.**

You can also use a single shared catalog, both HDInsight on AKS running Flink cluster and Spark on Azure Databricks can 
operate on the same Iceberg warehouse.

## Requirements <br>
Azure HDInsight Flink 1.16 on AKS

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/ee1c0745-f6b9-42d6-b244-ce48cb02a6c4)

## Prepare Iceberg Database and Table on Flink SQL:

Please referr below HDInsight on AKS public doc to create iceberg database and table: <br>

#Ref <br>
https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-catalog-iceberg-hive

In this demo, connect to the SSH from Azure portal: <br>

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/5b7041dc-59b1-4e12-bf4c-b6919ed6ca04)

#Ref <br>
https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-web-ssh-on-portal-to-flink-sql

**Connecting to Flink SQL Client**

```
user@sshnode-0 [ ~ ]$ bin/sql-client.sh 

                                   ????????
                               ????????????????
                            ???????        ???????  ?
                          ????   ?????????      ?????
                          ???         ???????    ?????
                            ???            ???   ?????
                              ??       ???????????????
                            ?? ?   ???       ?????? ?????
                            ?????   ????      ????? ?????
                         ???????       ???    ??????? ???
                   ????????? ??         ??    ??????????
                  ????????  ??           ?   ?? ???????
                ????  ???            ?  ?? ???????? ?????
               ???? ? ??          ? ?? ????????    ????  ??
              ???? ????          ??????????       ??? ?? ????
           ???? ?? ???       ???????????         ????  ? ?  ???
           ???  ?? ??? ?????????              ????           ???
           ??    ? ???????              ????????          ??? ??
           ???    ???    ????????????????????            ????  ?
          ????? ???   ??????   ????????                  ????  ??
          ????????  ???????????????                            ??
          ?? ????   ???????  ???       ??????    ??          ???
          ??? ???  ???  ???????            ????   ?????????????
           ??? ?????  ????  ??                ??      ????   ???
           ??   ???   ?     ??                ??              ??
            ??   ??         ??                 ??        ????????
             ?? ?????       ??                  ???????????    ??
              ??   ????      ?                    ???????      ??
               ???   ?????                         ?? ???????????
                ????    ????                     ??????? ????????
                  ?????                          ??  ????  ?????
                      ?????????????????????????????????  ?????
          
    ______ _ _       _       _____  ____  _         _____ _ _            _  BETA   
   |  ____| (_)     | |     / ____|/ __ \| |       / ____| (_)          | |  
   | |__  | |_ _ __ | | __ | (___ | |  | | |      | |    | |_  ___ _ __ | |_ 
   |  __| | | | '_ \| |/ /  \___ \| |  | | |      | |    | | |/ _ \ '_ \| __|
   | |    | | | | | |   <   ____) | |__| | |____  | |____| | |  __/ | | | |_ 
   |_|    |_|_|_| |_|_|\_\ |_____/ \___\_\______|  \_____|_|_|\___|_| |_|\__|
          
        Welcome! Enter 'HELP;' to list all available commands. 'QUIT;' to exit.

Command history file path: /home/user/.flink-sql-history

Flink SQL> 
```

**Create hive catalog**
``` SQL
CREATE CATALOG hive_catalog WITH (
	'type'='iceberg',
	'catalog-type'='hive',
	'uri'='thrift://hive-metastore:9083',
	'clients'='5',
	'property-version'='1',
	'warehouse'='abfs://<container>@<storage_account>.dfs.core.windows.net/<path>');

USE catalog hive_catalog;
```

**Add iceberg dependencies to server classpath**
```
ADD JAR '/opt/flink-webssh/lib/iceberg-flink-runtime-1.16-1.3.0.jar';
ADD JAR '/opt/flink-webssh/lib/parquet-column-1.12.2.jar';
```

**Create Database**
``` SQL
CREATE DATABASE lord;
USE lord;
```
**Create Table**
``` SQL
CREATE TABLE `hive_catalog`.`iceberg_db_2`.`iceberg_sample_2`
(
`character` STRING,
`location` STRING,
`event_time` TIMESTAMP(3)
);

Flink SQL> show tables from lord;
+---------------------+
|          table name |
+---------------------+
| character_sightings |
+---------------------+
1 row in set

```


## DataStream Source:

This Java Faker library can generate fake data. It's useful when you're developing a new project and need some pretty data for showcase.
In this demo, I use it to generate stream Lord of the Rings data: <LordSourceFunction.java>

Below LordSourceFunction is used in the main method to create a DataStream<RowData> source. This source is then used as the input for the Iceberg sink. The purpose of this function is to continuously generate and emit rows of data that can be processed by the Flink job. The data is emitted at a rate of one row every 5 seconds. Each row consists of a Lord of the Rings character name, a location, and a timestamp. 
The character name and location are randomly generated using the Faker library. 
The timestamp is a random value between the current time and 500 years ago. 
This data is then written into an Iceberg table.

It extends the RichParallelSourceFunction class, which is a base class for implementing a parallel data source in Flink.

**Schema** <br>
  . character string
  . location string
  . event_time timestamp

``` java
public class LordSourceFunction extends RichParallelSourceFunction<RowData> {
    private volatile boolean isRunning = true;

    @Override
    public void run(SourceContext<RowData> ctx) throws Exception {
        Faker faker = new Faker();
        while (isRunning) {
            ZonedDateTime now = ZonedDateTime.now(ZoneId.systemDefault());
            ZonedDateTime fiveHundredYearsAgo = now.minusYears(500);
            long randomTimestamp = ThreadLocalRandom
                    .current()
                    .nextLong(fiveHundredYearsAgo.toInstant().toEpochMilli(), now.toInstant().toEpochMilli());

            // Convert the timestamp to a TimestampData
            TimestampData event_time = TimestampData.fromEpochMillis(randomTimestamp);

            // Create a new row
            GenericRowData row = new GenericRowData(3);
            row.setField(0, StringData.fromString(faker.lordOfTheRings().character()));
            row.setField(1, StringData.fromString(faker.lordOfTheRings().location()));
            row.setField(2, event_time);

            // Sleep for 5 seconds
            Thread.sleep(5000);

            // Emit the row
            ctx.collect(row);

        }
    }

    @Override
    public void cancel() {
        isRunning = false;
    }
}
```

#Ref <br>
https://github.com/DiUS/java-faker

## Maven pom.xml

``` XML
    <properties>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
        <flink.version>1.16.0</flink.version>
        <java.version>1.8</java.version>
    </properties>
    <dependencies>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-streaming-java -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-streaming-java</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-java</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-clients -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-clients</artifactId>
            <version>${flink.version}</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-connector-files -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-connector-files</artifactId>
            <version>${flink.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.hive</groupId>
            <artifactId>hive-exec</artifactId>
            <version>3.1.2</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-table-api-java</artifactId>
            <version>${flink.version}</version>
            <scope>provided</scope>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.flink/flink-connector-hive -->
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-connector-hive_2.12</artifactId>
            <version>1.16.0</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>com.github.javafaker</groupId>
            <artifactId>javafaker</artifactId>
            <version>1.0.2</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.apache.iceberg/iceberg-flink-1.16 -->
        <dependency>
            <groupId>org.apache.iceberg</groupId>
            <artifactId>iceberg-flink-1.16</artifactId>
            <version>1.3.0</version>
        </dependency>
        <dependency>
            <groupId>com.codahale.metrics</groupId>
            <artifactId>metrics-core</artifactId>
            <version>3.0.2</version>
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-metrics-dropwizard</artifactId>
            <version>${flink.version}</version>
        </dependency>
    </dependencies>
```

## Main Code: <FlinkSinkTest.java>

**Set up the execution environment for the Flink streaming job**
``` java
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
```

**checkpointing is set to 10 seconds**

``` java
        env.enableCheckpointing(10000);
        String checkPointPath = "abfs://iceberg@cicihilogen2.dfs.core.windows.net/CheckPoint";
        env.getCheckpointConfig().setCheckpointStorage(checkPointPath);
```

**Generate the stream data**
**the interval at which a fake data record is generated is set to 5 seconds**

 ``` java
        DataStream<RowData> streamSource = env.addSource(new LordSourceFunction());
        streamSource.print();
```
**Define the Iceberg schema**

``` java
        Schema icebergSchema = new Schema(
                Types.NestedField.optional(1, "character", Types.StringType.get()),
                Types.NestedField.optional(2, "location", Types.StringType.get()),
                Types.NestedField.optional(3, "event_time", Types.TimestampType.withoutZone())
        );
```

**Specify database and table**

``` java
        String databaseName = "lord";
        String tableName = "character_sightings";
```

**Create a HiveConf**

``` java
        HiveConf hiveConf = new HiveConf();
        hiveConf.set("hive.metastore.uris", "thrift://hive-metastore:9083");
        hiveConf.set("hive.metastore.warehouse.dir", "abfs://iceberg@cicihilogen2.dfs.core.windows.net/iceberg-output");
```

**Convert HiveConf to Configuration** <br>

Below are used to load the Iceberg catalog and table. 
The catalog is loaded from a Hive Metastore, and the table is identified by the database name lord and table name character_sightings.

``` java
        Configuration hadoopConf = new Configuration(hiveConf);
```

**Create a CatalogLoader**

``` java
        CatalogLoader catalogLoader = CatalogLoader.hive(catalogName, hadoopConf, Collections.emptyMap());
```

**Create a TableIdentifier**
``` java
        TableIdentifier identifier = TableIdentifier.of(databaseName, tableName);
```

**Create a TableLoader**

``` java
        TableLoader tableLoader = TableLoader.fromCatalog(catalogLoader, identifier);
```

**Sink the stream data into the Iceberg table, the sink is configured with the table loader, the Iceberg schema, the distribution mode, and the write parallelism.**

``` java
        FlinkSink.forRowData(streamSource)
                .tableLoader(tableLoader)
                .tableSchema(FlinkSchemaUtil.toSchema(icebergSchema))
                .distributionMode(DistributionMode.HASH)
                .writeParallelism(2)
                .append();
        
        // Start the Flink streaming job
        env.execute("iceberg Sink Job");
```

## Package the jar and submit to HDInsight Flink cluster on AKS to run <br>

Connect to the SSH from Azure portal and upload the jar and submit the job:

```
bin/flink run -c contoso.example.FlinkSinkTest -j FlinkIceBergDemo-1.0-SNAPSHOT.jar
Job has been submitted with JobID f1aa999990428ee07717e12c662189ab
```

Flink UI: <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/b3e3568f-1e0e-4b25-bce9-3524690a0db7)

## Check iceberg table data:

**Flink SQL**

```
select * from lord.character_sightings;
```

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/3d6252b6-c93b-450b-8d34-5f6fb160facc)

**On Azure Storage side**

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/f671201c-f543-4f9e-a93d-64e522261f5a)

## Clean up resource

. Stop streaming job on Flink UI <br>
. Delete the table <br>
. Delete the Cluster, Cluster Pool <br>






