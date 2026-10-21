import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../providers/settings_provider.dart';
import '../../providers/farm_provider.dart';
import '../../models/alert.dart';

enum LanguageType { app, voice, sms }

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        children: [
          _buildProfileSection(context),
          const SizedBox(height: 24),
          _buildSettingsGroup(context, 'App Settings', [
            _buildSettingTile(
              Icons.language, 
              'App Language', 
              _getLanguageName(settings.currentLocale.languageCode), 
              () => _showLanguagePicker(context, settings, LanguageType.app),
            ),
            _buildSettingTile(
              Icons.volume_up, 
              'Voice Alerts', 
              settings.voiceAlertsEnabled ? 'Enabled' : 'Disabled', 
              () => settings.toggleVoiceAlerts(!settings.voiceAlertsEnabled),
            ),
            _buildSettingTile(
              Icons.record_voice_over, 
              'Voice Language', 
              _getLanguageName(settings.voiceLocale.languageCode), 
              () => _showLanguagePicker(context, settings, LanguageType.voice),
            ),
            _buildSettingTile(
              Icons.sms, 
              'SMS Alert Language', 
              _getLanguageName(settings.smsLocale.languageCode), 
              () => _showLanguagePicker(context, settings, LanguageType.sms),
            ),
            _buildSettingTile(Icons.notifications, 'Notification Settings', 'Critical & Important', () {}),
          ]),
          const SizedBox(height: 24),
          _buildSettingsGroup(context, 'Farm Configuration', [
            _buildSettingTile(Icons.agriculture, 'Farm Details', 'Green Valley Farm', () {}),
            _buildSettingTile(Icons.settings_input_component, 'Motor Setup', '3-Phase Submersible', () {}),
            _buildSettingTile(Icons.water, 'Water Source', 'Borewell 1', () {}),
          ]),
          const SizedBox(height: 24),
          _buildSettingsGroup(context, 'System Audit & Demo', [
            _buildSettingTile(
              Icons.bug_report, 
              'Test Alert System', 
              'Trigger Simulation', 
              () => _showDemoMenu(context, Provider.of<FarmProvider>(context, listen: false))
            ),
          ]),
          const SizedBox(height: 24),
          _buildSettingsGroup(context, 'Support', [
            _buildSettingTile(Icons.help_outline, 'Help & Support', 'Contact Expert', () {}),
            _buildSettingTile(Icons.info_outline, 'About App', 'v1.0.0', () {}),
            _buildSettingTile(Icons.logout, 'Logout', '', () {}, isDestructive: true),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'kn': return 'ಕನ್ನಡ (Kannada)';
      case 'hi': return 'हिन्दी (Hindi)';
      case 'te': return 'తెలుగు (Telugu)';
      default: return 'English';
    }
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider settings, LanguageType type) {
    Locale current;
    switch (type) {
      case LanguageType.app: current = settings.currentLocale; break;
      case LanguageType.voice: current = settings.voiceLocale; break;
      case LanguageType.sms: current = settings.smsLocale; break;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select ${type == LanguageType.app ? "App" : type == LanguageType.voice ? "Voice" : "SMS"} Language', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _buildLanguageOption(context, settings, type, 'English', const Locale('en'), current),
            _buildLanguageOption(context, settings, type, 'ಕನ್ನಡ (Kannada)', const Locale('kn'), current),
            _buildLanguageOption(context, settings, type, 'हिन्दी (Hindi)', const Locale('hi'), current),
            _buildLanguageOption(context, settings, type, 'తెలుగు (Telugu)', const Locale('te'), current),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, SettingsProvider settings, LanguageType type, String name, Locale locale, Locale current) {
    return ListTile(
      title: Text(name),
      onTap: () {
        switch (type) {
          case LanguageType.app: settings.setLocale(locale); break;
          case LanguageType.voice: settings.setVoiceLocale(locale); break;
          case LanguageType.sms: settings.setSmsLocale(locale); break;
        }
        Navigator.pop(context);
      },
      trailing: current.languageCode == locale.languageCode ? const Icon(Icons.check, color: AppColors.primary) : null,
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farmer Rajesh',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '+91 98765 43210',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurfaceVariant),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String value, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary),
      title: Text(title, style: TextStyle(color: isDestructive ? AppColors.error : AppColors.onSurface)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty)
            Text(value, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showDemoMenu(BuildContext context, FarmProvider farm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Alert Audit Simulation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('Manually trigger alerts to test localized Voice & SMS logic.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 24),
            _buildDemoItem(context, 'Power Off', () => farm.triggerManualAlert('power_off_alert', AlertSeverity.warning)),
            _buildDemoItem(context, 'Power Restored', () => farm.triggerManualAlert('power_restored_alert', AlertSeverity.success)),
            _buildDemoItem(context, 'Motor Started', () => farm.triggerManualAlert('motor_started_alert', AlertSeverity.information)),
            _buildDemoItem(context, 'Motor Stopped', () => farm.triggerManualAlert('motor_stopped_alert', AlertSeverity.information)),
            _buildDemoItem(context, 'Overload', () => farm.triggerManualAlert('overcurrent_alert', AlertSeverity.critical)),
            _buildDemoItem(context, 'Dry Run', () => farm.triggerManualAlert('dry_run_alert', AlertSeverity.critical)),
            _buildDemoItem(context, 'High Voltage', () => farm.triggerManualAlert('high_voltage_alert', AlertSeverity.warning)),
            _buildDemoItem(context, 'Low Water', () => farm.triggerManualAlert('low_water_alert', AlertSeverity.warning)),
            _buildDemoItem(context, 'Disconnected', () => farm.triggerManualAlert('hardware_disconnected_alert', AlertSeverity.critical)),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoItem(BuildContext context, String label, VoidCallback onTap) {
    return ListTile(
      title: Text(label),
      leading: const Icon(Icons.play_arrow, color: AppColors.primary),
      onTap: () {
        onTap();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulated: $label')));
      },
    );
  }
}
