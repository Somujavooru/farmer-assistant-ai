class PowerStatus {
  final bool isAvailable;
  final bool phase1Available;
  final bool phase2Available;
  final bool phase3Available;
  final DateTime? lastOnTime;
  final DateTime? lastOffTime;
  final double voltage;
  final double current;
  final double power;
  final double energy;
  final double frequency;
  final String phaseInfo; // e.g., "Normal", "Phase Missing", "Unbalanced"

  PowerStatus({
    required this.isAvailable,
    this.phase1Available = true,
    this.phase2Available = true,
    this.phase3Available = true,
    this.lastOnTime,
    this.lastOffTime,
    this.voltage = 0.0,
    this.current = 0.0,
    this.power = 0.0,
    this.energy = 0.0,
    this.frequency = 50.0,
    this.phaseInfo = 'Normal',
  });

  int get availablePhasesCount {
    int count = 0;
    if (phase1Available) count++;
    if (phase2Available) count++;
    if (phase3Available) count++;
    return count;
  }

  String get outageDuration {
    if (isAvailable || lastOffTime == null) return '0h 0m';
    final diff = DateTime.now().difference(lastOffTime!);
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  String get availableSince {
    if (!isAvailable || lastOnTime == null) return '--';
    final diff = DateTime.now().difference(lastOnTime!);
    return '${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}';
  }
}
