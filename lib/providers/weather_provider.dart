import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';

class FarmLocation {
  final String name;
  final double latitude;
  final double longitude;

  const FarmLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class WeatherProvider with ChangeNotifier {
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Default farm location
  FarmLocation _currentLocation = const FarmLocation(
    name: 'Green Valley Farm, Karnataka',
    latitude: 12.9716,
    longitude: 77.5946,
  );

  static const List<FarmLocation> presetLocations = [
    FarmLocation(name: 'Green Valley Farm (Bangalore)', latitude: 12.9716, longitude: 77.5946),
    FarmLocation(name: 'Mandya Paddy Fields', latitude: 12.5218, longitude: 76.8951),
    FarmLocation(name: 'Mysuru Agriculture Belt', latitude: 12.2958, longitude: 76.6394),
    FarmLocation(name: 'Hassan Farm Region', latitude: 13.0033, longitude: 76.1004),
    FarmLocation(name: 'Davanagere Cotton Belt', latitude: 14.4644, longitude: 75.9218),
    FarmLocation(name: 'Belagavi Sugarcane Fields', latitude: 15.8497, longitude: 74.4977),
    FarmLocation(name: 'Raichur Grain Belt', latitude: 16.2076, longitude: 77.3463),
  ];

  WeatherData? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  FarmLocation get currentLocation => _currentLocation;

  WeatherProvider() {
    _loadCachedWeatherAndFetch();
  }

  Future<void> _loadCachedWeatherAndFetch() async {
    await _loadCachedWeather();
    await fetchWeather();
  }

  Future<void> _loadCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocName = prefs.getString('weather_location_name');
      final savedLat = prefs.getDouble('weather_location_lat');
      final savedLng = prefs.getDouble('weather_location_lng');

      if (savedLocName != null && savedLat != null && savedLng != null) {
        _currentLocation = FarmLocation(
          name: savedLocName,
          latitude: savedLat,
          longitude: savedLng,
        );
      }

      final String? cachedJson = prefs.getString('cached_weather_data');
      if (cachedJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);
        _weatherData = WeatherData.fromMap(decoded).copyWith(isCached: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[WEATHER] Error loading cache: $e');
    }
  }

  Future<void> _saveWeatherToCache(WeatherData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_weather_data', jsonEncode(data.toMap()));
      await prefs.setString('weather_location_name', _currentLocation.name);
      await prefs.setDouble('weather_location_lat', _currentLocation.latitude);
      await prefs.setDouble('weather_location_lng', _currentLocation.longitude);
    } catch (e) {
      debugPrint('[WEATHER] Error saving cache: $e');
    }
  }

  Future<void> setLocation(FarmLocation location) async {
    _currentLocation = location;
    notifyListeners();
    await fetchWeather(forceRefresh: true);
  }

  Future<List<FarmLocation>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?'
        'name=$encodedQuery&count=10&language=en&format=json',
      );

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;

        if (json.containsKey('results') && json['results'] != null) {
          final List<dynamic> results = json['results'];
          return results.map((item) {
            final String name = item['name'] ?? 'Unknown';
            final String? admin1 = item['admin1'];
            final String? country = item['country'];
            final double lat = (item['latitude'] as num).toDouble();
            final double lng = (item['longitude'] as num).toDouble();

            final String fullName = admin1 != null
                ? '$name, $admin1 (${country ?? ""})'
                : '$name, ${country ?? ""}';

            return FarmLocation(
              name: fullName,
              latitude: lat,
              longitude: lng,
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('[WEATHER] Geocoding search error: $e');
    }
    return [];
  }

  Future<void> fetchWeather({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?'
        'latitude=${_currentLocation.latitude}&'
        'longitude=${_currentLocation.longitude}&'
        'current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation&'
        'daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum&'
        'timezone=auto',
      );

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;

        final current = json['current'] as Map<String, dynamic>;
        final daily = json['daily'] as Map<String, dynamic>;

        final double temp = (current['temperature_2m'] as num).toDouble();
        final int code = (current['weather_code'] as num).toInt();
        final int humidity = (current['relative_humidity_2m'] as num).toInt();
        final double wind = (current['wind_speed_10m'] as num).toDouble();
        final double precip = (current['precipitation'] as num).toDouble();

        final List<dynamic> dates = daily['time'];
        final List<dynamic> dailyCodes = daily['weather_code'];
        final List<dynamic> maxTemps = daily['temperature_2m_max'];
        final List<dynamic> minTemps = daily['temperature_2m_min'];
        final List<dynamic> dailyPrecip = daily['precipitation_sum'];

        final List<DailyForecast> forecasts = [];
        for (int i = 0; i < dates.length; i++) {
          final int dCode = (dailyCodes[i] as num).toInt();
          forecasts.add(
            DailyForecast(
              date: DateTime.parse(dates[i].toString()),
              weatherCode: dCode,
              condition: WeatherData.getWeatherDescription(dCode),
              maxTemp: (maxTemps[i] as num).toDouble(),
              minTemp: (minTemps[i] as num).toDouble(),
              precipitation: (dailyPrecip[i] as num).toDouble(),
            ),
          );
        }

        final liveData = WeatherData(
          temperature: temp,
          weatherCode: code,
          condition: WeatherData.getWeatherDescription(code),
          humidity: humidity,
          windSpeed: wind,
          precipitation: precip,
          locationName: _currentLocation.name,
          latitude: _currentLocation.latitude,
          longitude: _currentLocation.longitude,
          lastUpdated: DateTime.now(),
          isCached: false,
          dailyForecast: forecasts,
        );

        _weatherData = liveData;
        _errorMessage = null;
        await _saveWeatherToCache(liveData);
      } else {
        _handleFetchError('Server error (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('[WEATHER] Network/API Error: $e');
      _handleFetchError('Unable to connect to weather service');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleFetchError(String message) {
    if (_weatherData != null) {
      // Keep cached weather data but flag error message for banner
      _weatherData = _weatherData!.copyWith(isCached: true);
      _errorMessage = '$message. Showing cached data.';
    } else {
      _errorMessage = message;
    }
  }
}
