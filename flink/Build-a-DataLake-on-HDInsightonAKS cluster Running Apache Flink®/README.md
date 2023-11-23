## Build a DataLake on HDInsight AKS cluster running Apache Flink

Building a data-driven business necessitates the democratization of enterprise data assets in a data catalog. A unified data catalog allows for quick dataset searches and understanding of data schema, format, and location. Azure HDInsight on AKS uses Hive’s Metastore as a persistent catalog with Apache Flink’s Hive Catalog, providing a uniform repository where disparate systems can store and find metadata to keep track of data.

Apache Flink is a widely used data processing engine for scalable streaming ETL, analytics, and event-driven applications. It offers precise time and state management with fault tolerance. Flink can process both bounded streams (batch) and unbounded streams (stream) with a unified API or application. After data is processed with Apache Flink, downstream applications can access the curated data through a unified data catalog. With unified metadata, both data processing and data consuming applications can access the tables using the same metadata.

In HDInsight AKS cluster running Apache Flink, we enable the option to use an external Hive metastore when creating a Flink cluster in the Azure HDInsight cluster pool on the portal. This allows you to ingest streaming data in real time and access the data in near-real time for business analysis.

This post shows you how to integrate Apache Flink in Azure HDInsight on AKS with Hive’s Metastore so that you can ingest streaming data in real time and access the data in near-real time for business analysis. By leveraging the capabilities of Azure HDInsight on AKS and Apache Flink, you can build robust, scalable, and efficient data processing pipelines that power your data-driven business.

## Apache Flink connector and catalog architecture

Apache Flink employs a connector for data interaction and a catalog for metadata interaction. The architecture of the Apache Flink connector, which handles data read/write operations, and the catalog, which manages metadata read/write operations, is depicted in the following diagram.


**Catalog Types**

Flink has three built-in implementations for the catalog: <br>

. GenericInMemoryCatalog <br>

The GenericInMemoryCatalog stores the catalog data in memory.  All objects will be available only for the lifetime of the session.

. JbcCatalog <br>

The JdbcCatalog stores the catalog data in a JDBC-supported relational database. 
The JDBC connector allows for reading data from and writing data into any relational databases with a JDBC driver.

. HiveCatalog <br>

The HiveCatalog stores the catalog data in Hive Metastore. 
It serves two purposes; as persistent storage for pure Flink metadata, and as an interface for reading and writing existing Hive metadata.

. User-Defined Catalog <br>

Catalogs are pluggable and users can develop custom catalogs by implementing the Catalog interface.

## Catalog On HDInsight AKS cluster running Apache Flink <br>

In HDInsight AKS cluster running Apache Flink, we enable the option to use an external Hive metastore when creating a Flink cluster in the Azure HDInsight cluster pool on the portal. 

### Enable HDInsight AKS cluster running Apache Flink with Hive’s Metastore

Ref <br>
https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-create-cluster-portal#create-an-apache-flink-cluster

Create a Flink Cluster with HMS on Azure portal <br>

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/69553231-6454-4b50-a459-08cf26a10dba)

Confirm on Flink Cluster overview  <br>

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/5eea41fd-e788-4b2f-aa73-f940c306f94f)

Check HMS process running on pods on Auzre portal AKS cluster pool side  <br>

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/6ecc8e52-5290-4870-a952-742e1ddfa89a)












