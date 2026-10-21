import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/farm_provider.dart';
import '../../models/alert.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../providers/settings_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch FarmProvider and SettingsProvider for immediate UI updates
    final provider = context.watch<FarmProvider>();
    final settings = context.watch<SettingsProvider>();
    final alerts = provider.alerts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alert Center', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildVoiceToggle(settings),
          Expanded(
            child: alerts.isEmpty
                ? const Center(child: Text('No new alerts'))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.screenPadding),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return _buildAlertTile(context, alert, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceToggle(SettingsProvider settings) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.screenPadding),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  settings.voiceAlertsEnabled ? Icons.volume_up : Icons.volume_off,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Voice Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        'Announce critical alerts',
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.voiceAlertsEnabled,
            onChanged: (value) {
              settings.toggleVoiceAlerts(value);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile(BuildContext context, Alert alert, FarmProvider provider) {
    Color severityColor;
    IconData icon;

    switch (alert.severity) {
      case AlertSeverity.critical:
        severityColor = AppColors.error;
        icon = Icons.gpp_maybe;
        break;
      case AlertSeverity.warning:
        severityColor = AppColors.warning;
        icon = Icons.warning_amber;
        break;
      case AlertSeverity.success:
        severityColor = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      default:
        severityColor = AppColors.info;
        icon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: alert.isRead ? Colors.white.withOpacity(0.6) : Colors.white,
      child: InkWell(
        onTap: () => provider.markAlertAsRead(alert.id),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: severityColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!alert.isRead)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('hh:mm a').format(alert.timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
