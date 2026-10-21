import 'package:flutter/material.dart';
import '../../models/paddy_condition.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

class PaddyConditionDetailScreen extends StatelessWidget {
  final PaddyCondition condition;

  const PaddyConditionDetailScreen({super.key, required this.condition});

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'moderate':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor(condition.severityGuidance);
    final typeColor = condition.isPest ? Colors.orange : Colors.purple;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(condition.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context, typeColor, severityColor),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              title: 'Observed Symptoms',
              icon: Icons.search,
              iconColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: condition.symptoms.map((symptom) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                        Expanded(child: Text(symptom, style: const TextStyle(fontSize: 13, height: 1.4))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              title: 'Affected Plant Part',
              icon: Icons.grass,
              iconColor: AppColors.secondary,
              child: Text(
                condition.affectedPart,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              title: 'Impact on Crop Growth & Yield',
              icon: Icons.trending_down,
              iconColor: AppColors.error,
              child: Text(
                condition.cropImpact,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              title: 'Safe Management Practices',
              icon: Icons.health_and_safety,
              iconColor: AppColors.success,
              child: Text(
                condition.managementPractices,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context,
              title: 'Prevention Practices',
              icon: Icons.shield_outlined,
              iconColor: AppColors.primary,
              child: Text(
                condition.preventionPractices,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            _buildExpertContactCard(context),
            const SizedBox(height: 16),
            _buildFutureAiNoteCard(context),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Color typeColor, Color severityColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    condition.type.toUpperCase(),
                    style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: severityColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${condition.severityGuidance.toUpperCase()} SEVERITY',
                    style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              condition.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Target Paddy / Rice Crop Condition',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildExpertContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.contact_support, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'When to Contact an Expert',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                ),
                const SizedBox(height: 4),
                Text(
                  condition.whenToContactExpert,
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureAiNoteCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Future Photo AI Integration Ready',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                ),
                SizedBox(height: 2),
                Text(
                  'When a trained Paddy Disease CNN model is connected, taking a leaf photo will automatically detect and open this condition page.',
                  style: TextStyle(fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
