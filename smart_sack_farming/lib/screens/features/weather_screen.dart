import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../theme/app_theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late WeeklyWeather _weatherData;

  @override
  void initState() {
    super.initState();
    _initializeWeatherData();
  }

  void _initializeWeatherData() {
    // Sample weather data for the week
    final currentDate = DateTime.now();
    
    _weatherData = WeeklyWeather(
      location: 'Tubungan',
      region: 'Iloilo, Philippines',
      currentWeather: WeatherData(
        day: 'Today',
        highTemp: 32,
        lowTemp: 24,
        condition: 'Partly Cloudy',
        icon: '⛅',
        humidity: 65,
        windSpeed: 12.5,
        uvIndex: 8,
        rainfall: 0,
        date: currentDate,
      ),
      forecasts: [
        WeatherData(
          day: 'Thursday',
          highTemp: 32,
          lowTemp: 24,
          condition: 'Partly Cloudy',
          icon: '⛅',
          humidity: 65,
          windSpeed: 12.5,
          uvIndex: 8,
          rainfall: 0,
          date: currentDate,
        ),
        WeatherData(
          day: 'Friday',
          highTemp: 30,
          lowTemp: 22,
          condition: 'Rainy',
          icon: '🌧️',
          humidity: 80,
          windSpeed: 18.0,
          uvIndex: 4,
          rainfall: 15,
          date: currentDate.add(const Duration(days: 1)),
        ),
        WeatherData(
          day: 'Saturday',
          highTemp: 28,
          lowTemp: 20,
          condition: 'Heavy Rain',
          icon: '⛈️',
          humidity: 85,
          windSpeed: 25.0,
          uvIndex: 2,
          rainfall: 45,
          date: currentDate.add(const Duration(days: 2)),
        ),
        WeatherData(
          day: 'Sunday',
          highTemp: 29,
          lowTemp: 21,
          condition: 'Cloudy',
          icon: '☁️',
          humidity: 75,
          windSpeed: 15.0,
          uvIndex: 5,
          rainfall: 5,
          date: currentDate.add(const Duration(days: 3)),
        ),
        WeatherData(
          day: 'Monday',
          highTemp: 31,
          lowTemp: 23,
          condition: 'Sunny',
          icon: '☀️',
          humidity: 60,
          windSpeed: 10.0,
          uvIndex: 9,
          rainfall: 0,
          date: currentDate.add(const Duration(days: 4)),
        ),
        WeatherData(
          day: 'Tuesday',
          highTemp: 33,
          lowTemp: 25,
          condition: 'Sunny',
          icon: '☀️',
          humidity: 55,
          windSpeed: 8.0,
          uvIndex: 10,
          rainfall: 0,
          date: currentDate.add(const Duration(days: 5)),
        ),
        WeatherData(
          day: 'Wednesday',
          highTemp: 32,
          lowTemp: 24,
          condition: 'Partly Cloudy',
          icon: '⛅',
          humidity: 62,
          windSpeed: 11.0,
          uvIndex: 8,
          rainfall: 2,
          date: currentDate.add(const Duration(days: 6)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Weather Forecast',
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textMedium),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _weatherData.location,
                            style: const TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _weatherData.region,
                            style: const TextStyle(
                              color: AppTheme.textMedium,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Current weather
            Text(
              'Today\'s Weather',
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildCurrentWeatherCard(_weatherData.currentWeather),
            const SizedBox(height: 24),
            // 7-day forecast
            Text(
              '7-Day Forecast',
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _weatherData.forecasts.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWeatherCard(_weatherData.forecasts[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard(WeatherData weather) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.highTemp}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'High: ${weather.highTemp}° / Low: ${weather.lowTemp}°',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                weather.icon,
                style: const TextStyle(fontSize: 64),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            weather.condition,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Weather details grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeatherDetail('💧', 'Humidity', '${weather.humidity}%'),
              _buildWeatherDetail('💨', 'Wind', '${weather.windSpeed} km/h'),
              _buildWeatherDetail('☀️', 'UV Index', '${weather.uvIndex}'),
              _buildWeatherDetail('🌧️', 'Rainfall', '${weather.rainfall}mm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(WeatherData weather) {
    final Color conditionColor = _getConditionColor(weather.condition);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Day and icon
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weather.day,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${weather.date.day}/${weather.date.month}',
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Weather icon
          Text(
            weather.icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          // Temperature and condition
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${weather.highTemp}°',
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${weather.lowTemp}°',
                      style: const TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  weather.condition,
                  style: const TextStyle(
                    color: AppTheme.textMedium,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Rainfall indicator
          if (weather.rainfall > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  const Text(
                    '🌧️',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${weather.rainfall}mm',
                    style: const TextStyle(
                      color: const Color(0xFF2196F3),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String icon, String label, String value) {
    return Flexible(
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(String condition) {
    if (condition.contains('Rain') || condition.contains('rain')) {
      return Colors.blue;
    } else if (condition.contains('Sunny') || condition.contains('sunny')) {
      return Colors.orange;
    } else if (condition.contains('Cloud') || condition.contains('cloud')) {
      return Colors.grey;
    } else if (condition.contains('Storm') || condition.contains('storm')) {
      return Colors.purple;
    }
    return AppTheme.primary;
  }
}
