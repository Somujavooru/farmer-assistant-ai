import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../providers/farm_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/weather_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_card.dart';
import '../../utils/constants.dart';
import '../../models/hardware_status.dart';
import '../settings/settings_screen.dart';
import '../history/history_screen.dart';
import '../expenses/expenses_screen.dart';
import '../weather/weather_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<FarmProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: provider.refreshStaticData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.screenPadding),
                      child: _buildHeader(context, provider),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                      child: _buildMainStatus(context, provider),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.screenPadding),
                      child: _buildQuickActions(context),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                      child: _buildFarmOverview(context, provider),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FarmProvider provider) {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) greeting = 'Good Afternoon';
    if (hour >= 17) greeting = 'Good Evening';

    return FadeInDown(
      duration: AppConstants.mediumAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Farmer Rajesh',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Green Valley Farm, Karnataka',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConnectionIcon(provider.connectionStatus),
              IconButton(
                onPressed: () {},
                icon: const Badge(
                  label: Text('3'),
                  child: Icon(Icons.notifications_outlined),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text('R', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionIcon(ConnectionStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case ConnectionStatus.connected:
        icon = Icons.sensors;
        color = AppColors.success;
        break;
      case ConnectionStatus.connecting:
        icon = Icons.sensors;
        color = AppColors.warning;
        break;
      case ConnectionStatus.error:
        icon = Icons.sensors_off;
        color = AppColors.error;
        break;
      default:
        icon = Icons.sensors_off;
        color = AppColors.grey400;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildMainStatus(BuildContext context, FarmProvider provider) {
    final power = provider.powerStatus;
    final motor = provider.motorStatus;
    final water = provider.waterStatus;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FadeInLeft(
                delay: const Duration(milliseconds: 200),
                child: StatusCard(
                  title: 'POWER',
                  status: power?.isAvailable ?? false ? 'ON' : 'OFF',
                  subtitle: power?.isAvailable ?? false 
                      ? 'Since ${power?.availableSince}' 
                      : 'Outage: ${power?.outageDuration}',
                  icon: Icons.power,
                  color: power?.isAvailable ?? false ? AppColors.success : AppColors.error,
                  isActive: power?.isAvailable ?? false,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.elementSpacing),
            Expanded(
              child: FadeInRight(
                delay: const Duration(milliseconds: 200),
                child: StatusCard(
                  title: 'MOTOR',
                  status: motor?.isRunning ?? false ? 'RUNNING' : 'STOPPED',
                  subtitle: motor?.isRunning ?? false 
                      ? 'Runtime: ${motor?.currentRuntime}' 
                      : 'Last run: 1h 24m',
                  icon: Icons.settings_input_component,
                  color: motor?.isRunning ?? false ? AppColors.primary : AppColors.onSurfaceVariant,
                  isActive: motor?.isRunning ?? false,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.elementSpacing),
        FadeInUp(
          delay: const Duration(milliseconds: 400),
          child: StatusCard(
            title: 'WATER FLOW',
            status: water?.isFlowing ?? false ? '${water?.flowRate} L/min' : 'NO FLOW',
            subtitle: water?.isFlowing ?? false ? 'Pumping normally' : 'Motor is off',
            icon: Icons.water_drop,
            color: water?.isFlowing ?? false ? AppColors.secondary : AppColors.onSurfaceVariant,
            isActive: water?.isFlowing ?? false,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppConstants.smallSpacing),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActionItem(context, 'History', Icons.history, AppColors.primary, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
              }),
              _buildActionItem(context, 'Expenses', Icons.account_balance_wallet, Colors.brown, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpensesScreen()));
              }),
              _buildActionItem(context, 'Crop AI', Icons.camera_alt, Colors.purple, () {}),
              _buildActionItem(context, 'Weather', Icons.cloud, AppColors.secondary, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WeatherScreen()));
              }),
              _buildActionItem(context, 'Alerts', Icons.notifications, AppColors.warning, () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmOverview(BuildContext context, FarmProvider provider) {
    final crop = provider.crop;
    final overallTotal = provider.getOverallTotalExpense();
    final currencyFormat = NumberFormat('#,##,##0.00');

    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weather = weatherProvider.weatherData;
    final weatherText = weather != null
        ? '${weather.temperature.toStringAsFixed(1)}°C, ${weather.condition}'
        : (weatherProvider.isLoading ? 'Loading weather...' : 'Weather unavailable');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Farm Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Provider.of<NavigationProvider>(context, listen: false).setIndex(3);
              },
              child: const Text('View Details'),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildOverviewRow(Icons.eco, 'Main Crop', crop?.name ?? 'No active crop'),
                if (crop != null) ...[
                  const Divider(),
                  _buildOverviewRow(Icons.location_on, 'Field', crop.field),
                ],
                const Divider(),
                _buildOverviewRow(Icons.account_balance_wallet, 'Total Expenditure', '₹ ${currencyFormat.format(overallTotal)}'),
                const Divider(),
                _buildOverviewRow(Icons.thermostat, 'Soil Moisture', '${crop?.soilMoisture ?? 0}%'),
                const Divider(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WeatherScreen()));
                  },
                  child: _buildOverviewRow(Icons.wb_sunny, 'Weather', weatherText),
                ),
                const Divider(),
                _buildOverviewRow(Icons.flash_on, 'Voltage', '${provider.powerStatus?.voltage?.toStringAsFixed(1) ?? 0} V'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
