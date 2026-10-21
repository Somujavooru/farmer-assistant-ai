import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/crop.dart';
import '../../models/expense.dart';
import '../../providers/farm_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import 'widgets/add_edit_expense_dialog.dart';

class ExpensesScreen extends StatefulWidget {
  final String? initialCropId;

  const ExpensesScreen({super.key, this.initialCropId});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String? _selectedCropFilter;

  @override
  void initState() {
    super.initState();
    _selectedCropFilter = widget.initialCropId;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Seeds':
        return Icons.eco;
      case 'Fertilizer':
        return Icons.science;
      case 'Labour':
        return Icons.people;
      case 'Pesticide':
        return Icons.bug_report;
      case 'Irrigation/Electricity':
        return Icons.flash_on;
      case 'Machinery':
        return Icons.build;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmProvider>(
      builder: (context, farmProvider, child) {
        final crops = farmProvider.crops;
        final allExpenses = farmProvider.expenses;

        // Apply crop filter
        final filteredExpenses = _selectedCropFilter == null
            ? allExpenses
            : allExpenses.where((e) => e.cropId == _selectedCropFilter).toList();

        final totalAmount = _selectedCropFilter == null
            ? farmProvider.getOverallTotalExpense()
            : farmProvider.getTotalExpenseForCrop(_selectedCropFilter!);

        final breakdown = farmProvider.getCategoryBreakdown(cropId: _selectedCropFilter);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Farm Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              _buildCropFilterBar(context, crops),
              _buildTotalSummary(context, totalAmount, breakdown),
              Expanded(
                child: filteredExpenses.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
                        itemCount: filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = filteredExpenses[index];
                          final crop = crops.where((c) => c.id == expense.cropId).firstOrNull;
                          return _buildExpenseCard(context, farmProvider, expense, crop);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddExpenseDialog(context, farmProvider),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('ADD EXPENSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildCropFilterBar(BuildContext context, List<Crop> crops) {
    if (crops.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Crops'),
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

  Widget _buildTotalSummary(BuildContext context, double totalAmount, Map<String, double> breakdown) {
    // Sort breakdown by highest amount and pick top 3
    final sortedCategories = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(3).toList();

    return Container(
      margin: const EdgeInsets.all(AppConstants.screenPadding),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCropFilter == null ? 'Total Farm Expenditure' : 'Crop Expenditure',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹ ${NumberFormat('#,##,##0.00').format(totalAmount)}',
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
          if (topCategories.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: topCategories.map((entry) {
                return _buildMiniStat(entry.key, '₹ ${NumberFormat('#,##0').format(entry.value)}');
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    FarmProvider farmProvider,
    Expense expense,
    Crop? crop,
  ) {
    final currencyFormat = NumberFormat('#,##,##0.00');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(_getCategoryIcon(expense.category), color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        expense.description,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '₹ ${currencyFormat.format(expense.amount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          expense.category,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM yyyy').format(expense.date),
                        style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                  if (crop != null || expense.field != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Crop: ${crop?.name ?? "Unknown"} • Field: ${expense.field ?? crop?.field ?? "N/A"}',
                      style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: AppColors.onSurfaceVariant),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
              ],
              onSelected: (action) {
                if (action == 'edit') {
                  _showEditExpenseDialog(context, farmProvider, expense);
                } else if (action == 'delete') {
                  _confirmDeleteExpense(context, farmProvider, expense);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'No expenses recorded yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your seeds, fertilizer, labour, and irrigation costs',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddExpenseDialog(BuildContext context, FarmProvider farmProvider) async {
    final result = await showDialog<Expense>(
      context: context,
      builder: (context) => AddEditExpenseDialog(initialCropId: _selectedCropFilter),
    );

    if (result != null) {
      farmProvider.addExpense(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully')),
        );
      }
    }
  }

  Future<void> _showEditExpenseDialog(BuildContext context, FarmProvider farmProvider, Expense expense) async {
    final result = await showDialog<Expense>(
      context: context,
      builder: (context) => AddEditExpenseDialog(expense: expense),
    );

    if (result != null) {
      farmProvider.updateExpense(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense updated successfully')),
        );
      }
    }
  }

  void _confirmDeleteExpense(BuildContext context, FarmProvider farmProvider, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete this expense of ₹ ${expense.amount.toStringAsFixed(2)} for ${expense.description}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              farmProvider.deleteExpense(expense.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Expense deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
