import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/weather_service.dart';
import '../utils/app_theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  WeatherSnapshot? _snapshot;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Set initial fallback snapshot so screen renders immediately on Web & Mobile
    _snapshot = WeatherSnapshot.demo(
      city: 'Maharashtra, India',
      reason: 'Loading current weather...',
    );
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    double? lat;
    double? lon;
    String city = 'Maharashtra, India';

    try {
      // 1. Try fetching farmer's location from Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 2));
        if (doc.exists) {
          final data = doc.data();
          final userLoc = data?['location'] as String?;
          if (userLoc != null && userLoc.trim().isNotEmpty) {
            city = userLoc.trim();
          }
        }
      }
    } catch (_) {
      // Ignore Firestore timeout/error
    }

    try {
      // 2. Try fetching live device/browser geolocation safely
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(const Duration(seconds: 1), onTimeout: () => false);
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission().timeout(const Duration(seconds: 1), onTimeout: () => LocationPermission.denied);
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission().timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 2),
            ),
          ).timeout(const Duration(seconds: 2));
          lat = position.latitude;
          lon = position.longitude;
        }
      }
    } catch (_) {
      // Geolocation unavailable or timed out, proceed with city fallback
    }

    try {
      final snapshot = await WeatherSnapshot.fetchWeather(lat: lat, lon: lon, city: city);
      if (mounted) {
        setState(() {
          _snapshot = snapshot;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _snapshot = WeatherSnapshot.demo(city: city);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        title: const Text('Weather'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadWeather,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh weather',
          ),
        ],
      ),
      body: _isLoading && snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWeather,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  snapshot?.icon ?? '☀️',
                                  style: const TextStyle(fontSize: 42),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        snapshot?.city ?? 'Maharashtra',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        snapshot?.description ?? 'Weather available',
                                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              snapshot?.temperature ?? '28°C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot?.feelsLike ?? 'Feels like 30°C',
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            if (snapshot?.isDemo == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  snapshot?.message ?? 'Showing fallback weather.',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _InfoTile(label: 'Humidity', value: snapshot?.humidity ?? 'Humidity 61%'),
                      const SizedBox(height: 12),
                      _InfoTile(label: 'Wind', value: snapshot?.wind ?? 'Wind 5 km/h'),
                      const SizedBox(height: 12),
                      _InfoTile(label: 'Status', value: snapshot?.message ?? 'Weather fetched successfully.'),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
