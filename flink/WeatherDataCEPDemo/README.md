## Flink Complex Event Processing to calculate Max Daily Temperature

The goal of this blog is to parse the [Quality Controlled Local Climatological Data (QCLCD)](https://www.ncdc.noaa.gov/cdo-web/datasets), 
calculates the maximum daily temperature of the stream by using Flink on HDInsight on AKS and writes the results back into an Azure Data Explorer 
and Azure managed PostgreSQL database(postgres.database.azure.com)

## Set up testing environment

• Flink 1.17.0 on HDInsight on AKS <br>
• Azure Data Explorer
• Azure managed PostgreSQL: 16.0
• Maven project development on Azure VM in the same Vnet <br>

