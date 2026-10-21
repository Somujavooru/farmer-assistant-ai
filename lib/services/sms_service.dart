import 'dart:async';
import 'package:flutter/material.dart';

abstract class SmsService {
  Future<void> sendAlertSms(String message, String phoneNumber, Locale locale);
}

class MockSmsService implements SmsService {
  // Sequential SMS queue to prevent overlaps and ensure reliable auditing
  Future<void> _smsQueue = Future.value();
  int _queueCount = 0;

  @override
  Future<void> sendAlertSms(String message, String phoneNumber, Locale locale) async {
    _queueCount++;
    debugPrint('[SMS] QUEUED: ${locale.languageCode} (Queue: $_queueCount)');

    // Chain to queue for reliable sequential processing
    _smsQueue = _smsQueue.then((_) async {
      debugPrint('[SMS] PROCESSING (Remaining: $_queueCount)');
      try {
        await _executeMockSend(message, phoneNumber, locale);
      } catch (e) {
        debugPrint('[SMS] FAILED: $e');
      } finally {
        _queueCount--;
        debugPrint('[SMS] QUEUE CONTINUING');
        if (_queueCount == 0) debugPrint('[SMS] QUEUE EMPTY');
      }
    }).catchError((e) {
      debugPrint('[SMS] ERROR: Pipeline error: $e');
      _queueCount = 0;
    });
  }

  Future<void> _executeMockSend(String message, String phoneNumber, Locale locale) async {
    // Simulated network/processing delay
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('--- SMS SYSTEM AUDIT ---');
    debugPrint('Recipient: $phoneNumber');
    debugPrint('Language: ${locale.languageCode}');
    debugPrint('Message: $message');
    debugPrint('Status: Prepared (Waiting for Hardware Integration)');
    debugPrint('------------------------');
    
    debugPrint('[SMS] PREPARED');
  }
}
