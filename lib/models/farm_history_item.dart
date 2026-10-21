enum FarmHistoryType {
  planting,
  expense,
  systemAlert,
}

class FarmHistoryItem {
  final String id;
  final FarmHistoryType type;
  final DateTime date;
  final String title;
  final String subtitle;
  final String? details;
  final String? cropId;
  final String? cropName;
  final double? amount;
  final Object originalObject;

  FarmHistoryItem({
    required this.id,
    required this.type,
    required this.date,
    required this.title,
    required this.subtitle,
    this.details,
    this.cropId,
    this.cropName,
    this.amount,
    required this.originalObject,
  });
}
