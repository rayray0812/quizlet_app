import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/providers/sync_provider.dart';
import 'package:recall_app/providers/locale_provider.dart';
import 'package:recall_app/core/icons/material_icon_mapper.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/core/widgets/glass_press_effect.dart';
import 'package:recall_app/core/widgets/liquid_glass.dart';
import 'package:recall_app/features/home/screens/search_screen.dart';
import 'package:recall_app/features/stats/screens/stats_screen.dart';
import 'package:recall_app/features/home/widgets/study_set_card.dart';
import 'package:recall_app/features/home/widgets/today_review_card.dart';
import 'package:recall_app/features/home/widgets/daily_challenge_card.dart';
import 'package:recall_app/features/home/widgets/revenge_card.dart';
import 'package:recall_app/services/import_export_service.dart';
import 'package:recall_app/services/local_storage_service.dart';
import 'package:recall_app/providers/folder_provider.dart';
import 'package:recall_app/providers/sort_provider.dart';
import 'package:recall_app/providers/pomodoro_provider.dart';
import 'package:recall_app/providers/gemini_key_provider.dart';
import 'package:recall_app/features/home/widgets/folder_chips.dart';
import 'package:recall_app/features/home/widgets/sort_selector.dart';
import 'package:recall_app/providers/notification_provider.dart';
import 'package:recall_app/providers/widget_provider.dart';
import 'package:recall_app/providers/biometric_provider.dart';
import 'package:recall_app/providers/auth_analytics_provider.dart';
import 'package:recall_app/providers/admin_provider.dart';
import 'package:recall_app/models/sync_conflict.dart';

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
    final now = DateTime.now();
    final pageTitle = switch (_currentTab) {
      1 => l10n.search,
      2 => l10n.statistics,
      3 => l10n.settings,
      _ => AppConstants.appName,
    };
    final showFab = _currentTab == 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.8,
              ),
            ),
          ),
        ),
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
          child: _currentTab == 0
              ? Column(
                  key: const ValueKey('home-title'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pageTitle,
                      style: TextStyle(
                        color: AppTheme.indigo,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      '${now.month}/${now.day} �P ${l10n.todayReview}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                )
              : Text(
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: AppTheme.softCardDecoration(
            fillColor: Colors.white.withValues(alpha: 0.9),
            borderRadius: 22,
            borderColor: Theme.of(context).colorScheme.outlineVariant,
            elevation: 1,
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
                      : Icons.no_accounts_outlined,
                ),
                selectedIcon: Icon(
                  user != null ? Icons.person_rounded : Icons.no_accounts_rounded,
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

    return IndexedStack(
      index: _currentTab,
      children: pages,
    );
  }

  Widget _buildSettingsTab(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final supabase = ref.read(supabaseServiceProvider);
    final user = supabase.currentUser;
    final locale = ref.watch(localeProvider);
    final biometricQuickUnlockEnabled = ref.watch(biometricQuickUnlockProvider);
    final isAdmin = ref
        .watch(adminAccessProvider)
        .maybeWhen(data: (value) => value, orElse: () => false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        _AdaptiveSettingsCard(
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
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _GeminiApiKeyCard(),
        const SizedBox(height: 14),
        const _NotificationCard(),
        const SizedBox(height: 14),
        _AdaptiveSettingsCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.emoji_events_rounded),
                title: Text(l10n.achievements),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/achievements'),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              ListTile(
                leading: const Icon(Icons.folder_rounded),
                title: Text(l10n.folders),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/folders'),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              ListTile(
                leading: const Icon(Icons.timer_rounded),
                title: Text(l10n.pomodoro),
                subtitle: Text(l10n.pomodoroDesc),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ref.read(pomodoroProvider.notifier).start();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.pomodoroStarted)),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AdaptiveSettingsCard(
          child: SwitchListTile(
            secondary: const Icon(Icons.fingerprint_rounded),
            title: const Text('Biometric Quick Unlock'),
            subtitle: Text(
              user == null
                  ? 'Sign in first to enable biometric unlock.'
                  : 'Require biometric unlock when returning to app.',
            ),
            value: biometricQuickUnlockEnabled,
            onChanged: user == null
                ? null
                : (enabled) => _toggleBiometricQuickUnlock(
                    context: context,
                    ref: ref,
                    enabled: enabled,
                  ),
          ),
        ),
        const SizedBox(height: 14),
        _AdaptiveSettingsCard(
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
                    if (isAdmin)
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings_rounded),
                        title: const Text('Admin Console'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/admin'),
                      ),
                    ListTile(
                      leading: const Icon(Icons.security_rounded),
                      title: const Text('Security Center'),
                      subtitle: const Text(
                        'Manage sessions and account security actions.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showSecurityCenterDialog(
                        context: context,
                        ref: ref,
                        email: user.email ?? 'Unknown',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await ref
                                .read(authAnalyticsServiceProvider)
                                .logAuthEvent(
                                  action: 'sign_out',
                                  provider: 'session',
                                  result: 'local',
                                );
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

  Future<void> _toggleBiometricQuickUnlock({
    required BuildContext context,
    required WidgetRef ref,
    required bool enabled,
  }) async {
    final notifier = ref.read(biometricQuickUnlockProvider.notifier);
    if (!enabled) {
      await notifier.setEnabled(false);
      return;
    }

    final biometricService = ref.read(biometricServiceProvider);
    final available = await biometricService.isBiometricAvailable();
    if (!available) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication is not available.'),
        ),
      );
      return;
    }

    final verified = await biometricService.authenticateForUnlock();
    if (!context.mounted) return;
    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric verification failed. Try again.'),
        ),
      );
      return;
    }

    await notifier.setEnabled(true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometric quick unlock enabled.')),
    );
  }

  Future<void> _showSecurityCenterDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String email,
  }) async {
    final supabase = ref.read(supabaseServiceProvider);
    final analytics = ref.read(authAnalyticsServiceProvider);
    final localStorage = ref.read(localStorageServiceProvider);
    final importExportService = ImportExportService();
    final conflicts = ref.read(syncConflictsProvider);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Security Center'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current account: $email'),
            const SizedBox(height: 8),
            Text('Sync conflicts: ${conflicts.length}'),
            const SizedBox(height: 8),
            const Text(
              'Use these actions when you suspect account access on another device.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showSyncConflictDialog(context: context, ref: ref);
            },
            child: const Text('Resolve Conflicts'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _showEncryptedBackupDialog(
                context: context,
                localStorage: localStorage,
                importExportService: importExportService,
              );
            },
            child: const Text('Encrypted Backup'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _showDeleteAccountDialog(context: context, ref: ref);
            },
            child: const Text('Delete Account'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await analytics.logAuthEvent(
                action: 'sign_out',
                provider: 'session',
                result: 'local',
              );
              await supabase.signOut();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Sign Out This Device'),
          ),
          ElevatedButton(
            onPressed: () async {
              await analytics.logAuthEvent(
                action: 'sign_out',
                provider: 'session',
                result: 'global',
              );
              await supabase.signOutAllSessions();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Sign Out All Devices'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSyncConflictDialog({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final syncService = ref.read(syncServiceProvider);
    final conflicts = ref.read(syncConflictsProvider);
    if (conflicts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sync conflicts detected.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sync Conflicts'),
        content: SizedBox(
          width: 500,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: conflicts.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, index) {
              final conflict = conflicts[index];
              return _ConflictRow(
                conflict: conflict,
                onKeepLocal: () async {
                  await syncService.resolveConflictKeepLocal(conflict.setId);
                  ref.invalidate(syncConflictsProvider);
                },
                onKeepRemote: () async {
                  await syncService.resolveConflictKeepRemote(conflict.setId);
                  ref.invalidate(syncConflictsProvider);
                  ref.read(studySetsProvider.notifier).refresh();
                },
                onMerge: () async {
                  await syncService.resolveConflictMerge(conflict.setId);
                  ref.invalidate(syncConflictsProvider);
                  ref.read(studySetsProvider.notifier).refresh();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEncryptedBackupDialog({
    required BuildContext context,
    required LocalStorageService localStorage,
    required ImportExportService importExportService,
  }) async {
    final passphraseController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Encrypted Backup'),
        content: TextField(
          controller: passphraseController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Passphrase',
            hintText: 'At least 8 characters',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final passphrase = passphraseController.text;
              if (passphrase.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passphrase must be at least 8 characters.')),
                );
                return;
              }
              try {
                await importExportService.exportEncryptedBackup(
                  localStorage: localStorage,
                  passphrase: passphrase,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Encrypted backup exported.')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
              } finally {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text('Export'),
          ),
          ElevatedButton(
            onPressed: () async {
              final passphrase = passphraseController.text;
              try {
                final result = await importExportService.importEncryptedBackup(
                  localStorage: localStorage,
                  passphrase: passphrase,
                );
                if (!context.mounted) return;
                ref.read(studySetsProvider.notifier).refresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Imported ${result.setCount} sets, ${result.progressCount} progress, ${result.reviewLogCount} logs.',
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
              } finally {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
    passphraseController.dispose();
  }

  Future<void> _showDeleteAccountDialog({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final passwordController = TextEditingController();
    final supabase = ref.read(supabaseServiceProvider);
    final analytics = ref.read(authAnalyticsServiceProvider);
    final localStorage = ref.read(localStorageServiceProvider);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action is irreversible. Enter password to re-authenticate if needed.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password (optional for OAuth users)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final fullDeleted = await supabase.deleteCurrentAccount(
                  passwordForReauth: passwordController.text,
                );
                await localStorage.clearAllStudyData();
                await analytics.logAuthEvent(
                  action: 'delete_account',
                  provider: 'session',
                  result: fullDeleted ? 'full_deleted' : 'data_deleted',
                );
                if (!context.mounted) return;
                ref.read(studySetsProvider.notifier).refresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      fullDeleted
                          ? 'Account deleted successfully.'
                          : 'Account data deleted. Ask admin to enable full auth-user deletion RPC.',
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete account failed: $e')),
                );
              } finally {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    passwordController.dispose();
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
        SortOption.mostDue => 0, // handled below
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
    final sorted = _sortAndFilter(studySets);
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 110),
      children: [
        TodayReviewCard(animating: _currentTab == 0),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: _HomeSectionHeader(
            title: 'Study Modes',
            trailing: Text(
              'Quick Access',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    letterSpacing: 0.8,
                  ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: GridView.count(
            crossAxisCount: 2,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.24,
            children: [
              _HomeQuickActionTile(
                icon: Icons.play_circle_outline_rounded,
                title: l10n.todayReview,
                subtitle: l10n.startReview,
                tint: AppTheme.indigo,
                onTap: () => context.push('/review'),
              ),
              _HomeQuickActionTile(
                icon: Icons.edit_note_rounded,
                title: l10n.customStudy,
                subtitle: 'Pick a mode',
                tint: AppTheme.cyan,
                onTap: () => context.push('/study/custom'),
              ),
              _HomeQuickActionTile(
                icon: Icons.search_rounded,
                title: l10n.search,
                subtitle: 'Find cards',
                tint: AppTheme.purple,
                onTap: () => setState(() => _currentTab = 1),
              ),
              _HomeQuickActionTile(
                icon: Icons.add_box_rounded,
                title: l10n.createBtn,
                subtitle: l10n.importBtn,
                tint: AppTheme.orange,
                onTap: () => _showCreateOrImportSheet(context, ref),
              ),
            ],
          ),
        ),
        const DailyChallengeCard(),
        const RevengeCard(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: _HomeSectionHeader(
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
        const SortSelector(),
          ...List<Widget>.generate(sorted.length, (index) {
            final set = sorted[index];
            return _StaggeredFadeItem(
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
              icon: Icons.qr_code_scanner_rounded,
              iconColor: AppTheme.cyan,
              title: l10n.scanQr,
              onTap: () {
                Navigator.pop(sheetContext);
                screenContext.push('/scan');
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
    final titleController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
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
              final trimmedTitle = titleController.text.trim();
              if (trimmedTitle.isEmpty) return;
              Navigator.pop(dialogContext, <String, String>{
                'title': trimmedTitle,
                'description': descController.text.trim(),
              });
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    titleController.dispose();
    descController.dispose();

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

class _HomeSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _HomeSectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.indigo,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _HomeQuickActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;

  const _HomeQuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  @override
  State<_HomeQuickActionTile> createState() => _HomeQuickActionTileState();
}

class _HomeQuickActionTileState extends State<_HomeQuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTap: () {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: AppTheme.softCardDecoration(
            fillColor: Colors.white,
            borderRadius: 14,
            borderColor: widget.tint.withValues(alpha: 0.22),
            elevation: _pressed ? 0.8 : 1.1,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.tint, size: 22),
              ),
              const Spacer(),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
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
    return GlassPressEffect(
      borderRadius: 12,
      pressedOpacity: 0.13,
      child: ListTile(
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
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade400,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}

class _ConflictRow extends StatelessWidget {
  final SyncConflict conflict;
  final Future<void> Function() onKeepLocal;
  final Future<void> Function() onKeepRemote;
  final Future<void> Function() onMerge;

  const _ConflictRow({
    required this.conflict,
    required this.onKeepLocal,
    required this.onKeepRemote,
    required this.onMerge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          conflict.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Local: ${conflict.localUpdatedAt.toLocal()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          'Remote: ${conflict.remoteUpdatedAt.toLocal()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => onKeepLocal(),
              child: const Text('Keep Local'),
            ),
            OutlinedButton(
              onPressed: () => onKeepRemote(),
              child: const Text('Keep Remote'),
            ),
            ElevatedButton(
              onPressed: () => onMerge(),
              child: const Text('Merge'),
            ),
          ],
        ),
      ],
    );
  }
}

class _GeminiApiKeyCard extends ConsumerStatefulWidget {
  const _GeminiApiKeyCard();

  @override
  ConsumerState<_GeminiApiKeyCard> createState() => _GeminiApiKeyCardState();
}

class _GeminiApiKeyCardState extends ConsumerState<_GeminiApiKeyCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final currentKey = ref.read(geminiKeyProvider);
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
    return _AdaptiveSettingsCard(
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
                    ref.read(geminiKeyProvider.notifier).setApiKey(key);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.geminiApiKeySaved)),
                    );
                  },
                  icon: const Icon(Icons.save_rounded),
                  style: IconButton.styleFrom(foregroundColor: AppTheme.indigo),
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
  const _NotificationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(notificationProvider);

    return _AdaptiveSettingsCard(
      child: SwitchListTile(
        secondary: const Icon(Icons.notifications_rounded),
        title: Text(l10n.dailyReminder),
        subtitle: Text(l10n.dailyReminderDesc),
        value: enabled,
        onChanged: (value) {
          ref
              .read(notificationProvider.notifier)
              .toggle(
                value,
                title: l10n.reminderTitle,
                body: l10n.reminderBody,
              );
        },
      ),
    );
  }
}

class _AdaptiveSettingsCard extends StatelessWidget {
  final Widget child;

  const _AdaptiveSettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassCard(
      borderRadius: 20,
      fillColor: Theme.of(context).cardColor,
      elevation: 1.2,
      child: child,
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

    final delay = Duration(milliseconds: 80 * (widget.index.clamp(0, 8)));
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

