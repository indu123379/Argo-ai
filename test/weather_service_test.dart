import 'package:flutter_test/flutter_test.dart';
import 'package:crop_disease_app/services/weather_service.dart';

void main() {
  group('WeatherSnapshot', () {
    test('parses weather values from a valid payload', () {
      final snapshot = WeatherSnapshot.fromJson({
        'name': 'Delhi',
        'main': {'temp': 31, 'feels_like': 33, 'humidity': 60},
        'weather': [{'description': 'clear sky', 'icon': '01d'}],
        'wind': {'speed': 3.2},
      }, fallbackCity: 'Delhi');

      expect(snapshot.city, 'Delhi');
      expect(snapshot.temperature, '31°C');
      expect(snapshot.humidity, 'Humidity 60%');
      expect(snapshot.isDemo, isFalse);
    });

    test('builds a demo snapshot when data is unavailable', () {
      final snapshot = WeatherSnapshot.demo(city: 'Delhi', reason: 'offline');
      expect(snapshot.city, 'Delhi');
      expect(snapshot.isDemo, isTrue);
      expect(snapshot.message, 'offline');
    });
  });
}
