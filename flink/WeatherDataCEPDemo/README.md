## Flink Complex Event Processing to calculate Max Daily Temperature

The goal of this blog is to parse the [Quality Controlled Local Climatological Data (QCLCD)](https://www.ncdc.noaa.gov/cdo-web/datasets), 
calculates the maximum daily temperature of the stream by using Flink on HDInsight on AKS and writes the results back into an Azure Data Explorer 
and Azure managed PostgreSQL database(postgres.database.azure.com)

## Set up testing environment

• Flink 1.17.0 on HDInsight on AKS <br>
• Azure Data Explorer  <br>
• Azure managed PostgreSQL: 16.0  <br>
• Maven project development on Azure VM in the same Vnet <br>

## FlinkCEP - Complex event processing

https://nightlies.apache.org/flink/flink-docs-release-1.17/docs/libs/cep/

FlinkCEP is the Complex Event Processing (CEP) library implemented on top of Flink. It allows you to detect event patterns in an endless stream of events, giving you the opportunity to get hold of what’s important in your data.

FlinkCEP dependency to the pom.xml 
``` xml
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-cep</artifactId>
    <version>1.17.0</version>
</dependency>
```
## FlinkCEP - Complex event processing

## Testing steps

### Input Source

[Quality Controlled Local Climatological Data (QCLCD)](https://www.ncdc.noaa.gov/cdo-web/datasets)
https://www.ncdc.noaa.gov/cdo-web/datasets

Local Climatological Data is a monthly summary consisting of: 1) Summary sheet containing daily extremes and averages of temperature , departures from normal, average dew point and wet bulb temperatures, degree days, significant weather, precipitation, snowfall, snow depth, station and sea level pressure, and average and extreme wind speeds; 2) Hourly observations of most of these same weather elements plus sky conditions and visibility; 3) Hourly coded remarks; and 4) Hourly Precipitation table. The LCD is provided for approximately 1000 U.S. stations since 2005.

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/b5e5cc6b-9e55-4fb4-89f6-e2a2735b0033)

In this blog, I 


### Sink 1: Azure Database for PostgreSQL flexible server on Azure portal

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/039be564-a07f-414c-b3b4-fe1c764500f9)

Create WeatherTable(Max Temporature Table) and Warning Table:<br>
``` SQL
postgres=> CREATE TABLE WeatherTable(
station TEXT,
date timestamp,
temperature TEXT,
skyCondition TEXT,
stationPressure TEXT,
windSpeed TEXT);
CREATE TABLE
postgres=> \d WeatherTable;
                          Table "public.weathertable"
     Column      |            Type             | Collation | Nullable | Default 
-----------------+-----------------------------+-----------+----------+---------
 station         | text                        |           |          | 
 date            | timestamp without time zone |           |          | 
 temperature     | text                        |           |          | 
 skycondition    | text                        |           |          | 
 stationpressure | text                        |           |          |
 windSpeed       | text                        |           |          | 

postgres=> CREATE TABLE WeatherTableWarning (
  message TEXT);
CREATE TABLE
postgres=> \d WeatherTableWarning
       Table "public.weathertablewarning"
 Column  | Type | Collation | Nullable | Default 
---------+------+-----------+----------+---------
 message | text |           |          | 
```

### Sink 2: Azure Data Explorer(ADX) on Azure portal

**ADX over view on Azure portal** <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/8d3f2eb9-7ebf-4d3a-ac8d-0ef80a848045)

**Create Database**  <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/acf077b3-7e44-4a0c-bf31-9374d7819a00)

**Register Severice principle and Grant Admin user role in ADX**  <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/0e5417cc-94a6-4421-a3dd-01dfad15d336)

**Create WeatherTable(Max Temp) and Warning table**  <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/695c9306-5959-4bc0-8925-72b44eb5d04c)


## Testing steps

```
wget https://cicigen2.blob.core.windows.net/jar/CEPWeatherDemo-1.0-SNAPSHOT.jar
bin/flink run -c contoso.example.CEP.source.WeatherDSExample -j CEPWeatherDemo-1.0-SNAPSHOT.jar
bin/flink run -c contoso.example.CEP.source.WeatherDataCEPExample -j CEPWeatherDemo-1.0-SNAPSHOT.jar![image]
```

```
data@sshnode-0 [ ~ ]$ bin/flink run -c contoso.example.CEP.source.WeatherDSExample -j CEPWeatherDemo-1.0-SNAPSHOT.jar
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by org.apache.flink.api.java.ClosureCleaner (file:/opt/flink-webssh/lib/flink-dist-1.17.0-1.1.8.jar) to field java.lang.String.value
WARNING: Please consider reporting this to the maintainers of org.apache.flink.api.java.ClosureCleaner
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release
Job has been submitted with JobID 1cc452c21bc23766197dec599435bd42![image]
```

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/45372fe4-cf4c-4c09-86cf-25242add6081)


```
data@sshnode-0 [ ~ ]$ bin/flink run -c contoso.example.CEP.source.WeatherDataCEPExample -j CEPWeatherDemo-1.0-SNAPSHOT.jar
WARNING: An illegal reflective access operation has occurred
WARNING: Illegal reflective access by org.apache.flink.api.java.ClosureCleaner (file:/opt/flink-webssh/lib/flink-dist-1.17.0-1.1.8.jar) to field java.lang.String.value
WARNING: Please consider reporting this to the maintainers of org.apache.flink.api.java.ClosureCleaner
WARNING: Use --illegal-access=warn to enable warnings of further illegal reflective access operations
WARNING: All illegal access operations will be denied in a future release
Job has been submitted with JobID 3d5a9732c52e0ab989365d3d54af458d![image]
```

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/7f58a8a7-a356-4a73-8db4-d6729a20f8a8)

**Result: <br>**
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/4e987892-e29d-4e04-9cf2-08c2db614e28)

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/8df71fe3-5fd2-4700-83bb-778f548ccff7)

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/b6ae7dd2-52cd-4bca-9648-0fe690ee822a)

## ADX
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/d4a78de0-1dd4-4e1a-948b-1524464a71b0)


## Postgres
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/04c9ae5f-89c0-4437-a9cc-ef2f0cc89356)
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/5d876203-949e-4daa-9c36-6e784843b72d)

## Clean up the Resource

• Flink 1.17.0 on HDInsight on AKS <br>
• Azure Data Explorer  <br>
• Azure managed PostgreSQL: 16.0  <br>
• Maven project development on Azure VM in the same Vnet <br>

## References
This blog refers [https://github.com/apache/flink-training/blob/master/README.md](https://github.com/KarstenSchnitter/FlinkExperiments)











