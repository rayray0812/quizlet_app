import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
          const Positioned.fill(child: _BackdropAccents()),
          if (_currentTab == 0) const _HomeAmbientGlow(),
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
        child: _buildSettingsTab(context, ref),
      ),
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
    final reminderEnabled = ref.watch(notificationProvider);
    final biometricQuickUnlockEnabled = ref.watch(biometricQuickUnlockProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isAdmin = ref
        .watch(adminAccessProvider)
        .maybeWhen(data: (value) => value, orElse: () => false);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 28 + bottomInset),
      children: [
        // -- User card --
        _AdaptiveSettingsCard(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.52),
                  AppTheme.indigo.withValues(alpha: 0.1),
                  AppTheme.cyan.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
                  ),
                  child: Icon(
                    user == null ? CupertinoIcons.person : CupertinoIcons.person_fill,
                    color: AppTheme.indigo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user == null ? l10n.guestMode : l10n.personalSettings,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? l10n.loginToSync,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user == null)
                  FilledButton(
                    onPressed: () => context.push('/login'),
                    child: Text(l10n.logIn),
                  ),
              ],
            ),
          ),
        ),

        // -- General --
        const SizedBox(height: 18),
        _SettingsGroupTitle(l10n.settingsPreferences),
        _AdaptiveSettingsCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                minLeadingWidth: 24,
                leading: const Icon(CupertinoIcons.paintbrush),
                title: _serifSettingTitle(context, l10n.displayAndLanguage),
                subtitle: Text(l10n.displaySubtitle),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: () => _showDisplaySettingsSheet(context: context, ref: ref),
              ),
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                secondary: const Icon(CupertinoIcons.bell),
                title: _serifSettingTitle(context, l10n.dailyReviewReminder),
                value: reminderEnabled,
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
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                secondary: const Icon(CupertinoIcons.lock_shield),
                title: _serifSettingTitle(context, l10n.biometricUnlock),
                value: biometricQuickUnlockEnabled,
                onChanged: user == null
                    ? null
                    : (enabled) => _toggleBiometricQuickUnlock(
                          context: context,
                          ref: ref,
                          enabled: enabled,
                        ),
              ),
            ],
          ),
        ),

        // -- Learning tools --
        const SizedBox(height: 18),
        _SettingsGroupTitle(l10n.settingsLearning),
        _AdaptiveSettingsCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                minLeadingWidth: 24,
                leading: const Icon(CupertinoIcons.star),
                title: _serifSettingTitle(context, l10n.achievements),
                subtitle: Text(l10n.achievementsSubtitle),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: () => context.push('/achievements'),
              ),
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                minLeadingWidth: 24,
                leading: const Icon(CupertinoIcons.folder),
                title: _serifSettingTitle(context, l10n.folders),
                subtitle: Text(l10n.foldersSubtitle),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: () => context.push('/folders'),
              ),
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                minLeadingWidth: 24,
                leading: const Icon(CupertinoIcons.timer),
                title: _serifSettingTitle(context, l10n.pomodoro),
                subtitle: Text(l10n.pomodoroSubtitle),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: () {
                  ref.read(pomodoroProvider.notifier).start();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.pomodoroStarted)),
                  );
                },
              ),
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                minLeadingWidth: 24,
                leading: const Icon(CupertinoIcons.sparkles),
                title: _serifSettingTitle(context, l10n.aiSettings),
                subtitle: Text(l10n.aiSettingsSubtitle),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: () => _showGeminiKeyDialog(context: context, ref: ref),
              ),
            ],
          ),
        ),

        // -- Account & Security --
        const SizedBox(height: 18),
        _SettingsGroupTitle(l10n.settingsAccount),
        _AdaptiveSettingsCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                minLeadingWidth: 24,
                leading: const Icon(CupertinoIcons.shield),
                title: _serifSettingTitle(context, l10n.accountAndSecurity),
                subtitle: Text(l10n.securitySubtitle),
                trailing: const Icon(CupertinoIcons.chevron_right),
                onTap: () => _showSecuritySettingsSheet(
                  context: context,
                  ref: ref,
                  isAdmin: isAdmin,
                ),
              ),
              if (user != null) ...[
                Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  minLeadingWidth: 24,
                  leading: Icon(Icons.logout_rounded, color: Colors.red.shade400),
                  title: Text(
                    l10n.signOut,
                    style: GoogleFonts.notoSerifTc(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade400,
                    ),
                  ),
                  onTap: () async {
                    await ref.read(authAnalyticsServiceProvider).logAuthEvent(
                          action: 'sign_out',
                          provider: 'session',
                          result: 'local',
                        );
                    await supabase.signOut();
                    if (context.mounted) {
                      setState(() => _currentTab = 0);
                    }
                  },
                ),
              ],
            ],
          ),
        ),

        // -- Version footer --
        const SizedBox(height: 28),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => context.push('/about'),
                child: Text(
                  '${AppConstants.appName} Recall \u00B7 v${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    decoration: TextDecoration.underline,
                    decorationColor: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\u2764\uFE0F ${l10n.madeWithLove}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDisplaySettingsSheet({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final l10n = AppLocalizations.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _buildSettingsSheetContainer(
          context: sheetContext,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: _serifSettingTitle(context, l10n.language),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showLanguageMenu(context, ref),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showGeminiKeyDialog({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final l10n = AppLocalizations.of(context);
    final currentKey = ref.read(geminiKeyProvider);
    final controller = TextEditingController(text: currentKey);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.geminiApiKey),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              hintText: l10n.geminiApiKeyHint,
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final key = controller.text.trim();
                ref.read(geminiKeyProvider.notifier).setApiKey(key);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.geminiApiKeySaved)),
                );
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  Widget _buildSettingsSheetContainer({
    required BuildContext context,
    required Widget child,
  }) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: child,
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: isLiquidGlassSupported
            ? LiquidGlass(
                borderRadius: 24,
                blurSigma: 22,
                tintColor: Colors.white.withValues(alpha: 0.26),
                child: content,
              )
            : Container(
                decoration: AppTheme.softCardDecoration(
                  fillColor: Theme.of(context).colorScheme.surface,
                  borderRadius: 24,
                  elevation: 1.2,
                ),
                child: content,
              ),
      ),
    );
  }


  Future<void> _showSecuritySettingsSheet({
    required BuildContext context,
    required WidgetRef ref,
    required bool isAdmin,
  }) async {
    final l10n = AppLocalizations.of(context);
    final supabase = ref.read(supabaseServiceProvider);
    final user = supabase.currentUser;
    final biometricQuickUnlockEnabled = ref.read(biometricQuickUnlockProvider);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _buildSettingsSheetContainer(
          context: sheetContext,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint_rounded),
                title: _serifSettingTitle(context, l10n.biometricUnlock),
                subtitle: Text(
                  user == null ? l10n.loginRequiredToEnable : l10n.biometricOnResume,
                ),
                value: biometricQuickUnlockEnabled,
                onChanged: user == null
                    ? null
                    : (enabled) async {
                        await _toggleBiometricQuickUnlock(
                          context: context,
                          ref: ref,
                          enabled: enabled,
                        );
                        if (context.mounted) Navigator.pop(sheetContext);
                      },
              ),
              if (user != null)
                ListTile(
                  leading: const Icon(Icons.security_rounded),
                  title: _serifSettingTitle(context, l10n.securityCenter),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _showSecurityCenterDialog(
                      context: context,
                      ref: ref,
                      email: user.email ?? 'Unknown',
                    );
                  },
                ),
              if (isAdmin && user != null)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_rounded),
                  title: _serifSettingTitle(context, l10n.adminConsole),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/admin');
                  },
                ),
              if (user != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(authAnalyticsServiceProvider).logAuthEvent(
                              action: 'sign_out',
                              provider: 'session',
                              result: 'local',
                            );
                        await supabase.signOut();
                        if (context.mounted) {
                          Navigator.pop(sheetContext);
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
        );
      },
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
    var passphrase = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Encrypted Backup'),
        content: TextField(
          obscureText: true,
          onChanged: (value) => passphrase = value,
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
  }

  Future<void> _showDeleteAccountDialog({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    var passwordForReauth = '';
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
              obscureText: true,
              onChanged: (value) => passwordForReauth = value,
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
                  passwordForReauth: passwordForReauth,
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
          child: _HomeSectionHeader(
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
                            child: _TaskMetric(
                              label: l10n.pendingReview,
                              value: '$dueCount',
                              tint: AppTheme.indigo,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TaskMetric(
                              label: l10n.completedToday,
                              value: '$todayReviewed',
                              tint: AppTheme.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _TaskMetric(
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
        const SizedBox(height: 10),
        const SortSelector(),
        const SizedBox(height: 8),
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
            _SheetItem(
              icon: CupertinoIcons.globe,
              iconColor: AppTheme.purple,
              title: l10n.importFromRecall,
              onTap: () {
                Navigator.pop(sheetContext);
                screenContext.push('/import');
              },
            ),
            _SheetItem(
              icon: CupertinoIcons.doc,
              iconColor: AppTheme.green,
              title: l10n.importFromFile,
              onTap: () {
                Navigator.pop(sheetContext);
                _importFromFile(screenContext, ref);
              },
            ),
            _SheetItem(
              icon: CupertinoIcons.qrcode,
              iconColor: AppTheme.cyan,
              title: l10n.scanQr,
              onTap: () {
                Navigator.pop(sheetContext);
                screenContext.push('/scan');
              },
            ),
            _SheetItem(
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

class _HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _HomeSectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 2.5,
          height: subtitle == null ? 20 : 34,
          decoration: BoxDecoration(
            color: AppTheme.indigo.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ],
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

class _TaskMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color tint;

  const _TaskMetric({
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tint,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

}

Widget _serifSettingTitle(BuildContext context, String text) {
  return Text(
    text,
    style: GoogleFonts.notoSerifTc(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class _HomeAmbientGlow extends StatelessWidget {
  const _HomeAmbientGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 24,
            child: _GlowOrb(
              size: 160,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            top: 28,
            right: -18,
            child: _GlowOrb(
              size: 220,
              color: AppTheme.cyan.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 148,
            left: -44,
            child: _GlowOrb(
              size: 180,
              color: AppTheme.indigo.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropAccents extends StatelessWidget {
  const _BackdropAccents();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned.fill(child: _DiagonalLightVeil()),
          Positioned(
            top: -68,
            right: -56,
            child: _GlowOrb(
              size: 280,
              color: Colors.white.withValues(alpha: 0.24),
            ),
          ),
          Positioned(
            top: 120,
            left: -72,
            child: _GlowOrb(
              size: 240,
              color: AppTheme.cyan.withValues(alpha: 0.13),
            ),
          ),
          Positioned(
            bottom: -80,
            right: 10,
            child: _GlowOrb(
              size: 220,
              color: AppTheme.indigo.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagonalLightVeil extends StatelessWidget {
  const _DiagonalLightVeil();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -60,
          child: Transform.rotate(
            angle: -0.32,
            child: Container(
              width: 360,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -80,
          child: Transform.rotate(
            angle: -0.28,
            child: Container(
              width: 340,
              height: 170,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.cyan.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.02),
            Colors.transparent,
          ],
          stops: const [0.0, 0.62, 1.0],
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
          CupertinoIcons.chevron_right,
          color: Colors.grey.shade400,
          size: 18,
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

class _AdaptiveSettingsCard extends StatelessWidget {
  final Widget child;

  const _AdaptiveSettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlassCard(
      borderRadius: 22,
      fillColor: Colors.white.withValues(alpha: 0.82),
      borderColor: Colors.white.withValues(alpha: 0.38),
      elevation: 2.0,
      child: child,
    );
  }
}

class _SettingsGroupTitle extends StatelessWidget {
  final String title;

  const _SettingsGroupTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
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
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

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


