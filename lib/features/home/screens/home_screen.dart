import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:quizlet_app/models/study_set.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/providers/auth_provider.dart';
import 'package:quizlet_app/providers/sync_provider.dart';
import 'package:quizlet_app/features/home/widgets/study_set_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studySets = ref.watch(studySetsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Study Sets'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => ref.refresh(syncProvider),
              tooltip: 'Sync',
            ),
          IconButton(
            icon: Icon(user != null
                ? Icons.account_circle
                : Icons.account_circle_outlined),
            onPressed: () {
              if (user != null) {
                _showProfileDialog(context, ref);
              } else {
                context.go('/login');
              }
            },
            tooltip: user != null ? 'Profile' : 'Log In',
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
                    'No study sets yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Import from Quizlet or create your own',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.go('/import'),
                        icon: const Icon(Icons.download),
                        label: const Text('Import'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showCreateDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: studySets.length,
              itemBuilder: (context, index) {
                final set = studySets[index];
                return StudySetCard(
                  studySet: set,
                  onTap: () => context.go('/study/${set.id}'),
                  onDelete: () => _confirmDelete(context, ref, set),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrImportSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateOrImportSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create New Set'),
              onTap: () {
                Navigator.pop(context);
                _showCreateDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Import from Quizlet'),
              onTap: () {
                Navigator.pop(context);
                context.go('/import');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Study Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, StudySet set) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Study Set?'),
        content: Text('Are you sure you want to delete "${set.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(studySetsProvider.notifier).remove(set.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, WidgetRef ref) {
    final supabase = ref.read(supabaseServiceProvider);
    final user = supabase.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Text('Signed in as:\n${user?.email ?? "Unknown"}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await supabase.signOut();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
