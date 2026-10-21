import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/crop.dart';
import '../../models/crop_ai_result.dart';
import '../../models/paddy_condition.dart';
import '../../providers/farm_provider.dart';
import '../../services/crop_ai_service.dart';
import '../../services/paddy_knowledge_base.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import 'paddy_condition_detail_screen.dart';

class CropAiScreen extends StatefulWidget {
  final Crop? initialCrop;

  const CropAiScreen({super.key, this.initialCrop});

  @override
  State<CropAiScreen> createState() => _CropAiScreenState();
}

class _CropAiScreenState extends State<CropAiScreen> {
  final ImagePicker _picker = ImagePicker();
  final CropAiService _aiService = CropAiService();
  final TextEditingController _searchController = TextEditingController();

  File? _selectedImage;
  String? _selectedCropId;
  String _typeFilter = 'All'; // 'All', 'Pest', 'Disease'
  String _searchQuery = '';
  bool _isAnalyzing = false;
  CropAiResult? _analysisResult;

  @override
  void initState() {
    super.initState();
    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    _selectedCropId = widget.initialCrop?.id ??
        farmProvider.activeCrop?.id ??
        (farmProvider.crops.isNotEmpty ? farmProvider.crops.first.id : null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null; // Reset previous result for new photo
        });
      }
    } catch (e) {
      debugPrint('[CROP AI] Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${source == ImageSource.camera ? "camera" : "gallery"}: $e')),
        );
      }
    }
  }

  Future<void> _runAnalysis() async {
    if (_selectedImage == null) return;

    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    final crop = farmProvider.crops.where((c) => c.id == _selectedCropId).firstOrNull;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _aiService.analyzeLeafPhoto(
        imageFile: _selectedImage!,
        cropId: crop?.id ?? 'default_crop',
        cropName: crop?.name ?? 'Farm Crop',
      );

      if (mounted) {
        if (result != null) {
          setState(() {
            _analysisResult = result;
            _isAnalyzing = false;
          });
          // Save analysis result to farm history & persistent storage
          farmProvider.saveAiAnalysisResult(result);
        } else {
          setState(() {
            _isAnalyzing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to analyze image file. Please try again.')),
          );
        }
      }
    } catch (e) {
      debugPrint('[CROP AI] Analysis Error: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmProvider = Provider.of<FarmProvider>(context);
    final crops = farmProvider.crops;

    // Filter paddy conditions
    List<PaddyCondition> filteredConditions = PaddyKnowledgeBase.search(_searchQuery);
    if (_typeFilter != 'All') {
      filteredConditions = filteredConditions.where((c) => c.type.toLowerCase() == _typeFilter.toLowerCase()).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paddy Crop AI & Knowledge', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCropSelector(crops),
            const SizedBox(height: 16),
            _buildPhotoCaptureCard(),
            const SizedBox(height: 20),
            _buildKnowledgeHeader(),
            const SizedBox(height: 12),
            _buildSearchAndFilters(),
            const SizedBox(height: 16),
            if (filteredConditions.isEmpty)
              _buildEmptySearchState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredConditions.length,
                itemBuilder: (context, index) {
                  final condition = filteredConditions[index];
                  return _buildConditionCard(context, condition);
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCropSelector(List<Crop> crops) {
    if (crops.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No crop records found. Adding a crop record helps associate advisory notes.',
                style: TextStyle(fontSize: 11, color: Colors.amber),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<String>(
          initialValue: _selectedCropId ?? crops.first.id,
          decoration: const InputDecoration(
            labelText: 'Target Crop / Field',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.eco, color: AppColors.primary),
          ),
          items: crops.map((crop) {
            return DropdownMenuItem<String>(
              value: crop.id,
              child: Text('${crop.name} (${crop.field})'),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedCropId = val),
        ),
      ),
    );
  }

  Widget _buildPhotoCaptureCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_enhance, size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        const Text('Paddy Leaf Photo Capture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Take or select a photo of leaf symptoms or pests', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7))),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('CAMERA'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('GALLERY'),
                  ),
                ),
              ],
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _runAnalysis,
                  icon: _isAnalyzing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.psychology),
                  label: Text(_isAnalyzing ? 'ANALYZING LEAF PHOTO...' : 'ANALYZE LEAF PHOTO'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                ),
              ),
            ],
            if (_analysisResult != null) ...[
              const SizedBox(height: 16),
              _buildAnalysisResultCard(_analysisResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResultCard(CropAiResult result) {
    if (result.modelState == CropAiModelState.modelNotInstalled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.extension_off, color: Colors.orange, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Real Crop-Analysis Model Not Installed Yet',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.orange,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            const Text(
              'Photo-based AI diagnosis requires an offline trained TensorFlow Lite CNN model file.',
              style: TextStyle(fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.grey200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Model Installation Path:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  SizedBox(height: 4),
                  Text('1. Model File: assets/models/paddy_disease.tflite', style: TextStyle(fontSize: 11)),
                  Text('2. Labels File: assets/models/labels.txt', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please select the observed symptoms from the Paddy Knowledge Base below for immediate advisory.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
      );
    }

    if (!result.hasValidPrediction) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Unable to Identify / Non-Crop Image',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.amber,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Uncertain',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            const Text('Observations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            ...result.symptoms.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $s', style: const TextStyle(fontSize: 11, height: 1.3)),
                )),
            const SizedBox(height: 12),
            const Text('Guidance:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(result.recommendation, style: const TextStyle(fontSize: 12, height: 1.3)),
          ],
        ),
      );
    }

    final confidencePercent = ((result.confidence ?? 0.0) * 100).toStringAsFixed(0);
    final isHealthy = (result.predictedLabel ?? '').toLowerCase().contains('healthy');
    final cardColor = isHealthy ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  result.predictedLabel ?? 'Unknown Condition',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: cardColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$confidencePercent% Confidence',
                  style: TextStyle(
                    color: cardColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (result.diseaseType != null) ...[
            const SizedBox(height: 6),
            Text(
              'Type: ${result.diseaseType} • Affected Part: ${result.affectedPart ?? "Leaf"}',
              style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
            ),
          ],
          const Divider(height: 20),
          const Text('Observed Symptoms:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          ...result.symptoms.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $s', style: const TextStyle(fontSize: 11, height: 1.3)),
              )),
          const SizedBox(height: 12),
          const Text('Recommended Treatment:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(result.recommendation, style: const TextStyle(fontSize: 12, height: 1.3)),
          const SizedBox(height: 12),
          const Text('Prevention:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(result.prevention, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildKnowledgeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paddy Pest & Disease Knowledge Base',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Select any paddy condition below to view symptoms, crop impact, safe management, and expert advice.',
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search pests or diseases (e.g. BPH, Blast, Blight)...',
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (q) => setState(() => _searchQuery = q),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTypeFilterChip('All'),
            const SizedBox(width: 8),
            _buildTypeFilterChip('Pest'),
            const SizedBox(width: 8),
            _buildTypeFilterChip('Disease'),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeFilterChip(String type) {
    final isSelected = _typeFilter == type;
    return ChoiceChip(
      label: Text(type, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _typeFilter = type);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
    );
  }

  Widget _buildConditionCard(BuildContext context, PaddyCondition condition) {
    final typeColor = condition.isPest ? Colors.orange : Colors.purple;
    final isHigh = condition.severityGuidance.toLowerCase() == 'high';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaddyConditionDetailScreen(condition: condition),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  condition.isPest ? Icons.bug_report : Icons.coronavirus,
                  color: typeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            condition.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isHigh ? AppColors.error : AppColors.warning).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            condition.severityGuidance,
                            style: TextStyle(
                              color: isHigh ? AppColors.error : AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Part: ${condition.affectedPart}',
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      condition.symptoms.first,
                      style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant.withValues(alpha: 0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('No matching paddy condition found', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Try searching for BPH, Blast, Blight, Stem Borer or Gandhi Bug.', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
