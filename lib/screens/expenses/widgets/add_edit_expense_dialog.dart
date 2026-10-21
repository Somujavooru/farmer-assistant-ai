import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/expense.dart';
import '../../../providers/farm_provider.dart';

class AddEditExpenseDialog extends StatefulWidget {
  final Expense? expense;
  final String? initialCropId;

  const AddEditExpenseDialog({
    super.key,
    this.expense,
    this.initialCropId,
  });

  @override
  State<AddEditExpenseDialog> createState() => _AddEditExpenseDialogState();
}

class _AddEditExpenseDialogState extends State<AddEditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCropId;
  late String _selectedCategory;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _fieldController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final farmProvider = Provider.of<FarmProvider>(context, listen: false);
    final activeCrop = farmProvider.activeCrop;

    _selectedCropId = widget.expense?.cropId ??
        widget.initialCropId ??
        (activeCrop?.id ?? (farmProvider.crops.isNotEmpty ? farmProvider.crops.first.id : ''));

    _selectedCategory = widget.expense?.category ?? Expense.categories.first;
    _amountController = TextEditingController(
      text: widget.expense != null ? widget.expense!.amount.toStringAsFixed(2) : '',
    );
    _descriptionController = TextEditingController(text: widget.expense?.description ?? '');
    
    // Default field to crop's field if available
    String defaultField = widget.expense?.field ?? '';
    if (defaultField.isEmpty && _selectedCropId.isNotEmpty) {
      final crop = farmProvider.crops.where((c) => c.id == _selectedCropId).firstOrNull;
      if (crop != null) {
        defaultField = crop.field;
      }
    }
    _fieldController = TextEditingController(text: defaultField);
    _selectedDate = widget.expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _fieldController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onCropChanged(String? newCropId) {
    if (newCropId == null) return;
    setState(() {
      _selectedCropId = newCropId;
      final farmProvider = Provider.of<FarmProvider>(context, listen: false);
      final crop = farmProvider.crops.where((c) => c.id == newCropId).firstOrNull;
      if (crop != null && _fieldController.text.isEmpty) {
        _fieldController.text = crop.field;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final farmProvider = Provider.of<FarmProvider>(context);
    final crops = farmProvider.crops;

    return AlertDialog(
      title: Text(widget.expense == null ? 'Add Farm Expense' : 'Edit Expense'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (crops.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Text(
                    'Note: No crop records exist yet. Please add a crop record first or enter details.',
                    style: TextStyle(fontSize: 12, color: Colors.amber),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedCropId.isNotEmpty ? _selectedCropId : crops.first.id,
                  decoration: const InputDecoration(
                    labelText: 'Associated Crop / Planting',
                    prefixIcon: Icon(Icons.eco),
                  ),
                  items: crops.map((crop) {
                    return DropdownMenuItem<String>(
                      value: crop.id,
                      child: Text(
                        '${crop.name} (${crop.field})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: _onCropChanged,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Please select a crop' : null,
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Expense Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: Expense.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: 'e.g. 2500',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description / Notes',
                  hintText: 'e.g. 2 bags of NPK fertilizer',
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fieldController,
                decoration: const InputDecoration(
                  labelText: 'Field / Farm (Optional)',
                  hintText: 'e.g. North Plot',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Expense Date', style: TextStyle(fontSize: 12)),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.edit_calendar, size: 20),
                onTap: () => _selectDate(context),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final amount = double.parse(_amountController.text.trim());
              final expense = Expense(
                id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                cropId: _selectedCropId.isNotEmpty
                    ? _selectedCropId
                    : 'default_crop',
                category: _selectedCategory,
                amount: amount,
                date: _selectedDate,
                description: _descriptionController.text.trim(),
                field: _fieldController.text.trim().isNotEmpty
                    ? _fieldController.text.trim()
                    : null,
              );
              Navigator.pop(context, expense);
            }
          },
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
