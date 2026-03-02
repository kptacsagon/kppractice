class WeatherData {
  final String day;
  final int highTemp;
  final int lowTemp;
  final String condition;
  final String icon;
  final int humidity;
  final double windSpeed;
  final int uvIndex;
  final int rainfall;
  final DateTime date;

  WeatherData({
    required this.day,
    required this.highTemp,
    required this.lowTemp,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.rainfall,
    required this.date,
  });
}

class WeeklyWeather {
  final String location;
  final String region;
  final List<WeatherData> forecasts;
  final WeatherData currentWeather;

  WeeklyWeather({
    required this.location,
    required this.region,
    required this.forecasts,
    required this.currentWeather,
  });
}
