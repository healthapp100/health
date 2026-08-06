import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/design_system.dart';
import '../../models/enums.dart';
import '../../models/vital.dart';

Future<void> showLogVitalSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _LogVitalSheet(),
  );
}

class _LogVitalSheet extends ConsumerStatefulWidget {
  const _LogVitalSheet();

  @override
  ConsumerState<_LogVitalSheet> createState() => _LogVitalSheetState();
}

class _LogVitalSheetState extends ConsumerState<_LogVitalSheet> {
  static const _metrics = {
    VitalMetric.bloodGlucose: ('Blood glucose', 'mg/dL'),
    VitalMetric.systolicBp: ('Systolic BP', 'mmHg'),
    VitalMetric.diastolicBp: ('Diastolic BP', 'mmHg'),
    VitalMetric.weightKg: ('Weight', 'kg'),
    VitalMetric.heartRate: ('Heart rate', 'bpm'),
  };

  String _selectedMetric = VitalMetric.bloodGlucose;
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<bool> _submit() async {
    final value = double.tryParse(_valueController.text.trim());
    if (value == null) return false;
    final unit = _metrics[_selectedMetric]!.$2;
    try {
      await ref.read(vitalsServiceProvider).logVital(
            metricType: _selectedMetric,
            value: value,
            unit: unit,
            source: VitalSource.manual,
          );
      // No manual invalidation needed — ownVitalsStreamProvider is a Realtime subscription that
      // picks up the new row on its own.
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
          Text('Log a reading', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedMetric,
            decoration: const InputDecoration(labelText: 'Metric'),
            items: _metrics.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.$1)))
                .toList(),
            onChanged: (v) => setState(() => _selectedMetric = v ?? _selectedMetric),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Value (${_metrics[_selectedMetric]!.$2})',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AnimatedConfirmButton(
              label: 'Save',
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
