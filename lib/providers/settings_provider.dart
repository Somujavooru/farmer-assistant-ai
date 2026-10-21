import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _voiceAlertsEnabled = true;
  Locale _appLocale = const Locale('en');
  Locale _voiceLocale = const Locale('en');
  Locale _smsLocale = const Locale('en');

  SettingsProvider() {
    _loadSettings();
  }

  bool get voiceAlertsEnabled => _voiceAlertsEnabled;
  Locale get currentLocale => _appLocale;
  Locale get voiceLocale => _voiceLocale;
  Locale get smsLocale => _smsLocale;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _voiceAlertsEnabled = prefs.getBool('voice_alerts_enabled') ?? true;
    _appLocale = Locale(prefs.getString('app_language') ?? 'en');
    _voiceLocale = Locale(prefs.getString('voice_language') ?? 'en');
    _smsLocale = Locale(prefs.getString('sms_language') ?? 'en');
    notifyListeners();
  }

  Future<void> toggleVoiceAlerts(bool value) async {
    _voiceAlertsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_alerts_enabled', value);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _appLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', locale.languageCode);
    notifyListeners();
  }

  Future<void> setVoiceLocale(Locale locale) async {
    _voiceLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voice_language', locale.languageCode);
    notifyListeners();
  }

  Future<void> setSmsLocale(Locale locale) async {
    _smsLocale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sms_language', locale.languageCode);
    notifyListeners();
  }
}
