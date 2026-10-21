import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../providers/farm_provider.dart';
import '../providers/weather_provider.dart';
import 'paddy_knowledge_base.dart';

enum UserIntent {
  greeting,
  motorStatus,
  powerStatus,
  soilMoisture,
  weather,
  cropStatus,
  expenseSummary,
  cropGrowthAndAgronomy,
  cropDiseaseAndPest,
  followUp,
  generalHelp,
  unknown,
}

class AssistantService {
  static const String _apiPrefKey = 'gemini_api_key';

  Future<String?> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_apiPrefKey);
      if (key != null && key.trim().isNotEmpty) return key.trim();
    } catch (e) {
      debugPrint('[ASSISTANT] Error reading API key: $e');
    }
    return Platform.environment['GEMINI_API_KEY'];
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiPrefKey, key.trim());
  }

  String buildFarmContextSummary({
    required FarmProvider farm,
    required WeatherProvider weather,
    required Locale locale,
  }) {
    final power = farm.powerStatus;
    final motor = farm.motorStatus;
    final water = farm.waterStatus;
    final crop = farm.activeCrop;
    final weatherData = weather.weatherData;

    final StringBuffer sb = StringBuffer();
    if (power != null) {
      sb.writeln("Power Status: ${power.isAvailable ? 'AVAILABLE (ON)' : 'OFF (Outage)'}");
      sb.writeln("Power Outage Duration: ${power.outageDuration}");
    } else {
      sb.writeln("Power Status: UNKNOWN (Hardware Disconnected)");
    }

    if (motor != null) {
      sb.writeln("Motor Status: ${motor.isRunning ? 'RUNNING' : 'STOPPED'}");
      sb.writeln("Last Run Duration: ${motor.currentRuntime}");
    } else {
      sb.writeln("Motor Status: STOPPED");
    }

    if (water != null) {
      sb.writeln("Water Flow: ${water.isFlowing ? 'FLOWING' : 'NO FLOW'} (${water.flowRate.toStringAsFixed(1)} L/min)");
    }

    if (crop != null) {
      sb.writeln("Active Crop: ${crop.name} (Field: ${crop.field}, Stage: ${crop.stage})");
      sb.writeln("Soil Moisture: ${crop.soilMoisture}% [Simulated Test Data]");
    } else {
      sb.writeln("Active Crop: None registered");
    }

    if (weatherData != null) {
      sb.writeln("Weather at ${weather.currentLocation.name}: ${weatherData.temperature.toStringAsFixed(1)}°C, ${weatherData.condition}");
      sb.writeln("Humidity: ${weatherData.humidity}%, Wind: ${weatherData.windSpeed.toStringAsFixed(1)} km/h, Rain: ${weatherData.precipitation.toStringAsFixed(1)} mm");
    } else {
      sb.writeln("Weather: Data unavailable");
    }

    sb.writeln("Total Farm Expenses: ₹${farm.getOverallTotalExpense().toStringAsFixed(2)}");
    sb.writeln("Active Language: ${locale.languageCode}");

    return sb.toString();
  }

  UserIntent classifyIntent(String cleanInput) {
    final lower = cleanInput.toLowerCase().trim();

    // 1. Strict Greetings
    if (_isGreeting(lower)) {
      return UserIntent.greeting;
    }

    // 2. Follow-up Check
    if (_isFollowUp(lower)) {
      return UserIntent.followUp;
    }

    // 3. Motor / Pump
    if (lower.contains('motor') || lower.contains('pump') || lower.contains('pumping')) {
      return UserIntent.motorStatus;
    }

    // 4. Power / Electricity
    if (lower.contains('power') || lower.contains('electricity') || lower.contains('voltage') || lower.contains('phase')) {
      return UserIntent.powerStatus;
    }

    // 5. Soil Moisture
    if (lower.contains('soil') || lower.contains('moisture') || lower.contains('water level')) {
      return UserIntent.soilMoisture;
    }

    // 6. Weather
    if (lower.contains('weather') || lower.contains('temperature') || lower.contains('rain') || lower.contains('forecast') || lower.contains('humidity') || lower.contains('wind')) {
      return UserIntent.weather;
    }

    // 7. Crop / Agronomy / Growth
    if (lower.contains('improve') || lower.contains('growth') || lower.contains('yield') || lower.contains('grow') || lower.contains('fertilizer') || lower.contains('weed') || lower.contains('urea') || lower.contains('potash') || lower.contains('agronomy') || lower.contains('nitrogen')) {
      return UserIntent.cropGrowthAndAgronomy;
    }

    // 8. Pest / Disease
    for (var condition in PaddyKnowledgeBase.conditions) {
      if (lower.contains(condition.name.toLowerCase()) ||
          condition.id.toLowerCase().contains(lower) ||
          condition.symptoms.any((s) => lower.contains(s.toLowerCase()))) {
        return UserIntent.cropDiseaseAndPest;
      }
    }
    if (lower.contains('pest') || lower.contains('disease') || lower.contains('bug') || lower.contains('blight') || lower.contains('spot') || lower.contains('blast')) {
      return UserIntent.cropDiseaseAndPest;
    }

    // 9. Active Crop Details
    if (lower.contains('crop') || lower.contains('field') || lower.contains('planting') || lower.contains('stage')) {
      return UserIntent.cropStatus;
    }

    // 10. Expenses
    if (lower.contains('expense') || lower.contains('cost') || lower.contains('spent') || lower.contains('money')) {
      return UserIntent.expenseSummary;
    }

    // 11. General Help
    if (lower.contains('help') || lower.contains('what can you do') || lower.contains('options')) {
      return UserIntent.generalHelp;
    }

    return UserIntent.unknown;
  }

  Future<ChatMessage> generateResponse({
    required String userText,
    required List<ChatMessage> history,
    required FarmProvider farm,
    required WeatherProvider weather,
    required Locale locale,
  }) async {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final cleanInput = userText.trim();

    if (cleanInput.isEmpty) {
      return ChatMessage(
        id: id,
        text: "Please type or speak a question.",
        isUser: false,
        timestamp: now,
      );
    }

    final apiKey = await getApiKey();

    if (apiKey != null && apiKey.isNotEmpty) {
      try {
        final apiResponse = await _callGeminiApi(
          apiKey: apiKey,
          userText: cleanInput,
          history: history,
          farm: farm,
          weather: weather,
          locale: locale,
        );
        if (apiResponse != null) {
          return ChatMessage(
            id: id,
            text: apiResponse,
            isUser: false,
            timestamp: now,
          );
        }
      } catch (e) {
        debugPrint('[ASSISTANT] Gemini API Call Error: $e');
      }
    }

    // Smart Conversational Fallback Engine
    final responseText = _processSmartFallback(
      cleanInput: cleanInput,
      history: history,
      farm: farm,
      weather: weather,
      locale: locale,
    );

    return ChatMessage(
      id: id,
      text: responseText,
      isUser: false,
      timestamp: now,
    );
  }

  Future<String?> _callGeminiApi({
    required String apiKey,
    required String userText,
    required List<ChatMessage> history,
    required FarmProvider farm,
    required WeatherProvider weather,
    required Locale locale,
  }) async {
    try {
      final contextSummary = buildFarmContextSummary(farm: farm, weather: weather, locale: locale);
      final systemPrompt = """
You are an expert, friendly AI Farm Assistant for a farmer.
Language Preference: ${locale.languageCode} (Respond in the user's language).

LIVE FARM TELEMETRY DATA:
$contextSummary

RULES:
1. Answer the farmer's question directly and concisely.
2. Use the live farm telemetry data above to answer specific farm questions (motor, power, soil, weather, expenses).
3. If data is marked [Simulated/Test Data], mention that it is test data.
4. If asked a greeting (e.g. "hi"), greet warmly and ask how to help.
5. Provide safe agricultural guidance for pest or crop questions.
""";

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      final contents = [
        {
          'role': 'user',
          'parts': [{'text': systemPrompt}]
        },
        ...history.take(6).map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'parts': [{'text': m.text}]
            }),
        {
          'role': 'user',
          'parts': [{'text': userText}]
        }
      ];

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'contents': contents}));

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final candidates = json['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List<dynamic>;
          if (parts.isNotEmpty) {
            return parts[0]['text'].toString().trim();
          }
        }
      }
    } catch (e) {
      debugPrint('[ASSISTANT] Gemini REST call exception: $e');
    }
    return null;
  }

  String _processSmartFallback({
    required String cleanInput,
    required List<ChatMessage> history,
    required FarmProvider farm,
    required WeatherProvider weather,
    required Locale locale,
  }) {
    final lower = cleanInput.toLowerCase().trim();
    final lang = locale.languageCode;
    final intent = classifyIntent(cleanInput);

    switch (intent) {
      case UserIntent.greeting:
        if (lang == 'kn') {
          return "ನಮಸ್ಕಾರ! ಇಂದು ನಿಮ್ಮ ತೋಟದ ಬಗ್ಗೆ ಏನು ತಿಳಿಯಬೇಕಾಗಿದೆ?";
        } else if (lang == 'hi') {
          return "नमस्ते! आज आप अपने खेत के बारे में क्या जानना चाहते हैं?";
        }
        return "Hi there! What would you like to check on your farm right now?";

      case UserIntent.followUp:
        return _handleFollowUpContext(history: history, farm: farm);

      case UserIntent.motorStatus:
        final motor = farm.motorStatus;
        final isRunning = motor?.isRunning ?? false;
        final runtime = motor?.currentRuntime ?? '00h 00m';
        final water = farm.waterStatus;

        if (isRunning) {
          return "Your motor is currently RUNNING. Active runtime: $runtime. Water flow: ${water?.flowRate.toStringAsFixed(1) ?? '0.0'} L/min.";
        } else {
          return "Your motor is currently STOPPED. Last run duration: $runtime.";
        }

      case UserIntent.powerStatus:
        final power = farm.powerStatus;
        final isAvail = power?.isAvailable ?? false;
        final outage = power?.outageDuration ?? '0h 0m';

        if (isAvail) {
          return "Main power is currently AVAILABLE (ON) at your farm.";
        } else {
          return "Main power is currently OFF (Outage). Power outage duration: $outage.";
        }

      case UserIntent.soilMoisture:
        final crop = farm.activeCrop;
        final moisture = crop?.soilMoisture ?? 0.0;
        return "Soil Moisture is currently ${moisture.toStringAsFixed(1)}% [Simulated Test Data]. Ensure adequate irrigation during hot weather.";

      case UserIntent.weather:
        final w = weather.weatherData;
        if (w != null) {
          return "Current weather at ${weather.currentLocation.name} is ${w.temperature.toStringAsFixed(1)}°C, ${w.condition}. Humidity: ${w.humidity}%, Wind: ${w.windSpeed.toStringAsFixed(1)} km/h, Rain: ${w.precipitation.toStringAsFixed(1)} mm.";
        } else {
          return "Weather data is currently unavailable. Please check your internet connection or pull to refresh on the Weather tab.";
        }

      case UserIntent.cropGrowthAndAgronomy:
        return "To improve paddy growth and grain yield:\n\n"
            "1. Soil & Nutrient Management: Apply Nitrogen (Urea) in 3 split doses (basal, tillering, panicle initiation). Apply Potash (K) to strengthen tillers.\n"
            "2. Water Management: Maintain 2-5 cm standing water during tillering and flowering stages.\n"
            "3. Weed Control: Perform weeding at 15-20 days after transplanting.\n"
            "4. Disease Monitoring: Check leaves regularly for spots using the Crop AI scanner.";

      case UserIntent.cropDiseaseAndPest:
        for (var condition in PaddyKnowledgeBase.conditions) {
          if (lower.contains(condition.name.toLowerCase()) ||
              condition.id.toLowerCase().contains(lower) ||
              condition.symptoms.any((s) => lower.contains(s.toLowerCase()))) {
            return "${condition.name} (${condition.type}):\n\nImpact:\n${condition.cropImpact}\n\nSafe Management:\n${condition.managementPractices}\n\nWhen to Call Expert:\n${condition.whenToContactExpert}";
          }
        }
        return "Paddy Pest & Disease Guidance:\nInspect leaves for spindle spots (Blast), yellow margins (Bacterial Blight), or burnt patches (BPH). You can use the Crop AI tab to capture leaf photos for instant diagnosis.";

      case UserIntent.cropStatus:
        final crop = farm.activeCrop;
        if (crop != null) {
          return "Active Crop: ${crop.name} (Field: ${crop.field}) at ${crop.stage} stage. Planted ${crop.daysSincePlanting} days ago across ${crop.area} ${crop.areaUnit}.";
        } else {
          return "No active crop record found. You can add a new crop in the Crop Management tab.";
        }

      case UserIntent.expenseSummary:
        final total = farm.getOverallTotalExpense();
        return "Total farm expenditure recorded so far is ₹${total.toStringAsFixed(2)}.";

      case UserIntent.generalHelp:
        return "I can help answer questions about:\n• Motor & Power status\n• Soil Moisture & Water Flow\n• Live Weather forecasts\n• Active Crop & Expense summaries\n• Paddy Growth & Disease treatment";

      case UserIntent.unknown:
        return "I can help answer questions about your motor status, power supply, weather forecast, soil moisture, crop health, or paddy growth advice. What would you like to check?";
    }
  }

  String _handleFollowUpContext({
    required List<ChatMessage> history,
    required FarmProvider farm,
  }) {
    if (history.isEmpty) {
      return "Which crop condition or farm issue would you like treatment advice for? You can mention a disease like Rice Blast or ask about soil moisture.";
    }

    // Inspect previous messages in conversation history
    final previousMessages = history.reversed.toList();
    
    // Find preceding topic from previous assistant/user messages
    for (var msg in previousMessages) {
      final text = msg.text.toLowerCase();

      // 1. Soil Moisture Context
      if (text.contains('soil moisture') || text.contains('moisture is currently')) {
        return "The displayed 0.0% soil moisture is simulated test data and cannot establish the actual condition of your field soil.\n\n"
            "General Soil & Irrigation Guidance:\n"
            "• Visually inspect field soil moisture or connect a hardware soil sensor for live readings.\n"
            "• For paddy crops, maintain 2-5 cm standing water during tillering and panicle flowering stages.\n"
            "• Irrigate during early morning or evening to minimize evaporation losses.";
      }

      // 2. Disease / Pest Context (e.g. Blast, Brown Spot, BLB, BPH, Stem Borer, Hispa, Tungro)
      for (var condition in PaddyKnowledgeBase.conditions) {
        if (text.contains(condition.name.toLowerCase()) ||
            text.contains(condition.id.replaceAll('_', ' ')) ||
            text.contains(condition.id)) {
          return "Treatment Guidance for ${condition.name} (${condition.type}):\n\n"
              "${condition.managementPractices}\n\n"
              "When to Call Expert:\n${condition.whenToContactExpert}";
        }
      }

      // 3. Motor / Irrigation Context
      if (text.contains('motor') || text.contains('pump') || text.contains('running') || text.contains('stopped')) {
        return "You can toggle the motor ON or OFF from the Control tab, or configure automated schedules under Motor Scheduler. Ensure main power is ON before starting the motor.";
      }
    }

    // Ambiguous reference (No clear preceding disease, soil, or motor topic)
    return "Which crop condition or farm issue would you like treatment advice for? You can mention a disease like Rice Blast or ask about soil moisture.";
  }

  bool _isGreeting(String text) {
    final exactGreetings = ['hi', 'hello', 'hey', 'namaste', 'namaskara', 'good morning', 'good evening', 'good afternoon', 'how are you'];
    if (exactGreetings.contains(text)) return true;
    for (var g in ['hi ', 'hello ', 'hey ', 'namaste ', 'namaskara ']) {
      if (text.startsWith(g)) return true;
    }
    return false;
  }

  bool _isFollowUp(String text) {
    final followUps = [
      'how can i treat it',
      'how to treat it',
      'how to fix it',
      'how do i treat it',
      'what to do',
      'how to treat',
      'how to fix',
      'tell me more',
      'what should i do',
      'how to cure it',
      'what next',
      'why'
    ];
    return followUps.any((f) => text.contains(f));
  }
}
