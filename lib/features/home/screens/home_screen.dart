import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:quizlet_app/models/study_set.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/providers/auth_provider.dart';
import 'package:quizlet_app/providers/sync_provider.dart';
import 'package:quizlet_app/providers/locale_provider.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';
import 'package:quizlet_app/features/home/widgets/study_set_card.dart';
import 'package:quizlet_app/features/home/widgets/today_review_card.dart';
import 'package:quizlet_app/services/import_export_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studySets = ref.watch(studySetsProvider);
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myStudySets),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
            tooltip: l10n.search,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/stats'),
            tooltip: l10n.statistics,
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _showLanguageMenu(context, ref),
            tooltip: l10n.language,
          ),
          if (user != null)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => ref.refresh(syncProvider),
              tooltip: l10n.sync,
            ),
          IconButton(
            icon: Icon(user != null
                ? Icons.account_circle
                : Icons.account_circle_outlined),
            onPressed: () {
              if (user != null) {
                _showProfileDialog(context, ref);
              } else {
                context.push('/login');
              }
            },
            tooltip: user != null ? l10n.profile : l10n.logIn,
          ),
        ],
      ),
      body: studySets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noStudySetsYet,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.importOrCreate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push('/import'),
                        icon: const Icon(Icons.download),
                        label: Text(l10n.importBtn),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showCreateDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.createBtn),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: studySets.length + 1, // +1 for today review banner
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const TodayReviewCard();
                }
                final set = studySets[index - 1];
                return StudySetCard(
                  studySet: set,
                  onTap: () => context.push('/study/${set.id}'),
                  onDelete: () => _confirmDelete(context, ref, set),
                  onEdit: () => context.push('/edit/${set.id}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrImportSheet(context, ref),
        child: const Icon(Icons.add),
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
              onTap: () {
                ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('zh', 'TW'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.english),
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

  void _showCreateOrImportSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.createNewSet),
              onTap: () {
                Navigator.pop(context);
                _showCreateDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(l10n.importFromQuizlet),
              onTap: () {
                Navigator.pop(context);
                context.push('/import');
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_open),
              title: Text(l10n.importFromFile),
              onTap: () {
                Navigator.pop(context);
                _importFromFile(context, ref);
              },
            ),
          ],
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

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newStudySet),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: l10n.title),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration:
                  InputDecoration(labelText: l10n.descriptionOptional),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
                createdAt: DateTime.now(),
                cards: [],
              );
              ref.read(studySetsProvider.notifier).add(newSet);
              Navigator.pop(context);
              context.push('/edit/${newSet.id}');
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final supabase = ref.read(supabaseServiceProvider);
    final user = supabase.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.profile),
        content: Text(l10n.signedInAs(user?.email ?? 'Unknown')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: () async {
              await supabase.signOut();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}
