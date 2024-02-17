package contoso.example.CEP.generator;

import com.fasterxml.jackson.annotation.JsonPropertyOrder;

@JsonPropertyOrder({"station","date","temperature","skyCondition","stationPressure","windSpeed"})
public class LocalWeatherData {
    public String station;
    public String date;
    public Integer temperature;
    public String skyCondition;
    public Float stationPressure;
    public Integer windSpeed;

    public LocalWeatherData() {
    }

    public LocalWeatherData(String station, String date, Integer temperature, String skyCondition, Float stationPressure, Integer windSpeed) {
        this.station = station;
        this.date = date;
        this.temperature = temperature;
        this.skyCondition = skyCondition;
        this.stationPressure = stationPressure;
        this.windSpeed = windSpeed;
    }

    // getters and setters...

    public String getStation() {
        return station;
    }

    public void setStation(String station) {
        this.station = station;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public Integer getTemperature() {
        return temperature;
    }

    public void setTemperature(Integer temperature) {
        this.temperature = temperature;
    }

    public String getSkyCondition() {
        return skyCondition;
    }

    public void setSkyCondition(String skyCondition) {
        this.skyCondition = skyCondition;
    }

    public Float getStationPressure() {
        return stationPressure;
    }

    public void setStationPressure(Float stationPressure) {
        this.stationPressure = stationPressure;
    }

    public Integer getWindSpeed() {
        return windSpeed;
    }

    public void setWindSpeed(Integer windSpeed) {
        this.windSpeed = windSpeed;
    }

    public String toString() {
        return "LocalWeatherData{" +
                "station='" + station + '\'' +
                ", date='" + date + '\'' +
                ", temperature=" + temperature +
                ", skyCondition='" + skyCondition + '\'' +
                ", stationPressure=" + stationPressure +
                ", windSpeed=" + windSpeed +
                '}';
    }
}


