This blog refers https://github.com/apache/flink-training/blob/master/README.md

**This example uses DStreamAPI to create a simple sink that assigns kafka topic click event message to ADLSgen2.**

## Purpose of this test

## Set up testing environment

## Use the taxi Data Streams

**Schema of taxi ride events** <br>
Our taxi data set contains information about individual taxi rides in New York City.
Each ride is represented by two events: a trip start, and a trip end.
Each event consists of ten fields:

```
rideId         : Long      // a unique id for each ride
taxiId         : Long      // a unique id for each taxi
driverId       : Long      // a unique id for each driver
isStart        : Boolean   // TRUE for ride start events, FALSE for ride end events
eventTime      : Instant   // the timestamp for this event
startLon       : Float     // the longitude of the ride start location
startLat       : Float     // the latitude of the ride start location
endLon         : Float     // the longitude of the ride end location
endLat         : Float     // the latitude of the ride end location
passengerCnt   : Short     // number of passengers on the ride
```

**Schema of taxi fare events** <br>
There is also a related data set containing fare data about those same rides, with the following fields:
```
rideId         : Long      // a unique id for each ride
taxiId         : Long      // a unique id for each taxi
driverId       : Long      // a unique id for each driver
startTime      : Instant   // the start time for this ride
paymentType    : String    // CASH or CARD
tip            : Float     // tip for this ride
tolls          : Float     // tolls for this ride
totalFare      : Float     // total fare collected
```

## Testing tasks

**1. Filtering a Stream (Ride Cleansing)**
The task is to cleanse a stream of TaxiRide events by removing events that start or end outside of New York City.

The GeoUtils utility class provides a static method isInNYC(float lon, float lat) to check if a location is within the NYC area.

Input Data <br>
It is based on a stream of TaxiRide events, as described above in Using the Taxi ride Data Streams.

Code in [GeoUtils.java](https://github.com/Baiys1234/hdinsight-aks/blob/main/flink/MergeTwoDataStreams(Rides%20and%20Fares)/src/main/java/contoso/example/utils/GeoUtils.java) <br>
``` java
    /**
     * Checks if a location specified by longitude and latitude values is within the geo boundaries
     * of New York City.
     *
     * @param lon longitude of the location to check
     * @param lat latitude of the location to check
     * @return true if the location is within NYC boundaries, otherwise false.
     */
    public static boolean isInNYC(float lon, float lat) {

        return !(lon > LON_EAST || lon < LON_WEST) && !(lat > LAT_NORTH || lat < LAT_SOUTH);
    }
```

**1. Filtering a Stream (Ride Cleansing)**
**1. Filtering a Stream (Ride Cleansing)**
**1. Filtering a Stream (Ride Cleansing)**

## Clean up resouces

The goal of this exercise is to join together the TaxiRide and TaxiFare records for each ride.

For each distinct rideId, there are exactly three events:

a TaxiRide START event
a TaxiRide END event
a TaxiFare event (whose timestamp happens to match the start time)
