import 'package:flutter/material.dart';

class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final String condition;
  final double maxTemp;
  final double minTemp;
  final double precipitation;

  DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.condition,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitation,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'weatherCode': weatherCode,
      'condition': condition,
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'precipitation': precipitation,
    };
  }

  factory DailyForecast.fromMap(Map<String, dynamic> map) {
    return DailyForecast(
      date: DateTime.parse(map['date']),
      weatherCode: map['weatherCode'] ?? 0,
      condition: map['condition'] ?? 'Clear',
      maxTemp: (map['maxTemp'] as num).toDouble(),
      minTemp: (map['minTemp'] as num).toDouble(),
      precipitation: (map['precipitation'] as num).toDouble(),
    );
  }
}

class WeatherData {
  final double temperature;
  final int weatherCode;
  final String condition;
  final int humidity;
  final double windSpeed;
  final double precipitation;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;
  final bool isCached;
  final List<DailyForecast> dailyForecast;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
    this.isCached = false,
    required this.dailyForecast,
  });

  WeatherData copyWith({
    double? temperature,
    int? weatherCode,
    String? condition,
    int? humidity,
    double? windSpeed,
    double? precipitation,
    String? locationName,
    double? latitude,
    double? longitude,
    DateTime? lastUpdated,
    bool? isCached,
    List<DailyForecast>? dailyForecast,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      weatherCode: weatherCode ?? this.weatherCode,
      condition: condition ?? this.condition,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      precipitation: precipitation ?? this.precipitation,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCached: isCached ?? this.isCached,
      dailyForecast: dailyForecast ?? this.dailyForecast,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'weatherCode': weatherCode,
      'condition': condition,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'precipitation': precipitation,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isCached': isCached,
      'dailyForecast': dailyForecast.map((f) => f.toMap()).toList(),
    };
  }

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      temperature: (map['temperature'] as num).toDouble(),
      weatherCode: map['weatherCode'] ?? 0,
      condition: map['condition'] ?? 'Clear',
      humidity: (map['humidity'] as num).toInt(),
      windSpeed: (map['windSpeed'] as num).toDouble(),
      precipitation: (map['precipitation'] as num).toDouble(),
      locationName: map['locationName'] ?? 'Farm Location',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      lastUpdated: DateTime.parse(map['lastUpdated']),
      isCached: map['isCached'] ?? false,
      dailyForecast: (map['dailyForecast'] as List<dynamic>?)
              ?.map((f) => DailyForecast.fromMap(f))
              .toList() ??
          [],
    );
  }

  static String getWeatherDescription(int code) {
    if (code == 0) return 'Clear Sky';
    if (code == 1) return 'Mainly Clear';
    if (code == 2) return 'Partly Cloudy';
    if (code == 3) return 'Overcast';
    if (code == 45 || code == 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rain Showers';
    if (code >= 71 && code <= 77) return 'Snow Showers';
    if (code >= 80 && code <= 82) return 'Heavy Rain';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Partly Cloudy';
  }

  static IconData getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code == 1 || code == 2) return Icons.wb_cloudy;
    if (code == 3) return Icons.cloud;
    if (code == 45 || code == 48) return Icons.cloud_queue;
    if (code >= 51 && code <= 65) return Icons.umbrella;
    if (code >= 80 && code <= 82) return Icons.grain;
    if (code >= 95 && code <= 99) return Icons.flash_on;
    return Icons.wb_sunny;
  }
}
