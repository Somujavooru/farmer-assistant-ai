class PaddyCondition {
  final String id;
  final String name;
  final String type; // 'Pest' or 'Disease'
  final List<String> symptoms;
  final String affectedPart; // e.g. Leaf, Stem, Grain, Whole Plant
  final String cropImpact;
  final String severityGuidance; // 'High', 'Moderate', 'Low'
  final String managementPractices;
  final String preventionPractices;
  final String whenToContactExpert;

  const PaddyCondition({
    required this.id,
    required this.name,
    required this.type,
    required this.symptoms,
    required this.affectedPart,
    required this.cropImpact,
    required this.severityGuidance,
    required this.managementPractices,
    required this.preventionPractices,
    required this.whenToContactExpert,
  });

  bool get isPest => type.toLowerCase() == 'pest';
  bool get isDisease => type.toLowerCase() == 'disease';
}
