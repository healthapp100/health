import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/widgets/design_system.dart';
import '../../../models/learn_topic.dart';
import 'learn_cms_providers.dart';

Future<void> showTopicFormSheet(BuildContext context, WidgetRef ref, {LearnTopic? topic}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TopicFormSheet(topic: topic),
  );
}

const _iconOptions = [
  'menu_book_outlined',
  'bloodtype_outlined',
  'monitor_heart_outlined',
  'favorite_outline',
  'psychology_outlined',
  'restaurant_outlined',
  'fitness_center_outlined',
];

class _TopicFormSheet extends ConsumerStatefulWidget {
  final LearnTopic? topic;
  const _TopicFormSheet({this.topic});

  @override
  ConsumerState<_TopicFormSheet> createState() => _TopicFormSheetState();
}

class _TopicFormSheetState extends ConsumerState<_TopicFormSheet> {
  late final _titleController = TextEditingController(text: widget.topic?.title ?? '');
  late final _slugController = TextEditingController(text: widget.topic?.slug ?? '');
  late final _summaryController = TextEditingController(text: widget.topic?.summary ?? '');
  late String _icon = widget.topic?.icon ?? _iconOptions.first;
  late bool _published = widget.topic?.published ?? true;
  bool _slugEdited = false;

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return false;
    final slug = _slugController.text.trim().isEmpty ? slugify(title) : _slugController.text.trim();
    final service = ref.read(learnContentServiceProvider);
    try {
      final draft = LearnTopic(
        id: widget.topic?.id ?? '',
        slug: slug,
        title: title,
        summary: _summaryController.text.trim().isEmpty ? null : _summaryController.text.trim(),
        icon: _icon,
        coverImageUrl: widget.topic?.coverImageUrl,
        sortOrder: widget.topic?.sortOrder ?? 0,
        published: _published,
        createdBy: widget.topic?.createdBy ?? '',
        createdAt: widget.topic?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (widget.topic == null) {
        await service.createTopic(draft);
      } else {
        await service.updateTopic(widget.topic!.id, draft);
      }
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
    final isEditing = widget.topic != null;
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
            Text(isEditing ? 'Edit topic' : 'Add topic', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title (e.g. Diabetes)'),
              onChanged: (v) {
                if (!_slugEdited) _slugController.text = slugify(v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _slugController,
              decoration: const InputDecoration(labelText: 'Slug (URL-safe identifier)'),
              onChanged: (_) => _slugEdited = true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _summaryController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Short summary (optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _icon,
              decoration: const InputDecoration(labelText: 'Icon'),
              items: _iconOptions
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: (v) => setState(() => _icon = v ?? _icon),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Published'),
              subtitle: const Text('Visible to patients when on'),
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AnimatedConfirmButton(
                label: isEditing ? 'Save changes' : 'Add topic',
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
