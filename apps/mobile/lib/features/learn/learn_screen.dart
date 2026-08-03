import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/design_system.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/content.dart';
import 'learn_providers.dart';

/// Health Knowledge Library + Blogs + Online Seminars — BLUEPRINT.md §5.1's 20+ topic list.
/// Redesigned search-first: a 22-item always-visible chip scroller forces users to scan
/// off-screen options with no way to search, so search now leads, with a handful of common
/// categories as quick filters and the full topic list one tap away in a browsable sheet —
/// the pattern modern health/learning platforms (and this app's own Care/Labs tabs) converge on.
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> with SingleTickerProviderStateMixin {
  static const allCategories = [
    'diabetes', 'hypertension', 'ckd', 'cancer', 'heart_disease', 'obesity',
    'thyroid', 'liver', 'respiratory', 'mental_health', 'womens_health',
    'mens_health', 'child_health', 'elderly_care', 'nutrition', 'lifestyle_diseases',
    'fitness', 'preventive_care', 'vaccination', 'sleep', 'stress_management', 'immunity',
  ];
  // The handful most patients look for first — everything else is one tap away via "All topics".
  static const quickCategories = [
    'diabetes', 'hypertension', 'nutrition', 'mental_health', 'fitness', 'heart_disease',
  ];

  String? _selectedCategory;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Timer? _debounce;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _searchQuery = value.trim());
    });
  }

  Future<void> _openAllTopics() async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AllTopicsSheet(
        categories: allCategories,
        selected: _selectedCategory,
      ),
    );
    if (picked != _selectedCategory) {
      setState(() => _selectedCategory = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Articles'), Tab(text: 'Seminars'), Tab(text: 'Past recordings')],
        ),
      ),
      body: ResponsiveContent(
        child: TabBarView(
          controller: _tabController,
          children: [_buildArticlesTab(), _buildSeminarsTab(), _buildPastSeminarsTab()],
        ),
      ),
    );
  }

  Widget _buildArticlesTab() {
    final isSearching = _searchQuery.length >= 2;
    final articlesAsync = isSearching
        ? ref.watch(articleSearchProvider(_searchQuery))
        : ref.watch(articlesProvider(_selectedCategory));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search articles, symptoms, conditions…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
            ),
          ),
        ),
        if (!isSearching)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...quickCategories.map(
                  (c) => _CategoryChip(
                    label: c.replaceAll('_', ' '),
                    selected: _selectedCategory == c,
                    onTap: () => setState(() => _selectedCategory = c),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 16),
                  label: const Text('All topics'),
                  onPressed: _openAllTopics,
                ),
              ],
            ),
          ),
        if (!isSearching) const SizedBox(height: 8),
        Expanded(
          child: articlesAsync.when(
            data: (articles) => AsyncListView<HealthArticle>(
              data: articles,
              error: null,
              isLoading: false,
              emptyIcon: isSearching ? Icons.search_off : Icons.menu_book_outlined,
              emptyTitle: isSearching ? 'No articles match "$_searchQuery"' : 'No articles in this category yet',
              itemBuilder: (context, article, index) => AnimatedListEntry(
                index: index,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text(article.title),
                    subtitle: article.summary != null
                        ? Text(article.summary!, maxLines: 2, overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/learn/article/${article.slug}'),
                  ),
                ),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SkeletonList(count: 4),
            ),
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
        itemBuilder: (context, seminar, index) =>
            AnimatedListEntry(index: index, child: _SeminarTile(seminar: seminar)),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonList(count: 3),
      ),
      error: (e, _) => ErrorState(message: '$e'),
    );
  }

  Widget _buildPastSeminarsTab() {
    final pastAsync = ref.watch(pastSeminarsProvider);
    return pastAsync.when(
      data: (seminars) => AsyncListView<Seminar>(
        data: seminars,
        error: null,
        isLoading: false,
        emptyTitle: 'No past recordings yet',
        itemBuilder: (context, seminar, index) => AnimatedListEntry(
          index: index,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(seminar.title),
              subtitle: Text(
                '${seminar.speakerName} · ${DateFormat('d MMM yyyy').format(seminar.scheduledAt)}',
              ),
              onTap: () async {
                final uri = Uri.parse(seminar.recordingUrl!);
                final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Could not open the recording')));
                }
              },
            ),
          ),
        ),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonList(count: 3),
      ),
      error: (e, _) => ErrorState(message: '$e'),
    );
  }
}

class _AllTopicsSheet extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  const _AllTopicsSheet({required this.categories, required this.selected});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All topics', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 160,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.4,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final c = categories[index];
                  final isSelected = c == selected;
                  return ChoiceChip(
                    label: Text(c.replaceAll('_', ' ')),
                    selected: isSelected,
                    onSelected: (_) => Navigator.of(context).pop(isSelected ? null : c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeminarTile extends ConsumerWidget {
  final Seminar seminar;
  const _SeminarTile({required this.seminar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registeredAsync = ref.watch(seminarRegisteredProvider(seminar.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(seminar.title),
        subtitle: Text(
          '${seminar.speakerName} · ${DateFormat('EEE, d MMM · h:mm a').format(seminar.scheduledAt)}',
        ),
        trailing: registeredAsync.when(
          data: (isRegistered) => isRegistered
              ? OutlinedButton(
                  onPressed: () async {
                    await ref.read(contentServiceProvider).cancelRegistration(seminar.id);
                    ref.invalidate(seminarRegisteredProvider(seminar.id));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Registration cancelled')));
                    }
                  },
                  child: const Text('Registered'),
                )
              : FilledButton(
                  onPressed: () async {
                    await ref.read(contentServiceProvider).registerForSeminar(seminar.id);
                    ref.invalidate(seminarRegisteredProvider(seminar.id));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Registered — we’ll remind you')));
                    }
                  },
                  child: const Text('Register'),
                ),
          loading: () => const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, _) => const SizedBox.shrink(),
        ),
      ),
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
