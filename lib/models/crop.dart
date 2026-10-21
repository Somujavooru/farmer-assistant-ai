class Crop {
  final String id;
  final String name;
  final String stage;
  final DateTime plantingDate;
  final DateTime expectedHarvestDate;
  final double soilMoisture;
  final String healthStatus;
  final String? imageUrl;
  final String field;
  final double area;
  final String areaUnit;
  final bool isActive;

  Crop({
    required this.id,
    required this.name,
    required this.stage,
    required this.plantingDate,
    required this.expectedHarvestDate,
    required this.soilMoisture,
    required this.healthStatus,
    this.imageUrl,
    this.field = 'Main Field',
    this.area = 0.0,
    this.areaUnit = 'Acres',
    this.isActive = true,
  });

  int get daysSincePlanting {
    return DateTime.now().difference(plantingDate).inDays;
  }

  Crop copyWith({
    String? id,
    String? name,
    String? stage,
    DateTime? plantingDate,
    DateTime? expectedHarvestDate,
    double? soilMoisture,
    String? healthStatus,
    String? imageUrl,
    String? field,
    double? area,
    String? areaUnit,
    bool? isActive,
  }) {
    return Crop(
      id: id ?? this.id,
      name: name ?? this.name,
      stage: stage ?? this.stage,
      plantingDate: plantingDate ?? this.plantingDate,
      expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      healthStatus: healthStatus ?? this.healthStatus,
      imageUrl: imageUrl ?? this.imageUrl,
      field: field ?? this.field,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stage': stage,
      'plantingDate': plantingDate.toIso8601String(),
      'expectedHarvestDate': expectedHarvestDate.toIso8601String(),
      'soilMoisture': soilMoisture,
      'healthStatus': healthStatus,
      'imageUrl': imageUrl,
      'field': field,
      'area': area,
      'areaUnit': areaUnit,
      'isActive': isActive,
    };
  }

  factory Crop.fromMap(Map<String, dynamic> map) {
    return Crop(
      id: map['id'],
      name: map['name'],
      stage: map['stage'],
      plantingDate: DateTime.parse(map['plantingDate']),
      expectedHarvestDate: DateTime.parse(map['expectedHarvestDate']),
      soilMoisture: (map['soilMoisture'] as num).toDouble(),
      healthStatus: map['healthStatus'],
      imageUrl: map['imageUrl'],
      field: map['field'] ?? 'Main Field',
      area: (map['area'] as num?)?.toDouble() ?? 0.0,
      areaUnit: map['areaUnit'] ?? 'Acres',
      isActive: map['isActive'] ?? true,
    );
  }
}
