import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Farmer Assistant',
      'power': 'POWER',
      'motor': 'MOTOR',
      'water': 'WATER',
      // Power Alerts
      'power_off_alert': 'Power has gone at your farm.',
      'power_restored_alert': 'Power has come to your farm.',
      'phase_fault_2_alert': 'Power supply fault: only 2 phases are available at your farm.',
      'phase_fault_1_alert': 'Power supply fault: only 1 phase is available at your farm.',
      // Motor Alerts
      'motor_started_alert': 'Motor has been turned ON.',
      'motor_stopped_alert': 'Motor has been turned OFF.',
      'motor_failed_alert': 'Motor command FAILED.',
      'motor_start_failure_alert': 'Motor Start Failed: No feedback from hardware.',
      'motor_overload_alert': 'Motor Overload: High current detected.',
      'dry_run_alert': 'DRY MOTOR ALERT: Motor is running without water!',
      // Electrical Alerts
      'high_voltage_alert': 'High Voltage Warning detected.',
      'low_voltage_alert': 'Low Voltage Warning detected.',
      'overcurrent_alert': 'Overcurrent / Motor Overload detected.',
      // Water Alerts
      'low_water_alert': 'Warning: Low water level detected.',
      'water_flow_restored_alert': 'Water reached the motor. Pumping normally.',
      // Connection Alerts
      'hardware_disconnected_alert': 'Hardware Disconnected. Checking connection...',
      'hardware_reconnected_alert': 'Hardware Reconnected successfully.',
      'telemetry_timeout_alert': 'Telemetry Timeout: Data is not being updated.',
    },
    'kn': {
      'title': 'ರೈತ ಸಹಾಯಕ',
      'power': 'ವಿದ್ಯುತ್',
      'motor': 'ಮೋಟರ್',
      'water': 'ನೀರು',
      // Power Alerts
      'power_off_alert': 'ನಿಮ್ಮ ತೋಟದಲ್ಲಿ ವಿದ್ಯುತ್ ಹೋಗಿದೆ.',
      'power_restored_alert': 'ನಿಮ್ಮ ತೋಟಕ್ಕೆ ವಿದ್ಯುತ್ ಬಂದಿದೆ.',
      'phase_fault_2_alert': 'ವಿದ್ಯುತ್ ಪೂರೈಕೆ ದೋಷ: ನಿಮ್ಮ ತೋಟದಲ್ಲಿ ಕೇವಲ 2 ಫೇಸ್‌ಗಳು ಲಭ್ಯವಿವೆ.',
      'phase_fault_1_alert': 'ವಿದ್ಯುತ್ ಪೂರೈಕೆ ದೋಷ: ನಿಮ್ಮ ತೋಟದಲ್ಲಿ ಕೇವಲ 1 ಫೇಸ್ ಲಭ್ಯವಿದೆ.',
      // Motor Alerts
      'motor_started_alert': 'ಮೋಟರ್ ಆನ್ ಮಾಡಲಾಗಿದೆ.',
      'motor_stopped_alert': 'ಮೋಟರ್ ಆಫ್ ಮಾಡಲಾಗಿದೆ.',
      'motor_failed_alert': 'ಮೋಟರ್ ಕಮಾಂಡ್ ವಿಫಲವಾಗಿದೆ.',
      'motor_start_failure_alert': 'ಮೋಟರ್ ಪ್ರಾರಂಭಿಸಲು ವಿಫಲವಾಗಿದೆ: ಹಾರ್ಡ್‌ವೇರ್‌ನಿಂದ ಯಾವುದೇ ಪ್ರತಿಕ್ರಿಯೆ ಇಲ್ಲ.',
      'motor_overload_alert': 'ಮೋಟರ್ ಓವರ್‌ಲೋಡ್: ಹೆಚ್ಚಿನ ವಿದ್ಯುತ್ ಪತ್ತೆಯಾಗಿದೆ.',
      'dry_run_alert': 'ಡ್ರೈ ಮೋಟಾರ್ ಎಚ್ಚರಿಕೆ: ನೀರಿಲ್ಲದೆ ಮೋಟಾರ್ ಓಡುತ್ತಿದೆ!',
      // Electrical Alerts
      'high_voltage_alert': 'ಹೆಚ್ಚಿನ ವೋಲ್ಟೇಜ್ ಎಚ್ಚರಿಕೆ ಪತ್ತೆಯಾಗಿದೆ.',
      'low_voltage_alert': 'ಕಡಿಮೆ ವೋಲ್ಟೇಜ್ ಎಚ್ಚರಿಕೆ ಪತ್ತೆಯಾಗಿದೆ.',
      'overcurrent_alert': 'ಮೋಟರ್ ಓವರ್‌ಲೋಡ್ ಪತ್ತೆಯಾಗಿದೆ.',
      // Water Alerts
      'low_water_alert': 'ಎಚ್ಚರಿಕೆ: ನೀರಿನ ಮಟ್ಟ ಕಡಿಮೆಯಾಗಿದೆ.',
      'water_flow_restored_alert': 'ನೀರನ್ನು ಪಂಪ್ ಮಾಡಲಾಗುತ್ತಿದೆ. ಸಹಜ ಸ್ಥಿತಿಗೆ ಮರಳಿದೆ.',
      // Connection Alerts
      'hardware_disconnected_alert': 'ಹಾರ್ಡ್‌ವೇರ್ ಸಂಪರ್ಕ ಕಡಿತಗೊಂಡಿದೆ.',
      'hardware_reconnected_alert': 'ಹಾರ್ಡ್‌ವೇರ್ ಮರುಸಂಪರ್ಕಗೊಂಡಿದೆ.',
      'telemetry_timeout_alert': 'ಟೆಲಿಮೆಟ್ರಿ ಅವಧಿ ಮುಗಿದಿದೆ: ಡೇಟಾ ಅಪ್‌ಡೇಟ್ ಆಗುತ್ತಿಲ್ಲ.',
    },
    'hi': {
      'title': 'किसान सहायक',
      'power': 'बिजली',
      'motor': 'मोटर',
      'water': 'पानी',
      // Power Alerts
      'power_off_alert': 'आपके खेत की बिजली चली गई है।',
      'power_restored_alert': 'आपके खेत की बिजली आ गई है।',
      'phase_fault_2_alert': 'बिजली आपूर्ति में खराबी: आपके खेत में केवल 2 फेज उपलब्ध हैं।',
      'phase_fault_1_alert': 'बिजली आपूर्ति में खराबी: आपके खेत में केवल 1 फेज उपलब्ध है।',
      // Motor Alerts
      'motor_started_alert': 'मोटर चालू कर दी गई है।',
      'motor_stopped_alert': 'मोटर बंद कर दी गई है।',
      'motor_failed_alert': 'मोटर कमांड विफल रहा।',
      'motor_start_failure_alert': 'मोटर शुरू होने में विफल: हार्डवेयर से कोई फीडबैक नहीं।',
      'motor_overload_alert': 'मोटर ओवरलोड: उच्च धारा का पता चला।',
      'dry_run_alert': 'ड्राय मोटर चेतावनी: मोटर बिना पानी के चल रही है!',
      // Electrical Alerts
      'high_voltage_alert': 'हाई वोल्टेज की चेतावनी।',
      'low_voltage_alert': 'लो वोल्टेज की चेतावनी।',
      'overcurrent_alert': 'मोटर ओवरलोड का पता चला है।',
      // Water Alerts
      'low_water_alert': 'चेतावनी: पानी का स्तर कम है।',
      'water_flow_restored_alert': 'पानी मोटर तक पहुँच गया है। सामान्य रूप से पंप हो रहा है।',
      // Connection Alerts
      'hardware_disconnected_alert': 'हार्डवेयर डिस्कनेक्ट हो गया है।',
      'hardware_reconnected_alert': 'हार्डवेयर फिर से जुड़ गया है।',
      'telemetry_timeout_alert': 'टेलीमेट्री टाइमआउट: डेटा अपडेट नहीं हो रहा है।',
    },
    'te': {
      'title': 'రైతు సహాయకుడు',
      'power': 'విద్యుత్',
      'motor': 'మోటారు',
      'water': 'నీరు',
      // Power Alerts
      'power_off_alert': 'మీ పొలంలో విద్యుత్ నిలిచిపోయింది.',
      'power_restored_alert': 'మీ పొలంలో విద్యుత్ పునరుద్ధరించబడింది.',
      // Motor Alerts
      'motor_started_alert': 'మోటారు ప్రారంభమైంది.',
      'motor_stopped_alert': 'మోటారు ఆగిపోయింది.',
      'motor_failed_alert': 'మోటారు కమాండ్ విఫలమైంది.',
      'dry_run_alert': 'డ్రై రన్ గుర్తించబడింది: మోటారు నడుస్తోంది కానీ నీరు రావడం లేదు.',
      // Electrical Alerts
      'high_voltage_alert': 'అధిక వోల్టేజ్ హెచ్చరిక గుర్తించబడింది.',
      'low_voltage_alert': 'తక్కువ వోల్టేజ్ హెచ్చరిక గుర్తించబడింది.',
      'overcurrent_alert': 'మోటారు ఓవర్‌లోడ్ గుర్తించబడింది.',
      // Water Alerts
      'low_water_alert': 'హెచ్చరిక: నీటి మట్టం తక్కువగా ఉంది.',
      // Connection Alerts
      'hardware_disconnected_alert': 'హార్డ్‌వేర్ డిస్‌కనెక్ట్ చేయబడింది.',
      'hardware_reconnected_alert': 'హార్డ్‌వేర్ విజయవంతంగా మళ్లీ కనెక్ట్ చేయబడింది.',
      'telemetry_timeout_alert': 'టెలిమెట్రీ గడువు ముగిసింది.',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'kn', 'hi', 'te'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
