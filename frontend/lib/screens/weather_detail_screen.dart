import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/weather_model.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../widgets/custom_cards.dart';

class WeatherDetailScreen extends StatelessWidget {
  const WeatherDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farmProvider = context.watch<FarmProvider>();
    final workflow = context.watch<FarmingWorkflowProvider>();
    final farm = farmProvider.activeFarm;
    final weather = workflow.weather;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Comprehensive Agro-Weather"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to Dashboard",
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Weather",
            onPressed: () {
              if (farm != null) {
                workflow.fetchWeather(farm.latitude, farm.longitude);
              }
            },
          ),
        ],
      ),
      body: weather == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () async {
                if (farm != null) {
                  await workflow.fetchWeather(farm.latitude, farm.longitude);
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Hero Weather Card
                    _buildHeroWeatherCard(context, farm, weather),

                    // Key Agricultural Climate Indicators Grid
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: "Agro-Climatic Parameters",
                            subtitle: "Real-time measurements impacting crops and soil",
                          ),
                          const SizedBox(height: 12),
                          _buildClimateGrid(weather),
                          const SizedBox(height: 24),

                          // 7-Day Future Forecast Section
                          const SectionHeader(
                            title: "7-Day Weather & Rainfall Forecast",
                            subtitle: "Precipitation sum and temperature trends from Open-Meteo & IMD",
                          ),
                          const SizedBox(height: 12),
                          ...weather.forecast.map((df) => _buildForecastDayCard(df)),

                          const SizedBox(height: 24),
                          // Smart Farming Advisories based on Forecast
                          const SectionHeader(
                            title: "Agronomic Field Advisories",
                            subtitle: "Actionable recommendations triggered by incoming weather",
                          ),
                          const SizedBox(height: 12),
                          _buildAgronomicAdvisories(weather),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroWeatherCard(BuildContext context, dynamic farm, WeatherModel weather) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm?.farmName ?? "Farm Location",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Lat: ${weather.latitude.toStringAsFixed(2)}°, Lon: ${weather.longitude.toStringAsFixed(2)}°",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      weather.isDay ? Icons.wb_sunny : Icons.nightlight_round,
                      color: Colors.amberAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      weather.isDay ? "Daytime" : "Nighttime",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather.temperatureC.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    "°C",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(_getWeatherIcon(weather.weatherCondition), size: 38, color: Colors.white),
                  const SizedBox(height: 6),
                  Text(
                    weather.weatherCondition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeroSubMetric("Humidity", "${weather.relativeHumidityPct.toStringAsFixed(0)}%", Icons.water_drop_outlined),
              _buildHeroSubMetric("Rain Today", "${weather.precipitationMm.toStringAsFixed(1)} mm", Icons.grain),
              _buildHeroSubMetric("Wind", "${weather.windSpeedKmh.toStringAsFixed(0)} km/h", Icons.air),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSubMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildClimateGrid(WeatherModel weather) {
    final rainStatus = weather.precipitationMm > 5.0
        ? "Heavy Rain"
        : (weather.precipitationMm > 0.0 ? "Light Rain" : "No Rain");

    final humidityStatus = weather.relativeHumidityPct > 80
        ? "Very High"
        : (weather.relativeHumidityPct > 50 ? "Optimal" : "Dry Air");

    final windStatus = weather.windSpeedKmh > 25
        ? "Breezy"
        : (weather.windSpeedKmh > 10 ? "Moderate" : "Calm");

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetricTile("Precipitation", "${weather.precipitationMm.toStringAsFixed(1)} mm", rainStatus, Icons.grain, const Color(0xFF0077B6)),
        _buildMetricTile("Relative Humidity", "${weather.relativeHumidityPct.toStringAsFixed(0)}%", humidityStatus, Icons.water_drop, const Color(0xFF2A9D8F)),
        _buildMetricTile("Wind Speed", "${weather.windSpeedKmh.toStringAsFixed(0)} km/h", windStatus, Icons.air, const Color(0xFFE76F51)),
        _buildMetricTile("Temperature", "${weather.temperatureC.toStringAsFixed(1)}°C", "Current Ambient", Icons.thermostat, const Color(0xFFF4A261)),
      ],
    );
  }

  Widget _buildMetricTile(String title, String value, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastDayCard(DailyForecastModel df) {
    final rainProb = df.precipitationSumMm > 10.0
        ? "Heavy Rainfall"
        : (df.precipitationSumMm > 1.0 ? "Showers Expected" : "Dry / Clear");

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.sageLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getWeatherIcon(df.weatherCondition), color: AppTheme.emerald, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  df.date,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  "${df.weatherCondition} • $rainProb",
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${df.maxTempC.toStringAsFixed(0)}° / ${df.minTempC.toStringAsFixed(0)}°C",
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textDark),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grain, size: 12, color: Color(0xFF0077B6)),
                  const SizedBox(width: 2),
                  Text(
                    "${df.precipitationSumMm.toStringAsFixed(1)} mm",
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0077B6), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgronomicAdvisories(WeatherModel weather) {
    final totalForecastRain = weather.forecast.fold<double>(
      0.0,
      (sum, item) => sum + item.precipitationSumMm,
    );

    return Column(
      children: [
        _buildAdvisoryTile(
          title: "Irrigation Scheduling",
          desc: totalForecastRain > 15.0
              ? "Substantial rainfall (~${totalForecastRain.toStringAsFixed(1)} mm) projected over 7 days. Defer surface & drip irrigation to prevent waterlogging and nitrogen leaching."
              : "Low precipitation anticipated (~${totalForecastRain.toStringAsFixed(1)} mm). Maintain standard field moisture according to crop growth stage.",
          icon: Icons.water,
          color: totalForecastRain > 15.0 ? const Color(0xFF0077B6) : AppTheme.emerald,
        ),
        const SizedBox(height: 10),
        _buildAdvisoryTile(
          title: "Pesticide & Fertilizer Spray Window",
          desc: weather.windSpeedKmh > 20
              ? "Wind speeds exceeding 20 km/h will cause droplet drift. Postpone chemical foliar spraying until calmer morning or evening hours."
              : (weather.precipitationMm > 0.5
                  ? "Recent precipitation active. Allow leaves to dry before fungicide or fertilizer application to prevent wash-off."
                  : "Calm conditions and no imminent rain. Optimal window for nutrient and crop protection spraying."),
          icon: Icons.science_outlined,
          color: const Color(0xFFE76F51),
        ),
        const SizedBox(height: 10),
        _buildAdvisoryTile(
          title: "Fungal & Pest Vulnerability",
          desc: weather.relativeHumidityPct > 75 && weather.temperatureC > 22
              ? "Elevated humidity combined with warm temperatures creates favorable conditions for blast, rust, and powdery mildew. Inspect field corners and underside of foliage."
              : "Moderate humidity levels. Fungal spore germination pressure is currently within normal threshold limits.",
          icon: Icons.pest_control_outlined,
          color: const Color(0xFFD97706),
        ),
      ],
    );
  }

  Widget _buildAdvisoryTile({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('rain') || lower.contains('drizzle')) return Icons.grain;
    if (lower.contains('thunder')) return Icons.flash_on;
    if (lower.contains('cloud')) return Icons.cloud;
    if (lower.contains('fog')) return Icons.blur_on;
    return Icons.wb_sunny;
  }
}
