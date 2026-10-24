class DailyForecastModel {
  final String date;
  final double maxTempC;
  final double minTempC;
  final double precipitationSumMm;
  final String weatherCondition;

  DailyForecastModel({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.precipitationSumMm,
    required this.weatherCondition,
  });

  factory DailyForecastModel.fromJson(Map<String, dynamic> json) {
    return DailyForecastModel(
      date: json['date'] ?? '',
      maxTempC: (json['max_temp_c'] as num?)?.toDouble() ?? 30.0,
      minTempC: (json['min_temp_c'] as num?)?.toDouble() ?? 20.0,
      precipitationSumMm: (json['precipitation_sum_mm'] as num?)?.toDouble() ?? 0.0,
      weatherCondition: json['weather_condition'] ?? 'Clear',
    );
  }
}

class WeatherModel {
  final double latitude;
  final double longitude;
  final double temperatureC;
  final double relativeHumidityPct;
  final double precipitationMm;
  final double windSpeedKmh;
  final String weatherCondition;
  final bool isDay;
  final double annualRainfallMm;
  final String source;
  final String retrievedAt;

  WeatherModel({
    required this.latitude,
    required this.longitude,
    required this.temperatureC,
    required this.relativeHumidityPct,
    required this.precipitationMm,
    required this.windSpeedKmh,
    required this.weatherCondition,
    required this.isDay,
    required this.forecast,
    required this.annualRainfallMm,
    required this.source,
    required this.retrievedAt,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final rawForecast = json['forecast'] as List<dynamic>? ?? [];
    return WeatherModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      temperatureC: (json['temperature_c'] as num?)?.toDouble() ?? 25.0,
      relativeHumidityPct: (json['relative_humidity_pct'] as num?)?.toDouble() ?? 60.0,
      precipitationMm: (json['precipitation_mm'] as num?)?.toDouble() ?? 0.0,
      windSpeedKmh: (json['wind_speed_kmh'] as num?)?.toDouble() ?? 10.0,
      weatherCondition: json['weather_condition'] ?? 'Clear',
      isDay: json['is_day'] ?? true,
      forecast: rawForecast.map((e) => DailyForecastModel.fromJson(e)).toList(),
      annualRainfallMm: (json['annual_rainfall_mm'] as num?)?.toDouble() ?? 950.0,
      source: json['source'] ?? '',
      retrievedAt: json['retrieved_at'] ?? '',
    );
  }
}

