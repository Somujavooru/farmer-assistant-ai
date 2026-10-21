import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/motor_schedule.dart';

class SchedulerProvider with ChangeNotifier {
  List<MotorSchedule> _schedules = [];
  Timer? _timer;
  
  // Callback to trigger the actual motor command
  Future<void> Function(bool)? onTriggerMotor;
  
  // Safety check callback to see if power is available
  bool Function()? isPowerAvailable;

  // Tracker for executed occurrences to prevent loops and duplicate triggers
  // Format: "scheduleId_YYYY-MM-DD_action" (action is "ON" or "OFF")
  final Set<String> _executedOccurrences = {};

  List<MotorSchedule> get schedules => _schedules;

  SchedulerProvider() {
    _loadSchedules();
    _startTimer();
  }

  Future<void> _loadSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? schedulesJson = prefs.getString('motor_schedules');
      if (schedulesJson != null) {
        final List<dynamic> decoded = jsonDecode(schedulesJson);
        _schedules = decoded.map((item) => MotorSchedule.fromMap(item)).toList();
        
        // Clean up old executed occurrences (older than today)
        _pruneExecutedOccurrences();
        
        notifyListeners();
        _logNextOccurrence();
      }
    } catch (e) {
      debugPrint('[SCHEDULER] Error loading schedules: $e');
    }
  }

  void _pruneExecutedOccurrences() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _executedOccurrences.removeWhere((key) => !key.contains(today));
  }

  Future<void> _saveSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_schedules.map((s) => s.toMap()).toList());
      await prefs.setString('motor_schedules', encoded);
      _logNextOccurrence();
    } catch (e) {
      debugPrint('[SCHEDULER] Error saving schedules: $e');
    }
  }

  void addSchedule(MotorSchedule schedule) {
    _schedules.add(schedule);
    _saveSchedules();
    notifyListeners();
  }

  void updateSchedule(MotorSchedule updated) {
    final index = _schedules.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      _schedules[index] = updated;
      _saveSchedules();
      notifyListeners();
    }
  }

  void deleteSchedule(String id) {
    _schedules.removeWhere((s) => s.id == id);
    _saveSchedules();
    notifyListeners();
  }

  void toggleSchedule(String id, bool enabled) {
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      _schedules[index] = _schedules[index].copyWith(enabled: enabled);
      _saveSchedules();
      notifyListeners();
    }
  }

  void _startTimer() {
    // Check every 30 seconds for precision
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkSchedules();
    });
  }

  void _checkSchedules() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final hour = now.hour;
    final minute = now.minute;
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    debugPrint('[SCHEDULER] Checking at ${DateFormat('HH:mm:ss').format(now)}');

    for (var schedule in _schedules) {
      if (!schedule.enabled) continue;
      if (!schedule.repeatDays.contains(weekday)) continue;

      // Check ON time
      if (schedule.onTime.hour == hour && schedule.onTime.minute == minute) {
        final key = '${schedule.id}_${dateStr}_ON';
        if (!_executedOccurrences.contains(key)) {
          _executedOccurrences.add(key);
          _triggerAction(true, schedule, key);
        } else {
          // Log only once per minute to avoid spam
          if (now.second < 5) debugPrint('[SCHEDULER] ON already executed for today: ${schedule.label}');
        }
      }

      // Check OFF time
      if (schedule.offTime.hour == hour && schedule.offTime.minute == minute) {
        final key = '${schedule.id}_${dateStr}_OFF';
        if (!_executedOccurrences.contains(key)) {
          _executedOccurrences.add(key);
          _triggerAction(false, schedule, key);
        } else {
          if (now.second < 5) debugPrint('[SCHEDULER] OFF already executed for today: ${schedule.label}');
        }
      }
    }
    
    // Prune periodically (at midnight)
    if (hour == 0 && minute == 0 && now.second < 35) {
      _pruneExecutedOccurrences();
    }
  }

  void _triggerAction(bool turnOn, MotorSchedule schedule, String occurrenceKey) {
    debugPrint('[MOTOR COMMAND] SCHEDULED ${turnOn ? "ON" : "OFF"}');
    debugPrint('[SCHEDULER] ${turnOn ? "ON" : "OFF"} EXECUTED: $occurrenceKey (${schedule.label})');
    
    if (isPowerAvailable != null && !isPowerAvailable!()) {
      debugPrint('[SCHEDULER] Motor ${turnOn ? "ON" : "OFF"} requested but Power unavailable. Command skipped for safety.');
      return;
    }

    if (onTriggerMotor != null) {
      onTriggerMotor!(turnOn);
    } else {
      debugPrint('[SCHEDULER] Waiting for hardware integration (No handler registered)');
    }
  }

  void _logNextOccurrence() {
    final next = _calculateNextAction();
    if (next != null) {
      debugPrint('[SCHEDULER] Next occurrence: ${next.isStart ? "ON" : "OFF"} at ${DateFormat('yyyy-MM-dd HH:mm').format(next.time)}');
    } else {
      debugPrint('[SCHEDULER] No upcoming occurrences');
    }
  }

  String getNextActionText() {
    final next = _calculateNextAction();
    if (next == null) return 'None scheduled';
    
    final now = DateTime.now();
    final isToday = next.time.day == now.day && next.time.month == now.month && next.time.year == now.year;
    final dayStr = isToday ? 'Today' : DateFormat('EEEE').format(next.time);
    final timeStr = DateFormat('hh:mm a').format(next.time);
    
    return 'Motor ${next.isStart ? "ON" : "OFF"}\n$dayStr, $timeStr';
  }

  _NextAction? _calculateNextAction() {
    if (_schedules.isEmpty) return null;

    final now = DateTime.now();
    final dateTodayStr = DateFormat('yyyy-MM-dd').format(now);
    _NextAction? earliest;

    for (var schedule in _schedules) {
      if (!schedule.enabled) continue;

      for (int weekday in schedule.repeatDays) {
        // ON Time
        DateTime onTime = _getNextOccurrence(now, weekday, schedule.onTime);
        final onKey = '${schedule.id}_${DateFormat('yyyy-MM-dd').format(onTime)}_ON';
        
        // If it's today and already executed, find next week's
        if (DateFormat('yyyy-MM-dd').format(onTime) == dateTodayStr && _executedOccurrences.contains(onKey)) {
          onTime = onTime.add(const Duration(days: 7));
        }

        if (earliest == null || onTime.isBefore(earliest.time)) {
          earliest = _NextAction(time: onTime, isStart: true, schedule: schedule);
        }

        // OFF Time
        DateTime offTime = _getNextOccurrence(now, weekday, schedule.offTime);
        final offKey = '${schedule.id}_${DateFormat('yyyy-MM-dd').format(offTime)}_OFF';

        if (DateFormat('yyyy-MM-dd').format(offTime) == dateTodayStr && _executedOccurrences.contains(offKey)) {
          offTime = offTime.add(const Duration(days: 7));
        }

        if (offTime.isBefore(earliest.time)) {
          earliest = _NextAction(time: offTime, isStart: false, schedule: schedule);
        }
      }
    }

    return earliest;
  }

  DateTime _getNextOccurrence(DateTime now, int weekday, TimeOfDay time) {
    DateTime scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    int daysUntil = (weekday - now.weekday) % 7;
    if (daysUntil < 0) daysUntil += 7;
    
    scheduled = scheduled.add(Duration(days: daysUntil));
    
    // If it's today and the time has already passed, move to next week
    if (daysUntil == 0 && scheduled.isBefore(now)) {
      // Check if it's currently the same minute (allow trigger)
      if (scheduled.hour == now.hour && scheduled.minute == now.minute) {
        // Keep it as today
      } else {
        scheduled = scheduled.add(const Duration(days: 7));
      }
    }
    
    return scheduled;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _NextAction {
  final DateTime time;
  final bool isStart;
  final MotorSchedule schedule;

  _NextAction({required this.time, required this.isStart, required this.schedule});
}
