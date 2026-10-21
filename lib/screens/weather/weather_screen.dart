import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/weather_data.dart';
import '../../providers/weather_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        final weather = weatherProvider.weatherData;
        final isLoading = weatherProvider.isLoading;
        final error = weatherProvider.errorMessage;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Farm Weather', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.refresh),
                onPressed: isLoading ? null : () => weatherProvider.fetchWeather(forceRefresh: true),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => weatherProvider.fetchWeather(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationBar(context, weatherProvider),
                  const SizedBox(height: 12),
                  if (error != null) _buildErrorBanner(context, error),
                  if (weather != null && weather.isCached) _buildCachedBanner(context, weather.lastUpdated),
                  const SizedBox(height: 12),
                  if (isLoading && weather == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (weather == null)
                    _buildNoDataState(context, weatherProvider)
                  else ...[
                    _buildMainWeatherCard(context, weather),
                    const SizedBox(height: 20),
                    _buildSmartIrrigationAdvice(context, weather),
                    const SizedBox(height: 20),
                    _buildForecastSection(context, weather.dailyForecast),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationBar(BuildContext context, WeatherProvider weatherProvider) {
    final currentLocation = weatherProvider.currentLocation;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected Farm Location', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                Text(
                  currentLocation.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert, color: AppColors.primary),
            onPressed: () => _showLocationSelector(context, weatherProvider),
          ),
        ],
      ),
    );
  }

  void _showLocationSelector(BuildContext context, WeatherProvider weatherProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return _LocationSearchBottomSheet(
              scrollController: scrollController,
              weatherProvider: weatherProvider,
            );
          },
        );
      },
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCachedBanner(BuildContext context, DateTime lastUpdated) {
    final dateFormat = DateFormat('hh:mm a, dd MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing cached weather • Updated ${dateFormat.format(lastUpdated)}',
              style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainWeatherCard(BuildContext context, WeatherData weather) {
    final iconData = WeatherData.getWeatherIcon(weather.weatherCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, Color(0xFF0277BD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    weather.condition,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Icon(iconData, color: Colors.amber, size: 64),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherMetric('Humidity', '${weather.humidity}%', Icons.water_drop_outlined),
              _buildWeatherMetric('Wind', '${weather.windSpeed.toStringAsFixed(1)} km/h', Icons.air),
              _buildWeatherMetric('Rain', '${weather.precipitation.toStringAsFixed(1)} mm', Icons.umbrella_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildSmartIrrigationAdvice(BuildContext context, WeatherData weather) {
    String adviceTitle = 'Optimal Conditions';
    String adviceText = 'Weather conditions are normal. Follow your standard irrigation schedule.';
    Color color = AppColors.success;
    IconData icon = Icons.check_circle_outline;

    if (weather.precipitation > 5.0) {
      adviceTitle = 'Rain Expected / Occurring';
      adviceText = 'Significant rainfall (${weather.precipitation} mm) detected. Consider pausing scheduled irrigation to conserve water.';
      color = AppColors.primary;
      icon = Icons.umbrella;
    } else if (weather.temperature > 35.0) {
      adviceTitle = 'High Temperature Warning';
      adviceText = 'High heat (${weather.temperature}°C) increases soil evaporation. Monitor soil moisture closely.';
      color = AppColors.warning;
      icon = Icons.thermostat;
    } else if (weather.humidity < 35) {
      adviceTitle = 'Low Atmospheric Humidity';
      adviceText = 'Low humidity (${weather.humidity}%) can dry out topsoil quickly. Ensure crops are adequately watered.';
      color = Colors.orange;
      icon = Icons.water;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Irrigation Advice: $adviceTitle',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  adviceText,
                  style: const TextStyle(fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection(BuildContext context, List<DailyForecast> forecasts) {
    if (forecasts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7-Day Farm Forecast',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: forecasts.length,
          itemBuilder: (context, index) {
            final forecast = forecasts[index];
            final icon = WeatherData.getWeatherIcon(forecast.weatherCode);
            final dayStr = index == 0 ? 'Today' : DateFormat('EEEE').format(forecast.date);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        dayStr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Icon(icon, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        forecast.condition,
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (forecast.precipitation > 0) ...[
                      Text(
                        '${forecast.precipitation.toStringAsFixed(1)}mm',
                        style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '${forecast.maxTemp.round()}° / ${forecast.minTemp.round()}°',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoDataState(BuildContext context, WeatherProvider weatherProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 64, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('Weather data unavailable', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => weatherProvider.fetchWeather(forceRefresh: true),
              child: const Text('RETRY CONNECTION'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSearchBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final WeatherProvider weatherProvider;

  const _LocationSearchBottomSheet({
    required this.scrollController,
    required this.weatherProvider,
  });

  @override
  State<_LocationSearchBottomSheet> createState() => _LocationSearchBottomSheetState();
}

class _LocationSearchBottomSheetState extends State<_LocationSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<FarmLocation> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      final results = await widget.weatherProvider.searchLocations(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = widget.weatherProvider.currentLocation;
    final isSearchingQuery = _searchController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select or Search Farm Location',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search city or village (e.g. Hubli, Tumkur)...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: isSearchingQuery
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (isSearchingQuery) ...[
            Text(
              'Search Results',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        'No matching locations found for "${_searchController.text.trim()}".',
                        style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final loc = _searchResults[index];
                        final isSelected = loc.name == currentLocation.name;

                        return ListTile(
                          leading: const Icon(Icons.location_city, color: AppColors.primary),
                          title: Text(
                            loc.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : Colors.black87,
                            ),
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                          onTap: () {
                            widget.weatherProvider.setLocation(loc);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ] else ...[
            Text(
              'Karnataka Farm Regions',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                itemCount: WeatherProvider.presetLocations.length,
                itemBuilder: (context, index) {
                  final loc = WeatherProvider.presetLocations[index];
                  final isSelected = loc.name == currentLocation.name;

                  return ListTile(
                    leading: Icon(
                      Icons.agriculture,
                      color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                    ),
                    title: Text(
                      loc.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : Colors.black87,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                    onTap: () {
                      widget.weatherProvider.setLocation(loc);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

