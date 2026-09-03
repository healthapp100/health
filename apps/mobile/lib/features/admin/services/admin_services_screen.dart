import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/widgets/design_system.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../models/services_models.dart';
import '../../care/care_providers.dart';
import 'admin_services_providers.dart';

/// Shared "are you sure?" gate for every delete button on this screen — none of the five
/// sub-modules' delete actions originally had one (unlike Learn/Blogs/Seminars, which all
/// confirm before deleting), so a single misclick permanently destroyed a monitoring message,
/// video, or directory listing with no undo. Returns true only if the admin confirmed.
Future<bool> _confirmDelete(BuildContext context, String itemLabel) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete?'),
      content: Text('"$itemLabel" will be permanently deleted. This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
      ],
    ),
  );
  return confirmed ?? false;
}

/// One admin screen with a tab per Services sub-module (Daily Monitoring, Daily Videos, Lab
/// directory, Health Kit directory, Medicines) — each tab's form is short enough (a handful of
/// fields) that a single consolidated screen stays easier to navigate than five separate admin
/// routes would, unlike Learn/Blogs/Seminars which each warranted their own full screen.
class AdminServicesScreen extends ConsumerStatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  ConsumerState<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends ConsumerState<AdminServicesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Daily Monitoring'),
            Tab(text: 'Daily Videos'),
            Tab(text: 'Lab directory'),
            Tab(text: 'Health kits'),
            Tab(text: 'Medicines'),
            Tab(text: 'Doctor info'),
          ],
        ),
      ),
      body: ResponsiveContent(
        child: TabBarView(
          controller: _tabController,
          children: const [
            _MonitoringMessagesTab(),
            _DailyVideosTab(),
            _LabDirectoryTab(),
            _HealthKitsTab(),
            _MedicinesTab(),
            _DoctorContactInfoTab(),
          ],
        ),
      ),
    );
  }
}

class _MonitoringMessagesTab extends ConsumerWidget {
  const _MonitoringMessagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(adminMonitoringMessagesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMessageSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New message'),
      ),
      body: messagesAsync.when(
        data: (messages) {
          if (messages.isEmpty) {
            return const ActionableEmptyState(icon: Icons.campaign_outlined, title: 'No messages sent yet');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return AnimatedListEntry(
                index: index,
                child: Card(
                  child: ListTile(
                    leading: Icon(message.isBroadcast ? Icons.campaign_outlined : Icons.person_outline),
                    title: Text(message.title),
                    subtitle: Text(message.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusChip(
                          label: message.isBroadcast ? 'Broadcast' : 'Targeted',
                          tone: message.isBroadcast ? StatusTone.info : StatusTone.neutral,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (!await _confirmDelete(context, message.title)) return;
                            await ref
                                .read(servicesDirectoryServiceProvider)
                                .deleteMonitoringMessage(message.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Padding(padding: EdgeInsets.all(16), child: SkeletonList(count: 3)),
        error: (e, _) => ErrorState(message: '$e'),
      ),
    );
  }

  Future<void> _showMessageSheet(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _MonitoringMessageForm(),
    );
  }
}

class _MonitoringMessageForm extends ConsumerStatefulWidget {
  const _MonitoringMessageForm();

  @override
  ConsumerState<_MonitoringMessageForm> createState() => _MonitoringMessageFormState();
}

class _MonitoringMessageFormState extends ConsumerState<_MonitoringMessageForm> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _patientIdController = TextEditingController();
  bool _isBroadcast = true;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _patientIdController.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return false;
    try {
      await ref.read(servicesDirectoryServiceProvider).createMonitoringMessage(
            MonitoringMessage(
              id: '',
              patientId: _isBroadcast
                  ? null
                  : (_patientIdController.text.trim().isEmpty ? null : _patientIdController.text.trim()),
              title: title,
              body: body,
              createdBy: '',
              createdAt: DateTime.now(),
            ),
          );
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send. $e')));
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
          Text('New monitoring message', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Broadcast (all patients)')),
              ButtonSegment(value: false, label: Text('One patient')),
            ],
            selected: {_isBroadcast},
            onSelectionChanged: (s) => setState(() => _isBroadcast = s.first),
          ),
          if (!_isBroadcast) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _patientIdController,
              decoration: const InputDecoration(
                labelText: 'Patient profile ID (uuid)',
                helperText: 'Found in Supabase → profiles table',
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AnimatedConfirmButton(
              label: 'Send',
              successLabel: 'Sent',
              onPressed: _save,
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

class _DailyVideosTab extends ConsumerWidget {
  const _DailyVideosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(adminDailyVideosProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => const _DailyVideoForm(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add video'),
      ),
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return const ActionableEmptyState(icon: Icons.play_circle_outline, title: 'No videos yet');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return AnimatedListEntry(
                index: index,
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(video.title),
                    subtitle: Text(
                      video.isExpired
                          ? 'Expired ${DateFormat('d MMM').format(video.expiresAt!)}'
                          : video.isCurrentlyVisible
                              ? 'Visible now'
                              : 'Scheduled ${DateFormat('d MMM, h:mm a').format(video.publishAt)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusChip(
                          label: video.isExpired
                              ? 'Expired'
                              : (video.isCurrentlyVisible ? 'Live' : 'Scheduled'),
                          tone: video.isExpired
                              ? StatusTone.neutral
                              : (video.isCurrentlyVisible ? StatusTone.success : StatusTone.info),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (!await _confirmDelete(context, video.title)) return;
                            await ref.read(servicesDirectoryServiceProvider).deleteVideo(video.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Padding(padding: EdgeInsets.all(16), child: SkeletonList(count: 3)),
        error: (e, _) => ErrorState(message: '$e'),
      ),
    );
  }
}

class _DailyVideoForm extends ConsumerStatefulWidget {
  const _DailyVideoForm();

  @override
  ConsumerState<_DailyVideoForm> createState() => _DailyVideoFormState();
}

class _DailyVideoFormState extends ConsumerState<_DailyVideoForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  DateTime? _expiresAt;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _expiresAt = date);
  }

  Future<bool> _save() async {
    final title = _titleController.text.trim();
    final url = _urlController.text.trim();
    if (title.isEmpty || url.isEmpty) return false;
    try {
      await ref.read(servicesDirectoryServiceProvider).createVideo(
            DailyVideo(
              id: '',
              title: title,
              description:
                  _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
              videoUrl: url,
              publishAt: DateTime.now(),
              expiresAt: _expiresAt,
              createdBy: '',
              createdAt: DateTime.now(),
            ),
          );
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
          Text('Add a daily video', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(labelText: 'YouTube or Google Drive link'),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Expires on'),
            subtitle: Text(_expiresAt == null ? 'Never' : DateFormat('d MMM yyyy').format(_expiresAt!)),
            trailing: TextButton(onPressed: _pickExpiry, child: const Text('Set')),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AnimatedConfirmButton(
              label: 'Add video',
              successLabel: 'Added',
              onPressed: _save,
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

class _LabDirectoryTab extends ConsumerWidget {
  const _LabDirectoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(adminLabDirectoryProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => const _LabDirectoryForm(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add listing'),
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const ActionableEmptyState(icon: Icons.science_outlined, title: 'No listings yet');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return AnimatedListEntry(
                index: index,
                child: Card(
                  child: ListTile(
                    title: Text(entry.name),
                    subtitle: Text(entry.kind),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!entry.published)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: StatusChip(label: 'Draft', tone: StatusTone.neutral),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (!await _confirmDelete(context, entry.name)) return;
                            await ref.read(servicesDirectoryServiceProvider).deleteLabEntry(entry.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Padding(padding: EdgeInsets.all(16), child: SkeletonList(count: 3)),
        error: (e, _) => ErrorState(message: '$e'),
      ),
    );
  }
}

class _LabDirectoryForm extends ConsumerStatefulWidget {
  const _LabDirectoryForm();

  @override
  ConsumerState<_LabDirectoryForm> createState() => _LabDirectoryFormState();
}

class _LabDirectoryFormState extends ConsumerState<_LabDirectoryForm> {
  final _nameController = TextEditingController();
  final _doctorController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _servicesController = TextEditingController();
  final _timingsController = TextEditingController();
  final _linkController = TextEditingController();
  String _kind = 'diagnostic_center';

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _doctorController,
      _phoneController,
      _emailController,
      _addressController,
      _servicesController,
      _timingsController,
      _linkController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return false;
    try {
      await ref.read(servicesDirectoryServiceProvider).createLabEntry(
            LabDirectoryEntry(
              id: '',
              name: name,
              kind: _kind,
              doctorName: _doctorController.text.trim().isEmpty ? null : _doctorController.text.trim(),
              contactPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
              contactEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
              address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
              services: _servicesController.text.trim().isEmpty ? null : _servicesController.text.trim(),
              timings: _timingsController.text.trim().isEmpty ? null : _timingsController.text.trim(),
              externalLink: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
              published: true,
            ),
          );
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add lab listing', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'clinic', label: Text('Clinic')),
                ButtonSegment(value: 'diagnostic_center', label: Text('Diagnostic center')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _doctorController,
              decoration: const InputDecoration(labelText: 'Doctor name (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Contact phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Contact email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _servicesController,
              decoration: const InputDecoration(labelText: 'Services offered'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timingsController,
              decoration: const InputDecoration(labelText: 'Timings'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(labelText: 'External link (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AnimatedConfirmButton(
                label: 'Add',
                successLabel: 'Added',
                onPressed: _save,
                onSuccessComplete: () {
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthKitsTab extends ConsumerWidget {
  const _HealthKitsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(adminHealthKitsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => const _HealthKitForm(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const ActionableEmptyState(icon: Icons.fitness_center_outlined, title: 'No items yet');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return AnimatedListEntry(
                index: index,
                child: Card(
                  child: ListTile(
                    title: Text(entry.name),
                    subtitle: Text(entry.category),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (!await _confirmDelete(context, entry.name)) return;
                        await ref.read(servicesDirectoryServiceProvider).deleteHealthKit(entry.id);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Padding(padding: EdgeInsets.all(16), child: SkeletonList(count: 3)),
        error: (e, _) => ErrorState(message: '$e'),
      ),
    );
  }
}

class _HealthKitForm extends ConsumerStatefulWidget {
  const _HealthKitForm();

  @override
  ConsumerState<_HealthKitForm> createState() => _HealthKitFormState();
}

class _HealthKitFormState extends ConsumerState<_HealthKitForm> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _supplierController = TextEditingController();
  final _purchaseLinkController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _category = 'device';

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _descriptionController,
      _supplierController,
      _purchaseLinkController,
      _instructionsController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return false;
    try {
      await ref.read(servicesDirectoryServiceProvider).createHealthKit(
            HealthKitEntry(
              id: '',
              name: name,
              category: _category,
              description:
                  _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
              supplierName:
                  _supplierController.text.trim().isEmpty ? null : _supplierController.text.trim(),
              purchaseLink:
                  _purchaseLinkController.text.trim().isEmpty ? null : _purchaseLinkController.text.trim(),
              instructions:
                  _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
              published: true,
            ),
          );
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add health kit item', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'device', child: Text('Device')),
                DropdownMenuItem(value: 'kit', child: Text('Kit')),
                DropdownMenuItem(value: 'equipment', child: Text('Equipment')),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _supplierController,
              decoration: const InputDecoration(labelText: 'Supplier name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _purchaseLinkController,
              decoration: const InputDecoration(labelText: 'Purchase link'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructionsController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Instructions'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AnimatedConfirmButton(
                label: 'Add',
                successLabel: 'Added',
                onPressed: _save,
                onSuccessComplete: () {
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicinesTab extends ConsumerWidget {
  const _MedicinesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicinesAsync = ref.watch(adminMedicinesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => const _MedicineForm(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add medicine'),
      ),
      body: medicinesAsync.when(
        data: (medicines) {
          if (medicines.isEmpty) {
            return const ActionableEmptyState(icon: Icons.medication_outlined, title: 'No entries yet');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              return AnimatedListEntry(
                index: index,
                child: Card(
                  child: ListTile(
                    title: Text(medicine.name),
                    subtitle: medicine.category != null ? Text(medicine.category!) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (!await _confirmDelete(context, medicine.name)) return;
                        await ref.read(servicesDirectoryServiceProvider).deleteMedicine(medicine.id);
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Padding(padding: EdgeInsets.all(16), child: SkeletonList(count: 3)),
        error: (e, _) => ErrorState(message: '$e'),
      ),
    );
  }
}

class _MedicineForm extends ConsumerStatefulWidget {
  const _MedicineForm();

  @override
  ConsumerState<_MedicineForm> createState() => _MedicineFormState();
}

class _MedicineFormState extends ConsumerState<_MedicineForm> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final _linkController = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _categoryController,
      _descriptionController,
      _recommendationsController,
      _linkController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return false;
    try {
      await ref.read(servicesDirectoryServiceProvider).createMedicine(
            MedicineInfo(
              id: '',
              name: name,
              category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
              description:
                  _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
              recommendations: _recommendationsController.text.trim().isEmpty
                  ? null
                  : _recommendationsController.text.trim(),
              externalLink: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
              published: true,
            ),
          );
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add medicine info', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _recommendationsController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Recommendations'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(labelText: 'External link (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AnimatedConfirmButton(
                label: 'Add',
                successLabel: 'Added',
                onPressed: _save,
                onSuccessComplete: () {
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Supplementary contact/availability info shown alongside a verified doctor's existing
/// provider_directory card — lists every verified doctor (from the same source the patient
/// "Find a doctor" tab uses) so the admin picks who to add info for, rather than typing a raw
/// profile ID by hand.
class _DoctorContactInfoTab extends ConsumerWidget {
  const _DoctorContactInfoTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(verifiedDoctorsProvider);
    final contactInfoAsync = ref.watch(adminDoctorContactInfoProvider);

    return doctorsAsync.when(
      data: (doctors) {
        if (doctors.isEmpty) {
          return const ActionableEmptyState(
            icon: Icons.medical_information_outlined,
            title: 'No verified doctors yet',
            subtitle: 'Verify a doctor\'s credentials first — see provider_credentials.',
          );
        }
        final contactByProviderId = {
          for (final c in contactInfoAsync.valueOrNull ?? <DoctorContactInfo>[])
            c.providerProfileId: c,
        };
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            final info = contactByProviderId[doctor.profileId];
            return AnimatedListEntry(
              index: index,
              child: Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(doctor.fullName),
                  subtitle: Text(
                    info == null
                        ? 'No contact info added'
                        : [
                            if (info.contactPhone != null) info.contactPhone!,
                            if (info.availability != null) info.availability!,
                          ].join(' · '),
                  ),
                  trailing: TextButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) =>
                          _DoctorContactInfoForm(doctorId: doctor.profileId, existing: info),
                    ),
                    child: Text(info == null ? 'Add' : 'Edit'),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Padding(padding: EdgeInsets.all(16), child: SkeletonList(count: 3)),
      error: (e, _) => ErrorState(message: '$e'),
    );
  }
}

class _DoctorContactInfoForm extends ConsumerStatefulWidget {
  final String doctorId;
  final DoctorContactInfo? existing;
  const _DoctorContactInfoForm({required this.doctorId, this.existing});

  @override
  ConsumerState<_DoctorContactInfoForm> createState() => _DoctorContactInfoFormState();
}

class _DoctorContactInfoFormState extends ConsumerState<_DoctorContactInfoForm> {
  late final _phoneController = TextEditingController(text: widget.existing?.contactPhone ?? '');
  late final _emailController = TextEditingController(text: widget.existing?.contactEmail ?? '');
  late final _feeController = TextEditingController(text: widget.existing?.consultationFee ?? '');
  late final _availabilityController =
      TextEditingController(text: widget.existing?.availability ?? '');
  late final _notesController = TextEditingController(text: widget.existing?.notes ?? '');

  @override
  void dispose() {
    for (final c in [
      _phoneController,
      _emailController,
      _feeController,
      _availabilityController,
      _notesController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _save() async {
    try {
      await ref.read(servicesDirectoryServiceProvider).upsertDoctorContactInfo(
            DoctorContactInfo(
              id: widget.existing?.id ?? '',
              providerProfileId: widget.doctorId,
              contactPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
              contactEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
              consultationFee: _feeController.text.trim().isEmpty ? null : _feeController.text.trim(),
              availability:
                  _availabilityController.text.trim().isEmpty ? null : _availabilityController.text.trim(),
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              published: true,
            ),
          );
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor contact info', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Contact phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Contact email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feeController,
              decoration: const InputDecoration(labelText: 'Consultation fee'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _availabilityController,
              decoration: const InputDecoration(labelText: 'Availability (e.g. Mon-Fri, 10am-4pm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AnimatedConfirmButton(
                label: 'Save',
                successLabel: 'Saved',
                onPressed: _save,
                onSuccessComplete: () {
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
