import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/content.dart';
import '../learn_cms/learn_cms_providers.dart' show slugify;

/// Create/edit form for a blog/article/news row. `contentType` is fixed at creation (matching
/// which tab the admin tapped "Add" from) — changing what something IS after the fact would be
/// an unusual edit, not a typical one, so it's not exposed as an editable field here.
class BlogEditScreen extends ConsumerStatefulWidget {
  final String contentType;
  final HealthArticle? article;
  const BlogEditScreen({super.key, required this.contentType, this.article});

  @override
  ConsumerState<BlogEditScreen> createState() => _BlogEditScreenState();
}

class _BlogEditScreenState extends ConsumerState<BlogEditScreen> with SingleTickerProviderStateMixin {
  late final _titleController = TextEditingController(text: widget.article?.title ?? '');
  late final _slugController = TextEditingController(text: widget.article?.slug ?? '');
  late final _categoryController = TextEditingController(text: widget.article?.category ?? '');
  late final _summaryController = TextEditingController(text: widget.article?.summary ?? '');
  late final _bodyController = TextEditingController(text: widget.article?.bodyMarkdown ?? '');
  late final _coverImageController =
      TextEditingController(text: widget.article?.coverImageUrl ?? '');
  late final _tagsController = TextEditingController(text: (widget.article?.tags ?? []).join(', '));
  late final _externalLinkController =
      TextEditingController(text: widget.article?.externalLink ?? '');
  late final _youtubeController = TextEditingController(text: widget.article?.youtubeUrl ?? '');

  late bool _featured = widget.article?.featured ?? false;
  late DateTime? _publishedAt = widget.article?.publishedAt;
  bool _slugEdited = false;
  bool _isSaving = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bodyController.addListener(_refresh);
    _titleController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _titleController,
      _slugController,
      _categoryController,
      _summaryController,
      _bodyController,
      _coverImageController,
      _tagsController,
      _externalLinkController,
      _youtubeController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPublishDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _publishedAt ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_publishedAt ?? now),
    );
    if (time == null) return;
    setState(() {
      _publishedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || category.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Title, category, and content are required')));
      return;
    }
    setState(() => _isSaving = true);
    final slug =
        _slugController.text.trim().isEmpty ? slugify(title) : _slugController.text.trim();
    try {
      final draft = HealthArticle(
        id: widget.article?.id ?? '',
        slug: slug,
        title: title,
        category: category,
        contentType: widget.contentType,
        bodyMarkdown: body,
        summary: _summaryController.text.trim().isEmpty ? null : _summaryController.text.trim(),
        coverImageUrl:
            _coverImageController.text.trim().isEmpty ? null : _coverImageController.text.trim(),
        publishedAt: _publishedAt,
        featured: _featured,
        tags: _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        externalLink:
            _externalLinkController.text.trim().isEmpty ? null : _externalLinkController.text.trim(),
        youtubeUrl: _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
      );
      final service = ref.read(contentServiceProvider);
      if (widget.article == null) {
        await service.createArticle(draft);
      } else {
        await service.updateArticle(widget.article!.id, draft);
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

  String get _typeLabel => switch (widget.contentType) {
        'blog' => 'blog',
        'news' => 'news item',
        _ => 'article',
      };

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.article != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit $_typeLabel' : 'Add $_typeLabel'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Edit'), Tab(text: 'Preview')]),
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
      body: TabBarView(
        controller: _tabController,
        children: [_buildEditTab(), _buildPreviewTab()],
      ),
    );
  }

  Widget _buildEditTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Title'),
          onChanged: (v) {
            if (!_slugEdited) _slugController.text = slugify(v);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _slugController,
          decoration: const InputDecoration(labelText: 'Slug'),
          onChanged: (_) => _slugEdited = true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _categoryController,
          decoration: const InputDecoration(labelText: 'Category (e.g. diabetes, nutrition)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tagsController,
          decoration: const InputDecoration(labelText: 'Tags (comma-separated)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _summaryController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Short summary'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _coverImageController,
          decoration: const InputDecoration(labelText: 'Cover image URL'),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Featured'),
          subtitle: const Text('Shown in the highlighted strip at the top'),
          value: _featured,
          onChanged: (v) => setState(() => _featured = v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule_outlined),
          title: const Text('Publish date & time'),
          subtitle: Text(
            _publishedAt == null
                ? 'Not scheduled (stays a draft)'
                : '${_publishedAt!.toLocal()}'.split('.').first,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: _pickPublishDateTime, child: const Text('Set')),
              if (_publishedAt != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Unpublish / clear',
                  onPressed: () => setState(() => _publishedAt = null),
                ),
            ],
          ),
        ),
        const Divider(height: 32),
        Text('Content (Markdown)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyController,
          maxLines: 14,
          decoration: const InputDecoration(alignLabelWithHint: true, border: OutlineInputBorder()),
        ),
        const Divider(height: 32),
        TextField(
          controller: _externalLinkController,
          decoration: const InputDecoration(labelText: 'External link (optional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _youtubeController,
          decoration: const InputDecoration(labelText: 'YouTube link (optional)'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPreviewTab() {
    final body = _bodyController.text.trim();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          _titleController.text.trim().isEmpty ? '(untitled)' : _titleController.text.trim(),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        if (body.isNotEmpty)
          MarkdownBody(data: body)
        else
          Text('No content yet.', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
