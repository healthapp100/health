import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/learn_topic.dart';
import 'learn_cms_providers.dart';

/// Full editor for one subtopic (a content page like "Definition" or "Diet" under a topic) —
/// a full screen rather than a sheet because the content fields (markdown body, image/PDF/link
/// lists, YouTube, references) need more room than a bottom sheet comfortably gives. Admin
/// writes plain markdown syntax in the body field; there's no WYSIWYG rich-text editor wired up
/// (no such package is declared in pubspec) — the live preview tab renders exactly what a
/// patient will see, which is the practical substitute.
class SubtopicEditScreen extends ConsumerStatefulWidget {
  final String topicId;
  final LearnSubtopic? subtopic;
  const SubtopicEditScreen({super.key, required this.topicId, this.subtopic});

  @override
  ConsumerState<SubtopicEditScreen> createState() => _SubtopicEditScreenState();
}

class _SubtopicEditScreenState extends ConsumerState<SubtopicEditScreen>
    with SingleTickerProviderStateMixin {
  late final _titleController = TextEditingController(text: widget.subtopic?.title ?? '');
  late final _slugController = TextEditingController(text: widget.subtopic?.slug ?? '');
  late final _bodyController = TextEditingController(text: widget.subtopic?.bodyMarkdown ?? '');
  late final _youtubeController = TextEditingController(text: widget.subtopic?.youtubeUrl ?? '');
  late final _referencesController =
      TextEditingController(text: widget.subtopic?.referencesText ?? '');
  late bool _published = widget.subtopic?.published ?? true;
  bool _slugEdited = false;
  bool _isSaving = false;
  late final TabController _tabController;

  late final List<TextEditingController> _imageControllers = (widget.subtopic?.imageUrls ?? [])
      .map((u) => TextEditingController(text: u))
      .toList();
  late final List<TextEditingController> _pdfControllers = (widget.subtopic?.pdfUrls ?? [])
      .map((u) => TextEditingController(text: u))
      .toList();
  late final List<(TextEditingController, TextEditingController)> _linkControllers =
      (widget.subtopic?.externalLinks ?? [])
          .map((l) => (TextEditingController(text: l.label), TextEditingController(text: l.url)))
          .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Rebuilds the Preview tab as the admin types — TabBarView keeps both tabs alive, so without
    // this the preview would only reflect whatever text existed when the screen first opened.
    _bodyController.addListener(_onContentChanged);
    _titleController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _slugController.dispose();
    _bodyController.dispose();
    _youtubeController.dispose();
    _referencesController.dispose();
    for (final c in _imageControllers) {
      c.dispose();
    }
    for (final c in _pdfControllers) {
      c.dispose();
    }
    for (final (a, b) in _linkControllers) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _isSaving = true);
    final slug =
        _slugController.text.trim().isEmpty ? slugify(title) : _slugController.text.trim();
    try {
      final draft = LearnSubtopic(
        id: widget.subtopic?.id ?? '',
        topicId: widget.topicId,
        slug: slug,
        title: title,
        sortOrder: widget.subtopic?.sortOrder ?? 0,
        published: _published,
        bodyMarkdown: _bodyController.text.trim().isEmpty ? null : _bodyController.text.trim(),
        imageUrls: _imageControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
        pdfUrls: _pdfControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
        externalLinks: _linkControllers
            .where((pair) => pair.$1.text.trim().isNotEmpty && pair.$2.text.trim().isNotEmpty)
            .map((pair) => ExternalLink(label: pair.$1.text.trim(), url: pair.$2.text.trim()))
            .toList(),
        youtubeUrl: _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
        referencesText:
            _referencesController.text.trim().isEmpty ? null : _referencesController.text.trim(),
        createdBy: widget.subtopic?.createdBy ?? '',
        createdAt: widget.subtopic?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final service = ref.read(learnContentServiceProvider);
      if (widget.subtopic == null) {
        await service.createSubtopic(draft);
      } else {
        await service.updateSubtopic(widget.subtopic!.id, draft);
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
    final isEditing = widget.subtopic != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit subtopic' : 'Add subtopic'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Edit'), Tab(text: 'Preview')],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
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
          decoration: const InputDecoration(labelText: 'Title (e.g. Definition, Causes, Diet)'),
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
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Published'),
          value: _published,
          onChanged: (v) => setState(() => _published = v),
        ),
        const Divider(height: 32),
        Text('Content (Markdown)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyController,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: '# Heading\\n\\nBody text, **bold**, - bullet lists, [link](https://...)',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const Divider(height: 32),
        Text('Images', style: Theme.of(context).textTheme.titleMedium),
        ..._buildUrlListEditor(_imageControllers, 'Image URL'),
        TextButton.icon(
          onPressed: () => setState(() => _imageControllers.add(TextEditingController())),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add image URL'),
        ),
        const Divider(height: 32),
        Text('PDFs', style: Theme.of(context).textTheme.titleMedium),
        ..._buildUrlListEditor(_pdfControllers, 'PDF URL'),
        TextButton.icon(
          onPressed: () => setState(() => _pdfControllers.add(TextEditingController())),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Add PDF URL'),
        ),
        const Divider(height: 32),
        Text('External links', style: Theme.of(context).textTheme.titleMedium),
        ..._buildLinkListEditor(),
        TextButton.icon(
          onPressed: () => setState(
            () => _linkControllers.add((TextEditingController(), TextEditingController())),
          ),
          icon: const Icon(Icons.link),
          label: const Text('Add external link'),
        ),
        const Divider(height: 32),
        TextField(
          controller: _youtubeController,
          decoration: const InputDecoration(labelText: 'YouTube link (optional)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _referencesController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'References (optional)'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  List<Widget> _buildUrlListEditor(List<TextEditingController> controllers, String label) {
    return List.generate(controllers.length, (i) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controllers[i],
                decoration: InputDecoration(labelText: '$label ${i + 1}'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => setState(() => controllers.removeAt(i).dispose()),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildLinkListEditor() {
    return List.generate(_linkControllers.length, (i) {
      final (labelController, urlController) = _linkControllers[i];
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => setState(() {
                final removed = _linkControllers.removeAt(i);
                removed.$1.dispose();
                removed.$2.dispose();
              }),
            ),
          ],
        ),
      );
    });
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
