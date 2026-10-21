import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/crop.dart';
import '../../models/alert.dart';
import '../../models/farm_history_item.dart';
import '../../providers/farm_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

class HistoryScreen extends StatefulWidget {
  final String? initialCropId;

  const HistoryScreen({super.key, this.initialCropId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _selectedCropFilter;
  FarmHistoryType? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    _selectedCropFilter = widget.initialCropId;
  }

  IconData _getItemIcon(FarmHistoryType type, Object original) {
    switch (type) {
      case FarmHistoryType.planting:
        return Icons.eco;
      case FarmHistoryType.expense:
        return Icons.account_balance_wallet;
      case FarmHistoryType.systemAlert:
        if (original is Alert) {
          if (original.severity == AlertSeverity.critical) return Icons.warning;
          if (original.severity == AlertSeverity.warning) return Icons.error_outline;
        }
        return Icons.notifications;
    }
  }

  Color _getItemColor(FarmHistoryType type, Object original) {
    switch (type) {
      case FarmHistoryType.planting:
        return AppColors.success;
      case FarmHistoryType.expense:
        return Colors.brown;
      case FarmHistoryType.systemAlert:
        if (original is Alert) {
          if (original.severity == AlertSeverity.critical) return AppColors.error;
          if (original.severity == AlertSeverity.warning) return AppColors.warning;
        }
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final crops = farmProvider.crops;
        final historyItems = farmProvider.getHistoryItems(
          filterCropId: _selectedCropFilter,
          filterType: _selectedTypeFilter,
        );

        final totalExpenses = historyItems
            .where((item) => item.type == FarmHistoryType.expense && item.amount != null)
            .fold(0.0, (sum, item) => sum + (item.amount ?? 0.0));

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Farm History', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              _buildCropFilterBar(context, crops),
              _buildTypeFilterBar(context),
              _buildSummaryHeader(context, historyItems.length, totalExpenses),
              Expanded(
                child: historyItems.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                        itemCount: historyItems.length,
                        itemBuilder: (context, index) {
                          final item = historyItems[index];
                          return _buildHistoryCard(context, item);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCropFilterBar(BuildContext context, List<Crop> crops) {
    if (crops.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: 6),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Crops & Overall Farm'),
            selected: _selectedCropFilter == null,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedCropFilter = null);
              }
            },
            selectedColor: AppColors.primary.withValues(alpha: 0.2),
            checkmarkColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
          ...crops.map((crop) {
            final isSelected = _selectedCropFilter == crop.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${crop.name} (${crop.field})'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCropFilter = selected ? crop.id : null;
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTypeFilterBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: 4),
      child: Row(
        children: [
          _buildChoiceChip('All Events', null),
          const SizedBox(width: 8),
          _buildChoiceChip('Plantings', FarmHistoryType.planting),
          const SizedBox(width: 8),
          _buildChoiceChip('Expenses', FarmHistoryType.expense),
          const SizedBox(width: 8),
          _buildChoiceChip('Alerts/Logs', FarmHistoryType.systemAlert),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, FarmHistoryType? type) {
    final isSelected = _selectedTypeFilter == type;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTypeFilter = selected ? type : null;
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, int totalEvents, double totalExpenses) {
    final currencyFormat = NumberFormat('#,##,##0.00');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryStat(
              context,
              'Total Events',
              '$totalEvents',
              Icons.history_toggle_off,
              AppColors.primary,
            ),
          ),
          Container(height: 30, width: 1, color: AppColors.grey200),
          Expanded(
            child: _buildSummaryStat(
              context,
              'Expenditure',
              '₹ ${currencyFormat.format(totalExpenses)}',
              Icons.account_balance_wallet,
              AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, FarmHistoryItem item) {
    final icon = _getItemIcon(item.type, item.originalObject);
    final color = _getItemColor(item.type, item.originalObject);
    final dateFormat = DateFormat('EEE, dd MMM yyyy • hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showHistoryDetailModal(context, item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.amount != null)
                          Text(
                            '₹ ${NumberFormat('#,##0').format(item.amount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(item.date),
                          style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
                        ),
                        if (item.cropName != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.cropName!,
                              style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'No history records found',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Plantings, expenses, and farm events will appear here in chronological order',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showHistoryDetailModal(BuildContext context, FarmHistoryItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getItemColor(item.type, item.originalObject).withValues(alpha: 0.1),
                    child: Icon(_getItemIcon(item.type, item.originalObject), color: _getItemColor(item.type, item.originalObject)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(DateFormat('EEEE, dd MMMM yyyy • hh:mm a').format(item.date), style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow('Description', item.subtitle),
              if (item.details != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Additional Details', item.details!),
              ],
              if (item.cropName != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Crop / Planting', item.cropName!),
              ],
              if (item.amount != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Amount', '₹ ${NumberFormat('#,##,##0.00').format(item.amount)}'),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
