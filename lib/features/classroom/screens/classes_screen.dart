import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/models/classroom.dart';
import 'package:recall_app/providers/classroom_provider.dart';

class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(myRoleProvider);
    final classesAsync = ref.watch(myClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
        actions: [
          roleAsync.when(
            data: (role) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: role,
                    borderRadius: BorderRadius.circular(12),
                    onChanged: (value) async {
                      if (value == null) return;
                      await ref.read(classroomServiceProvider).updateMyRole(value);
                      ref.invalidate(myRoleProvider);
                      ref.invalidate(myClassesProvider);
                    },
                    items: const [
                      DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                      DropdownMenuItem(value: 'student', child: Text('Student')),
                    ],
                  ),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: roleAsync.when(
        data: (role) {
          if (role != 'teacher') return null;
          return FloatingActionButton.extended(
            onPressed: () => _showCreateClassDialog(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Class'),
          );
        },
        error: (_, __) => null,
        loading: () => null,
      ),
      body: classesAsync.when(
        data: (items) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myClassesProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.group_add_rounded),
                    title: const Text('Join with invite code'),
                    subtitle: const Text('Students can join a class instantly'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showJoinClassDialog(context, ref),
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: Text('No classes yet')),
                  ),
                ...items.map((classroom) => _ClassCard(item: classroom)),
              ],
            ),
          );
        },
        error: (err, _) => Center(child: Text('Failed to load classes: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _showCreateClassDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final gradeController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Class name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(labelText: 'Grade'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                await ref.read(classroomServiceProvider).createClass(
                  name: nameController.text,
                  subject: subjectController.text,
                  grade: gradeController.text,
                );
                if (context.mounted) Navigator.of(context).pop(true);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Create class failed: $e')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    nameController.dispose();
    subjectController.dispose();
    gradeController.dispose();
    if (created == true) {
      ref.invalidate(myClassesProvider);
    }
  }

  Future<void> _showJoinClassDialog(BuildContext context, WidgetRef ref) async {
    final codeController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final joined = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Class'),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Invite code',
            hintText: 'Example: A1B2C3D4',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref
                    .read(classroomServiceProvider)
                    .joinClassByInviteCode(codeController.text);
                if (context.mounted) Navigator.of(context).pop(true);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Join class failed: $e')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
    codeController.dispose();
    if (joined == true) {
      ref.invalidate(myClassesProvider);
    }
  }
}

class _ClassCard extends StatelessWidget {
  final Classroom item;

  const _ClassCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final subtitle = [item.subject, item.grade]
        .where((s) => s.trim().isNotEmpty)
        .join(' | ');
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.class_rounded)),
        title: Text(item.name),
        subtitle: Text(subtitle.isEmpty ? 'No subject/grade' : subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/classes/${item.id}'),
      ),
    );
  }
}
