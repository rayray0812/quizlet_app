import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/core/icons/material_icon_mapper.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/core/widgets/liquid_glass.dart';
import 'package:recall_app/features/community/screens/community_screen.dart';
import 'package:recall_app/features/stats/screens/stats_screen.dart';
import 'package:recall_app/features/home/screens/settings_tab.dart';
import 'package:recall_app/features/home/widgets/study_set_card.dart';
import 'package:recall_app/features/home/widgets/dashboard_helpers.dart';
import 'package:recall_app/services/import_export_service.dart';
import 'package:recall_app/models/folder.dart';
import 'package:recall_app/providers/folder_provider.dart';
import 'package:recall_app/providers/community_provider.dart';
import 'package:recall_app/providers/sort_provider.dart';
import 'package:recall_app/providers/gemini_key_provider.dart';
import 'package:recall_app/features/home/widgets/sort_selector.dart';
import 'package:recall_app/providers/widget_provider.dart';
import 'package:recall_app/providers/fsrs_provider.dart';
import 'package:recall_app/providers/stats_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentTab = 0;
  String _homeSearchQuery = '';
  final _homeSearchController = TextEditingController();
  bool _isSearching = false;

  // Multi-select state
  bool _isMultiSelectMode = false;
  final Set<String> _selectedSetIds = {};

  @override
  void initState() {
    super.initState();
    // Sync widget data when app opens
    Future.microtask(() {
      if (mounted) ref.read(widgetRefreshProvider)();
    });
  }

  @override
  void dispose() {
    _homeSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studySets = ref.watch(studySetsProvider);
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);
    final pageTitle = switch (_currentTab) {
      1 => l10n.community,
      2 => l10n.statistics,
      3 => l10n.settings,
      _ => AppConstants.appName,
    };
    final showFab = _currentTab == 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() {
                  _isMultiSelectMode = false;
                  _selectedSetIds.clear();
                }),
              )
            : null,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: _isMultiSelectMode
              ? Text(
                  key: const ValueKey('multi-select-title'),
                  l10n.selectedCount(_selectedSetIds.length),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                )
              : (_currentTab == 0 && _isSearching)
              ? TextField(
                  key: const ValueKey('search-field'),
                  controller: _homeSearchController,
                  autofocus: true,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  decoration: InputDecoration(
                    hintText: l10n.searchCards,
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) =>
                      setState(() => _homeSearchQuery = v.trim()),
                )
              : _currentTab == 0
                  ? Row(
                      key: const ValueKey('app-logo-title'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 30,
                          width: 30,
                          child: Image.asset(
                            'assets/branding/logo_clean.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.appDisplayName,
                          style: TextStyle(
                            color: AppTheme.indigo,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: ValueKey(pageTitle),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          switch (_currentTab) {
                            1 => Icons.people_rounded,
                            2 => Icons.bar_chart_rounded,
                            3 => Icons.settings_rounded,
                            _ => Icons.home_rounded,
                          },
                          color: AppTheme.indigo,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pageTitle,
                          style: TextStyle(
                            color: AppTheme.indigo,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
        ),
        actions: [
          if (!_isMultiSelectMode && _currentTab == 0)
            _isSearching
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () {
                      _homeSearchController.clear();
                      setState(() {
                        _homeSearchQuery = '';
                        _isSearching = false;
                      });
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.search_rounded, size: 22),
                    onPressed: () => setState(() => _isSearching = true),
                    tooltip: l10n.searchCards,
                  ),
          if (_isMultiSelectMode)
            TextButton(
              onPressed: () {
                final allSets = ref.read(studySetsProvider);
                setState(() {
                  if (_selectedSetIds.length == allSets.length) {
                    _selectedSetIds.clear();
                  } else {
                    _selectedSetIds.addAll(allSets.map((s) => s.id));
                  }
                });
              },
              child: Text(
                _selectedSetIds.length == ref.read(studySetsProvider).length
                    ? l10n.cancel
                    : l10n.all,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surfaceContainerLowest,
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: BackdropAccents()),
          if (_currentTab == 0) const HomeAmbientGlow(),
          const Positioned.fill(child: GrainOverlay()),
          Positioned.fill(
            child: _buildAnimatedTabBody(context, ref, studySets, l10n),
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: showFab
            ? FloatingActionButton(
                key: const ValueKey('home-fab'),
                onPressed: () => _showCreateOrImportSheet(context, ref),
                backgroundColor: AppTheme.indigo,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(CupertinoIcons.plus, size: 24),
              )
            : const SizedBox.shrink(key: ValueKey('empty-fab')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _isMultiSelectMode
          ? _buildMultiSelectBar(context, ref, l10n)
          : Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: AppTheme.softCardDecoration(
            fillColor: Colors.white.withValues(alpha: 0.9),
            borderRadius: 22,
            borderColor: Colors.white.withValues(alpha: 0.42),
            elevation: 1.4,
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.14),
            height: 72,
            selectedIndex: _currentTab,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              setState(() => _currentTab = index);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(CupertinoIcons.house),
                selectedIcon: const Icon(CupertinoIcons.house_fill),
                label: l10n.home,
              ),
              NavigationDestination(
                icon: const Icon(CupertinoIcons.person_2),
                selectedIcon: const Icon(CupertinoIcons.person_2_fill),
                label: l10n.community,
              ),
              NavigationDestination(
                icon: const Icon(CupertinoIcons.chart_bar),
                selectedIcon: const Icon(CupertinoIcons.chart_bar_fill),
                label: l10n.statistics,
              ),
              NavigationDestination(
                icon: Icon(
                  user != null
                      ? CupertinoIcons.person
                      : CupertinoIcons.person_badge_minus,
                ),
                selectedIcon: Icon(
                  user != null ? CupertinoIcons.person_fill : CupertinoIcons.person_badge_minus,
                ),
                label: l10n.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectBar(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _isMultiSelectMode = false;
                _selectedSetIds.clear();
              }),
              icon: const Icon(Icons.close_rounded),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.selectedCount(_selectedSetIds.length),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _selectedSetIds.isEmpty
                  ? null
                  : () => _showBatchMoveFolderDialog(context, ref),
              icon: const Icon(Icons.drive_file_move_outlined, size: 18),
              label: Text(l10n.moveToFolder),
            ),
          ],
        ),
      ),
    );
  }

  void _showBatchMoveFolderDialog(BuildContext context, WidgetRef ref) {
    final folders = ref.read(foldersProvider);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.batchMoveToFolder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.noFolder),
              onTap: () {
                for (final id in _selectedSetIds) {
                  ref.read(studySetsProvider.notifier).moveToFolder(id, null);
                }
                Navigator.pop(ctx);
                setState(() {
                  _isMultiSelectMode = false;
                  _selectedSetIds.clear();
                });
              },
            ),
            ...folders.map((folder) => ListTile(
                  leading: Icon(
                    MaterialIconMapper.fromCodePoint(folder.iconCodePoint),
                    color: Color(int.parse(folder.colorHex, radix: 16)),
                  ),
                  title: Text(folder.name),
                  onTap: () {
                    for (final id in _selectedSetIds) {
                      ref
                          .read(studySetsProvider.notifier)
                          .moveToFolder(id, folder.id);
                    }
                    Navigator.pop(ctx);
                    setState(() {
                      _isMultiSelectMode = false;
                      _selectedSetIds.clear();
                    });
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTabBody(
    BuildContext context,
    WidgetRef ref,
    List<StudySet> studySets,
    AppLocalizations l10n,
  ) {
    final pages = <Widget>[
      studySets.isEmpty
          ? _buildEmptyState(context, l10n)
          : _buildList(context, studySets),
      const CommunityScreen(embedded: true),
      const StatsScreen(embedded: true),
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SettingsTab(
          onResetTab: () => setState(() => _currentTab = 0),
        ),
      ),
    ];

    return IndexedStack(
      index: _currentTab,
      children: pages,
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 120),
      children: [
        AdaptiveGlassCard(
          borderRadius: 20,
          fillColor: Colors.white.withValues(alpha: 0.84),
          borderColor: Colors.white.withValues(alpha: 0.4),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.indigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 34,
                  color: AppTheme.indigo.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noStudySetsYet,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.importOrCreate,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showCreateDialog(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.createBtn),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _importFromFile(context, ref),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(l10n.importBtn),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<StudySet> _sortAndFilter(List<StudySet> studySets) {
    final selectedFolderId = ref.read(selectedFolderIdProvider);
    final sortOption = ref.read(sortOptionProvider);

    var filtered = selectedFolderId == null
        ? studySets
        : studySets.where((s) => s.folderId == selectedFolderId).toList();

    final pinned = filtered.where((s) => s.isPinned).toList();
    final unpinned = filtered.where((s) => !s.isPinned).toList();

    int compare(StudySet a, StudySet b) {
      return switch (sortOption) {
        SortOption.newestFirst => b.createdAt.compareTo(a.createdAt),
        SortOption.alphabetical => a.title.compareTo(b.title),
        SortOption.mostDue => ref
            .read(dueCountForSetProvider(b.id))
            .compareTo(ref.read(dueCountForSetProvider(a.id))),
        SortOption.lastStudied =>
          (b.lastStudiedAt ?? DateTime(2000)).compareTo(
            a.lastStudiedAt ?? DateTime(2000),
          ),
      };
    }

    pinned.sort(compare);
    unpinned.sort(compare);

    return [...pinned, ...unpinned];
  }

  Widget _buildList(BuildContext context, List<StudySet> studySets) {
    ref.watch(selectedFolderIdProvider);
    ref.watch(sortOptionProvider);
    final dueCount = ref.watch(dueCountProvider);
    final todayReviewed = ref.watch(todayReviewCountProvider);
    final sorted = _sortAndFilter(studySets);
    final l10n = AppLocalizations.of(context);
    final recentSets = studySets.where((s) => s.lastStudiedAt != null).toList()
      ..sort((a, b) => b.lastStudiedAt!.compareTo(a.lastStudiedAt!));
    final continueSet =
        recentSets.isNotEmpty ? recentSets.first : (studySets.isNotEmpty ? studySets.first : null);
    final target = dueCount + todayReviewed;
    final focusProgress = target <= 0 ? 1.0 : (todayReviewed / target).clamp(0.0, 1.0);

    // Filter study sets by search query
    final searchFiltered = _homeSearchQuery.isEmpty
        ? sorted
        : sorted.where((s) {
            final q = _homeSearchQuery.toLowerCase();
            if (s.title.toLowerCase().contains(q)) return true;
            if (s.description.toLowerCase().contains(q)) return true;
            return s.cards.any((c) =>
                c.term.toLowerCase().contains(q) ||
                c.definition.toLowerCase().contains(q) ||
                c.tags.any((t) => t.toLowerCase().contains(q)));
          }).toList();

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 110),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: HomeSectionHeader(
            title: l10n.todayTasks,
            trailing: Text(
              l10n.nCards(studySets.fold<int>(0, (sum, s) => sum + s.cards.length)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    letterSpacing: 0.8,
                  ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: AdaptiveGlassCard(
            borderRadius: 20,
            fillColor: Colors.white.withValues(alpha: 0.82),
            borderColor: Colors.white.withValues(alpha: 0.44),
            elevation: 1.8,
            child: Stack(
              children: [
                Positioned(
                  top: -36,
                  right: -26,
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.34),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.58, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.28),
                            Colors.white.withValues(alpha: 0.06),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.indigo.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                              child: Icon(
                                dueCount > 0
                                    ? Icons.play_lesson_rounded
                                    : Icons.check_circle_rounded,
                                color: AppTheme.indigo,
                                size: 20,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              dueCount > 0 ? l10n.hasReviewTasks : l10n.allTasksCompleted,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: focusProgress,
                          minHeight: 10,
                          backgroundColor: AppTheme.indigo.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.indigo),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TaskMetric(
                              label: l10n.pendingReview,
                              value: '$dueCount',
                              tint: AppTheme.indigo,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TaskMetric(
                              label: l10n.completedToday,
                              value: '$todayReviewed',
                              tint: AppTheme.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TaskMetric(
                              label: l10n.studySetsLabel,
                              value: '${sorted.length}',
                              tint: AppTheme.cyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: dueCount > 0
                              ? () => context.push('/review')
                              : () => _showCreateOrImportSheet(context, ref),
                          icon: Icon(
                            dueCount > 0
                                ? Icons.play_circle_rounded
                                : Icons.add_circle_rounded,
                          ),
                          label: Text(dueCount > 0 ? l10n.startTodayReview : l10n.createOrImportSet),
                        ),
                      ),
                      if (dueCount <= 0) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => context.push('/study/custom'),
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: Text(l10n.useCustomPractice),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (continueSet != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: AdaptiveGlassCard(
              borderRadius: 14,
              fillColor: Colors.white.withValues(alpha: 0.78),
              borderColor: Colors.white.withValues(alpha: 0.38),
              elevation: 1.2,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.indigo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: AppTheme.indigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.continueLastSet(continueSet.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/study/${continueSet.id}'),
                    child: Text(l10n.goTo),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
          child: SizedBox(
            height: 120,
            child: Row(
              children: [
                Expanded(
                  child: HomeQuickActionTile(
                    icon: dueCount > 0
                        ? Icons.play_circle_fill_rounded
                        : Icons.history_rounded,
                    title: dueCount > 0
                        ? l10n.reviewCards
                        : (continueSet != null
                            ? l10n.goTo
                            : l10n.createBtn),
                    subtitle: dueCount > 0
                        ? l10n.nDueCards(dueCount)
                        : (continueSet != null
                            ? continueSet.title
                            : l10n.importOrCreate),
                    tint: AppTheme.indigo,
                    onTap: dueCount > 0
                        ? () => context.push('/review')
                        : (continueSet != null
                            ? () => context.push('/study/${continueSet.id}')
                            : () => _showCreateOrImportSheet(context, ref)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HomeQuickActionTile(
                    icon: Icons.search_rounded,
                    title: l10n.search,
                    subtitle: _homeSearchQuery.isEmpty
                        ? l10n.searchCards
                        : _homeSearchQuery,
                    tint: AppTheme.cyan,
                    onTap: () => setState(() => _isSearching = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HomeQuickActionTile(
                    icon: Icons.add_box_rounded,
                    title: l10n.createOrImportSet,
                    subtitle: l10n.importOrCreate,
                    tint: AppTheme.green,
                    onTap: () => _showCreateOrImportSheet(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: HomeSectionHeader(
            title: l10n.myStudySets,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${searchFiltered.length}',
                style: TextStyle(
                  color: AppTheme.indigo,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SortSelector(),
        const SizedBox(height: 8),
        // Folder section (inline)
        _buildFolderSection(context, ref, l10n),
          ...List<Widget>.generate(searchFiltered.length, (index) {
            final set = searchFiltered[index];
            final isSelected = _selectedSetIds.contains(set.id);
            return StaggeredFadeItem(
              index: index + 1,
              child: GestureDetector(
                onLongPress: () {
                  if (_isMultiSelectMode) return;
                  setState(() {
                    _isMultiSelectMode = true;
                    _selectedSetIds.add(set.id);
                  });
                },
                onTap: _isMultiSelectMode
                    ? () {
                        setState(() {
                          if (isSelected) {
                            _selectedSetIds.remove(set.id);
                            if (_selectedSetIds.isEmpty) {
                              _isMultiSelectMode = false;
                            }
                          } else {
                            _selectedSetIds.add(set.id);
                          }
                        });
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  decoration: isSelected
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.indigo,
                            width: 2,
                          ),
                        )
                      : null,
                  child: StudySetCard(
                    studySet: set,
                    onTap: _isMultiSelectMode
                        ? null
                        : () => context.push('/study/${set.id}'),
                    onDelete: _isMultiSelectMode
                        ? null
                        : () => _confirmDelete(context, ref, set),
                    onEdit: _isMultiSelectMode
                        ? null
                        : () => context.push('/edit/${set.id}'),
                    onMore: _isMultiSelectMode
                        ? null
                        : () => _showSetContextMenu(context, ref, set),
                  ),
                ),
              ),
            );
          }),
        if (searchFiltered.isEmpty) ...[
          if (_homeSearchQuery.isNotEmpty)
            // Search returned no results
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: AdaptiveGlassCard(
                borderRadius: 14,
                fillColor: Colors.white.withValues(alpha: 0.8),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.noResults,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (ref.watch(selectedFolderIdProvider) != null)
            // Folder filter active but empty
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: AdaptiveGlassCard(
                borderRadius: 14,
                fillColor: Colors.white.withValues(alpha: 0.8),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 36,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.folderEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        ref.read(selectedFolderIdProvider.notifier).state = null;
                      },
                      icon: const Icon(Icons.clear_all_rounded, size: 18),
                      label: Text(l10n.showAll),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildFolderSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final folders = ref.watch(foldersProvider);
    final selectedId = ref.watch(selectedFolderIdProvider);
    final allSets = ref.watch(studySetsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // "All" chip
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FolderChip(
                label: l10n.all,
                icon: Icons.apps_rounded,
                color: AppTheme.indigo,
                count: allSets.length,
                isSelected: selectedId == null,
                onTap: () =>
                    ref.read(selectedFolderIdProvider.notifier).state = null,
              ),
            ),
            // Folder chips
            ...folders.map((folder) {
              final color = Color(int.parse(folder.colorHex, radix: 16));
              final setCount =
                  allSets.where((s) => s.folderId == folder.id).length;
              final isSelected = selectedId == folder.id;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _FolderChip(
                  label: folder.name,
                  icon: MaterialIconMapper.fromCodePoint(folder.iconCodePoint),
                  color: color,
                  count: setCount,
                  isSelected: isSelected,
                  onTap: () =>
                      ref.read(selectedFolderIdProvider.notifier).state =
                          isSelected ? null : folder.id,
                  onLongPress: () =>
                      _showFolderContextMenu(context, ref, l10n, folder),
                ),
              );
            }),
            // "+" add folder chip
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ActionChip(
                avatar: Icon(Icons.add_rounded, size: 16, color: Colors.grey[800]),
                label: Text(
                  l10n.newFolder,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                onPressed: () => _showFolderDialog(context, ref, l10n),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderContextMenu(BuildContext context, WidgetRef ref, AppLocalizations l10n, Folder folder) {
    final user = ref.read(currentUserProvider);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editFolder),
              onTap: () {
                Navigator.pop(ctx);
                _showFolderDialog(context, ref, l10n, folder: folder);
              },
            ),
            if (user != null)
              ListTile(
                leading: const Icon(Icons.cloud_upload_rounded),
                title: Text(l10n.communityPublish),
                subtitle: Text(l10n.shareFolderToCommunity),
                onTap: () {
                  Navigator.pop(ctx);
                  _publishFolder(context, ref, l10n, folder);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppTheme.red),
              title: Text(l10n.delete, style: TextStyle(color: AppTheme.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteFolder(context, ref, l10n, folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteFolder(BuildContext context, WidgetRef ref, AppLocalizations l10n, Folder folder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteFolder),
        content: Text(l10n.deleteFolderConfirm(folder.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(foldersProvider.notifier).remove(folder.id);
              if (ref.read(selectedFolderIdProvider) == folder.id) {
                ref.read(selectedFolderIdProvider.notifier).state = null;
              }
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _publishFolder(BuildContext context, WidgetRef ref, AppLocalizations l10n, Folder folder) async {
    // Get all sets in this folder
    final setsInFolder = ref.read(studySetsProvider).where((s) => s.folderId == folder.id).toList();
    if (setsInFolder.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noStudySetsYet), behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }
    try {
      final service = ref.read(communityServiceProvider);
      for (final set in setsInFolder) {
        await service.publishStudySet(set);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.communityPublished} (${setsInFolder.length})'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showFolderDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n, {Folder? folder}) {
    final nameController = TextEditingController(text: folder?.name ?? '');
    final isEditing = folder != null;

    final colorOptions = [
      'FF6366F1', 'FF8B5CF6', 'FF3B82F6', 'FF06B6D4',
      'FF10B981', 'FFF59E0B', 'FFEF4444', 'FFEC4899',
    ];
    final iconOptions = [0xe6c4, 0xe335, 0xe153, 0xeb7b, 0xe3c9, 0xee94, 0xf06c, 0xea22];

    var selectedColor = folder?.colorHex ?? colorOptions[0];
    var selectedIcon = folder?.iconCodePoint ?? iconOptions[0];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? l10n.editFolder : l10n.newFolder),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.folderName),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Text(l10n.color, style: Theme.of(ctx).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colorOptions.map((hex) {
                    final color = Color(int.parse(hex, radix: 16));
                    final isSelected = hex == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = hex),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Theme.of(ctx).colorScheme.onSurface, width: 3) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(l10n.icon, style: Theme.of(ctx).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: iconOptions.map((codePoint) {
                    final isSelected = codePoint == selectedIcon;
                    final chipColor = Color(int.parse(selectedColor, radix: 16));
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = codePoint),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? chipColor.withValues(alpha: 0.2) : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected ? Border.all(color: chipColor, width: 2) : null,
                        ),
                        child: Icon(MaterialIconMapper.fromCodePoint(codePoint), size: 22, color: isSelected ? chipColor : Theme.of(ctx).colorScheme.onSurface),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final newFolder = Folder(
                  id: folder?.id ?? const Uuid().v4(),
                  name: name,
                  colorHex: selectedColor,
                  iconCodePoint: selectedIcon,
                  createdAt: folder?.createdAt ?? DateTime.now().toUtc(),
                );
                if (isEditing) {
                  ref.read(foldersProvider.notifier).update(newFolder);
                } else {
                  ref.read(foldersProvider.notifier).add(newFolder);
                }
                Navigator.pop(dialogContext);
              },
              child: Text(isEditing ? l10n.save : l10n.create),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetContextMenu(
      BuildContext context, WidgetRef ref, StudySet set) {
    final l10n = AppLocalizations.of(context);
    final folders = ref.read(foldersProvider);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.rename),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(context, ref, set);
              },
            ),
            ListTile(
              leading: Icon(
                set.isPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
              ),
              title: Text(set.isPinned ? l10n.unpin : l10n.pin),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(studySetsProvider.notifier).togglePin(set.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: Text(l10n.moveToFolder),
              subtitle: set.folderId != null
                  ? Text(
                      folders
                          .where((f) => f.id == set.folderId)
                          .map((f) => f.name)
                          .firstOrNull ??
                          '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                if (folders.isEmpty) {
                  _showFolderDialog(context, ref, l10n);
                } else {
                  _showMoveFolderDialog(context, ref, set);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_rounded),
              title: Text(l10n.shareSet),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/study/${set.id}/share');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, StudySet set) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: set.title);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.renameStudySet),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.title),
          onSubmitted: (_) {
            final newTitle = controller.text.trim();
            if (newTitle.isNotEmpty && newTitle != set.title) {
              ref
                  .read(studySetsProvider.notifier)
                  .update(set.copyWith(title: newTitle));
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != set.title) {
                ref
                    .read(studySetsProvider.notifier)
                    .update(set.copyWith(title: newTitle));
              }
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showMoveFolderDialog(
      BuildContext context, WidgetRef ref, StudySet set) {
    final folders = ref.read(foldersProvider);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.moveToFolder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.noFolder),
              selected: set.folderId == null,
              onTap: () {
                ref
                    .read(studySetsProvider.notifier)
                    .moveToFolder(set.id, null);
                Navigator.pop(ctx);
              },
            ),
            ...folders.map((folder) => ListTile(
                  leading: Icon(
                    MaterialIconMapper.fromCodePoint(folder.iconCodePoint),
                    color: Color(int.parse(folder.colorHex, radix: 16)),
                  ),
                  title: Text(folder.name),
                  selected: set.folderId == folder.id,
                  onTap: () {
                    ref
                        .read(studySetsProvider.notifier)
                        .moveToFolder(set.id, folder.id);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showCreateOrImportSheet(BuildContext screenContext, WidgetRef ref) {
    final l10n = AppLocalizations.of(screenContext);
    showModalBottomSheet(
      context: screenContext,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(
        alpha: isLiquidGlassSupported ? 0.16 : 0.26,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final sheetContent = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  sheetContext,
                ).colorScheme.outlineVariant.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            SheetItem(
              icon: CupertinoIcons.plus,
              iconColor: AppTheme.indigo,
              title: l10n.createNewSet,
              subtitle: l10n.createNewSetSubtitle,
              onTap: () async {
                Navigator.pop(sheetContext);
                await Future<void>.delayed(const Duration(milliseconds: 120));
                if (!screenContext.mounted) return;
                _showCreateDialog(screenContext, ref);
              },
            ),
            SheetItem(
              icon: CupertinoIcons.globe,
              iconColor: AppTheme.purple,
              title: l10n.importFromRecall,
              subtitle: l10n.importFromWebSubtitle,
              onTap: () {
                Navigator.pop(sheetContext);
                screenContext.push('/import');
              },
            ),
            SheetItem(
              icon: CupertinoIcons.doc,
              iconColor: AppTheme.green,
              title: l10n.importFromFile,
              subtitle: l10n.importFromFileSubtitle,
              onTap: () {
                Navigator.pop(sheetContext);
                _importFromFile(screenContext, ref);
              },
            ),
            SheetItem(
              icon: CupertinoIcons.qrcode,
              iconColor: AppTheme.cyan,
              title: l10n.scanQr,
              subtitle: l10n.scanQrSubtitle,
              onTap: () {
                Navigator.pop(sheetContext);
                screenContext.push('/scan');
              },
            ),
            SheetItem(
              icon: CupertinoIcons.camera,
              iconColor: AppTheme.orange,
              title: l10n.photoToFlashcard,
              subtitle: l10n.photoToFlashcardSubtitle,
              onTap: () {
                Navigator.pop(sheetContext);
                final apiKey = ref.read(geminiKeyProvider);
                if (apiKey.isEmpty) {
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    SnackBar(content: Text(l10n.geminiApiKeyNotSet)),
                  );
                  return;
                }
                screenContext.push('/import/photo');
              },
            ),
            const SizedBox(height: 10),
          ],
        );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: isLiquidGlassSupported
                ? LiquidGlass(
                    borderRadius: 24,
                    blurSigma: 22,
                    tintColor: Theme.of(
                      sheetContext,
                    ).colorScheme.surface.withValues(alpha: 0.24),
                    child: sheetContent,
                  )
                : Container(
                    decoration: AppTheme.softCardDecoration(
                      fillColor: Theme.of(sheetContext).colorScheme.surface,
                      borderRadius: 24,
                      elevation: 1.4,
                    ),
                    child: sheetContent,
                  ),
          ),
        );
      },
    );
  }

  Future<void> _importFromFile(BuildContext context, WidgetRef ref) async {
    final service = ImportExportService();
    final studySet = await service.importFromFile();
    if (studySet != null && context.mounted) {
      context.push('/import/review', extra: studySet);
    }
  }

  Future<void> _showCreateDialog(
    BuildContext screenContext,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(screenContext);
    final folders = ref.read(foldersProvider);
    var draftTitle = '';
    var draftDescription = '';
    // Default to the currently selected folder filter
    String? selectedFolderId = ref.read(selectedFolderIdProvider);

    final result = await showDialog<Map<String, String?>>(
      context: screenContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.newStudySet),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: l10n.title),
                  autofocus: true,
                  onChanged: (value) => draftTitle = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.descriptionOptional,
                  ),
                  onChanged: (value) => draftDescription = value,
                ),
                if (folders.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: selectedFolderId,
                    decoration: InputDecoration(
                      labelText: l10n.folders,
                      prefixIcon: Icon(
                        Icons.folder_rounded,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          l10n.noFolder,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      ...folders.map((folder) {
                        final color =
                            Color(int.parse(folder.colorHex, radix: 16));
                        return DropdownMenuItem<String?>(
                          value: folder.id,
                          child: Row(
                            children: [
                              Icon(
                                MaterialIconMapper.fromCodePoint(
                                    folder.iconCodePoint),
                                color: color,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(folder.name),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedFolderId = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final trimmedTitle = draftTitle.trim();
                if (trimmedTitle.isEmpty) return;
                Navigator.pop(dialogContext, <String, String?>{
                  'title': trimmedTitle,
                  'description': draftDescription.trim(),
                  'folderId': selectedFolderId,
                });
              },
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;
    final newSet = StudySet(
      id: const Uuid().v4(),
      title: result['title'] ?? '',
      description: result['description'] ?? '',
      folderId: result['folderId'],
      createdAt: DateTime.now().toUtc(),
      cards: [],
    );
    ref.read(studySetsProvider.notifier).add(newSet);
    if (screenContext.mounted) {
      screenContext.push('/edit/${newSet.id}');
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, StudySet set) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteStudySet),
        content: Text(l10n.deleteStudySetConfirm(set.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(studySetsProvider.notifier).remove(set.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _FolderChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : Theme.of(context).colorScheme.outline),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.12)
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
