import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/content.dart';

class SeminarEditScreen extends ConsumerStatefulWidget {
  final Seminar? seminar;
  const SeminarEditScreen({super.key, this.seminar});

  @override
  ConsumerState<SeminarEditScreen> createState() => _SeminarEditScreenState();
}

class _SeminarEditScreenState extends ConsumerState<SeminarEditScreen> {
  late final _titleController = TextEditingController(text: widget.seminar?.title ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.seminar?.description ?? '');
  late final _speakerNameController =
      TextEditingController(text: widget.seminar?.speakerName ?? '');
  late final _speakerBioController =
      TextEditingController(text: widget.seminar?.speakerBio ?? '');
  late final _joinUrlController = TextEditingController(text: widget.seminar?.joinUrl ?? '');
  late final _passwordController =
      TextEditingController(text: widget.seminar?.meetingPassword ?? '');
  late final _venueController = TextEditingController(text: widget.seminar?.venue ?? '');
  late final _bannerUrlController = TextEditingController(text: widget.seminar?.bannerUrl ?? '');
  late final _durationController =
      TextEditingController(text: widget.seminar?.durationMinutes?.toString() ?? '');
  late final _limitController =
      TextEditingController(text: widget.seminar?.registrationLimit?.toString() ?? '');
  late final _recordingUrlController =
      TextEditingController(text: widget.seminar?.recordingUrl ?? '');
  late final _notesController = TextEditingController(text: widget.seminar?.notes ?? '');

  late String _mode = widget.seminar?.mode ?? 'online';
  late String _status = widget.seminar?.status ?? 'scheduled';
  late DateTime _scheduledAt = widget.seminar?.scheduledAt ?? DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in [
      _titleController,
      _descriptionController,
      _speakerNameController,
      _speakerBioController,
      _joinUrlController,
      _passwordController,
      _venueController,
      _bannerUrlController,
      _durationController,
      _limitController,
      _recordingUrlController,
      _notesController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final speaker = _speakerNameController.text.trim();
    if (title.isEmpty || speaker.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Title and speaker name are required')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final draft = Seminar(
        id: widget.seminar?.id ?? '',
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        speakerName: speaker,
        speakerBio:
            _speakerBioController.text.trim().isEmpty ? null : _speakerBioController.text.trim(),
        scheduledAt: _scheduledAt,
        joinUrl: _mode == 'online' && _joinUrlController.text.trim().isNotEmpty
            ? _joinUrlController.text.trim()
            : null,
        recordingUrl: _recordingUrlController.text.trim().isEmpty
            ? null
            : _recordingUrlController.text.trim(),
        mode: _mode,
        durationMinutes: int.tryParse(_durationController.text.trim()),
        meetingPassword: _mode == 'online' && _passwordController.text.trim().isNotEmpty
            ? _passwordController.text.trim()
            : null,
        venue: _mode == 'offline' && _venueController.text.trim().isNotEmpty
            ? _venueController.text.trim()
            : null,
        bannerUrl: _bannerUrlController.text.trim().isEmpty ? null : _bannerUrlController.text.trim(),
        registrationLimit: int.tryParse(_limitController.text.trim()),
        status: _status,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      final service = ref.read(contentServiceProvider);
      if (widget.seminar == null) {
        await service.createSeminar(draft);
      } else {
        await service.updateSeminar(widget.seminar!.id, draft);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save. $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.seminar != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit seminar' : 'Add seminar'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(onPressed: _save, child: const Text('Save')),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _speakerNameController,
            decoration: const InputDecoration(labelText: 'Speaker name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _speakerBioController,
            decoration: const InputDecoration(labelText: 'Speaker bio'),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Date & time'),
            subtitle: Text('${_scheduledAt.toLocal()}'.split('.').first),
            trailing: TextButton(onPressed: _pickDateTime, child: const Text('Change')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duration (minutes, optional)'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'online', label: Text('Online'), icon: Icon(Icons.videocam_outlined)),
              ButtonSegment(
                value: 'offline',
                label: Text('Offline'),
                icon: Icon(Icons.location_on_outlined),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 12),
          if (_mode == 'online') ...[
            TextField(
              controller: _joinUrlController,
              decoration: const InputDecoration(labelText: 'Meeting link (Google Meet / Zoom)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Meeting password (optional)'),
            ),
          ] else
            TextField(
              controller: _venueController,
              decoration: const InputDecoration(labelText: 'Venue address'),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _bannerUrlController,
            decoration: const InputDecoration(labelText: 'Banner image URL (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _limitController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Registration limit (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _recordingUrlController,
            decoration: const InputDecoration(labelText: 'Recording URL (after the seminar)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
            ],
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Internal notes (optional)'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
