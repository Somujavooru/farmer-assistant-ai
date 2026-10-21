import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/farm_provider.dart';
import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'utils/constants.dart';
import 'localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/scheduler_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/assistant_provider.dart';

class FarmerAssistantApp extends StatelessWidget {
  const FarmerAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => AssistantProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, FarmProvider>(
          create: (context) => FarmProvider(
            settings: Provider.of<SettingsProvider>(context, listen: false),
          ),
          update: (context, settings, previous) => previous!..updateSettings(settings),
        ),
        ChangeNotifierProxyProvider<FarmProvider, SchedulerProvider>(
          create: (context) => SchedulerProvider(),
          update: (context, farm, previous) {
            final scheduler = previous ?? SchedulerProvider();
            scheduler.onTriggerMotor = farm.toggleMotor;
            scheduler.isPowerAvailable = () => farm.powerStatus?.isAvailable ?? false;
            return scheduler;
          },
        ),
      ],
      child: Selector<SettingsProvider, Locale>(
        selector: (context, settings) => settings.currentLocale,
        builder: (context, currentLocale, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('kn', ''),
              Locale('hi', ''),
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
