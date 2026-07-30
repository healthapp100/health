import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/content.dart';
import 'learn_providers.dart';

/// Health Knowledge Library + Blogs + Online Seminars — BLUEPRINT.md §5.1's 20+ topic list.
/// Categories are filter chips over public.health_articles.category rather than a fixed static
/// page per topic, so adding a new topic is a content-only change, no app release needed.
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> with SingleTickerProviderStateMixin {
  static const categories = [
    'diabetes', 'hypertension', 'ckd', 'cancer', 'heart_disease', 'obesity',
    'thyroid', 'liver', 'respiratory', 'mental_health', 'womens_health',
    'mens_health', 'child_health', 'elderly_care', 'nutrition', 'lifestyle_diseases',
    'fitness', 'preventive_care', 'vaccination', 'sleep', 'stress_management', 'immunity',
  ];

  String? _selectedCategory;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Learn'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Articles'), Tab(text: 'Seminars')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildArticlesTab(), _buildSeminarsTab()],
      ),
    );
  }

  Widget _buildArticlesTab() {
    final articlesAsync = ref.watch(articlesProvider(_selectedCategory));
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _CategoryChip(
                label: 'All',
                selected: _selectedCategory == null,
                onTap: () => setState(() => _selectedCategory = null),
              ),
              ...categories.map(
                (c) => _CategoryChip(
                  label: c.replaceAll('_', ' '),
                  selected: _selectedCategory == c,
                  onTap: () => setState(() => _selectedCategory = c),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: articlesAsync.when(
            data: (articles) => AsyncListView<HealthArticle>(
              data: articles,
              error: null,
              isLoading: false,
              emptyTitle: 'No articles in this category yet',
              itemBuilder: (context, article) => ListTile(
                title: Text(article.title),
                subtitle: article.summary != null ? Text(article.summary!, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                onTap: () => context.push('/learn/article/${article.slug}'),
              ),
            ),
            loading: () => const LoadingState(),
            error: (e, _) => ErrorState(message: '$e'),
          ),
        ),
      ],
    );
  }

  Widget _buildSeminarsTab() {
    final seminarsAsync = ref.watch(upcomingSeminarsProvider);
    return seminarsAsync.when(
      data: (seminars) => AsyncListView<Seminar>(
        data: seminars,
        error: null,
        isLoading: false,
        emptyTitle: 'No upcoming seminars',
        itemBuilder: (context, seminar) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(seminar.title),
            subtitle: Text(
              '${seminar.speakerName} · ${DateFormat('EEE, d MMM · h:mm a').format(seminar.scheduledAt)}',
            ),
            trailing: FilledButton(
              onPressed: () async {
                await ref.read(contentServiceProvider).registerForSeminar(seminar.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Registered — we’ll remind you')));
                }
              },
              child: const Text('Register'),
            ),
          ),
        ),
      ),
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(message: '$e'),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}
