import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer_assistant/services/assistant_service.dart';
import 'package:farmer_assistant/models/chat_message.dart';
import 'package:farmer_assistant/providers/farm_provider.dart';
import 'package:farmer_assistant/providers/weather_provider.dart';
import 'package:farmer_assistant/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssistantService Follow-up Context & Response Routing Tests', () {
    late AssistantService service;
    late FarmProvider farmProvider;
    late WeatherProvider weatherProvider;
    const locale = Locale('en');

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = AssistantService();
      final settings = SettingsProvider();
      farmProvider = FarmProvider(settings: settings);
      weatherProvider = WeatherProvider();
    });

    test('1. Greeting Intent Classification ("hi")', () {
      final intent = service.classifyIntent("hi");
      expect(intent, equals(UserIntent.greeting));
    });

    test('2. Follow-Up Intent Classification ("How can I treat it?")', () {
      final intent = service.classifyIntent("How can I treat it?");
      expect(intent, equals(UserIntent.followUp));
    });

    test('3. Follow-up after Soil Moisture question explains simulated test data and irrigation', () async {
      final history = [
        ChatMessage(
          id: '1',
          text: 'What is my current soil moisture?',
          isUser: true,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: '2',
          text: 'Soil Moisture is currently 0.0% [Simulated Test Data]. Ensure adequate irrigation during hot weather.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];

      final response = await service.generateResponse(
        userText: "How can I treat it?",
        history: history,
        farm: farmProvider,
        weather: weatherProvider,
        locale: locale,
      );

      expect(response.text, contains("simulated test data"));
      expect(response.text, contains("cannot establish the actual condition"));
      expect(response.text, contains("General Soil & Irrigation Guidance"));
      expect(response.text, isNot(contains("Hi there!")));
    });

    test('4. Follow-up after Crop Disease question ("Rice Blast") provides specific disease treatment', () async {
      final history = [
        ChatMessage(
          id: '1',
          text: 'Tell me about Rice Blast',
          isUser: true,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: '2',
          text: 'Rice Blast (Disease): Eye-shaped or diamond-shaped lesions with dark brown borders.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];

      final response = await service.generateResponse(
        userText: "How can I treat it?",
        history: history,
        farm: farmProvider,
        weather: weatherProvider,
        locale: locale,
      );

      expect(response.text, contains("Treatment Guidance for Rice Blast"));
      expect(response.text, contains("When to Call Expert"));
      expect(response.text, isNot(contains("Hi there!")));
    });

    test('5. Ambiguous Follow-up reference asks specific clarifying question', () async {
      final response = await service.generateResponse(
        userText: "How can I treat it?",
        history: [], // No preceding context
        farm: farmProvider,
        weather: weatherProvider,
        locale: locale,
      );

      expect(response.text, contains("Which crop condition or farm issue would you like treatment advice for?"));
      expect(response.text, isNot(contains("Hi there!")));
      expect(response.text, isNot(contains("simulated test data")));
    });

    test('6. Controlled Backend Failure / Timeout Fallback Test', () async {
      // Simulate configured API key pointing to failing endpoint or invalid credentials
      await service.saveApiKey('invalid_test_gemini_key_for_timeout_test');

      final history = [
        ChatMessage(
          id: '101',
          text: 'Is my motor running?',
          isUser: true,
          timestamp: DateTime.now(),
        ),
      ];

      // Execute generateResponse - should handle API error/timeout gracefully without throwing exception
      final response = await service.generateResponse(
        userText: "Is my motor running?",
        history: history,
        farm: farmProvider,
        weather: weatherProvider,
        locale: locale,
      );

      // Verify graceful fallback to local telemetry data
      expect(response.text, contains("Your motor is currently"));
      expect(response.isError, equals(false));
    });
  });
}
