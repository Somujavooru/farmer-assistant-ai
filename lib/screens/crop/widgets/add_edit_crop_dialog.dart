import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/crop.dart';

class AddEditCropDialog extends StatefulWidget {
  final Crop? crop;

  const AddEditCropDialog({super.key, this.crop});

  @override
  State<AddEditCropDialog> createState() => _AddEditCropDialogState();
}

class _AddEditCropDialogState extends State<AddEditCropDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _fieldController;
  late TextEditingController _areaController;
  late DateTime _plantingDate;
  late DateTime _harvestDate;
  String _selectedStage = 'Initial';
  String _healthStatus = 'Healthy';

  final List<String> _stages = ['Initial', 'Tillering', 'Flowering', 'Grain Filling', 'Maturity'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.crop?.name ?? '');
    _fieldController = TextEditingController(text: widget.crop?.field ?? '');
    _areaController = TextEditingController(text: widget.crop?.area.toString() ?? '');
    _plantingDate = widget.crop?.plantingDate ?? DateTime.now();
    _harvestDate = widget.crop?.expectedHarvestDate ?? DateTime.now().add(const Duration(days: 90));
    _selectedStage = widget.crop?.stage ?? 'Initial';
    _healthStatus = widget.crop?.healthStatus ?? 'Healthy';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fieldController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isPlanting) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPlanting ? _plantingDate : _harvestDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isPlanting) {
          _plantingDate = picked;
          if (_harvestDate.isBefore(_plantingDate)) {
            _harvestDate = _plantingDate.add(const Duration(days: 90));
          }
        } else {
          _harvestDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.crop == null ? 'Add New Crop' : 'Edit Crop Details'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Crop / Seed Name', hintText: 'e.g. Paddy, Wheat, Tomato'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter crop name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fieldController,
                decoration: const InputDecoration(labelText: 'Field / Farm Name', hintText: 'e.g. North Field, Main Farm'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter field name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: 'Area (Acres)', hintText: 'e.g. 2.5'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter area';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStage,
                decoration: const InputDecoration(labelText: 'Growth Stage'),
                items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedStage = val!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Planting Date', style: TextStyle(fontSize: 12)),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_plantingDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.calendar_today, size: 20),
                onTap: () => _selectDate(context, true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expected Harvest', style: TextStyle(fontSize: 12)),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_harvestDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.calendar_today, size: 20),
                onTap: () => _selectDate(context, false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newCrop = Crop(
                id: widget.crop?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text.trim(),
                field: _fieldController.text.trim(),
                area: double.parse(_areaController.text),
                plantingDate: _plantingDate,
                expectedHarvestDate: _harvestDate,
                stage: _selectedStage,
                healthStatus: _healthStatus,
                soilMoisture: widget.crop?.soilMoisture ?? 0.0,
                isActive: widget.crop?.isActive ?? true,
              );
              Navigator.pop(context, newCrop);
            }
          },
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
