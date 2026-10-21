import 'package:flutter/material.dart';
import '../../../models/motor_schedule.dart';
import '../../../theme/app_colors.dart';

class AddEditScheduleDialog extends StatefulWidget {
  final MotorSchedule? schedule;

  const AddEditScheduleDialog({super.key, this.schedule});

  @override
  State<AddEditScheduleDialog> createState() => _AddEditScheduleDialogState();
}

class _AddEditScheduleDialogState extends State<AddEditScheduleDialog> {
  late TimeOfDay _onTime;
  late TimeOfDay _offTime;
  late List<int> _repeatDays;
  late TextEditingController _labelController;

  final List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _onTime = widget.schedule?.onTime ?? const TimeOfDay(hour: 6, minute: 0);
    _offTime = widget.schedule?.offTime ?? const TimeOfDay(hour: 8, minute: 0);
    _repeatDays = List<int>.from(widget.schedule?.repeatDays ?? [1, 2, 3, 4, 5, 6, 7]);
    _labelController = TextEditingController(text: widget.schedule?.label ?? 'Motor Schedule');
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isOnTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOnTime ? _onTime : _offTime,
    );
    if (picked != null) {
      setState(() {
        if (isOnTime) {
          _onTime = picked;
        } else {
          _offTime = picked;
        }
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_repeatDays.contains(day)) {
        _repeatDays.remove(day);
      } else {
        _repeatDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.schedule == null ? 'Add Schedule' : 'Edit Schedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Schedule Label',
                hintText: 'e.g., Morning Irrigation',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Motor ON Time', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              title: Text(_onTime.format(context), style: const TextStyle(fontSize: 20)),
              trailing: const Icon(Icons.access_time, color: AppColors.primary),
              onTap: () => _selectTime(context, true),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            const Text('Motor OFF Time', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              title: Text(_offTime.format(context), style: const TextStyle(fontSize: 20)),
              trailing: const Icon(Icons.access_time, color: AppColors.error),
              onTap: () => _selectTime(context, false),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            const Text('Repeat on', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = _repeatDays.contains(day);
                return FilterChip(
                  label: Text(_dayNames[index]),
                  selected: isSelected,
                  onSelected: (_) => _toggleDay(day),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_onTime == _offTime) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ON and OFF times cannot be the same.')),
              );
              return;
            }
            if (_repeatDays.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select at least one day.')),
              );
              return;
            }

            final newSchedule = MotorSchedule(
              id: widget.schedule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              onTime: _onTime,
              offTime: _offTime,
              repeatDays: _repeatDays,
              label: _labelController.text,
              enabled: widget.schedule?.enabled ?? true,
            );
            Navigator.pop(context, newSchedule);
          },
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
