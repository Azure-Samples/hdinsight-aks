## Build a DataLake on HDInsight AKS cluster running Apache Flink

Building a data-driven business necessitates the democratization of enterprise data assets in a data catalog. A unified data catalog allows for quick dataset searches and understanding of data schema, format, and location. Azure HDInsight on AKS uses Hive’s Metastore as a persistent catalog with Apache Flink’s Hive Catalog, providing a uniform repository where disparate systems can store and find metadata to keep track of data in data silos.

Apache Flink is a widely used data processing engine for scalable streaming ETL, analytics, and event-driven applications. It offers precise time and state management with fault tolerance. Flink can process both bounded streams (batch) and unbounded streams (stream) with a unified API or application. After data is processed with Apache Flink, downstream applications can access the curated data through a unified data catalog. With unified metadata, both data processing and data consuming applications can access the tables using the same metadata.

In Azure HDInsight on AKS, we enable the option to use an external Hive metastore when creating a Flink cluster in the Azure HDInsight cluster pool on the portal. This allows you to ingest streaming data in real time and access the data in near-real time for business analysis.

This post shows you how to integrate Apache Flink in Azure HDInsight on AKS with Hive’s Metastore so that you can ingest streaming data in real time and access the data in near-real time for business analysis. By leveraging the capabilities of Azure HDInsight on AKS and Apache Flink, you can build robust, scalable, and efficient data processing pipelines that power your data-driven business.

## Apache Flink connector and catalog architecture

Apache Flink employs a connector for data interaction and a catalog for metadata interaction. The architecture of the Apache Flink connector, which handles data read/write operations, and the catalog, which manages metadata read/write operations, is depicted in the following diagram.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/a53831b7-98d7-4bd0-97ac-caf421634883)


**Catalog Types**

. GenericInMemoryCatalog <br>

The GenericInMemoryCatalog is an in-memory implementation of a catalog. All objects will be available only for the lifetime of the session.

. JbcCatalog <br>

The JdbcCatalog enables users to connect Flink to relational databases over JDBC protocol.
The JDBC connector allows for reading data from and writing data into any relational databases with a JDBC driver.

. HiveCatalog <br>

The HiveCatalog serves two purposes; as persistent storage for pure Flink metadata, and as an interface for reading and writing existing Hive metadata.

. User-Defined Catalog <br>

Catalogs are pluggable and users can develop custom catalogs by implementing the Catalog interface.

## HDInsight AKS cluster running Apache Flink with Hive’s Metastore

**Ref**
https://learn.microsoft.com/en-us/azure/hdinsight-aks/flink/flink-create-cluster-portal#create-an-apache-flink-cluster

**Create a Flink Cluster with HMS on Azure portal**
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/69553231-6454-4b50-a459-08cf26a10dba)

<img src="[https://github.com/Baiys1234/hdinsight-aks/assets/35547706/a53831b7-98d7-4bd0-97ac-caf421634883](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/69553231-6454-4b50-a459-08cf26a10dba)" width="300" height="300">

**Confirm on Flink Cluster overview**
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/e0b682b8-57f8-4bc2-bd34-5f024811c257)

**Check HMS process running on pods on Auzre portal AKS cluster pool side**
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/68bc020d-31e6-4f98-9d03-85e0c9fb07d7)





