import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _flutterTts = FlutterTts();
  Completer<void>? _initCompleter;
  bool _isInitialized = false;

  // Sequential task queue to prevent concurrent TTS operations
  Future<void> _ttsQueue = Future.value();
  int _queueCount = 0;
  bool _isProcessing = false;
  
  // Failure tracking for recovery
  int _consecutiveFailures = 0;
  static const int _failureThreshold = 3;

  VoiceService() {
    // Lazy initialization: No longer calling _init() in the constructor.
  }

  Future<void> _ensureInitialized() async {
    if (kIsWeb) return;
    if (_isInitialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();
    debugPrint('[VOICE] TTS INITIALIZING');
    
    try {
      _flutterTts.setStartHandler(() {
        debugPrint('[VOICE] START');
        _consecutiveFailures = 0;
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint('[VOICE] COMPLETE');
        _consecutiveFailures = 0;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('[VOICE] ERROR: $msg');
        _consecutiveFailures++;
      });

      _flutterTts.setCancelHandler(() {
        debugPrint('[VOICE] CANCELLED');
      });

      await Future.wait([
        _flutterTts.setVolume(1.0),
        _flutterTts.setSpeechRate(0.5),
        _flutterTts.setPitch(1.0),
      ]).timeout(const Duration(seconds: 3));
      
      _isInitialized = true;
      _initCompleter!.complete();
      debugPrint('[VOICE] TTS INITIALIZED');
    } catch (e) {
      debugPrint('[VOICE] ERROR: Initialization failure: $e');
      _isInitialized = false;
      if (!_initCompleter!.isCompleted) _initCompleter!.complete();
      _initCompleter = null;
    }
  }

  Future<void> _resetEngine() async {
    if (kIsWeb) return;
    debugPrint('[VOICE] RECOVERY');
    try {
      await _flutterTts.stop();
      _isInitialized = false;
      _initCompleter = null;
      _consecutiveFailures = 0;
      await _ensureInitialized();
    } catch (e) {
      debugPrint('[VOICE] ERROR: Recovery exception: $e');
    }
  }

  String _getPreferredTtsCode(String code) {
    switch (code) {
      case 'en': return 'en-IN';
      case 'kn': return 'kn-IN';
      case 'hi': return 'hi-IN';
      case 'te': return 'te-IN';
      case 'ta': return 'ta-IN';
      case 'ml': return 'ml-IN';
      case 'mr': return 'mr-IN';
      case 'bn': return 'bn-IN';
      case 'gu': return 'gu-IN';
      case 'pa': return 'pa-IN';
      default: return 'en-IN';
    }
  }

  Future<String?> _discoverBestLanguage(String preferred, String base) async {
    try {
      final List<dynamic>? languages = await _flutterTts.getLanguages;
      if (languages == null || languages.isEmpty) return null;
      final List<String> available = languages.map((l) => l.toString()).toList();

      if (available.contains(preferred)) return preferred;
      final String underscore = preferred.replaceAll('-', '_');
      if (available.contains(underscore)) return underscore;
      
      if (base == 'en') {
        for (var code in ['en-US', 'en_US', 'en-GB', 'en_GB']) {
          if (available.contains(code)) return code;
        }
      }
      
      if (available.contains(base)) return base;
      for (String lang in available) {
        if (lang.toLowerCase().startsWith('$base-') || lang.toLowerCase().startsWith('${base}_')) {
          return lang;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[VOICE] ERROR: Discovery Error: $e');
      return null;
    }
  }

  Future<bool> speak(String text, Locale locale) async {
    if (kIsWeb) {
      debugPrint('[VOICE] SKIPPED: TTS is unavailable on this platform.');
      return false;
    }

    _queueCount++;
    debugPrint('[VOICE] QUEUED: ${locale.languageCode} (Queue: $_queueCount)');
    final Completer<bool> resultCompleter = Completer<bool>();
    
    // Chain onto the queue to ensure sequential execution
    _ttsQueue = _ttsQueue.then((_) async {
      _isProcessing = true;
      debugPrint('[VOICE] PROCESSING (Remaining: $_queueCount)');
      try {
        bool result = await _executeSpeak(text, locale);
        resultCompleter.complete(result);
      } catch (e) {
        debugPrint('[VOICE] ERROR: Queue task failed: $e');
        resultCompleter.complete(false);
      } finally {
        _queueCount--;
        _isProcessing = false;
        debugPrint('[VOICE] QUEUE CONTINUING');
        if (_queueCount == 0) debugPrint('[VOICE] QUEUE EMPTY');
      }
    }).catchError((e) {
      debugPrint('[VOICE] ERROR: Pipeline error: $e');
      _queueCount = 0;
      _isProcessing = false;
      if (!resultCompleter.isCompleted) resultCompleter.complete(false);
    });

    return resultCompleter.future;
  }

  Future<bool> _executeSpeak(String text, Locale locale) async {
    try {
      if (_consecutiveFailures >= _failureThreshold) {
        debugPrint('[VOICE] RECOVERY');
        await _resetEngine();
      }

      await _ensureInitialized();
      if (!_isInitialized) {
        debugPrint('[VOICE] SKIPPED: Not initialized');
        return false;
      }

      await _flutterTts.stop();

      final String preferred = _getPreferredTtsCode(locale.languageCode);
      final String? discovered = await _discoverBestLanguage(preferred, locale.languageCode);
      
      // Attempt the discovered locale if found, otherwise force the preferred one.
      // This ensures we always TRY instead of skipping with "No voice".
      final String selected = discovered ?? preferred;
      
      debugPrint('[VOICE] START: $selected');
      
      await _flutterTts.setLanguage(selected);
      
      final result = await _flutterTts.speak(text).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[VOICE] TIMEOUT');
          _consecutiveFailures++;
          return 0; 
        }
      );

      if (result == 1) {
        debugPrint('[VOICE] COMPLETE');
        return true;
      } else {
        debugPrint('[VOICE] ERROR: TTS SPEAK FAILED (result $result)');
        _consecutiveFailures++;
        return false;
      }
    } catch (e) {
      debugPrint('[VOICE] ERROR: Exception: $e');
      _consecutiveFailures++;
      return false;
    }
  }

  Future<void> stop() async {
    if (kIsWeb) return;
    _ttsQueue = _ttsQueue.then((_) async {
      try {
        await _flutterTts.stop();
      } catch (e) {
        debugPrint('[VOICE] ERROR: Stop failed: $e');
      }
    });
  }
}
