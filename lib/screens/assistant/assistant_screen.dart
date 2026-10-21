import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/farm_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    final assistantProvider = Provider.of<AssistantProvider>(context, listen: false);
    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    assistantProvider.sendMessage(
      text: text,
      farm: farmProvider,
      weather: weatherProvider,
      settings: settingsProvider,
    );

    _scrollToBottom();
  }

  void _showVoicePromptDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.mic, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Voice Input (${settings.voiceLocale.languageCode.toUpperCase()})'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.graphic_eq, size: 60, color: AppColors.primary),
              SizedBox(height: 12),
              Text('Listening... Speak your farm question clearly.', textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _controller.text = "Is motor running?";
                _sendMessage();
              },
              child: const Text('SIMULATE VOICE MSG'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final assistantProvider = Provider.of<AssistantProvider>(context);
    final messages = assistantProvider.messages;

    _scrollToBottom();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Farm Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Chat History',
            onPressed: () {
              assistantProvider.clearChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              itemCount: messages.length + (assistantProvider.isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < messages.length) {
                  final msg = messages[index];
                  return _buildChatBubble(msg);
                } else {
                  return _buildThinkingBubble();
                }
              },
            ),
          ),
          _buildInputArea(assistantProvider.isThinking),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final timeStr = DateFormat('h:mm a').format(msg.timestamp);

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppColors.primary
              : (msg.isError ? Colors.red[50] : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isUser ? 18 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 18),
          ),
          border: msg.isError ? Border.all(color: AppColors.error.withValues(alpha: 0.4)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser
                    ? Colors.white
                    : (msg.isError ? AppColors.error : AppColors.onSurface),
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 10,
                color: msg.isUser
                    ? Colors.white70
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 10),
            Text('Analyzing live farm data...', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isThinking) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _showVoicePromptDialog,
              icon: const Icon(Icons.mic, color: AppColors.primary),
              tooltip: 'Voice Input',
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !isThinking,
                decoration: InputDecoration(
                  hintText: isThinking ? 'Assistant is typing...' : 'Ask about motor, weather, soil...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: isThinking ? Colors.grey : AppColors.primary,
              child: IconButton(
                onPressed: isThinking ? null : _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
