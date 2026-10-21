import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/assistant_service.dart';
import '../services/voice_service.dart';
import 'farm_provider.dart';
import 'weather_provider.dart';
import 'settings_provider.dart';

class AssistantProvider with ChangeNotifier {
  final AssistantService _service = AssistantService();
  final VoiceService _voiceService = VoiceService();
  
  List<ChatMessage> _messages = [];
  bool _isThinking = false;

  List<ChatMessage> get messages => _messages;
  bool get isThinking => _isThinking;

  AssistantProvider() {
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString('farm_chat_history');
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _messages = decoded.map((item) => ChatMessage.fromMap(item)).toList();
      } else {
        _messages = [
          ChatMessage(
            id: 'init_welcome',
            text: 'Hello! I am your AI Farm Assistant. How can I help you with your motor, crops, or weather today?',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[ASSISTANT] Error loading chat history: $e');
      _messages = [
        ChatMessage(
          id: 'init_welcome',
          text: 'Hello! I am your AI Farm Assistant. How can I help you today?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
      notifyListeners();
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_messages.map((m) => m.toMap()).toList());
      await prefs.setString('farm_chat_history', encoded);
    } catch (e) {
      debugPrint('[ASSISTANT] Error saving chat history: $e');
    }
  }

  Future<void> sendMessage({
    required String text,
    required FarmProvider farm,
    required WeatherProvider weather,
    required SettingsProvider settings,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isThinking) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: cleanText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isThinking = true;
    notifyListeners();
    await _saveChatHistory();

    try {
      final aiMessage = await _service.generateResponse(
        userText: cleanText,
        history: _messages,
        farm: farm,
        weather: weather,
        locale: settings.currentLocale,
      );

      _messages.add(aiMessage);
      _isThinking = false;
      notifyListeners();
      await _saveChatHistory();

      // Trigger TTS voice output if voice alerts are enabled
      if (settings.voiceAlertsEnabled) {
        _voiceService.speak(aiMessage.text, settings.voiceLocale);
      }
    } catch (e) {
      debugPrint('[ASSISTANT] Error generating response: $e');
      _isThinking = false;
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: "I am having trouble answering right now. Please try again.",
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
      notifyListeners();
      await _saveChatHistory();
    }
  }

  Future<void> clearChat() async {
    _messages = [
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Chat cleared. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
    _isThinking = false;
    notifyListeners();
    await _saveChatHistory();
  }
}
