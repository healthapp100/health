import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../models/enums.dart';
import '../../models/profile.dart';

/// Minimal booking flow: pick a time, confirm. Named-provider continuity (BLUEPRINT.md §4.2 —
/// HealthifyMe's top complaint was coaches swapped without handoff) means this always books
/// against one specific [provider], never an auto-assigned "next available" one.
Future<void> showBookAppointmentSheet(
  BuildContext context,
  WidgetRef ref,
  ProviderDirectoryEntry provider,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _BookAppointmentSheet(provider: provider),
  );
}

class _BookAppointmentSheet extends ConsumerStatefulWidget {
  final ProviderDirectoryEntry provider;
  const _BookAppointmentSheet({required this.provider});

  @override
  ConsumerState<_BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends ConsumerState<_BookAppointmentSheet> {
  DateTime? _selectedSlot;
  AppointmentMode _mode = AppointmentMode.video;
  bool _isSubmitting = false;

  List<DateTime> get _availableSlots {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final day = now.add(Duration(days: i + 1));
      return DateTime(day.year, day.month, day.day, 10, 0);
    });
  }

  Future<void> _confirm() async {
    if (_selectedSlot == null) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(appointmentServiceProvider).bookAppointment(
            providerId: widget.provider.profileId,
            scheduledAt: _selectedSlot!,
            mode: _mode,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment requested')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not book. $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          Text('Book with ${widget.provider.fullName}', style: Theme.of(context).textTheme.titleLarge),
          if (widget.provider.specialty != null) Text(widget.provider.specialty!),
          const SizedBox(height: 16),
          SegmentedButton<AppointmentMode>(
            segments: const [
              ButtonSegment(value: AppointmentMode.video, label: Text('Video'), icon: Icon(Icons.videocam_outlined)),
              ButtonSegment(value: AppointmentMode.audio, label: Text('Audio'), icon: Icon(Icons.call_outlined)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSlots.map((slot) {
              final selected = _selectedSlot == slot;
              return ChoiceChip(
                label: Text('${slot.day}/${slot.month} · ${slot.hour}:00'),
                selected: selected,
                onSelected: (_) => setState(() => _selectedSlot = slot),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedSlot != null && !_isSubmitting ? _confirm : null,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Confirm booking'),
            ),
          ),
        ],
      ),
    );
  }
}
