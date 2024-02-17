## Flink Complex Event Processing to calculate Max Daily Temperature

The goal of this blog is to parse the [Quality Controlled Local Climatological Data (QCLCD)](https://www.ncdc.noaa.gov/cdo-web/datasets), 
calculates the **maximum daily temperature** and print Warning if high-temp(>= 38) occurs twice within a span of two days of the stream and  by using Flink Complex Event Processing(CEP) Lib on HDInsight on AKS and writes the results back into an Azure Data Explorer 
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

[Quality Controlled Local Climatological Data (QCLCD)](https://www.ncdc.noaa.gov/cdo-web/datasets) <br>
https://www.ncdc.noaa.gov/cdo-web/datasets <br>
https://www.ncei.noaa.gov/cdo-web/datatools/lcd <br>

Local Climatological Data is a monthly summary consisting of: 1) Summary sheet containing daily extremes and averages of temperature , departures from normal, average dew point and wet bulb temperatures, degree days, significant weather, precipitation, snowfall, snow depth, station and sea level pressure, and average and extreme wind speeds; 2) Hourly observations of most of these same weather elements plus sky conditions and visibility; 3) Hourly coded remarks; and 4) Hourly Precipitation table. The LCD is provided for approximately 1000 U.S. stations since 2005.

This blog refers above Local Climatological Data to generate a streaming weather data with column below:<br>
[LocalWeatherGenerator.java] (https://github.com/Baiys1234/hdinsight-aks/blob/main/flink/WeatherDataCEPDemo/src/mian/java/contoso/example/CEP/generator/LocalWeatherGenerator.java)

example:<br>
```
station,date,temperature,skyCondition,stationPressure,windSpeed
72306613713,2023-02-28T00:55:00,67,SCT:04 50,29.38,15
72306613713,2023-02-28T01:55:00,65,FEW:02 44,29.38,10
72306613713,2023-02-28T02:55:00,62,CLR:00,29.39,8
72306613713,2023-02-28T03:55:00,61,CLR:00,29.4,6
72306613713,2023-02-28T04:55:00,59,FEW:02 60,29.43,6
72306613713,2023-02-28T05:55:00,57,CLR:00,29.46,7
```
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/b5e5cc6b-9e55-4fb4-89f6-e2a2735b0033)

Note:
```
station  -- WBAN Identifier: The unique identifier for this station
date  -- Weather Generate Data incluing timestamp
temperature   -- Dry Bulb Temperature:This is the temperature that we commonly refer to as the “air temperature”
skyCondition  -- This describes the condition of the sky at the time of observation. SCT:04 50 means there were scattered clouds at 5000 feet, FEW:02 44 means there were few clouds at 4400 feet, and CLR:00 means the sky was clear
stationPressure --  The atmospheric pressure at the station at the time of observation, likely measured in inches of mercury (inHg).
windSpeed -- the wind speed at the time of observation, likely measured in knots
```

### Sink Destination 1: Azure Database for PostgreSQL flexible server on Azure portal

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

### Sink Destination 2: Azure Data Explorer(ADX) on Azure portal

**ADX over view on Azure portal** <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/8d3f2eb9-7ebf-4d3a-ac8d-0ef80a848045)

**Create Database**  <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/acf077b3-7e44-4a0c-bf31-9374d7819a00)

**Register Severice principle and Grant Admin user role in ADX**  <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/0e5417cc-94a6-4421-a3dd-01dfad15d336)

**Create WeatherTable(Max Temp) and Warning table**  <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/695c9306-5959-4bc0-8925-72b44eb5d04c)


## Main code: <br>
### Take the Maximum Temperature per day <br>
[WeatherDSExample.java](https://github.com/Baiys1234/hdinsight-aks/blob/main/flink/WeatherDataCEPDemo/src/mian/java/contoso/example/CEP/source/WeatherDSExample.java)

``` java
        // use LocalWeatherGenerator to generator local weather data
        DataStream<LocalWeatherData> weatherDataStream = env.addSource(new LocalWeatherGenerator());

        // assign the Measurement Timestamp:
        DataStream<LocalWeatherData> localWeatherDataDataStream = weatherDataStream
                .assignTimestampsAndWatermarks(new AscendingTimestampExtractor<LocalWeatherData>() {
                    @Override
                    public long extractAscendingTimestamp(LocalWeatherData localWeatherData) {
                        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
                        Date measurementTime;
                        try {
                            measurementTime = dateFormat.parse(localWeatherData.getDate());
                        } catch (ParseException e) {
                            throw new RuntimeException("Unable to parse date " + localWeatherData.getDate(), e);
                        }
                        return measurementTime.getTime();
                    }
                });

        // First build a KeyedStream over the Data with LocalWeather:
        KeyedStream<LocalWeatherData, String> localWeatherDataByStation = localWeatherDataDataStream
                // Filter for Non-Null Temperature Values, because we might have missing data:
                .filter(new FilterFunction<LocalWeatherData>() {
                    @Override
                    public boolean filter(LocalWeatherData localWeatherData) throws Exception {
                        return localWeatherData.getTemperature() != null;
                    }
                })
                // Now create the keyed stream by the Station WBAN identifier:
                .keyBy(new KeySelector<LocalWeatherData, String>() {
                    @Override
                    public String getKey(LocalWeatherData localWeatherData) throws Exception {
                        return localWeatherData.getStation();
                    }
                });

        // Now take the Maximum Temperature per day from the KeyedStream:
        DataStream<LocalWeatherData> maxTemperaturePerDay =
                localWeatherDataByStation
                        // Use non-overlapping tumbling window with 1 day length:
                        .timeWindow(Time.days(1))
                        // And use the maximum temperature:
                        .maxBy("temperature");
```
### Warning if high-temp(>= 38) occurs twice within a span of two days<br>
[WeatherDataCEPExample.java](https://github.com/Baiys1234/hdinsight-aks/blob/main/flink/WeatherDataCEPDemo/src/mian/java/contoso/example/CEP/source/WeatherDataCEPExample.java)

A pattern named "high-temp" is defined. This pattern matches LocalWeatherData events where the temperature is greater than or equal to 38.0 degrees Fahrenheit. The pattern must occur twice within a span of two days.

``` java
        // Now take the Maximum Temperature per day from the KeyedStream:
        DataStream<LocalWeatherData> maxTemperaturePerDay =
                localWeatherDataByStation
                        // Use non-overlapping tumbling window with 1 day length:
                        .timeWindow(Time.days(1))
                        // And use the maximum temperature:
                        .maxBy("temperature");
        // Define the pattern
        Pattern<LocalWeatherData, ?> pattern = Pattern.<LocalWeatherData>begin("high-temp")
                .where(new SimpleCondition<LocalWeatherData>() {
                    @Override
                    public boolean filter(LocalWeatherData value) throws Exception {
                        return value.getTemperature() >= 38.0f;
                    }
                })
                .times(2)
                .within(Time.days(2));

        // Apply the pattern to the data stream
        PatternStream<LocalWeatherData> patternStream = CEP.pattern(maxTemperaturePerDay, pattern);

        // Define a select function to handle the matched patterns
        DataStream<String> warnings = patternStream.select(
                new PatternSelectFunction<LocalWeatherData, String>() {
                    @Override
                    public String select(Map<String, List<LocalWeatherData>> pattern) throws Exception {
                        List<LocalWeatherData> highTempEvents = pattern.get("high-temp");
                        return "Warning: " + "WBAN:" + highTempEvents.get(0).getStation() + ":Temperatures exceeded 38 degrees on:" + highTempEvents.get(0).getDate() + " and " + highTempEvents.get(1).getDate() + ".";
                    }
                }
        );
```

**Sink to ADX** <br>

Refer# <br>
https://github.com/Azure/flink-connector-kusto <br>

The Flink kusto connector allows the user to authenticate with AAD using an AAD application,or managed identity based auth.
This blog uses AAD Application Authentication. <br>

``` java
  // Configure Azure Kusto connection options
        String appId = "<client_id>";
        String appKey = "<appkey>";
        String tenantId = "<tenant_id>";
        String clusterUrl = "https://<adxname>.<region>.kusto.windows.net";
        String database = "DB1";
        String tableName = "WeatherTable";

        // Define KustoConnectionOptions
        KustoConnectionOptions kustoConnectionOptions = KustoConnectionOptions.builder()
                .withAppId(appId)
                .withAppKey(appKey)
                .withTenantId(tenantId)
                .withClusterUrl(clusterUrl).build();

        // Define KustoWriteOptions
        KustoWriteOptions kustoWriteOptions = KustoWriteOptions.builder()
                .withDatabase(database)
                .withTable(tableName)
                .withDeliveryGuarantee(DeliveryGuarantee.AT_LEAST_ONCE)
                .build();

        // Sink data to Azure Kusto
        KustoWriteSink.builder().setWriteOptions(kustoWriteOptions)
                .setConnectionOptions(kustoConnectionOptions).build(maxTemperaturePerDay,1);

```

**Sink To Postgres** <br>
``` java
maxTemperaturePerDay.addSink(
                JdbcSink.sink(
                        "INSERT INTO WeatherTable (station, date, temperature, skyCondition, stationPressure, windSpeed) VALUES (?, ?, ?, ?, ?, ?)",
                        (PreparedStatement statement, LocalWeatherData weatherData) -> {
                            statement.setString(1, weatherData.getStation());
                            // Convert the date string to a Timestamp
                            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
                            Date parsedDate = null;
                            try {
                                parsedDate = dateFormat.parse(weatherData.getDate());
                            } catch (ParseException e) {
                                throw new RuntimeException(e);
                            }
                            java.sql.Timestamp timestamp = new java.sql.Timestamp(parsedDate.getTime());

                            statement.setTimestamp(2, timestamp);
                            statement.setString(3, weatherData.getTemperature().toString());
                            statement.setString(4, weatherData.getSkyCondition());
                            statement.setString(5, weatherData.getStationPressure().toString());
                            statement.setString(6, weatherData.getWindSpeed().toString());
                        },
                        new JdbcExecutionOptions.Builder()
                                .withBatchSize(1000)
                                .withBatchIntervalMs(200)
                                .withMaxRetries(5)
                                .build(),
                        new JdbcConnectionOptions.JdbcConnectionOptionsBuilder()
                                .withUrl("jdbc:postgresql://contosopsqlserver.postgres.database.azure.com:5432/postgres")
                                .withDriverName("org.postgresql.Driver")
                                .withUsername("<dbusername>")
                                .withPassword("<password>")
                                .build()
                )
        );
```

## Submit the jar in maven to cluster to run <br>

**Take the Maximum Temperature per day** <br>
```
bin/flink run -c contoso.example.CEP.source.WeatherDSExample -j CEPWeatherDemo-1.0-SNAPSHOT.jar
```

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/12f7f3e9-0860-4fa2-a76d-8d308073deeb)

**Warning if high-temp occurs twice within a span of two days** <br>
```
bin/flink run -c contoso.example.CEP.source.WeatherDataCEPExample -j CEPWeatherDemo-1.0-SNAPSHOT.jar
```

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/ff6c44c2-e3ee-4224-9fd7-8d409b628feb)

## Check job on Flink Dashboard UI

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/16b1c64a-2daf-48f5-9aab-406a26ce709d)

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/0deefa37-00ac-4cfa-bbc4-249735559eec)

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/28548a25-adf5-490c-9558-b4fbc8046f56)

**Result: <br>**
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/4e987892-e29d-4e04-9cf2-08c2db614e28)

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/8df71fe3-5fd2-4700-83bb-778f548ccff7)

![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/b6ae7dd2-52cd-4bca-9648-0fe690ee822a)

## ADX
WeatherTable:Maximum Temperature per day <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/d4a78de0-1dd4-4e1a-948b-1524464a71b0)


## Postgres
WeatherTable:Maximum Temperature per day <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/04c9ae5f-89c0-4437-a9cc-ef2f0cc89356)

Warning when high-temp occurs twice within a span of two days <br>
![image](https://github.com/Baiys1234/hdinsight-aks/assets/35547706/5d876203-949e-4daa-9c36-6e784843b72d)

## Clean up the Resource

• Flink 1.17.0 on HDInsight on AKS <br>
• Azure Data Explorer  <br>
• Azure managed PostgreSQL: 16.0  <br>
• Maven project development on Azure VM in the same Vnet <br>

## References
This blog refers [https://github.com/apache/flink-training/blob/master/README.md](https://github.com/KarstenSchnitter/FlinkExperiments)











