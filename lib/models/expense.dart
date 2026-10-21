class Expense {
  final String id;
  final String cropId;
  final String category;
  final double amount;
  final DateTime date;
  final String description;
  final String? field;

  Expense({
    required this.id,
    required this.cropId,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    this.field,
  });

  Expense copyWith({
    String? id,
    String? cropId,
    String? category,
    double? amount,
    DateTime? date,
    String? description,
    String? field,
  }) {
    return Expense(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      field: field ?? this.field,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cropId': cropId,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'field': field,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      cropId: map['cropId'],
      category: map['category'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      description: map['description'] ?? '',
      field: map['field'],
    );
  }

  static const List<String> categories = [
    'Seeds',
    'Fertilizer',
    'Labour',
    'Pesticide',
    'Irrigation/Electricity',
    'Machinery',
    'Other',
  ];
}
