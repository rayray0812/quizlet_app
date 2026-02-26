import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/providers/sync_provider.dart';
import 'package:recall_app/core/icons/material_icon_mapper.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/core/widgets/liquid_glass.dart';
import 'package:recall_app/features/home/screens/search_screen.dart';
import 'package:recall_app/features/stats/screens/stats_screen.dart';
import 'package:recall_app/features/home/screens/settings_tab.dart';
import 'package:recall_app/features/home/widgets/study_set_card.dart';
import 'package:recall_app/features/home/widgets/dashboard_helpers.dart';
import 'package:recall_app/services/import_export_service.dart';
import 'package:recall_app/providers/folder_provider.dart';
import 'package:recall_app/providers/sort_provider.dart';
import 'package:recall_app/providers/gemini_key_provider.dart';
import 'package:recall_app/features/home/widgets/folder_chips.dart';
import 'package:recall_app/features/home/widgets/sort_selector.dart';
import 'package:recall_app/providers/widget_provider.dart';
import 'package:recall_app/providers/fsrs_provider.dart';
import 'package:recall_app/providers/stats_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    // Sync widget data when app opens
    Future.microtask(() {
      if (mounted) ref.read(widgetRefreshProvider)();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studySets = ref.watch(studySetsProvider);
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);
    final pageTitle = switch (_currentTab) {
      1 => l10n.search,
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
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: _currentTab == 0
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
                        1 => Icons.search_rounded,
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
          if (_currentTab == 0)
            IconButton(
              icon: const Icon(Icons.groups_2_rounded, size: 22),
              onPressed: () => context.push('/classes'),
              tooltip: 'Classes',
            ),
          if (_currentTab == 0)
            IconButton(
              icon: const Icon(Icons.search_rounded, size: 22),
              onPressed: () => setState(() => _currentTab = 1),
              tooltip: l10n.search,
            ),
          if (_currentTab == 0 && user != null)
            IconButton(
              icon: const Icon(Icons.sync_rounded, size: 22),
              onPressed: () => ref.refresh(syncProvider),
              tooltip: l10n.sync,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Padding(
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
                icon: const Icon(CupertinoIcons.search),
                selectedIcon: const Icon(CupertinoIcons.search),
                label: l10n.search,
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
      const SearchScreen(embedded: true),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
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
                        onPressed: () => context.push('/import'),
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
      ),
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

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 110),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
                          minHeight: 7,
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
                '${sorted.length}',
                style: TextStyle(
                  color: AppTheme.indigo,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const FolderChips(),
        const SizedBox(height: 10),
        const SortSelector(),
        const SizedBox(height: 8),
          ...List<Widget>.generate(sorted.length, (index) {
            final set = sorted[index];
            return StaggeredFadeItem(
              index: index + 1,
              child: GestureDetector(
                onLongPress: () => _showSetContextMenu(context, ref, set),
                child: StudySetCard(
                  studySet: set,
                  onTap: () => context.push('/study/${set.id}'),
                  onDelete: () => _confirmDelete(context, ref, set),
                  onEdit: () => context.push('/edit/${set.id}'),
                ),
              ),
            );
          }),
      ],
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
            if (folders.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.drive_file_move_outlined),
                title: Text(l10n.moveToFolder),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMoveFolderDialog(context, ref, set);
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
              onTap: () {
                Navigator.pop(sheetContext);
                screenContext.push('/import');
              },
            ),
            SheetItem(
              icon: CupertinoIcons.doc,
              iconColor: AppTheme.green,
              title: l10n.importFromFile,
              onTap: () {
                Navigator.pop(sheetContext);
                _importFromFile(screenContext, ref);
              },
            ),
            SheetItem(
              icon: CupertinoIcons.qrcode,
              iconColor: AppTheme.cyan,
              title: l10n.scanQr,
              onTap: () {
                Navigator.pop(sheetContext);
                screenContext.push('/scan');
              },
            ),
            SheetItem(
              icon: CupertinoIcons.camera,
              iconColor: AppTheme.orange,
              title: l10n.photoToFlashcard,
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
    var draftTitle = '';
    var draftDescription = '';

    final result = await showDialog<Map<String, String>>(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
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
              Navigator.pop(dialogContext, <String, String>{
                'title': trimmedTitle,
                'description': draftDescription.trim(),
              });
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;
    final newSet = StudySet(
      id: const Uuid().v4(),
      title: result['title'] ?? '',
      description: result['description'] ?? '',
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
