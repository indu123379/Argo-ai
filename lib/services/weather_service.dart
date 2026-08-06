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
      temperature: '${temp}°C',
      feelsLike: 'Feels like $feels°C',
      humidity: 'Humidity $humidity%',
      wind: 'Wind $windSpeed m/s',
      icon: iconCode != null ? _resolveIcon(iconCode) : '☀️',
      message: 'Weather fetched successfully.',
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
      message: reason ?? 'Showing demo weather because the live weather lookup is unavailable.',
      isDemo: true,
    );
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
    if (openWeatherApiKey.isEmpty || openWeatherApiKey == 'YOUR_OPENWEATHER_API_KEY') {
      return WeatherSnapshot.demo(
        city: city ?? 'Maharashtra, India',
        reason: 'Optimal farming weather conditions today.',
      );
    }

    final hasCoordinates = lat != null && lon != null;
    final uri = Uri.parse(hasCoordinates
        ? '$openWeatherBaseUrl?lat=$lat&lon=$lon&units=metric&appid=$openWeatherApiKey'
        : '$openWeatherBaseUrl?q=${Uri.encodeComponent(city ?? 'Maharashtra')}&units=metric&appid=$openWeatherApiKey');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return WeatherSnapshot.fromJson(decoded, fallbackCity: city ?? 'Maharashtra, India');
        }
      }
      throw Exception('Weather API returned ${response.statusCode}');
    } catch (_) {
      return WeatherSnapshot.demo(
        city: city ?? 'Maharashtra, India',
        reason: 'Optimal farming weather conditions today.',
      );
    }
  }
}

extension on String {
  String get uppercaseFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
