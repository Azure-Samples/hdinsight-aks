# Analyzing NYC Trip data using Trino in HDInsight on AKS

This demo showcases how you can use federated capability of Trino in HDInsight on AKS to analyze NYC Trip data

## Pre-requisites

* Trino cluster with HDInsight on AKS
* ADLS Gen2 storage and user-assigned managed identity (MSI)
* Azure Postgres or Azure SQL Database

## Scenario

For this scenario, we are going to cover the following path:
1. Take data from NYC Trip offical site, for this demostration, we will downalod one month data from [NYC site](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
2. Land the data ADLS Gen2 and expose it as Hive table in Trino.
3. Prepare zone data and land in AZure postgres or SQL Databse
4. Run Trino query on two data source hive and SQL databse

## Demo steps

### Step 1: Create a Trino cluster with HDInsight on AKS with hive catalog

* Create a [Trino cluster with HDInsight on AKS](/azure/hdinsight/kafka/apache-kafka-get-started) inside a VNet.

* Dowanload the NYC data for any month. For this demo, we are have downloaded Oct 2022 data as parquet file

* Create ADLS Gen 2 storage "sampleteststorage" with directory as "year=2022"/"month=10'
   * Copy/Upload the downloaded trip data to the new created directory in sampleteststorage

*
