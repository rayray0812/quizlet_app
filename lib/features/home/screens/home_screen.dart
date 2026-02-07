import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/providers/sync_provider.dart';
import 'package:recall_app/providers/locale_provider.dart';
import 'package:recall_app/providers/theme_provider.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/features/home/screens/search_screen.dart';
import 'package:recall_app/features/stats/screens/stats_screen.dart';
import 'package:recall_app/features/home/widgets/study_set_card.dart';
import 'package:recall_app/features/home/widgets/today_review_card.dart';
import 'package:recall_app/services/import_export_service.dart';
import 'package:recall_app/providers/gemini_key_provider.dart';
import 'package:recall_app/providers/notification_provider.dart';
import 'package:recall_app/providers/widget_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
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
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            pageTitle,
            key: ValueKey(pageTitle),
            style: TextStyle(
              color: AppTheme.indigo,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          if (_currentTab == 0 && user != null)
            IconButton(
              icon: const Icon(Icons.sync_rounded, size: 22),
              onPressed: () => ref.refresh(syncProvider),
              tooltip: l10n.sync,
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerLowest,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildAnimatedTabBody(context, ref, studySets, l10n),
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
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add_rounded, size: 28),
              )
            : const SizedBox.shrink(key: ValueKey('empty-fab')),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: NavigationBar(
            height: 72,
            selectedIndex: _currentTab,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              setState(() => _currentTab = index);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: l10n.home,
              ),
              NavigationDestination(
                icon: const Icon(Icons.search_outlined),
                selectedIcon: const Icon(Icons.search_rounded),
                label: l10n.search,
              ),
              NavigationDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart_rounded),
                label: l10n.statistics,
              ),
              NavigationDestination(
                icon: Icon(
                  user != null
                      ? Icons.person_outline_rounded
                      : Icons.person_outline_rounded,
                ),
                selectedIcon: Icon(
                  user != null ? Icons.person_rounded : Icons.person_rounded,
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
      _buildSettingsTab(context, ref),
    ];

    return Stack(
      children: List.generate(pages.length, (index) {
        final selected = index == _currentTab;
        return IgnorePointer(
          ignoring: !selected,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            opacity: selected ? 1 : 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              offset: selected ? Offset.zero : const Offset(0.04, 0),
              child: pages[index],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSettingsTab(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final supabase = ref.read(supabaseServiceProvider);
    final user = supabase.currentUser;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Container(
          decoration: AppTheme.softCardDecoration(
            fillColor: Theme.of(context).cardColor,
            borderRadius: 20,
            elevation: 1.2,
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: Text(l10n.language),
                subtitle: Text(
                  locale.languageCode == 'zh' ? l10n.chinese : l10n.english,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showLanguageMenu(context, ref),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.theme),
                subtitle: Text(switch (themeMode) {
                  ThemeMode.light => l10n.lightMode,
                  ThemeMode.dark => l10n.darkMode,
                  ThemeMode.system => l10n.systemMode,
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text(l10n.systemMode),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text(l10n.lightMode),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text(l10n.darkMode),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) {
                    themeNotifier.setThemeMode(selection.first);
                  },
                  showSelectedIcon: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _GeminiApiKeyCard(ref: ref),
        const SizedBox(height: 14),
        _NotificationCard(ref: ref),
        const SizedBox(height: 14),
        Container(
          decoration: AppTheme.softCardDecoration(
            fillColor: Theme.of(context).cardColor,
            borderRadius: 20,
            elevation: 1.2,
          ),
          child: user == null
              ? ListTile(
                  leading: const Icon(Icons.login_rounded),
                  title: Text(l10n.logIn),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/login'),
                )
              : Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_rounded),
                      title: Text(l10n.profile),
                      subtitle: Text(user.email ?? 'Unknown'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await supabase.signOut();
                            if (mounted) {
                              setState(() => _currentTab = 0);
                            }
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(l10n.signOut),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.indigo.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.library_books_rounded,
                  size: 48,
                  color: AppTheme.indigo.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.noStudySetsYet,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.importOrCreate,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(l10n.createBtn),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/import'),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: Text(l10n.importBtn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<StudySet> studySets) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: studySets.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const TodayReviewCard();
        }
        final set = studySets[index - 1];
        return _StaggeredFadeItem(
          index: index - 1,
          child: StudySetCard(
            studySet: set,
            onTap: () => context.push('/study/${set.id}'),
            onDelete: () => _confirmDelete(context, ref, set),
            onEdit: () => context.push('/edit/${set.id}'),
          ),
        );
      },
    );
  }

  void _showLanguageMenu(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.chinese),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('zh', 'TW'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.english),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('en', 'US'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOrImportSheet(BuildContext screenContext, WidgetRef ref) {
    final l10n = AppLocalizations.of(screenContext);
    showModalBottomSheet(
      context: screenContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _SheetItem(
                icon: Icons.add_rounded,
                iconColor: AppTheme.indigo,
                title: l10n.createNewSet,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showCreateDialog(screenContext, ref);
                },
              ),
              _SheetItem(
                icon: Icons.language_rounded,
                iconColor: AppTheme.purple,
                title: l10n.importFromRecall,
                onTap: () {
                  Navigator.pop(sheetContext);
                  screenContext.push('/import');
                },
              ),
              _SheetItem(
                icon: Icons.file_open_rounded,
                iconColor: AppTheme.green,
                title: l10n.importFromFile,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _importFromFile(screenContext, ref);
                },
              ),
              _SheetItem(
                icon: Icons.camera_alt_rounded,
                iconColor: AppTheme.orange,
                title: l10n.photoToFlashcard,
                onTap: () {
                  Navigator.pop(sheetContext);
                  final apiKey = ref.read(geminiKeyProvider);
                  if (apiKey.isEmpty) {
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      SnackBar(
                        content: Text(l10n.geminiApiKeyNotSet),
                      ),
                    );
                    return;
                  }
                  screenContext.push('/import/photo');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importFromFile(BuildContext context, WidgetRef ref) async {
    final service = ImportExportService();
    final studySet = await service.importFromFile();
    if (studySet != null && context.mounted) {
      context.push('/import/review', extra: studySet);
    }
  }

  void _showCreateDialog(BuildContext screenContext, WidgetRef ref) {
    final l10n = AppLocalizations.of(screenContext);
    final titleController = TextEditingController();
    final descController = TextEditingController();
    var disposed = false;

    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.newStudySet),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: l10n.title),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: l10n.descriptionOptional,
                ),
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
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              final newSet = StudySet(
                id: const Uuid().v4(),
                title: title,
                description: descController.text.trim(),
                createdAt: DateTime.now().toUtc(),
                cards: [],
              );
              ref.read(studySetsProvider.notifier).add(newSet);
              Navigator.pop(dialogContext);
              screenContext.push('/edit/${newSet.id}');
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    ).then((_) {
      if (!disposed) {
        titleController.dispose();
        descController.dispose();
        disposed = true;
      }
    });
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

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _SheetItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}

class _GeminiApiKeyCard extends StatefulWidget {
  final WidgetRef ref;

  const _GeminiApiKeyCard({required this.ref});

  @override
  State<_GeminiApiKeyCard> createState() => _GeminiApiKeyCardState();
}

class _GeminiApiKeyCardState extends State<_GeminiApiKeyCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final currentKey = widget.ref.read(geminiKeyProvider);
    _controller = TextEditingController(text: currentKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: AppTheme.softCardDecoration(
        fillColor: Theme.of(context).cardColor,
        borderRadius: 20,
        elevation: 1.2,
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: Text(l10n.geminiApiKey),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: l10n.geminiApiKeyHint,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    final key = _controller.text.trim();
                    widget.ref
                        .read(geminiKeyProvider.notifier)
                        .setApiKey(key);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.geminiApiKeySaved)),
                    );
                  },
                  icon: const Icon(Icons.save_rounded),
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.indigo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final WidgetRef ref;

  const _NotificationCard({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(notificationProvider);

    return Container(
      decoration: AppTheme.softCardDecoration(
        fillColor: Theme.of(context).cardColor,
        borderRadius: 20,
        elevation: 1.2,
      ),
      child: SwitchListTile(
        secondary: const Icon(Icons.notifications_rounded),
        title: Text(l10n.dailyReminder),
        subtitle: Text(l10n.dailyReminderDesc),
        value: enabled,
        onChanged: (value) {
          ref.read(notificationProvider.notifier).toggle(
            value,
            title: l10n.reminderTitle,
            body: l10n.reminderBody,
          );
        },
      ),
    );
  }
}

/// Staggered fade-in animation for list items.
class _StaggeredFadeItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredFadeItem({required this.index, required this.child});

  @override
  State<_StaggeredFadeItem> createState() => _StaggeredFadeItemState();
}

class _StaggeredFadeItemState extends State<_StaggeredFadeItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    final delay = Duration(milliseconds: 60 * (widget.index.clamp(0, 8)));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

