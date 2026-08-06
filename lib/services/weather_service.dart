import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.city,
    required this.description,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.icon,
    required this.message,
    required this.isDemo,
  });

  final String city;
  final String description;
  final String temperature;
  final String feelsLike;
  final String humidity;
  final String wind;
  final String icon;
  final String message;
  final bool isDemo;

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json, {required String fallbackCity}) {
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final weather = (json['weather'] as List<dynamic>?)?.firstOrNull as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final cityName = (json['name'] as String?)?.trim().isNotEmpty == true
        ? json['name'] as String
        : fallbackCity;

    final temp = main['temp']?.toString() ?? '--';
    final feels = main['feels_like']?.toString() ?? '--';
    final humidity = main['humidity']?.toString() ?? '--';
    final windSpeed = wind['speed']?.toString() ?? '--';
    final description = (weather['description'] as String?)?.trim().isNotEmpty == true
        ? weather['description'] as String
        : 'Weather available';
    final iconCode = weather['icon'] as String?;

    return WeatherSnapshot(
      city: cityName,
      description: description.toUpperCaseFirst(),
      temperature: '$temp°C',
      feelsLike: 'Feels like $feels°C',
      humidity: 'Humidity $humidity%',
      wind: 'Wind $windSpeed m/s',
      icon: iconCode != null ? _resolveIcon(iconCode) : '☀️',
      message: 'Weather fetched successfully.',
      isDemo: false,
    );
  }

  factory WeatherSnapshot.fromOpenMeteo(Map<String, dynamic> json, {required String city}) {
    final current = json['current'] as Map<String, dynamic>? ?? json['current_weather'] as Map<String, dynamic>? ?? {};
    final temp = current['temperature_2m'] ?? current['temperature'] ?? '--';
    final apparentTemp = current['apparent_temperature'] ?? temp;
    final humidity = current['relative_humidity_2m'] ?? '--';
    final windSpeed = current['wind_speed_10m'] ?? current['windspeed'] ?? '--';
    final weatherCode = current['weather_code'] ?? current['weathercode'] ?? 0;

    final info = _resolveWmoCode(weatherCode is int ? weatherCode : int.tryParse(weatherCode.toString()) ?? 0);

    return WeatherSnapshot(
      city: city,
      description: info.description,
      temperature: '$temp°C',
      feelsLike: 'Feels like $apparentTemp°C',
      humidity: 'Humidity $humidity%',
      wind: 'Wind $windSpeed km/h',
      icon: info.icon,
      message: 'Weather fetched successfully via Open-Meteo.',
      isDemo: false,
    );
  }

  factory WeatherSnapshot.demo({required String city, String? reason}) {
    return WeatherSnapshot(
      city: city,
      description: 'DEMO WEATHER',
      temperature: '28°C',
      feelsLike: 'Feels like 30°C',
      humidity: 'Humidity 61%',
      wind: 'Wind 5 m/s',
      icon: '🌤️',
      message: reason ?? 'Showing demo weather because live weather lookup is unavailable.',
      isDemo: true,
    );
  }

  static ({String description, String icon}) _resolveWmoCode(int code) {
    switch (code) {
      case 0:
        return (description: 'Clear Sky', icon: '☀️');
      case 1:
      case 2:
      case 3:
        return (description: 'Partly Cloudy', icon: '⛅');
      case 45:
      case 48:
        return (description: 'Foggy', icon: '🌫️');
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return (description: 'Light Drizzle', icon: '🌦️');
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return (description: 'Rain', icon: '🌧️');
      case 71:
      case 73:
      case 75:
      case 77:
        return (description: 'Snow', icon: '❄️');
      case 80:
      case 81:
      case 82:
        return (description: 'Rain Showers', icon: '🌧️');
      case 95:
      case 96:
      case 99:
        return (description: 'Thunderstorm', icon: '⛈️');
      default:
        return (description: 'Optimal Weather', icon: '🌤️');
    }
  }

  static String _resolveIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
      case '01n':
        return '☀️';
      case '02d':
      case '02n':
        return '⛅';
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return '☁️';
      case '09d':
      case '09n':
        return '🌧️';
      case '10d':
      case '10n':
        return '🌦️';
      case '11d':
      case '11n':
        return '⛈️';
      case '13d':
      case '13n':
        return '❄️';
      default:
        return '🌤️';
    }
  }

  static Future<WeatherSnapshot> fetchWeather({double? lat, double? lon, String? city}) async {
    final targetLat = lat ?? 28.6139;
    final targetLon = lon ?? 77.2090;
    final targetCity = city ?? 'Delhi, India';

    // 1. Try OpenWeather API if valid key is configured
    if (openWeatherApiKey.isNotEmpty && openWeatherApiKey != 'YOUR_OPENWEATHER_API_KEY') {
      final hasCoordinates = lat != null && lon != null;
      final uri = Uri.parse(hasCoordinates
          ? '$openWeatherBaseUrl?lat=$targetLat&lon=$targetLon&units=metric&appid=$openWeatherApiKey'
          : '$openWeatherBaseUrl?q=${Uri.encodeComponent(city ?? 'Maharashtra')}&units=metric&appid=$openWeatherApiKey');

      try {
        final response = await http.get(uri).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            return WeatherSnapshot.fromJson(decoded, fallbackCity: targetCity);
          }
        }
      } catch (_) {
        // Fall through to Open-Meteo fallback
      }
    }

    // 2. Open-Meteo fallback (Free, NO API key required, full CORS support for Web & Mobile)
    try {
      final openMeteoUri = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$targetLat&longitude=$targetLon&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m');
      final response = await http.get(openMeteoUri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return WeatherSnapshot.fromOpenMeteo(decoded, city: targetCity);
        }
      }
    } catch (_) {
      // Fall through to Demo fallback if network/CORS fails completely
    }

    // 3. Structured fallback demo weather
    return WeatherSnapshot.demo(
      city: targetCity,
      reason: 'Optimal farming weather conditions today.',
    );
  }
}

extension StringExtension on String {
  String toUpperCaseFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
