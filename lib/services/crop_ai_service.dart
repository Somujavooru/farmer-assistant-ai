import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/crop_ai_result.dart';
import '../models/paddy_condition.dart';
import 'paddy_knowledge_base.dart';

class CropAiConfig {
  final String modelAssetPath;
  final String labelsAssetPath;
  final int inputWidth;
  final int inputHeight;
  final int channels;
  final double confidenceThreshold;

  const CropAiConfig({
    this.modelAssetPath = 'assets/models/paddy_disease.tflite',
    this.labelsAssetPath = 'assets/models/labels.txt',
    this.inputWidth = 224,
    this.inputHeight = 224,
    this.channels = 3,
    this.confidenceThreshold = 0.35,
  });
}

class CropAiService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;
  final CropAiConfig config;

  CropAiService({this.config = const CropAiConfig()});

  bool get isModelLoaded => _isModelLoaded;

  Future<bool> checkModelInstalled() async {
    try {
      final ByteData data = await rootBundle.load(config.modelAssetPath);
      return data.lengthInBytes > 0;
    } catch (e) {
      debugPrint('[CROP AI] TFLite model asset not found at ${config.modelAssetPath}: $e');
      return false;
    }
  }

  Future<bool> initialize() async {
    try {
      final isInstalled = await checkModelInstalled();
      if (!isInstalled) {
        _isModelLoaded = false;
        return false;
      }

      final String assetName = config.modelAssetPath.replaceFirst('assets/', '');
      _interpreter = await Interpreter.fromAsset(assetName);
      await _loadLabels();

      _isModelLoaded = true;
      debugPrint('[CROP AI] TFLite model loaded successfully.');
      return true;
    } catch (e) {
      debugPrint('[CROP AI] Failed to initialize TFLite interpreter: $e');
      _isModelLoaded = false;
      return false;
    }
  }

  Future<void> _loadLabels() async {
    try {
      final String labelData = await rootBundle.loadString(config.labelsAssetPath);
      final List<String> lines = labelData.split('\n');
      _labels = lines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      debugPrint('[CROP AI] Loaded ${_labels.length} labels from ${config.labelsAssetPath}');
    } catch (e) {
      debugPrint('[CROP AI] Could not load labels file: $e');
      _labels = [];
    }
  }

  Future<CropAiResult> analyzeLeafPhoto({
    required File imageFile,
    required String cropId,
    required String cropName,
  }) async {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();

    // 1. Check if model is installed
    final isInstalled = await checkModelInstalled();
    if (!isInstalled) {
      return CropAiResult(
        id: id,
        cropId: cropId,
        cropName: cropName,
        imagePath: imageFile.path,
        modelState: CropAiModelState.modelNotInstalled,
        predictedLabel: null,
        confidence: null,
        symptoms: [
          'Real crop-analysis model (paddy_disease.tflite) is not installed in assets/models/'
        ],
        recommendation:
            'Photo-based AI diagnosis requires a trained TensorFlow Lite CNN model. Please place paddy_disease.tflite and labels.txt into assets/models/ to enable on-device inference.',
        prevention:
            'Use the Paddy Knowledge Base list below to explore symptoms and safe management practices.',
        timestamp: now,
      );
    }

    // 2. Initialize interpreter if needed
    if (!_isModelLoaded || _interpreter == null) {
      final ok = await initialize();
      if (!ok || _interpreter == null) {
        return CropAiResult(
          id: id,
          cropId: cropId,
          cropName: cropName,
          imagePath: imageFile.path,
          modelState: CropAiModelState.modelNotInstalled,
          predictedLabel: null,
          confidence: null,
          symptoms: ['Failed to initialize TFLite interpreter.'],
          recommendation: 'Check paddy_disease.tflite file in assets/models/.',
          prevention: 'Re-install valid TFLite model.',
          timestamp: now,
        );
      }
    }

    // 3. Read image bytes and run local TFLite inference
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        return CropAiResult(
          id: id,
          cropId: cropId,
          cropName: cropName,
          imagePath: imageFile.path,
          modelState: CropAiModelState.nonCropOrUnsupportedImage,
          predictedLabel: null,
          confidence: null,
          symptoms: ['Image file is empty or corrupted.'],
          recommendation: 'Please capture a clear photo of the paddy leaf.',
          prevention: 'Ensure camera lens is clean and well-lit.',
          timestamp: now,
        );
      }

      final int w = config.inputWidth;
      final int h = config.inputHeight;
      final int c = config.channels;

      // Tensor normalization matching MobileNetV3 (0.0 .. 1.0 or standard normalization)
      final List<double> inputBuffer = List<double>.filled(1 * h * w * c, 0.0);
      for (int i = 0; i < w * h; i++) {
        final int offset = (i * 4 < bytes.length) ? i * 4 : 0;
        inputBuffer[i * 3] = bytes[offset] / 255.0;
        inputBuffer[i * 3 + 1] = bytes[offset + 1] / 255.0;
        inputBuffer[i * 3 + 2] = bytes[offset + 2] / 255.0;
      }

      final input = inputBuffer.reshape([1, h, w, c]);
      final numLabels = _labels.isNotEmpty ? _labels.length : 10;
      final output = List<double>.filled(1 * numLabels, 0.0).reshape([1, numLabels]);

      _interpreter!.run(input, output);

      final List<double> probs = List<double>.from(output[0]);
      int maxIdx = 0;
      double maxProb = probs[0];

      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          maxIdx = i;
        }
      }

      // Rejection threshold for non-crop / low confidence images
      if (maxProb < config.confidenceThreshold) {
        return CropAiResult(
          id: id,
          cropId: cropId,
          cropName: cropName,
          imagePath: imageFile.path,
          modelState: CropAiModelState.lowConfidence,
          predictedLabel: null,
          confidence: maxProb,
          symptoms: [
            'Prediction confidence is too low (${(maxProb * 100).toStringAsFixed(1)}%).'
          ],
          recommendation:
              'The uploaded photo could not be reliably recognized as a known paddy condition. Please capture a clear close-up photo of the leaf or consult a local agricultural extension officer (KVK).',
          prevention:
              'Ensure bright daylight and hold the camera 15-20 cm away from the leaf.',
          timestamp: now,
        );
      }

      final String rawLabel = (maxIdx < _labels.length) ? _labels[maxIdx] : 'normal';
      final String formattedLabel = _formatLabelName(rawLabel);
      final PaddyCondition? condition = _matchKnowledgeCondition(rawLabel);

      return CropAiResult(
        id: id,
        cropId: cropId,
        cropName: cropName,
        imagePath: imageFile.path,
        modelState: CropAiModelState.validPrediction,
        predictedLabel: formattedLabel,
        conditionId: condition?.id,
        diseaseType: rawLabel == 'normal' ? 'Healthy' : (condition?.type ?? 'Disease'),
        confidence: maxProb,
        severity: rawLabel == 'normal' ? 'Low' : (condition?.severityGuidance ?? 'Moderate'),
        affectedPart: condition?.affectedPart ?? 'Leaf Blade',
        symptoms: condition?.symptoms ?? [formattedLabel],
        recommendation: rawLabel == 'normal'
            ? 'Crop foliage appears healthy! Maintain regular irrigation and balanced soil nutrient management.'
            : (condition?.managementPractices ?? 'Consult local agricultural extension officer for treatment.'),
        prevention: condition?.preventionPractices ?? 'Maintain clean fields and certified seed treatment.',
        timestamp: now,
      );
    } catch (e) {
      debugPrint('[CROP AI] TFLite inference error: $e');
      return CropAiResult(
        id: id,
        cropId: cropId,
        cropName: cropName,
        imagePath: imageFile.path,
        modelState: CropAiModelState.nonCropOrUnsupportedImage,
        predictedLabel: null,
        confidence: null,
        symptoms: ['Inference error: $e'],
        recommendation: 'Failed to process image tensor. Retake the photo in bright light.',
        prevention: 'Hold camera steady.',
        timestamp: now,
      );
    }
  }

  String _formatLabelName(String rawLabel) {
    switch (rawLabel.toLowerCase().trim()) {
      case 'bacterial_leaf_blight':
        return 'Bacterial Leaf Blight (BLB)';
      case 'bacterial_leaf_streak':
        return 'Bacterial Leaf Streak';
      case 'bacterial_panicle_blight':
        return 'Bacterial Panicle Blight';
      case 'blast':
        return 'Rice Blast (Pyricularia)';
      case 'brown_spot':
        return 'Brown Spot';
      case 'dead_heart':
        return 'Stem Borer (Dead Heart)';
      case 'downy_mildew':
        return 'Downy Mildew';
      case 'hispa':
        return 'Paddy Hispa Insect Damage';
      case 'normal':
        return 'Normal Healthy Paddy Leaf';
      case 'tungro':
        return 'Rice Tungro Virus';
      default:
        return rawLabel.replaceAll('_', ' ').toUpperCase();
    }
  }

  PaddyCondition? _matchKnowledgeCondition(String rawLabel) {
    final clean = rawLabel.toLowerCase().replaceAll('_', ' ').trim();
    for (var c in PaddyKnowledgeBase.conditions) {
      if (c.name.toLowerCase().contains(clean) || clean.contains(c.name.toLowerCase()) || c.id.toLowerCase().contains(clean)) {
        return c;
      }
    }
    return null;
  }

  void dispose() {
    try {
      _interpreter?.close();
      _interpreter = null;
      _isModelLoaded = false;
    } catch (e) {
      debugPrint('[CROP AI] Error disposing TFLite interpreter: $e');
    }
  }
}
