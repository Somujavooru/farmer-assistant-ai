enum CropAiModelState {
  modelNotInstalled,
  analyzing,
  validPrediction,
  lowConfidence,
  nonCropOrUnsupportedImage;

  String get displayName {
    switch (this) {
      case CropAiModelState.modelNotInstalled:
        return 'Real AI Model Not Installed Yet';
      case CropAiModelState.analyzing:
        return 'Analyzing Image Tensors...';
      case CropAiModelState.validPrediction:
        return 'Valid Model Prediction';
      case CropAiModelState.lowConfidence:
        return 'Low Confidence / Uncertain';
      case CropAiModelState.nonCropOrUnsupportedImage:
        return 'Non-Crop or Unrecognized Image';
    }
  }

  static CropAiModelState fromString(String val) {
    return CropAiModelState.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase().trim(),
      orElse: () => CropAiModelState.modelNotInstalled,
    );
  }
}

class CropAiResult {
  final String id;
  final String cropId;
  final String cropName;
  final String imagePath;
  final CropAiModelState modelState;
  final String? predictedLabel; // Null if no valid prediction
  final String? conditionId; // Matches PaddyCondition ID
  final String? diseaseType; // 'Pest', 'Disease', 'Healthy'
  final double? confidence; // Null or 0.0..1.0
  final String? severity; // 'High', 'Moderate', 'Low'
  final String? affectedPart;
  final List<String> symptoms;
  final String recommendation;
  final String prevention;
  final DateTime timestamp;

  CropAiResult({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.imagePath,
    required this.modelState,
    this.predictedLabel,
    this.conditionId,
    this.diseaseType,
    this.confidence,
    this.severity,
    this.affectedPart,
    required this.symptoms,
    required this.recommendation,
    required this.prevention,
    required this.timestamp,
  });

  bool get hasValidPrediction =>
      modelState == CropAiModelState.validPrediction &&
      predictedLabel != null &&
      confidence != null &&
      confidence! >= 0.50;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cropId': cropId,
      'cropName': cropName,
      'imagePath': imagePath,
      'modelState': modelState.name,
      'predictedLabel': predictedLabel,
      'conditionId': conditionId,
      'diseaseType': diseaseType,
      'confidence': confidence,
      'severity': severity,
      'affectedPart': affectedPart,
      'symptoms': symptoms,
      'recommendation': recommendation,
      'prevention': prevention,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CropAiResult.fromMap(Map<String, dynamic> map) {
    return CropAiResult(
      id: map['id'],
      cropId: map['cropId'] ?? '',
      cropName: map['cropName'] ?? '',
      imagePath: map['imagePath'] ?? '',
      modelState: CropAiModelState.fromString(map['modelState'] ?? 'modelNotInstalled'),
      predictedLabel: map['predictedLabel'],
      conditionId: map['conditionId'],
      diseaseType: map['diseaseType'],
      confidence: (map['confidence'] as num?)?.toDouble(),
      severity: map['severity'],
      affectedPart: map['affectedPart'],
      symptoms: map['symptoms'] != null ? List<String>.from(map['symptoms']) : [],
      recommendation: map['recommendation'] ?? '',
      prevention: map['prevention'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
