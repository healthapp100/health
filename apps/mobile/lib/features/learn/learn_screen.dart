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
import '../../services/content_service.dart';
import 'learn_providers.dart';
import 'learn_topics_tab.dart';

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
    _tabController = TabController(length: 5, vsync: this);
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'Topics'),
            Tab(text: 'Blogs'),
            Tab(text: 'Articles'),
            Tab(text: 'Seminars'),
            Tab(text: 'Past recordings'),
          ],
        ),
      ),
      body: ResponsiveContent(
        child: TabBarView(
          controller: _tabController,
          children: [
            const LearnTopicsTab(),
            const _BlogsTab(),
            _buildArticlesTab(),
            _buildSeminarsTab(),
            _buildPastSeminarsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesTab() {
    final isSearching = _searchQuery.length >= 2;

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
                  label: const Text('All categories'),
                  onPressed: _openAllTopics,
                ),
              ],
            ),
          ),
        if (!isSearching) const SizedBox(height: 8),
        Expanded(
          child: _PaginatedArticlesList(
            key: ValueKey('${_selectedCategory ?? 'all'}|$_searchQuery'),
            category: _selectedCategory,
            searchQuery: isSearching ? _searchQuery : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSeminarsTab() {
    final seminarsAsync = ref.watch(upcomingSeminarsProvider);
    // One shared subscription for every registration, not one query per seminar row.
    final registeredIds = ref.watch(ownRegisteredSeminarIdsProvider).valueOrNull ?? const {};
    return seminarsAsync.when(
      data: (seminars) => AsyncListView<Seminar>(
        data: seminars,
        error: null,
        isLoading: false,
        emptyTitle: 'No upcoming seminars',
        itemBuilder: (context, seminar, index) => AnimatedListEntry(
          index: index,
          child: _SeminarTile(seminar: seminar, isRegistered: registeredIds.contains(seminar.id)),
        ),
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

/// Page-based article list — a category or search result set isn't bounded, so this fetches
/// [ContentService.defaultPageSize] rows at a time and appends more only when the user actually
/// scrolls near the bottom, rather than pulling an entire category into memory up front. Keyed by
/// category+query at the call site so Flutter tears down and recreates this State (resetting
/// pagination) whenever either changes, instead of hand-written reset logic.
class _PaginatedArticlesList extends ConsumerStatefulWidget {
  final String? category;
  final String? searchQuery;
  final String contentType;
  const _PaginatedArticlesList({
    super.key,
    this.category,
    this.searchQuery,
    this.contentType = 'article',
  });

  @override
  ConsumerState<_PaginatedArticlesList> createState() => _PaginatedArticlesListState();
}

class _PaginatedArticlesListState extends ConsumerState<_PaginatedArticlesList> {
  final _scrollController = ScrollController();
  final List<HealthArticle> _articles = [];
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore) return;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 400) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    setState(() {
      if (_articles.isEmpty) {
        _isLoadingInitial = true;
      } else {
        _isLoadingMore = true;
      }
      _error = null;
    });
    try {
      final service = ref.read(contentServiceProvider);
      final page = widget.searchQuery != null
          ? await service.searchArticles(
              widget.searchQuery!,
              contentType: widget.contentType,
              offset: _articles.length,
            )
          : await service.getArticles(
              category: widget.category,
              contentType: widget.contentType,
              offset: _articles.length,
            );
      if (!mounted) return;
      setState(() {
        _articles.addAll(page);
        _hasMore = page.length == ContentService.defaultPageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isLoadingInitial = _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SkeletonList(count: 4),
      );
    }
    if (_error != null && _articles.isEmpty) {
      return ErrorState(message: '$_error', onRetry: _loadPage);
    }
    if (_articles.isEmpty) {
      return EmptyState(
        icon: widget.searchQuery != null ? Icons.search_off : Icons.menu_book_outlined,
        title: widget.searchQuery != null
            ? 'No articles match "${widget.searchQuery}"'
            : 'No articles in this category yet',
      );
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: _articles.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _articles.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final article = _articles[index];
        return AnimatedListEntry(
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
        );
      },
    );
  }
}

/// Blogs & Articles module: a Featured strip (editorial highlights, `featured = true`) above
/// the plain reverse-chronological list — "Daily Blog" is simply whatever's newest by
/// `published_at`, so no separate "daily" query/flag is needed beyond the existing ordering.
class _BlogsTab extends ConsumerWidget {
  const _BlogsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(featuredBlogsProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: featuredAsync.when(
            data: (featured) {
              if (featured.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Featured'),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: featured.length,
                        itemBuilder: (context, index) {
                          final blog = featured[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 220,
                              child: Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => context.push('/learn/article/${blog.slug}'),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.star, size: 16, color: Colors.amber[700]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Featured',
                                              style: Theme.of(context).textTheme.labelSmall,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          blog.title,
                                          style: Theme.of(context).textTheme.titleSmall,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Latest'),
          ),
        ),
        const SliverFillRemaining(
          child: _PaginatedArticlesList(contentType: 'blog'),
        ),
      ],
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
            Text('All categories', style: Theme.of(context).textTheme.titleLarge),
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

Future<bool> _confirmCancelRegistration(BuildContext context, String seminarTitle) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel registration?'),
      content: Text('You\'ll lose your spot for "$seminarTitle".'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep it')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Cancel registration'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _SeminarTile extends ConsumerWidget {
  final Seminar seminar;
  final bool isRegistered;
  const _SeminarTile({required this.seminar, required this.isRegistered});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(seminar.isOnline ? Icons.videocam_outlined : Icons.location_on_outlined),
        title: Text(seminar.title),
        subtitle: Text(
          [
            seminar.speakerName,
            DateFormat('EEE, d MMM · h:mm a').format(seminar.scheduledAt),
            seminar.isOnline ? 'Online' : (seminar.venue ?? 'Offline'),
          ].join(' · '),
        ),
        trailing: isRegistered
            ? OutlinedButton(
                onPressed: () async {
                  if (!await _confirmCancelRegistration(context, seminar.title)) return;
                  await ref.read(contentServiceProvider).cancelRegistration(seminar.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Registration cancelled')));
                  }
                },
                child: const Text('Registered'),
              )
            : FilledButton(
                onPressed: () async {
                  try {
                    await ref.read(contentServiceProvider).registerForSeminar(
                          seminar.id,
                          registrationLimit: seminar.registrationLimit,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registered — we’ll remind you')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Could not register. $e')));
                    }
                  }
                },
                child: const Text('Register'),
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
