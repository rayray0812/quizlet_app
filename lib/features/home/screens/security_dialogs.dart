import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/liquid_glass.dart';
import 'package:recall_app/features/home/widgets/dashboard_helpers.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/providers/auth_analytics_provider.dart';
import 'package:recall_app/providers/biometric_provider.dart';
import 'package:recall_app/providers/folder_provider.dart';
import 'package:recall_app/providers/profile_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/providers/sync_provider.dart';
import 'package:recall_app/services/import_export_service.dart';

class SecurityDialogs {
  SecurityDialogs._();

  static Future<void> showSecuritySettingsSheet({
    required BuildContext context,
    required WidgetRef ref,
    required bool isAdmin,
    required VoidCallback onResetTab,
  }) async {
    final l10n = AppLocalizations.of(context);
    final supabase = ref.read(supabaseServiceProvider);
    final user = supabase.currentUser;
    final userEmail = user?.email?.trim();
    final hasSignedInEmail = userEmail != null && userEmail.isNotEmpty;
    final biometricQuickUnlockEnabled = ref.read(biometricQuickUnlockProvider);
    final conflicts = ref.read(syncConflictsProvider);
    final conflictCount = conflicts.length;
    final analytics = ref.read(authAnalyticsServiceProvider);
    final localStorage = ref.read(localStorageServiceProvider);
    final importExportService = ImportExportService();

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
              // -- Header with shield icon + email --
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.indigo.withValues(alpha: 0.12),
                      AppTheme.cyan.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 32,
                      color: AppTheme.indigo.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.accountAndSecurity,
                      style: GoogleFonts.notoSerifTc(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(sheetContext).colorScheme.onSurface,
                      ),
                    ),
                    if (hasSignedInEmail) ...[
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                          color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // -- Security section --
              const SizedBox(height: 18),
              SettingsGroupTitle(l10n.securitySection),
              AdaptiveSettingsCard(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      secondary: const Icon(CupertinoIcons.lock_shield),
                      title: serifSettingTitle(sheetContext, l10n.biometricUnlock),
                      subtitle: Text(
                        user == null ? l10n.loginRequiredToEnable : l10n.biometricOnResume,
                        style: Theme.of(sheetContext).textTheme.bodySmall,
                      ),
                      value: biometricQuickUnlockEnabled,
                      onChanged: user == null
                          ? null
                          : (enabled) async {
                              await toggleBiometricQuickUnlock(
                                context: context,
                                ref: ref,
                                enabled: enabled,
                              );
                              if (context.mounted) Navigator.pop(sheetContext);
                            },
                    ),
                    if (hasSignedInEmail) ...[
                      Divider(height: 1, color: Theme.of(sheetContext).colorScheme.outlineVariant),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        minLeadingWidth: 24,
                        leading: const Icon(CupertinoIcons.cloud),
                        title: serifSettingTitle(sheetContext, l10n.syncConflicts),
                        subtitle: Text(
                          l10n.syncConflictsSubtitle,
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (conflictCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$conflictCount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            const Icon(CupertinoIcons.chevron_right, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showSyncConflictSheet(context: context, ref: ref);
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // -- Data Management section --
              if (hasSignedInEmail) ...[
                const SizedBox(height: 18),
                SettingsGroupTitle(l10n.dataManagement),
                AdaptiveSettingsCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        minLeadingWidth: 24,
                        leading: const Icon(CupertinoIcons.archivebox),
                        title: serifSettingTitle(sheetContext, l10n.encryptedBackup),
                        subtitle: Text(
                          l10n.encryptedBackupSubtitle,
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                        trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showEncryptedBackupSheet(
                            context: context,
                            ref: ref,
                            localStorage: localStorage,
                            importExportService: importExportService,
                          );
                        },
                      ),
                      Divider(height: 1, color: Theme.of(sheetContext).colorScheme.outlineVariant),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        minLeadingWidth: 24,
                        leading: Icon(CupertinoIcons.trash, color: Colors.red.shade400),
                        title: serifSettingTitle(sheetContext, l10n.deleteAccountTitle),
                        subtitle: Text(
                          l10n.deleteAccountSubtitle,
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                        trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showDeleteAccountSheet(context: context, ref: ref);
                        },
                      ),
                    ],
                  ),
                ),

                // -- Sign out section --
                const SizedBox(height: 18),
                AdaptiveSettingsCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        minLeadingWidth: 24,
                        leading: const Icon(Icons.logout_rounded),
                        title: serifSettingTitle(sheetContext, l10n.signOutDevice),
                        onTap: () async {
                          await analytics.logAuthEvent(
                            action: 'sign_out',
                            provider: 'session',
                            result: 'local',
                          );
                          await supabase.signOut();
                          await ref
                              .read(profileProvider.notifier)
                              .clearCachedProfile();
                          ref.invalidate(profileProvider);
                          if (context.mounted) {
                            Navigator.pop(sheetContext);
                            onResetTab();
                          }
                        },
                      ),
                      Divider(height: 1, color: Theme.of(sheetContext).colorScheme.outlineVariant),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        minLeadingWidth: 24,
                        leading: Icon(Icons.logout_rounded, color: Colors.red.shade400),
                        title: Text(
                          l10n.signOutAll,
                          style: GoogleFonts.notoSerifTc(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade400,
                          ),
                        ),
                        subtitle: Text(
                          l10n.signOutAllWarning,
                          style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade300,
                          ),
                        ),
                        onTap: () async {
                          await analytics.logAuthEvent(
                            action: 'sign_out',
                            provider: 'session',
                            result: 'global',
                          );
                          await supabase.signOutAllSessions();
                          await ref
                              .read(profileProvider.notifier)
                              .clearCachedProfile();
                          ref.invalidate(profileProvider);
                          if (context.mounted) {
                            Navigator.pop(sheetContext);
                            onResetTab();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],

              // -- Admin console --
              if (isAdmin && hasSignedInEmail) ...[
                const SizedBox(height: 18),
                AdaptiveSettingsCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    minLeadingWidth: 24,
                    leading: const Icon(Icons.admin_panel_settings_rounded),
                    title: serifSettingTitle(sheetContext, l10n.adminConsole),
                    trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push('/admin');
                    },
                  ),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static Future<void> toggleBiometricQuickUnlock({
    required BuildContext context,
    required WidgetRef ref,
    required bool enabled,
  }) async {
    final l10n = AppLocalizations.of(context);
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
        SnackBar(content: Text(l10n.biometricUnavailable)),
      );
      return;
    }

    final verified = await biometricService.authenticateForUnlock();
    if (!context.mounted) return;
    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.biometricFailed)),
      );
      return;
    }

    await notifier.setEnabled(true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.biometricEnabled)),
    );
  }

  static Future<void> _showSyncConflictSheet({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final l10n = AppLocalizations.of(context);
    final syncService = ref.read(syncServiceProvider);
    final conflicts = ref.read(syncConflictsProvider);

    if (conflicts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noSyncConflicts)),
      );
      return;
    }

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
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.withValues(alpha: 0.12),
                      Colors.amber.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.cloud_bolt,
                      size: 32,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.syncConflicts,
                      style: GoogleFonts.notoSerifTc(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.nConflicts(conflicts.length),
                      style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Conflict list
              ...conflicts.map((conflict) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdaptiveSettingsCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conflict.title,
                          style: GoogleFonts.notoSerifTc(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Local: ${conflict.localUpdatedAt.toLocal()}',
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                        Text(
                          'Remote: ${conflict.remoteUpdatedAt.toLocal()}',
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await syncService.resolveConflictKeepLocal(conflict.setId);
                                  ref.invalidate(syncConflictsProvider);
                                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                                },
                                icon: const Icon(CupertinoIcons.device_phone_portrait, size: 16),
                                label: Text(l10n.keepLocal, style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await syncService.resolveConflictKeepRemote(conflict.setId);
                                  ref.invalidate(syncConflictsProvider);
                                  ref.read(studySetsProvider.notifier).refresh();
                                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                                },
                                icon: const Icon(CupertinoIcons.cloud, size: 16),
                                label: Text(l10n.keepRemote, style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  await syncService.resolveConflictMerge(conflict.setId);
                                  ref.invalidate(syncConflictsProvider);
                                  ref.read(studySetsProvider.notifier).refresh();
                                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                                },
                                icon: const Icon(CupertinoIcons.arrow_merge, size: 16),
                                label: Text(l10n.merge, style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _showEncryptedBackupSheet({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic localStorage,
    required ImportExportService importExportService,
  }) async {
    final l10n = AppLocalizations.of(context);
    var passphrase = '';
    var obscureText = true;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return _buildSettingsSheetContainer(
              context: builderContext,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.indigo.withValues(alpha: 0.12),
                          AppTheme.cyan.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.archivebox,
                          size: 32,
                          color: AppTheme.indigo.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.encryptedBackup,
                          style: GoogleFonts.notoSerifTc(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      l10n.encryptedBackupDesc,
                      style: Theme.of(builderContext).textTheme.bodySmall?.copyWith(
                        color: Theme.of(builderContext).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Passphrase field
                  TextField(
                    obscureText: obscureText,
                    onChanged: (value) => passphrase = value,
                    decoration: InputDecoration(
                      labelText: l10n.passphrase,
                      hintText: l10n.passphraseHint,
                      prefixIcon: const Icon(CupertinoIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                        ),
                        onPressed: () => setState(() => obscureText = !obscureText),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            if (passphrase.length < 8) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.passphraseMinLength)),
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
                                SnackBar(content: Text(l10n.backupExported)),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            } finally {
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                            }
                          },
                          icon: const Icon(CupertinoIcons.arrow_up_doc, size: 18),
                          label: Text(l10n.exportBackup),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final result = await importExportService.importEncryptedBackup(
                                localStorage: localStorage,
                                passphrase: passphrase,
                              );
                              if (!context.mounted) return;
                              ref.read(studySetsProvider.notifier).refresh();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.backupImported(result.setCount))),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            } finally {
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                            }
                          },
                          icon: const Icon(CupertinoIcons.arrow_down_doc, size: 18),
                          label: Text(l10n.importBackup),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _showDeleteAccountSheet({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final l10n = AppLocalizations.of(context);
    var passwordForReauth = '';
    var obscureText = true;
    final supabase = ref.read(supabaseServiceProvider);
    final analytics = ref.read(authAnalyticsServiceProvider);
    final localStorage = ref.read(localStorageServiceProvider);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return _buildSettingsSheetContainer(
              context: builderContext,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Red warning header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.withValues(alpha: 0.12),
                          Colors.orange.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          size: 32,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.deleteAccountTitle,
                          style: GoogleFonts.notoSerifTc(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Warning text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      l10n.deleteAccountWarning,
                      style: Theme.of(builderContext).textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password field
                  TextField(
                    obscureText: obscureText,
                    onChanged: (value) => passwordForReauth = value,
                    decoration: InputDecoration(
                      labelText: l10n.passwordForReauth,
                      prefixIcon: const Icon(CupertinoIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                        ),
                        onPressed: () => setState(() => obscureText = !obscureText),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                          ),
                          onPressed: () async {
                            try {
                              final fullDeleted = await supabase.deleteCurrentAccount(
                                passwordForReauth: passwordForReauth,
                              );
                              await localStorage.clearAllUserData();
                              await ref
                                  .read(profileProvider.notifier)
                                  .clearCachedProfile();
                              await analytics.logAuthEvent(
                                action: 'delete_account',
                                provider: 'session',
                                result: fullDeleted ? 'full_deleted' : 'data_deleted',
                              );
                              if (!context.mounted) return;
                              ref.read(studySetsProvider.notifier).refresh();
                              ref.read(foldersProvider.notifier).refresh();
                              ref.invalidate(profileProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    fullDeleted
                                        ? l10n.accountDeleted
                                        : l10n.accountDataDeletedFallback,
                                  ),
                                  duration: const Duration(seconds: 6),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            } finally {
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                            }
                          },
                          child: Text(l10n.delete),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildSettingsSheetContainer({
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
}
