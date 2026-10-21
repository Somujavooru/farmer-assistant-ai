import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/farm_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import 'package:intl/intl.dart';
import '../../models/crop.dart';
import '../expenses/expenses_screen.dart';
import '../history/history_screen.dart';
import '../crop_ai/crop_ai_screen.dart';
import 'widgets/add_edit_crop_dialog.dart';

class CropScreen extends StatelessWidget {
  const CropScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Crop Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditCropDialog(context),
          ),
        ],
      ),
      body: Consumer<FarmProvider>(
        builder: (context, provider, child) {
          final activeCrop = provider.activeCrop;
          final archivedCrops = provider.crops.where((c) => !c.isActive).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeCrop != null) ...[
                  Text(
                    'Active Crop',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildCropStatusCard(context, activeCrop, provider),
                ] else ...[
                  _buildEmptyCropState(context),
                ],
                const SizedBox(height: 24),
                _buildAIAnalysisSection(context),
                const SizedBox(height: 24),
                if (archivedCrops.isNotEmpty) ...[
                  Text(
                    'Previous Crops',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: archivedCrops.length,
                    itemBuilder: (context, index) {
                      final crop = archivedCrops[index];
                      return _buildArchivedCropItem(context, crop, provider);
                    },
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCropState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.eco_outlined, size: 80, color: AppColors.onSurfaceVariant.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('No active crop record'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showAddEditCropDialog(context),
              child: const Text('ADD YOUR FIRST CROP'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropStatusCard(BuildContext context, Crop crop, FarmProvider provider) {
    final cropTotalExpense = provider.getTotalExpenseForCrop(crop.id);
    final currencyFormat = NumberFormat('#,##,##0.00');

    return FadeInDown(
      child: Card(
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Icon(Icons.eco, size: 60, color: AppColors.primary),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          crop.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          crop.healthStatus,
                          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(crop.field, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('Current Stage: ${crop.stage}', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn('Planted', '${crop.daysSincePlanting} days ago'),
                      _buildInfoColumn('Area', '${crop.area} ${crop.areaUnit}'),
                      _buildInfoColumn('Soil Moisture', '${crop.soilMoisture}%'),
                      _buildInfoColumn('Total Spent', '₹ ${currencyFormat.format(cropTotalExpense)}'),
                    ],
                  ),
                  const Divider(height: 32),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HistoryScreen(initialCropId: crop.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('HISTORY'),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExpensesScreen(initialCropId: crop.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                          label: const Text('EXPENSES'),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: () => _showAddEditCropDialog(context, crop),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('EDIT'),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: () => _showArchiveConfirmation(context, crop, provider),
                          icon: const Icon(Icons.archive_outlined, size: 18),
                          label: const Text('ARCHIVE'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedCropItem(BuildContext context, Crop crop, FarmProvider provider) {
    final cropTotalExpense = provider.getTotalExpenseForCrop(crop.id);
    final currencyFormat = NumberFormat('#,##,##0.00');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.grey200,
          child: Icon(Icons.history, color: AppColors.onSurfaceVariant),
        ),
        title: Text(crop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${crop.field} • ${crop.area} ${crop.areaUnit} • Spent: ₹ ${currencyFormat.format(cropTotalExpense)}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'history', child: Row(children: [Icon(Icons.history, size: 18), SizedBox(width: 8), Text('View History')])),
            const PopupMenuItem(value: 'expenses', child: Row(children: [Icon(Icons.account_balance_wallet_outlined, size: 18), SizedBox(width: 8), Text('View Expenses')])),
            const PopupMenuItem(value: 'restore', child: Row(children: [Icon(Icons.restore, size: 18), SizedBox(width: 8), Text('Restore as Active')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete Permanently', style: TextStyle(color: AppColors.error))])),
          ],
          onSelected: (val) {
            if (val == 'history') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(initialCropId: crop.id),
                ),
              );
            } else if (val == 'expenses') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpensesScreen(initialCropId: crop.id),
                ),
              );
            } else if (val == 'restore') {
              provider.updateCrop(crop.copyWith(isActive: true));
              provider.setActiveCrop(crop.id);
            } else if (val == 'delete') {
              provider.deleteCrop(crop.id);
            }
          },
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildAIAnalysisSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Health Check',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAICard(
                context,
                'Crop Disease',
                'Identify pests or disease',
                Icons.bug_report,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CropAiScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAICard(
                context,
                'Starter Panel',
                'Check motor electricals',
                Icons.electrical_services,
                Colors.blue,
                () {
                  _showAnalysisDialog(context, 'Starter Panel');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAICard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  void _showAnalysisDialog(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AI Analysis: $title',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Spacer(),
              const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Take a photo to analyze'),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CropAiScreen()),
                  );
                },
                icon: const Icon(Icons.camera),
                label: const Text('OPEN CAMERA'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CropAiScreen()),
                  );
                },
                child: const Text('CHOOSE FROM GALLERY'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddEditCropDialog(BuildContext context, [Crop? crop]) async {
    final provider = Provider.of<FarmProvider>(context, listen: false);
    final result = await showDialog<Crop>(
      context: context,
      builder: (context) => AddEditCropDialog(crop: crop),
    );

    if (result != null) {
      if (crop == null) {
        provider.addCrop(result);
      } else {
        provider.updateCrop(result);
      }
    }
  }

  void _showArchiveConfirmation(BuildContext context, Crop crop, FarmProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Crop'),
        content: Text('Are you sure you want to archive "${crop.name}"? It will move to previous crops.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              provider.archiveCrop(crop.id);
              Navigator.pop(context);
            },
            child: const Text('ARCHIVE'),
          ),
        ],
      ),
    );
  }
}
