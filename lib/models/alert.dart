enum AlertSeverity { critical, important, normal, information, success, warning }

class Alert {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final AlertSeverity severity;
  final bool isRead;

  Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.severity,
    this.isRead = false,
  });

  Alert copyWith({bool? isRead}) {
    return Alert(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      severity: severity,
      isRead: isRead ?? this.isRead,
    );
  }
}
