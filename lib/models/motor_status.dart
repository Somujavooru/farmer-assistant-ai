class MotorStatus {
  final bool isRunning;
  final DateTime? lastStartTime;
  final DateTime? lastStopTime;
  final Duration todayRuntime;
  final int startsToday;
  final double? motorCurrent; // Added for overload detection

  MotorStatus({
    required this.isRunning,
    this.lastStartTime,
    this.lastStopTime,
    this.todayRuntime = Duration.zero,
    this.startsToday = 0,
    this.motorCurrent,
  });

  String get currentRuntime {
    if (!isRunning || lastStartTime == null) return '00h 00m';
    final diff = DateTime.now().difference(lastStartTime!);
    return '${diff.inHours.toString().padLeft(2, '0')}h ${(diff.inMinutes % 60).toString().padLeft(2, '0')}m';
  }
}
