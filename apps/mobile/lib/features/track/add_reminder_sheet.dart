import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/design_system.dart';
import '../../models/meal_plan.dart';
import 'track_providers.dart';

const _allDays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

Future<void> showAddReminderSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _AddReminderSheet(),
  );
}

class _AddReminderSheet extends ConsumerStatefulWidget {
  const _AddReminderSheet();

  @override
  ConsumerState<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<bool> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return false;
    try {
      final timeString =
          '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
      await ref.read(medicineReminderServiceProvider).addReminder(
            MedicineReminder(
              id: '',
              patientId: '',
              medicineName: name,
              dosage: _dosageController.text.trim().isEmpty ? null : _dosageController.text.trim(),
              schedule: [MedicineScheduleEntry(time: timeString, days: _allDays)],
              active: true,
            ),
          );
      ref.invalidate(activeRemindersProvider);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save. $e')));
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a reminder', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Medicine name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dosageController,
            decoration: const InputDecoration(labelText: 'Dosage (optional)'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Daily reminder time'),
            subtitle: Text(_time.format(context)),
            trailing: TextButton(onPressed: _pickTime, child: const Text('Change')),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AnimatedConfirmButton(
              label: 'Save reminder',
              successLabel: 'Saved',
              onPressed: _submit,
              onSuccessComplete: () {
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
