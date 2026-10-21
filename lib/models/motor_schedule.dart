import 'package:flutter/material.dart';

class MotorSchedule {
  final String id;
  final TimeOfDay onTime;
  final TimeOfDay offTime;
  final List<int> repeatDays; // 1 = Monday, 7 = Sunday (standard DateTime.weekday)
  final bool enabled;
  final String label;

  MotorSchedule({
    required this.id,
    required this.onTime,
    required this.offTime,
    required this.repeatDays,
    this.enabled = true,
    this.label = 'Motor Schedule',
  });

  MotorSchedule copyWith({
    String? id,
    TimeOfDay? onTime,
    TimeOfDay? offTime,
    List<int>? repeatDays,
    bool? enabled,
    String? label,
  }) {
    return MotorSchedule(
      id: id ?? this.id,
      onTime: onTime ?? this.onTime,
      offTime: offTime ?? this.offTime,
      repeatDays: repeatDays ?? this.repeatDays,
      enabled: enabled ?? this.enabled,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'onHour': onTime.hour,
      'onMinute': onTime.minute,
      'offHour': offTime.hour,
      'offMinute': offTime.minute,
      'repeatDays': repeatDays,
      'enabled': enabled,
      'label': label,
    };
  }

  factory MotorSchedule.fromMap(Map<String, dynamic> map) {
    return MotorSchedule(
      id: map['id'],
      onTime: TimeOfDay(hour: map['onHour'], minute: map['onMinute']),
      offTime: TimeOfDay(hour: map['offHour'], minute: map['offMinute']),
      repeatDays: List<int>.from(map['repeatDays']),
      enabled: map['enabled'],
      label: map['label'] ?? 'Motor Schedule',
    );
  }

  String get repeatDaysText {
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.isEmpty) return 'No days selected';
    
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selected = repeatDays.map((d) => days[d - 1]).toList();
    return selected.join(', ');
  }
}
